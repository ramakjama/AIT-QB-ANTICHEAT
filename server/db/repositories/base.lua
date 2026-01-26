--[[
    AIT Framework - Repositorio Base
    Clase base para todos los repositorios con operaciones CRUD genericas

    Autor: AIT Development Team
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.DB = AIT.DB or {}
AIT.DB.Repositories = AIT.DB.Repositories or {}

-- ============================================================================
-- CLASE BASE REPOSITORY
-- ============================================================================

AIT.DB.Repositories.Base = {}
AIT.DB.Repositories.Base.__index = AIT.DB.Repositories.Base

-- ============================================================================
-- CONFIGURACION POR DEFECTO
-- ============================================================================

local DefaultConfig = {
    -- Nombre de la tabla (debe ser sobrescrito)
    tableName = nil,

    -- Columna de clave primaria
    primaryKey = "id",

    -- Habilitar timestamps automaticos
    timestamps = true,
    createdAtColumn = "created_at",
    updatedAtColumn = "updated_at",

    -- Habilitar soft deletes
    softDeletes = false,
    deletedAtColumn = "deleted_at",

    -- Columnas que se pueden asignar masivamente
    fillable = {},

    -- Columnas protegidas (no se pueden modificar)
    guarded = {"id", "created_at"},

    -- Columnas ocultas (no se incluyen en los resultados)
    hidden = {},

    -- Valores por defecto
    defaults = {},

    -- Relaciones
    relations = {},

    -- Cache
    enableCache = false,
    cacheTimeout = 60000
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

--- Crea una nueva instancia del repositorio
---@param config? table Configuracion del repositorio
---@return table
function AIT.DB.Repositories.Base:New(config)
    local instance = setmetatable({}, self)

    -- Combinar configuracion por defecto con la proporcionada
    instance.config = {}
    for key, value in pairs(DefaultConfig) do
        instance.config[key] = value
    end

    if config then
        for key, value in pairs(config) do
            instance.config[key] = value
        end
    end

    -- Validar configuracion
    if not instance.config.tableName then
        error("[AIT.DB.Repository] tableName es requerido")
    end

    -- Cache interna
    instance.cache = {}
    instance.cacheTimestamps = {}

    return instance
end

-- ============================================================================
-- UTILIDADES INTERNAS
-- ============================================================================

--- Obtiene la fecha/hora actual en formato SQL
---@return string
local function GetCurrentTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

--- Filtra las columnas segun fillable y guarded
---@param data table Datos a filtrar
---@param fillable table Columnas permitidas
---@param guarded table Columnas protegidas
---@return table
local function FilterColumns(data, fillable, guarded)
    local filtered = {}

    for key, value in pairs(data) do
        local isAllowed = true

        -- Verificar si esta en guarded
        for _, guardedCol in ipairs(guarded) do
            if key == guardedCol then
                isAllowed = false
                break
            end
        end

        -- Verificar si esta en fillable (si fillable no esta vacio)
        if isAllowed and #fillable > 0 then
            isAllowed = false
            for _, fillableCol in ipairs(fillable) do
                if key == fillableCol then
                    isAllowed = true
                    break
                end
            end
        end

        if isAllowed then
            filtered[key] = value
        end
    end

    return filtered
end

--- Oculta columnas del resultado
---@param data table Datos a procesar
---@param hidden table Columnas a ocultar
---@return table
local function HideColumns(data, hidden)
    if not data or #hidden == 0 then
        return data
    end

    local result = {}
    for key, value in pairs(data) do
        local shouldHide = false
        for _, hiddenCol in ipairs(hidden) do
            if key == hiddenCol then
                shouldHide = true
                break
            end
        end
        if not shouldHide then
            result[key] = value
        end
    end

    return result
end

--- Aplica valores por defecto
---@param data table Datos originales
---@param defaults table Valores por defecto
---@return table
local function ApplyDefaults(data, defaults)
    local result = {}

    -- Copiar defaults
    for key, value in pairs(defaults) do
        result[key] = value
    end

    -- Sobrescribir con datos proporcionados
    for key, value in pairs(data) do
        result[key] = value
    end

    return result
end

--- Genera una clave de cache
---@param method string Nombre del metodo
---@param params table Parametros
---@return string
local function GenerateCacheKey(method, params)
    return method .. "_" .. json.encode(params or {})
end

-- ============================================================================
-- METODOS DE CACHE
-- ============================================================================

--- Obtiene un valor de la cache
---@param key string Clave de cache
---@return any|nil
function AIT.DB.Repositories.Base:GetFromCache(key)
    if not self.config.enableCache then
        return nil
    end

    local timestamp = self.cacheTimestamps[key]
    if not timestamp then
        return nil
    end

    local now = GetGameTimer()
    if now - timestamp > self.config.cacheTimeout then
        self.cache[key] = nil
        self.cacheTimestamps[key] = nil
        return nil
    end

    return self.cache[key]
end

--- Guarda un valor en la cache
---@param key string Clave de cache
---@param value any Valor a guardar
function AIT.DB.Repositories.Base:SetCache(key, value)
    if not self.config.enableCache then
        return
    end

    self.cache[key] = value
    self.cacheTimestamps[key] = GetGameTimer()
end

--- Invalida la cache
---@param pattern? string Patron de claves a invalidar
function AIT.DB.Repositories.Base:InvalidateCache(pattern)
    if pattern then
        for key in pairs(self.cache) do
            if key:find(pattern) then
                self.cache[key] = nil
                self.cacheTimestamps[key] = nil
            end
        end
    else
        self.cache = {}
        self.cacheTimestamps = {}
    end
end

-- ============================================================================
-- METODOS CRUD BASICOS
-- ============================================================================

--- Busca un registro por su ID
---@param id number|string ID del registro
---@return table|nil
function AIT.DB.Repositories.Base:FindById(id)
    local cacheKey = GenerateCacheKey("FindById", {id = id})
    local cached = self:GetFromCache(cacheKey)
    if cached then
        return cached
    end

    local query = string.format(
        "SELECT * FROM %s WHERE %s = ?",
        self.config.tableName,
        self.config.primaryKey
    )

    -- Agregar condicion de soft delete si esta habilitado
    if self.config.softDeletes then
        query = query .. string.format(" AND %s IS NULL", self.config.deletedAtColumn)
    end

    local result = AIT.DB.Single(query, {id})

    if result then
        result = HideColumns(result, self.config.hidden)
        self:SetCache(cacheKey, result)
    end

    return result
end

--- Busca todos los registros
---@param options? table Opciones de busqueda (limit, offset, orderBy, orderDirection)
---@return table
function AIT.DB.Repositories.Base:FindAll(options)
    options = options or {}

    local query = string.format("SELECT * FROM %s", self.config.tableName)

    -- Agregar condicion de soft delete si esta habilitado
    if self.config.softDeletes then
        query = query .. string.format(" WHERE %s IS NULL", self.config.deletedAtColumn)
    end

    -- Ordenamiento
    if options.orderBy then
        local direction = options.orderDirection or "ASC"
        query = query .. string.format(" ORDER BY %s %s", options.orderBy, direction)
    end

    -- Limite
    if options.limit then
        query = query .. string.format(" LIMIT %d", options.limit)
    end

    -- Offset
    if options.offset then
        query = query .. string.format(" OFFSET %d", options.offset)
    end

    local results = AIT.DB.Query(query) or {}

    -- Ocultar columnas
    for i, result in ipairs(results) do
        results[i] = HideColumns(result, self.config.hidden)
    end

    return results
end

--- Busca registros por condiciones
---@param conditions table Condiciones de busqueda {columna = valor}
---@param options? table Opciones adicionales
---@return table
function AIT.DB.Repositories.Base:FindBy(conditions, options)
    options = options or {}

    local whereClauses = {}
    local params = {}

    for column, value in pairs(conditions) do
        if value == nil then
            table.insert(whereClauses, string.format("%s IS NULL", column))
        else
            table.insert(whereClauses, string.format("%s = ?", column))
            table.insert(params, value)
        end
    end

    local query = string.format(
        "SELECT * FROM %s WHERE %s",
        self.config.tableName,
        table.concat(whereClauses, " AND ")
    )

    -- Agregar condicion de soft delete si esta habilitado
    if self.config.softDeletes then
        query = query .. string.format(" AND %s IS NULL", self.config.deletedAtColumn)
    end

    -- Ordenamiento
    if options.orderBy then
        local direction = options.orderDirection or "ASC"
        query = query .. string.format(" ORDER BY %s %s", options.orderBy, direction)
    end

    -- Limite
    if options.limit then
        query = query .. string.format(" LIMIT %d", options.limit)
    end

    local results = AIT.DB.Query(query, params) or {}

    -- Ocultar columnas
    for i, result in ipairs(results) do
        results[i] = HideColumns(result, self.config.hidden)
    end

    return results
end

--- Busca el primer registro que coincida
---@param conditions table Condiciones de busqueda
---@return table|nil
function AIT.DB.Repositories.Base:FindOneBy(conditions)
    local results = self:FindBy(conditions, {limit = 1})
    if #results > 0 then
        return results[1]
    end
    return nil
end

--- Cuenta los registros
---@param conditions? table Condiciones de conteo
---@return number
function AIT.DB.Repositories.Base:Count(conditions)
    local query = string.format("SELECT COUNT(*) as count FROM %s", self.config.tableName)
    local params = {}

    local whereClauses = {}

    if conditions then
        for column, value in pairs(conditions) do
            if value == nil then
                table.insert(whereClauses, string.format("%s IS NULL", column))
            else
                table.insert(whereClauses, string.format("%s = ?", column))
                table.insert(params, value)
            end
        end
    end

    -- Agregar condicion de soft delete si esta habilitado
    if self.config.softDeletes then
        table.insert(whereClauses, string.format("%s IS NULL", self.config.deletedAtColumn))
    end

    if #whereClauses > 0 then
        query = query .. " WHERE " .. table.concat(whereClauses, " AND ")
    end

    local result = AIT.DB.Single(query, params)
    return result and result.count or 0
end

--- Verifica si existe un registro
---@param conditions table Condiciones de busqueda
---@return boolean
function AIT.DB.Repositories.Base:Exists(conditions)
    return self:Count(conditions) > 0
end

-- ============================================================================
-- METODOS DE CREACION
-- ============================================================================

--- Crea un nuevo registro
---@param data table Datos del registro
---@return table|nil Registro creado con ID
function AIT.DB.Repositories.Base:Create(data)
    -- Aplicar valores por defecto
    data = ApplyDefaults(data, self.config.defaults)

    -- Filtrar columnas
    data = FilterColumns(data, self.config.fillable, self.config.guarded)

    -- Agregar timestamps
    if self.config.timestamps then
        local now = GetCurrentTimestamp()
        data[self.config.createdAtColumn] = now
        data[self.config.updatedAtColumn] = now
    end

    -- Construir query
    local columns = {}
    local placeholders = {}
    local values = {}

    for column, value in pairs(data) do
        table.insert(columns, column)
        table.insert(placeholders, "?")
        table.insert(values, value)
    end

    local query = string.format(
        "INSERT INTO %s (%s) VALUES (%s)",
        self.config.tableName,
        table.concat(columns, ", "),
        table.concat(placeholders, ", ")
    )

    local insertId = AIT.DB.Insert(query, values)

    if insertId then
        self:InvalidateCache()
        return self:FindById(insertId)
    end

    return nil
end

--- Crea multiples registros
---@param dataList table Lista de datos
---@return table Lista de IDs creados
function AIT.DB.Repositories.Base:CreateMany(dataList)
    local createdIds = {}

    local success, err = AIT.DB.Transaction(function()
        for _, data in ipairs(dataList) do
            local created = self:Create(data)
            if created then
                table.insert(createdIds, created[self.config.primaryKey])
            end
        end
    end)

    if not success then
        print("[AIT.DB.Repository] Error en CreateMany: " .. tostring(err))
        return {}
    end

    return createdIds
end

--- Crea o actualiza un registro
---@param conditions table Condiciones de busqueda
---@param data table Datos a crear/actualizar
---@return table|nil
function AIT.DB.Repositories.Base:FirstOrCreate(conditions, data)
    local existing = self:FindOneBy(conditions)
    if existing then
        return existing
    end

    -- Combinar condiciones con datos
    local createData = {}
    for k, v in pairs(conditions) do
        createData[k] = v
    end
    for k, v in pairs(data or {}) do
        createData[k] = v
    end

    return self:Create(createData)
end

--- Actualiza o crea un registro
---@param conditions table Condiciones de busqueda
---@param data table Datos a actualizar/crear
---@return table|nil
function AIT.DB.Repositories.Base:UpdateOrCreate(conditions, data)
    local existing = self:FindOneBy(conditions)
    if existing then
        return self:Update(existing[self.config.primaryKey], data)
    end

    -- Combinar condiciones con datos
    local createData = {}
    for k, v in pairs(conditions) do
        createData[k] = v
    end
    for k, v in pairs(data or {}) do
        createData[k] = v
    end

    return self:Create(createData)
end

-- ============================================================================
-- METODOS DE ACTUALIZACION
-- ============================================================================

--- Actualiza un registro por ID
---@param id number|string ID del registro
---@param data table Datos a actualizar
---@return table|nil Registro actualizado
function AIT.DB.Repositories.Base:Update(id, data)
    -- Filtrar columnas
    data = FilterColumns(data, self.config.fillable, self.config.guarded)

    if not next(data) then
        return self:FindById(id)
    end

    -- Agregar timestamp de actualizacion
    if self.config.timestamps then
        data[self.config.updatedAtColumn] = GetCurrentTimestamp()
    end

    -- Construir query
    local setClauses = {}
    local values = {}

    for column, value in pairs(data) do
        table.insert(setClauses, string.format("%s = ?", column))
        table.insert(values, value)
    end

    table.insert(values, id)

    local query = string.format(
        "UPDATE %s SET %s WHERE %s = ?",
        self.config.tableName,
        table.concat(setClauses, ", "),
        self.config.primaryKey
    )

    local affected = AIT.DB.Update(query, values)

    if affected > 0 then
        self:InvalidateCache()
        return self:FindById(id)
    end

    return nil
end

--- Actualiza multiples registros por condiciones
---@param conditions table Condiciones de busqueda
---@param data table Datos a actualizar
---@return number Filas afectadas
function AIT.DB.Repositories.Base:UpdateWhere(conditions, data)
    -- Filtrar columnas
    data = FilterColumns(data, self.config.fillable, self.config.guarded)

    if not next(data) then
        return 0
    end

    -- Agregar timestamp de actualizacion
    if self.config.timestamps then
        data[self.config.updatedAtColumn] = GetCurrentTimestamp()
    end

    -- Construir SET clause
    local setClauses = {}
    local values = {}

    for column, value in pairs(data) do
        table.insert(setClauses, string.format("%s = ?", column))
        table.insert(values, value)
    end

    -- Construir WHERE clause
    local whereClauses = {}
    for column, value in pairs(conditions) do
        table.insert(whereClauses, string.format("%s = ?", column))
        table.insert(values, value)
    end

    local query = string.format(
        "UPDATE %s SET %s WHERE %s",
        self.config.tableName,
        table.concat(setClauses, ", "),
        table.concat(whereClauses, " AND ")
    )

    local affected = AIT.DB.Update(query, values)

    if affected > 0 then
        self:InvalidateCache()
    end

    return affected
end

--- Incrementa un valor numerico
---@param id number|string ID del registro
---@param column string Columna a incrementar
---@param amount? number Cantidad a incrementar (default: 1)
---@return boolean
function AIT.DB.Repositories.Base:Increment(id, column, amount)
    amount = amount or 1

    local query = string.format(
        "UPDATE %s SET %s = %s + ? WHERE %s = ?",
        self.config.tableName,
        column,
        column,
        self.config.primaryKey
    )

    local affected = AIT.DB.Update(query, {amount, id})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Decrementa un valor numerico
---@param id number|string ID del registro
---@param column string Columna a decrementar
---@param amount? number Cantidad a decrementar (default: 1)
---@return boolean
function AIT.DB.Repositories.Base:Decrement(id, column, amount)
    return self:Increment(id, column, -(amount or 1))
end

-- ============================================================================
-- METODOS DE ELIMINACION
-- ============================================================================

--- Elimina un registro por ID
---@param id number|string ID del registro
---@return boolean
function AIT.DB.Repositories.Base:Delete(id)
    local query
    local params = {id}

    if self.config.softDeletes then
        -- Soft delete: marcar como eliminado
        query = string.format(
            "UPDATE %s SET %s = ? WHERE %s = ?",
            self.config.tableName,
            self.config.deletedAtColumn,
            self.config.primaryKey
        )
        params = {GetCurrentTimestamp(), id}
    else
        -- Hard delete
        query = string.format(
            "DELETE FROM %s WHERE %s = ?",
            self.config.tableName,
            self.config.primaryKey
        )
    end

    local affected = AIT.DB.Delete(query, params)

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Elimina multiples registros por condiciones
---@param conditions table Condiciones de eliminacion
---@return number Filas afectadas
function AIT.DB.Repositories.Base:DeleteWhere(conditions)
    local whereClauses = {}
    local params = {}

    for column, value in pairs(conditions) do
        table.insert(whereClauses, string.format("%s = ?", column))
        table.insert(params, value)
    end

    local query

    if self.config.softDeletes then
        -- Soft delete
        table.insert(params, 1, GetCurrentTimestamp())
        query = string.format(
            "UPDATE %s SET %s = ? WHERE %s",
            self.config.tableName,
            self.config.deletedAtColumn,
            table.concat(whereClauses, " AND ")
        )
    else
        -- Hard delete
        query = string.format(
            "DELETE FROM %s WHERE %s",
            self.config.tableName,
            table.concat(whereClauses, " AND ")
        )
    end

    local affected = AIT.DB.Delete(query, params)

    if affected > 0 then
        self:InvalidateCache()
    end

    return affected
end

--- Restaura un registro eliminado (solo para soft deletes)
---@param id number|string ID del registro
---@return boolean
function AIT.DB.Repositories.Base:Restore(id)
    if not self.config.softDeletes then
        return false
    end

    local query = string.format(
        "UPDATE %s SET %s = NULL WHERE %s = ?",
        self.config.tableName,
        self.config.deletedAtColumn,
        self.config.primaryKey
    )

    local affected = AIT.DB.Update(query, {id})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Elimina permanentemente un registro (ignora soft deletes)
---@param id number|string ID del registro
---@return boolean
function AIT.DB.Repositories.Base:ForceDelete(id)
    local query = string.format(
        "DELETE FROM %s WHERE %s = ?",
        self.config.tableName,
        self.config.primaryKey
    )

    local affected = AIT.DB.Delete(query, {id})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Busca registros incluyendo los eliminados
---@param id number|string ID del registro
---@return table|nil
function AIT.DB.Repositories.Base:FindByIdWithTrashed(id)
    local query = string.format(
        "SELECT * FROM %s WHERE %s = ?",
        self.config.tableName,
        self.config.primaryKey
    )

    return AIT.DB.Single(query, {id})
end

--- Busca solo registros eliminados
---@param options? table Opciones de busqueda
---@return table
function AIT.DB.Repositories.Base:OnlyTrashed(options)
    if not self.config.softDeletes then
        return {}
    end

    options = options or {}

    local query = string.format(
        "SELECT * FROM %s WHERE %s IS NOT NULL",
        self.config.tableName,
        self.config.deletedAtColumn
    )

    if options.limit then
        query = query .. string.format(" LIMIT %d", options.limit)
    end

    return AIT.DB.Query(query) or {}
end

-- ============================================================================
-- METODOS DE QUERY BUILDER
-- ============================================================================

--- Retorna un query builder para la tabla
---@return table
function AIT.DB.Repositories.Base:Query()
    return AIT.DB.Table(self.config.tableName)
end

--- Ejecuta una query raw
---@param query string Query SQL
---@param params? table Parametros
---@return table|nil
function AIT.DB.Repositories.Base:Raw(query, params)
    return AIT.DB.Query(query, params)
end

-- ============================================================================
-- METODOS DE UTILIDAD
-- ============================================================================

--- Obtiene el nombre de la tabla
---@return string
function AIT.DB.Repositories.Base:GetTableName()
    return self.config.tableName
end

--- Obtiene el nombre de la clave primaria
---@return string
function AIT.DB.Repositories.Base:GetPrimaryKey()
    return self.config.primaryKey
end

--- Verifica si soft deletes esta habilitado
---@return boolean
function AIT.DB.Repositories.Base:HasSoftDeletes()
    return self.config.softDeletes
end

--- Obtiene la configuracion del repositorio
---@return table
function AIT.DB.Repositories.Base:GetConfig()
    return self.config
end

print("[AIT.DB.Repositories] Repositorio Base cargado correctamente")
