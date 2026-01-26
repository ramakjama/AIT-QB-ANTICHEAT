--[[
    AIT Framework - Sistema de Conexion a Base de Datos
    Wrapper para oxmysql con pool management y query builder

    Autor: AIT Development Team
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.DB = AIT.DB or {}

-- ============================================================================
-- CONFIGURACION
-- ============================================================================

local Config = {
    -- Configuracion del pool
    maxConnections = 10,
    connectionTimeout = 30000,
    queryTimeout = 10000,

    -- Configuracion de reintentos
    maxRetries = 3,
    retryDelay = 1000,

    -- Configuracion de logs
    enableLogging = true,
    logQueries = false,
    logSlowQueries = true,
    slowQueryThreshold = 1000, -- ms

    -- Configuracion de cache
    enableCache = true,
    cacheTimeout = 60000 -- ms
}

-- ============================================================================
-- ESTADO INTERNO
-- ============================================================================

local State = {
    initialized = false,
    activeTransactions = {},
    preparedStatements = {},
    queryCache = {},
    stats = {
        totalQueries = 0,
        successfulQueries = 0,
        failedQueries = 0,
        slowQueries = 0,
        cachedQueries = 0
    }
}

-- ============================================================================
-- UTILIDADES INTERNAS
-- ============================================================================

--- Genera un ID unico para transacciones
---@return string
local function GenerateTransactionId()
    return string.format("txn_%s_%d", os.time(), math.random(10000, 99999))
end

--- Registra un mensaje en la consola
---@param level string Nivel del log (info, warn, error, debug)
---@param message string Mensaje a registrar
---@param data? table Datos adicionales
local function Log(level, message, data)
    if not Config.enableLogging then return end

    local prefix = "[AIT.DB]"
    local formattedMessage = string.format("%s [%s] %s", prefix, level:upper(), message)

    if data then
        formattedMessage = formattedMessage .. " | Datos: " .. json.encode(data)
    end

    if level == "error" then
        print("^1" .. formattedMessage .. "^0")
    elseif level == "warn" then
        print("^3" .. formattedMessage .. "^0")
    elseif level == "debug" then
        print("^5" .. formattedMessage .. "^0")
    else
        print("^2" .. formattedMessage .. "^0")
    end
end

--- Mide el tiempo de ejecucion de una query
---@param startTime number Tiempo de inicio
---@return number
local function GetElapsedTime(startTime)
    return (os.clock() - startTime) * 1000
end

--- Valida los parametros de una query
---@param params table Parametros a validar
---@return boolean
---@return string?
local function ValidateParams(params)
    if type(params) ~= "table" then
        return false, "Los parametros deben ser una tabla"
    end
    return true, nil
end

--- Escapa valores para prevenir SQL injection (uso basico)
---@param value any Valor a escapar
---@return string
local function EscapeValue(value)
    if value == nil then
        return "NULL"
    elseif type(value) == "number" then
        return tostring(value)
    elseif type(value) == "boolean" then
        return value and "1" or "0"
    elseif type(value) == "string" then
        -- Escapar comillas simples
        return "'" .. value:gsub("'", "''") .. "'"
    else
        return "'" .. tostring(value):gsub("'", "''") .. "'"
    end
end

-- ============================================================================
-- QUERY BUILDER
-- ============================================================================

AIT.DB.QueryBuilder = {}
AIT.DB.QueryBuilder.__index = AIT.DB.QueryBuilder

--- Crea una nueva instancia del query builder
---@param tableName string Nombre de la tabla
---@return table
function AIT.DB.QueryBuilder:New(tableName)
    local instance = setmetatable({}, self)
    instance.tableName = tableName
    instance.selectColumns = "*"
    instance.whereConditions = {}
    instance.whereParams = {}
    instance.orderByClause = nil
    instance.limitValue = nil
    instance.offsetValue = nil
    instance.joinClauses = {}
    instance.groupByClause = nil
    instance.havingClause = nil
    return instance
end

--- Especifica las columnas a seleccionar
---@param columns string|table Columnas a seleccionar
---@return table
function AIT.DB.QueryBuilder:Select(columns)
    if type(columns) == "table" then
        self.selectColumns = table.concat(columns, ", ")
    else
        self.selectColumns = columns
    end
    return self
end

--- Agrega una condicion WHERE
---@param condition string Condicion SQL
---@param params? table Parametros para la condicion
---@return table
function AIT.DB.QueryBuilder:Where(condition, params)
    table.insert(self.whereConditions, condition)
    if params then
        for _, param in ipairs(params) do
            table.insert(self.whereParams, param)
        end
    end
    return self
end

--- Agrega una condicion WHERE con AND
---@param condition string Condicion SQL
---@param params? table Parametros
---@return table
function AIT.DB.QueryBuilder:AndWhere(condition, params)
    return self:Where(condition, params)
end

--- Agrega una condicion WHERE con OR
---@param condition string Condicion SQL
---@param params? table Parametros
---@return table
function AIT.DB.QueryBuilder:OrWhere(condition, params)
    if #self.whereConditions > 0 then
        local lastCondition = table.remove(self.whereConditions)
        table.insert(self.whereConditions, "(" .. lastCondition .. " OR " .. condition .. ")")
    else
        table.insert(self.whereConditions, condition)
    end
    if params then
        for _, param in ipairs(params) do
            table.insert(self.whereParams, param)
        end
    end
    return self
end

--- Agrega un JOIN
---@param joinType string Tipo de join (INNER, LEFT, RIGHT)
---@param tableName string Nombre de la tabla
---@param condition string Condicion del join
---@return table
function AIT.DB.QueryBuilder:Join(joinType, tableName, condition)
    table.insert(self.joinClauses, string.format("%s JOIN %s ON %s", joinType, tableName, condition))
    return self
end

--- Agrega un LEFT JOIN
---@param tableName string Nombre de la tabla
---@param condition string Condicion del join
---@return table
function AIT.DB.QueryBuilder:LeftJoin(tableName, condition)
    return self:Join("LEFT", tableName, condition)
end

--- Agrega un INNER JOIN
---@param tableName string Nombre de la tabla
---@param condition string Condicion del join
---@return table
function AIT.DB.QueryBuilder:InnerJoin(tableName, condition)
    return self:Join("INNER", tableName, condition)
end

--- Agrega ORDER BY
---@param column string Columna por la cual ordenar
---@param direction? string Direccion (ASC o DESC)
---@return table
function AIT.DB.QueryBuilder:OrderBy(column, direction)
    direction = direction or "ASC"
    self.orderByClause = string.format("%s %s", column, direction)
    return self
end

--- Agrega GROUP BY
---@param columns string|table Columnas para agrupar
---@return table
function AIT.DB.QueryBuilder:GroupBy(columns)
    if type(columns) == "table" then
        self.groupByClause = table.concat(columns, ", ")
    else
        self.groupByClause = columns
    end
    return self
end

--- Agrega HAVING
---@param condition string Condicion HAVING
---@return table
function AIT.DB.QueryBuilder:Having(condition)
    self.havingClause = condition
    return self
end

--- Agrega LIMIT
---@param limit number Limite de resultados
---@return table
function AIT.DB.QueryBuilder:Limit(limit)
    self.limitValue = limit
    return self
end

--- Agrega OFFSET
---@param offset number Offset de resultados
---@return table
function AIT.DB.QueryBuilder:Offset(offset)
    self.offsetValue = offset
    return self
end

--- Construye la query SELECT
---@return string
---@return table
function AIT.DB.QueryBuilder:BuildSelect()
    local query = string.format("SELECT %s FROM %s", self.selectColumns, self.tableName)

    -- Agregar JOINs
    if #self.joinClauses > 0 then
        query = query .. " " .. table.concat(self.joinClauses, " ")
    end

    -- Agregar WHERE
    if #self.whereConditions > 0 then
        query = query .. " WHERE " .. table.concat(self.whereConditions, " AND ")
    end

    -- Agregar GROUP BY
    if self.groupByClause then
        query = query .. " GROUP BY " .. self.groupByClause
    end

    -- Agregar HAVING
    if self.havingClause then
        query = query .. " HAVING " .. self.havingClause
    end

    -- Agregar ORDER BY
    if self.orderByClause then
        query = query .. " ORDER BY " .. self.orderByClause
    end

    -- Agregar LIMIT
    if self.limitValue then
        query = query .. " LIMIT " .. self.limitValue
    end

    -- Agregar OFFSET
    if self.offsetValue then
        query = query .. " OFFSET " .. self.offsetValue
    end

    return query, self.whereParams
end

--- Ejecuta la query SELECT
---@return table|nil
function AIT.DB.QueryBuilder:Get()
    local query, params = self:BuildSelect()
    return AIT.DB.Query(query, params)
end

--- Ejecuta la query y retorna el primer resultado
---@return table|nil
function AIT.DB.QueryBuilder:First()
    self:Limit(1)
    local results = self:Get()
    if results and #results > 0 then
        return results[1]
    end
    return nil
end

-- ============================================================================
-- FUNCIONES PRINCIPALES DE BASE DE DATOS
-- ============================================================================

--- Inicializa la conexion a la base de datos
---@param config? table Configuracion opcional
---@return boolean
function AIT.DB.Initialize(config)
    if config then
        for key, value in pairs(config) do
            Config[key] = value
        end
    end

    -- Verificar que oxmysql este disponible
    if not MySQL then
        Log("error", "oxmysql no esta disponible. Asegurate de que este iniciado antes que este recurso.")
        return false
    end

    State.initialized = true
    Log("info", "Sistema de base de datos inicializado correctamente")
    return true
end

--- Ejecuta una query con parametros
---@param query string Query SQL
---@param params? table Parametros de la query
---@return table|nil
function AIT.DB.Query(query, params)
    if not State.initialized then
        Log("error", "El sistema de base de datos no esta inicializado")
        return nil
    end

    params = params or {}
    local startTime = os.clock()

    State.stats.totalQueries = State.stats.totalQueries + 1

    if Config.logQueries then
        Log("debug", "Ejecutando query", {query = query, params = params})
    end

    local success, result = pcall(function()
        return MySQL.query.await(query, params)
    end)

    local elapsed = GetElapsedTime(startTime)

    if not success then
        State.stats.failedQueries = State.stats.failedQueries + 1
        Log("error", "Error ejecutando query: " .. tostring(result), {query = query})
        return nil
    end

    State.stats.successfulQueries = State.stats.successfulQueries + 1

    if Config.logSlowQueries and elapsed > Config.slowQueryThreshold then
        State.stats.slowQueries = State.stats.slowQueries + 1
        Log("warn", string.format("Query lenta detectada (%.2fms)", elapsed), {query = query})
    end

    return result
end

--- Ejecuta una query y retorna un solo resultado
---@param query string Query SQL
---@param params? table Parametros
---@return table|nil
function AIT.DB.Single(query, params)
    local results = AIT.DB.Query(query, params)
    if results and #results > 0 then
        return results[1]
    end
    return nil
end

--- Ejecuta una query y retorna un valor escalar
---@param query string Query SQL
---@param params? table Parametros
---@return any
function AIT.DB.Scalar(query, params)
    local result = AIT.DB.Single(query, params)
    if result then
        for _, value in pairs(result) do
            return value
        end
    end
    return nil
end

--- Ejecuta una query INSERT
---@param query string Query SQL
---@param params? table Parametros
---@return number|nil ID insertado
function AIT.DB.Insert(query, params)
    if not State.initialized then
        Log("error", "El sistema de base de datos no esta inicializado")
        return nil
    end

    params = params or {}

    local success, result = pcall(function()
        return MySQL.insert.await(query, params)
    end)

    if not success then
        Log("error", "Error ejecutando INSERT: " .. tostring(result), {query = query})
        return nil
    end

    return result
end

--- Ejecuta una query UPDATE
---@param query string Query SQL
---@param params? table Parametros
---@return number Filas afectadas
function AIT.DB.Update(query, params)
    if not State.initialized then
        Log("error", "El sistema de base de datos no esta inicializado")
        return 0
    end

    params = params or {}

    local success, result = pcall(function()
        return MySQL.update.await(query, params)
    end)

    if not success then
        Log("error", "Error ejecutando UPDATE: " .. tostring(result), {query = query})
        return 0
    end

    return result or 0
end

--- Ejecuta una query DELETE
---@param query string Query SQL
---@param params? table Parametros
---@return number Filas afectadas
function AIT.DB.Delete(query, params)
    return AIT.DB.Update(query, params)
end

-- ============================================================================
-- TRANSACCIONES
-- ============================================================================

--- Inicia una nueva transaccion
---@return string|nil ID de la transaccion
function AIT.DB.BeginTransaction()
    if not State.initialized then
        Log("error", "El sistema de base de datos no esta inicializado")
        return nil
    end

    local txnId = GenerateTransactionId()

    local success = pcall(function()
        MySQL.query.await("START TRANSACTION")
    end)

    if not success then
        Log("error", "Error iniciando transaccion")
        return nil
    end

    State.activeTransactions[txnId] = {
        startTime = os.time(),
        queries = 0
    }

    Log("debug", "Transaccion iniciada: " .. txnId)
    return txnId
end

--- Confirma una transaccion
---@param txnId string ID de la transaccion
---@return boolean
function AIT.DB.Commit(txnId)
    if not State.activeTransactions[txnId] then
        Log("error", "Transaccion no encontrada: " .. txnId)
        return false
    end

    local success = pcall(function()
        MySQL.query.await("COMMIT")
    end)

    if not success then
        Log("error", "Error confirmando transaccion: " .. txnId)
        return false
    end

    State.activeTransactions[txnId] = nil
    Log("debug", "Transaccion confirmada: " .. txnId)
    return true
end

--- Revierte una transaccion
---@param txnId string ID de la transaccion
---@return boolean
function AIT.DB.Rollback(txnId)
    if not State.activeTransactions[txnId] then
        Log("error", "Transaccion no encontrada: " .. txnId)
        return false
    end

    local success = pcall(function()
        MySQL.query.await("ROLLBACK")
    end)

    if not success then
        Log("error", "Error revirtiendo transaccion: " .. txnId)
        return false
    end

    State.activeTransactions[txnId] = nil
    Log("debug", "Transaccion revertida: " .. txnId)
    return true
end

--- Ejecuta una funcion dentro de una transaccion
---@param callback function Funcion a ejecutar
---@return boolean
---@return any
function AIT.DB.Transaction(callback)
    local txnId = AIT.DB.BeginTransaction()
    if not txnId then
        return false, "Error iniciando transaccion"
    end

    local success, result = pcall(callback)

    if success then
        if AIT.DB.Commit(txnId) then
            return true, result
        else
            AIT.DB.Rollback(txnId)
            return false, "Error confirmando transaccion"
        end
    else
        AIT.DB.Rollback(txnId)
        return false, result
    end
end

-- ============================================================================
-- PREPARED STATEMENTS
-- ============================================================================

--- Prepara una query para ejecucion repetida
---@param name string Nombre del statement
---@param query string Query SQL
---@return boolean
function AIT.DB.Prepare(name, query)
    State.preparedStatements[name] = query
    Log("debug", "Statement preparado: " .. name)
    return true
end

--- Ejecuta un statement preparado
---@param name string Nombre del statement
---@param params? table Parametros
---@return table|nil
function AIT.DB.Execute(name, params)
    local query = State.preparedStatements[name]
    if not query then
        Log("error", "Statement no encontrado: " .. name)
        return nil
    end

    return AIT.DB.Query(query, params)
end

-- ============================================================================
-- UTILIDADES
-- ============================================================================

--- Crea un nuevo query builder para una tabla
---@param tableName string Nombre de la tabla
---@return table
function AIT.DB.Table(tableName)
    return AIT.DB.QueryBuilder:New(tableName)
end

--- Obtiene las estadisticas de la base de datos
---@return table
function AIT.DB.GetStats()
    return {
        totalQueries = State.stats.totalQueries,
        successfulQueries = State.stats.successfulQueries,
        failedQueries = State.stats.failedQueries,
        slowQueries = State.stats.slowQueries,
        cachedQueries = State.stats.cachedQueries,
        activeTransactions = #State.activeTransactions
    }
end

--- Limpia la cache de queries
function AIT.DB.ClearCache()
    State.queryCache = {}
    Log("info", "Cache de queries limpiada")
end

--- Verifica si la conexion esta activa
---@return boolean
function AIT.DB.IsConnected()
    if not State.initialized then
        return false
    end

    local success = pcall(function()
        MySQL.query.await("SELECT 1")
    end)

    return success
end

-- ============================================================================
-- INICIALIZACION AUTOMATICA
-- ============================================================================

CreateThread(function()
    Wait(1000) -- Esperar a que oxmysql este listo
    AIT.DB.Initialize()
end)

-- Exportar funciones principales
exports("DB_Query", AIT.DB.Query)
exports("DB_Single", AIT.DB.Single)
exports("DB_Scalar", AIT.DB.Scalar)
exports("DB_Insert", AIT.DB.Insert)
exports("DB_Update", AIT.DB.Update)
exports("DB_Delete", AIT.DB.Delete)
exports("DB_Table", AIT.DB.Table)
exports("DB_Transaction", AIT.DB.Transaction)

Log("info", "Modulo AIT.DB cargado correctamente")
