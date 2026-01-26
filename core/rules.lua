--[[
    AIT Framework - Motor de Reglas de Negocio
    Archivo: core/rules.lua

    Sistema completo de reglas de negocio con:
    - Condiciones evaluables dinamicamente
    - Acciones configurables
    - Sistema de prioridades
    - Carga desde DB/config
    - Cache y optimizacion
]]

AIT = AIT or {}
AIT.Rules = AIT.Rules or {}

-- ============================================================================
-- CONFIGURACION DEL MOTOR DE REGLAS
-- ============================================================================

local Config = {
    -- Configuracion general
    habilitado = true,
    modoDebug = false,

    -- Cache de reglas
    cacheHabilitado = true,
    cacheTTL = 300, -- 5 minutos en segundos

    -- Limites de seguridad
    maxReglasActivas = 1000,
    maxCondicionesPorRegla = 20,
    maxAccionesPorRegla = 10,
    tiempoMaximoEvaluacion = 50, -- milisegundos

    -- Prioridades por defecto
    prioridadMinima = 0,
    prioridadMaxima = 1000,
    prioridadDefecto = 500
}

-- ============================================================================
-- ALMACENAMIENTO DE REGLAS
-- ============================================================================

local almacenReglas = {
    reglas = {},           -- Todas las reglas indexadas por ID
    reglasActivas = {},    -- Solo reglas activas
    reglasPorCategoria = {},-- Agrupadas por categoria
    reglasPorEvento = {},  -- Agrupadas por evento disparador
    cache = {},            -- Cache de evaluaciones
    ultimaActualizacion = 0
}

-- ============================================================================
-- OPERADORES DE CONDICION
-- ============================================================================

local Operadores = {
    -- Comparaciones basicas
    igual = function(a, b) return a == b end,
    diferente = function(a, b) return a ~= b end,
    mayor = function(a, b) return tonumber(a) > tonumber(b) end,
    menor = function(a, b) return tonumber(a) < tonumber(b) end,
    mayorIgual = function(a, b) return tonumber(a) >= tonumber(b) end,
    menorIgual = function(a, b) return tonumber(a) <= tonumber(b) end,

    -- Operadores de cadena
    contiene = function(a, b) return string.find(tostring(a), tostring(b)) ~= nil end,
    noContiene = function(a, b) return string.find(tostring(a), tostring(b)) == nil end,
    comienzaCon = function(a, b) return string.sub(tostring(a), 1, #tostring(b)) == tostring(b) end,
    terminaCon = function(a, b) return string.sub(tostring(a), -#tostring(b)) == tostring(b) end,
    coincidePatron = function(a, b) return string.match(tostring(a), tostring(b)) ~= nil end,

    -- Operadores de rango
    entre = function(a, min, max) local n = tonumber(a); return n >= tonumber(min) and n <= tonumber(max) end,
    fueraDeRango = function(a, min, max) local n = tonumber(a); return n < tonumber(min) or n > tonumber(max) end,

    -- Operadores de lista
    enLista = function(a, lista)
        if type(lista) == "table" then
            for _, v in ipairs(lista) do
                if v == a then return true end
            end
        end
        return false
    end,
    noEnLista = function(a, lista)
        return not Operadores.enLista(a, lista)
    end,

    -- Operadores de tipo
    esNulo = function(a) return a == nil end,
    noEsNulo = function(a) return a ~= nil end,
    esVacio = function(a) return a == nil or a == "" or (type(a) == "table" and next(a) == nil) end,
    noEsVacio = function(a) return not Operadores.esVacio(a) end,
    esTipo = function(a, tipo) return type(a) == tipo end,

    -- Operadores logicos (para combinar condiciones)
    y = function(...)
        for _, v in ipairs({...}) do
            if not v then return false end
        end
        return true
    end,
    o = function(...)
        for _, v in ipairs({...}) do
            if v then return true end
        end
        return false
    end,
    no = function(a) return not a end
}

-- ============================================================================
-- CLASE CONDICION
-- ============================================================================

local Condicion = {}
Condicion.__index = Condicion

function Condicion.nueva(config)
    local self = setmetatable({}, Condicion)

    self.id = config.id or AIT.Utils and AIT.Utils.GenerarUUID() or tostring(math.random(100000, 999999))
    self.campo = config.campo           -- Campo a evaluar (ej: "jugador.dinero")
    self.operador = config.operador     -- Nombre del operador
    self.valor = config.valor           -- Valor de comparacion
    self.valorExtra = config.valorExtra -- Valor extra para operadores como "entre"
    self.descripcion = config.descripcion or ""
    self.habilitada = config.habilitada ~= false

    return self
end

function Condicion:evaluar(contexto)
    if not self.habilitada then
        return true -- Condicion deshabilitada siempre pasa
    end

    -- Obtener valor del campo desde el contexto
    local valorCampo = self:obtenerValorCampo(contexto)

    -- Obtener funcion operador
    local funcionOperador = Operadores[self.operador]
    if not funcionOperador then
        if Config.modoDebug then
            print(string.format("[AIT.Rules] Operador desconocido: %s", self.operador))
        end
        return false
    end

    -- Evaluar condicion
    local resultado
    if self.valorExtra ~= nil then
        resultado = funcionOperador(valorCampo, self.valor, self.valorExtra)
    else
        resultado = funcionOperador(valorCampo, self.valor)
    end

    if Config.modoDebug then
        print(string.format("[AIT.Rules] Condicion evaluada: %s %s %s = %s",
            tostring(valorCampo), self.operador, tostring(self.valor), tostring(resultado)))
    end

    return resultado
end

function Condicion:obtenerValorCampo(contexto)
    if not self.campo or not contexto then
        return nil
    end

    -- Navegar por el path del campo (ej: "jugador.inventario.dinero")
    local partes = {}
    for parte in string.gmatch(self.campo, "[^%.]+") do
        table.insert(partes, parte)
    end

    local valor = contexto
    for _, parte in ipairs(partes) do
        if type(valor) == "table" then
            valor = valor[parte]
        else
            return nil
        end
    end

    return valor
end

-- ============================================================================
-- CLASE ACCION
-- ============================================================================

local Accion = {}
Accion.__index = Accion

-- Registro de tipos de acciones disponibles
local TiposAccion = {}

function Accion.registrarTipo(nombre, configuracion)
    TiposAccion[nombre] = {
        nombre = nombre,
        descripcion = configuracion.descripcion or "",
        ejecutor = configuracion.ejecutor,
        validador = configuracion.validador,
        parametrosRequeridos = configuracion.parametrosRequeridos or {}
    }

    if Config.modoDebug then
        print(string.format("[AIT.Rules] Tipo de accion registrado: %s", nombre))
    end
end

function Accion.nueva(config)
    local self = setmetatable({}, Accion)

    self.id = config.id or AIT.Utils and AIT.Utils.GenerarUUID() or tostring(math.random(100000, 999999))
    self.tipo = config.tipo             -- Tipo de accion (debe estar registrado)
    self.parametros = config.parametros or {}
    self.descripcion = config.descripcion or ""
    self.habilitada = config.habilitada ~= false
    self.orden = config.orden or 0      -- Orden de ejecucion
    self.continuar = config.continuar ~= false -- Continuar con siguiente accion?

    return self
end

function Accion:validar()
    local tipoAccion = TiposAccion[self.tipo]
    if not tipoAccion then
        return false, string.format("Tipo de accion no registrado: %s", self.tipo)
    end

    -- Verificar parametros requeridos
    for _, param in ipairs(tipoAccion.parametrosRequeridos) do
        if self.parametros[param] == nil then
            return false, string.format("Parametro requerido faltante: %s", param)
        end
    end

    -- Validacion personalizada si existe
    if tipoAccion.validador then
        return tipoAccion.validador(self.parametros)
    end

    return true
end

function Accion:ejecutar(contexto, regla)
    if not self.habilitada then
        return true, "Accion deshabilitada"
    end

    local tipoAccion = TiposAccion[self.tipo]
    if not tipoAccion or not tipoAccion.ejecutor then
        return false, string.format("No se puede ejecutar accion tipo: %s", self.tipo)
    end

    -- Ejecutar la accion
    local exito, resultado = pcall(function()
        return tipoAccion.ejecutor(self.parametros, contexto, regla)
    end)

    if Config.modoDebug then
        print(string.format("[AIT.Rules] Accion ejecutada: %s - Exito: %s", self.tipo, tostring(exito)))
    end

    return exito, resultado
end

-- ============================================================================
-- CLASE REGLA
-- ============================================================================

local Regla = {}
Regla.__index = Regla

function Regla.nueva(config)
    local self = setmetatable({}, Regla)

    self.id = config.id or AIT.Utils and AIT.Utils.GenerarUUID() or tostring(math.random(100000, 999999))
    self.nombre = config.nombre or "Regla sin nombre"
    self.descripcion = config.descripcion or ""
    self.categoria = config.categoria or "general"
    self.eventos = config.eventos or {}  -- Eventos que disparan esta regla
    self.prioridad = math.max(Config.prioridadMinima,
                              math.min(Config.prioridadMaxima,
                                      config.prioridad or Config.prioridadDefecto))

    self.condiciones = {}
    self.acciones = {}
    self.modoCondiciones = config.modoCondiciones or "todas" -- "todas" o "alguna"

    self.habilitada = config.habilitada ~= false
    self.fechaCreacion = config.fechaCreacion or os.time()
    self.fechaModificacion = config.fechaModificacion or os.time()
    self.version = config.version or 1
    self.metadata = config.metadata or {}

    -- Cargar condiciones si se proporcionan
    if config.condiciones then
        for _, condConfig in ipairs(config.condiciones) do
            self:agregarCondicion(Condicion.nueva(condConfig))
        end
    end

    -- Cargar acciones si se proporcionan
    if config.acciones then
        for _, accConfig in ipairs(config.acciones) do
            self:agregarAccion(Accion.nueva(accConfig))
        end
    end

    return self
end

function Regla:agregarCondicion(condicion)
    if #self.condiciones >= Config.maxCondicionesPorRegla then
        if Config.modoDebug then
            print("[AIT.Rules] Limite de condiciones alcanzado para regla: " .. self.id)
        end
        return false
    end

    table.insert(self.condiciones, condicion)
    return true
end

function Regla:agregarAccion(accion)
    if #self.acciones >= Config.maxAccionesPorRegla then
        if Config.modoDebug then
            print("[AIT.Rules] Limite de acciones alcanzado para regla: " .. self.id)
        end
        return false
    end

    table.insert(self.acciones, accion)
    -- Ordenar acciones por orden de ejecucion
    table.sort(self.acciones, function(a, b) return a.orden < b.orden end)
    return true
end

function Regla:evaluar(contexto)
    if not self.habilitada then
        return false, "Regla deshabilitada"
    end

    if #self.condiciones == 0 then
        return true, "Sin condiciones" -- Sin condiciones = siempre cumple
    end

    local resultados = {}
    for _, condicion in ipairs(self.condiciones) do
        local resultado = condicion:evaluar(contexto)
        table.insert(resultados, resultado)

        -- Optimizacion: corto circuito
        if self.modoCondiciones == "todas" and not resultado then
            return false, "Condicion no cumplida"
        elseif self.modoCondiciones == "alguna" and resultado then
            return true, "Al menos una condicion cumplida"
        end
    end

    -- Evaluar resultado final
    if self.modoCondiciones == "todas" then
        for _, r in ipairs(resultados) do
            if not r then return false, "No todas las condiciones cumplidas" end
        end
        return true, "Todas las condiciones cumplidas"
    else
        for _, r in ipairs(resultados) do
            if r then return true, "Al menos una condicion cumplida" end
        end
        return false, "Ninguna condicion cumplida"
    end
end

function Regla:ejecutar(contexto)
    if not self.habilitada then
        return false, "Regla deshabilitada"
    end

    -- Evaluar condiciones
    local cumple, mensaje = self:evaluar(contexto)
    if not cumple then
        return false, mensaje
    end

    -- Ejecutar acciones en orden
    local resultados = {}
    for _, accion in ipairs(self.acciones) do
        local exito, resultado = accion:ejecutar(contexto, self)
        table.insert(resultados, {
            accion = accion.tipo,
            exito = exito,
            resultado = resultado
        })

        -- Detener si la accion falla y no debe continuar
        if not exito and not accion.continuar then
            return false, resultados
        end
    end

    return true, resultados
end

function Regla:serializar()
    local condicionesData = {}
    for _, c in ipairs(self.condiciones) do
        table.insert(condicionesData, {
            id = c.id,
            campo = c.campo,
            operador = c.operador,
            valor = c.valor,
            valorExtra = c.valorExtra,
            descripcion = c.descripcion,
            habilitada = c.habilitada
        })
    end

    local accionesData = {}
    for _, a in ipairs(self.acciones) do
        table.insert(accionesData, {
            id = a.id,
            tipo = a.tipo,
            parametros = a.parametros,
            descripcion = a.descripcion,
            habilitada = a.habilitada,
            orden = a.orden,
            continuar = a.continuar
        })
    end

    return {
        id = self.id,
        nombre = self.nombre,
        descripcion = self.descripcion,
        categoria = self.categoria,
        eventos = self.eventos,
        prioridad = self.prioridad,
        modoCondiciones = self.modoCondiciones,
        condiciones = condicionesData,
        acciones = accionesData,
        habilitada = self.habilitada,
        fechaCreacion = self.fechaCreacion,
        fechaModificacion = self.fechaModificacion,
        version = self.version,
        metadata = self.metadata
    }
end

-- ============================================================================
-- MOTOR DE REGLAS PRINCIPAL
-- ============================================================================

function AIT.Rules.Inicializar(configuracion)
    if configuracion then
        for k, v in pairs(configuracion) do
            Config[k] = v
        end
    end

    -- Registrar tipos de acciones por defecto
    AIT.Rules.RegistrarAccionesBase()

    print("[AIT.Rules] Motor de reglas inicializado")
    return true
end

function AIT.Rules.RegistrarAccionesBase()
    -- Accion: Notificar
    Accion.registrarTipo("notificar", {
        descripcion = "Envia una notificacion al jugador",
        parametrosRequeridos = {"mensaje"},
        ejecutor = function(params, contexto)
            if contexto.jugador then
                TriggerClientEvent("AIT:Notificar", contexto.jugador, params.mensaje, params.tipo or "info")
            end
            return true
        end
    })

    -- Accion: Modificar variable
    Accion.registrarTipo("modificarVariable", {
        descripcion = "Modifica una variable en el contexto",
        parametrosRequeridos = {"variable", "valor"},
        ejecutor = function(params, contexto)
            local partes = {}
            for parte in string.gmatch(params.variable, "[^%.]+") do
                table.insert(partes, parte)
            end

            local obj = contexto
            for i = 1, #partes - 1 do
                if type(obj[partes[i]]) ~= "table" then
                    obj[partes[i]] = {}
                end
                obj = obj[partes[i]]
            end

            obj[partes[#partes]] = params.valor
            return true
        end
    })

    -- Accion: Ejecutar evento
    Accion.registrarTipo("ejecutarEvento", {
        descripcion = "Dispara un evento del servidor",
        parametrosRequeridos = {"evento"},
        ejecutor = function(params, contexto)
            TriggerEvent(params.evento, contexto, params.datos or {})
            return true
        end
    })

    -- Accion: Log
    Accion.registrarTipo("log", {
        descripcion = "Registra informacion en el log",
        parametrosRequeridos = {"mensaje"},
        ejecutor = function(params, contexto)
            local nivel = params.nivel or "info"
            print(string.format("[AIT.Rules][%s] %s", nivel:upper(), params.mensaje))
            return true
        end
    })

    -- Accion: Condicional
    Accion.registrarTipo("condicional", {
        descripcion = "Ejecuta accion basada en condicion",
        parametrosRequeridos = {"condicion", "accionSi"},
        ejecutor = function(params, contexto)
            local cond = Condicion.nueva(params.condicion)
            if cond:evaluar(contexto) then
                local acc = Accion.nueva(params.accionSi)
                return acc:ejecutar(contexto)
            elseif params.accionNo then
                local acc = Accion.nueva(params.accionNo)
                return acc:ejecutar(contexto)
            end
            return true
        end
    })
end

function AIT.Rules.RegistrarTipoAccion(nombre, configuracion)
    Accion.registrarTipo(nombre, configuracion)
end

function AIT.Rules.CrearRegla(config)
    local regla = Regla.nueva(config)
    return AIT.Rules.Registrar(regla)
end

function AIT.Rules.Registrar(regla)
    if #almacenReglas.reglasActivas >= Config.maxReglasActivas then
        print("[AIT.Rules] ADVERTENCIA: Limite de reglas activas alcanzado")
        return false, "Limite de reglas alcanzado"
    end

    -- Guardar en almacen principal
    almacenReglas.reglas[regla.id] = regla

    -- Actualizar indices
    if regla.habilitada then
        table.insert(almacenReglas.reglasActivas, regla)
        -- Ordenar por prioridad (mayor primero)
        table.sort(almacenReglas.reglasActivas, function(a, b) return a.prioridad > b.prioridad end)
    end

    -- Indexar por categoria
    if not almacenReglas.reglasPorCategoria[regla.categoria] then
        almacenReglas.reglasPorCategoria[regla.categoria] = {}
    end
    table.insert(almacenReglas.reglasPorCategoria[regla.categoria], regla)

    -- Indexar por eventos
    for _, evento in ipairs(regla.eventos) do
        if not almacenReglas.reglasPorEvento[evento] then
            almacenReglas.reglasPorEvento[evento] = {}
        end
        table.insert(almacenReglas.reglasPorEvento[evento], regla)
    end

    almacenReglas.ultimaActualizacion = os.time()

    if Config.modoDebug then
        print(string.format("[AIT.Rules] Regla registrada: %s (Prioridad: %d)", regla.nombre, regla.prioridad))
    end

    return true, regla.id
end

function AIT.Rules.Obtener(reglaId)
    return almacenReglas.reglas[reglaId]
end

function AIT.Rules.Eliminar(reglaId)
    local regla = almacenReglas.reglas[reglaId]
    if not regla then
        return false, "Regla no encontrada"
    end

    -- Eliminar de todos los indices
    almacenReglas.reglas[reglaId] = nil

    for i, r in ipairs(almacenReglas.reglasActivas) do
        if r.id == reglaId then
            table.remove(almacenReglas.reglasActivas, i)
            break
        end
    end

    if almacenReglas.reglasPorCategoria[regla.categoria] then
        for i, r in ipairs(almacenReglas.reglasPorCategoria[regla.categoria]) do
            if r.id == reglaId then
                table.remove(almacenReglas.reglasPorCategoria[regla.categoria], i)
                break
            end
        end
    end

    for _, evento in ipairs(regla.eventos) do
        if almacenReglas.reglasPorEvento[evento] then
            for i, r in ipairs(almacenReglas.reglasPorEvento[evento]) do
                if r.id == reglaId then
                    table.remove(almacenReglas.reglasPorEvento[evento], i)
                    break
                end
            end
        end
    end

    -- Limpiar cache
    almacenReglas.cache = {}

    return true
end

function AIT.Rules.Evaluar(contexto, opciones)
    opciones = opciones or {}
    local tiempoInicio = os.clock() * 1000

    local reglas
    if opciones.evento then
        reglas = almacenReglas.reglasPorEvento[opciones.evento] or {}
    elseif opciones.categoria then
        reglas = almacenReglas.reglasPorCategoria[opciones.categoria] or {}
    else
        reglas = almacenReglas.reglasActivas
    end

    local resultados = {}
    local reglasEjecutadas = 0

    for _, regla in ipairs(reglas) do
        -- Verificar tiempo de ejecucion
        local tiempoActual = os.clock() * 1000
        if (tiempoActual - tiempoInicio) > Config.tiempoMaximoEvaluacion then
            print("[AIT.Rules] ADVERTENCIA: Tiempo maximo de evaluacion excedido")
            break
        end

        local exito, resultado = regla:ejecutar(contexto)
        table.insert(resultados, {
            regla = regla.id,
            nombre = regla.nombre,
            exito = exito,
            resultado = resultado
        })

        if exito then
            reglasEjecutadas = reglasEjecutadas + 1

            -- Detener si se especifica
            if opciones.detenerEnPrimeraCoincidencia then
                break
            end
        end
    end

    local tiempoTotal = os.clock() * 1000 - tiempoInicio

    if Config.modoDebug then
        print(string.format("[AIT.Rules] Evaluacion completada: %d reglas ejecutadas en %.2fms",
            reglasEjecutadas, tiempoTotal))
    end

    return resultados, reglasEjecutadas
end

function AIT.Rules.EvaluarEvento(evento, contexto)
    return AIT.Rules.Evaluar(contexto, { evento = evento })
end

function AIT.Rules.CargarDesdeConfig(configuracion)
    if not configuracion or not configuracion.reglas then
        return false, "Configuracion invalida"
    end

    local cargadas = 0
    for _, reglaConfig in ipairs(configuracion.reglas) do
        local exito = AIT.Rules.CrearRegla(reglaConfig)
        if exito then
            cargadas = cargadas + 1
        end
    end

    print(string.format("[AIT.Rules] Cargadas %d reglas desde configuracion", cargadas))
    return true, cargadas
end

function AIT.Rules.CargarDesdeDB(callback)
    -- Esta funcion debe integrarse con el sistema de DB de AIT
    if AIT.DB and AIT.DB.Consultar then
        AIT.DB.Consultar("SELECT * FROM ait_reglas WHERE habilitada = 1", function(resultados)
            if resultados then
                for _, fila in ipairs(resultados) do
                    local reglaConfig = json.decode(fila.configuracion)
                    if reglaConfig then
                        reglaConfig.id = fila.id
                        AIT.Rules.CrearRegla(reglaConfig)
                    end
                end
            end
            if callback then callback(#resultados) end
        end)
    else
        print("[AIT.Rules] Sistema de DB no disponible")
        if callback then callback(0) end
    end
end

function AIT.Rules.GuardarEnDB(reglaId)
    local regla = almacenReglas.reglas[reglaId]
    if not regla then
        return false, "Regla no encontrada"
    end

    if AIT.DB and AIT.DB.Ejecutar then
        local datos = regla:serializar()
        AIT.DB.Ejecutar([[
            INSERT INTO ait_reglas (id, nombre, categoria, configuracion, habilitada)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            nombre = VALUES(nombre),
            categoria = VALUES(categoria),
            configuracion = VALUES(configuracion),
            habilitada = VALUES(habilitada)
        ]], {reglaId, regla.nombre, regla.categoria, json.encode(datos), regla.habilitada})
        return true
    end

    return false, "Sistema de DB no disponible"
end

function AIT.Rules.LimpiarCache()
    almacenReglas.cache = {}
end

function AIT.Rules.ObtenerEstadisticas()
    return {
        totalReglas = 0 + (function() local c = 0; for _ in pairs(almacenReglas.reglas) do c = c + 1 end; return c end)(),
        reglasActivas = #almacenReglas.reglasActivas,
        categorias = 0 + (function() local c = 0; for _ in pairs(almacenReglas.reglasPorCategoria) do c = c + 1 end; return c end)(),
        eventos = 0 + (function() local c = 0; for _ in pairs(almacenReglas.reglasPorEvento) do c = c + 1 end; return c end)(),
        ultimaActualizacion = almacenReglas.ultimaActualizacion
    }
end

function AIT.Rules.ListarReglas(filtros)
    filtros = filtros or {}
    local resultados = {}

    for _, regla in pairs(almacenReglas.reglas) do
        local incluir = true

        if filtros.categoria and regla.categoria ~= filtros.categoria then
            incluir = false
        end

        if filtros.habilitada ~= nil and regla.habilitada ~= filtros.habilitada then
            incluir = false
        end

        if filtros.prioridadMinima and regla.prioridad < filtros.prioridadMinima then
            incluir = false
        end

        if incluir then
            table.insert(resultados, regla:serializar())
        end
    end

    -- Ordenar por prioridad
    table.sort(resultados, function(a, b) return a.prioridad > b.prioridad end)

    return resultados
end

-- ============================================================================
-- EXPORTS PARA FIVEM
-- ============================================================================

if exports then
    exports("RulesInicializar", AIT.Rules.Inicializar)
    exports("RulesCrearRegla", AIT.Rules.CrearRegla)
    exports("RulesEvaluar", AIT.Rules.Evaluar)
    exports("RulesEvaluarEvento", AIT.Rules.EvaluarEvento)
    exports("RulesRegistrarTipoAccion", AIT.Rules.RegistrarTipoAccion)
    exports("RulesObtenerEstadisticas", AIT.Rules.ObtenerEstadisticas)
end

-- Inicializar automaticamente
CreateThread(function()
    Wait(100)
    AIT.Rules.Inicializar()
end)

print("[AIT Framework] Motor de Reglas de Negocio cargado - v1.0.0")
