--[[
    AIT Framework - Sistema de Feature Flags
    Sistema dinamico de feature flags con rollout gradual y A/B testing

    Autor: AIT Development Team
    Version: 1.0.0

    Caracteristicas:
    - Feature flags dinamicos
    - Rollout gradual por porcentaje
    - A/B Testing con variantes
    - Condiciones basadas en VIP, grupos, permisos
    - Persistencia y sincronizacion
    - Metricas de uso
]]

AIT = AIT or {}
AIT.FeatureFlags = AIT.FeatureFlags or {}

-- ============================================================================
-- CONFIGURACION
-- ============================================================================

AIT.FeatureFlags.Config = {
    -- Configuracion general
    habilitado = true,
    modoDebug = false,

    -- Cache
    tiempoCacheMs = 30000, -- 30 segundos

    -- Persistencia
    persistencia = {
        habilitada = true,
        recurso = "ait-qb",
    },

    -- Metricas
    metricas = {
        habilitadas = true,
        intervaloGuardado = 60000, -- 1 minuto
    },
}

-- ============================================================================
-- ALMACENAMIENTO
-- ============================================================================

local flags = {} -- Definiciones de feature flags
local estadoJugadores = {} -- Estado de flags por jugador
local metricas = {} -- Metricas de uso
local cache = {} -- Cache de evaluaciones
local ultimaActualizacion = 0

-- ============================================================================
-- TIPOS DE CONDICIONES
-- ============================================================================

local TipoCondicion = {
    SIEMPRE = "siempre",
    NUNCA = "nunca",
    PORCENTAJE = "porcentaje",
    GRUPO = "grupo",
    VIP = "vip",
    PERMISO = "permiso",
    IDENTIFICADOR = "identificador",
    FECHA = "fecha",
    HORA = "hora",
    PERSONALIZADO = "personalizado",
}

AIT.FeatureFlags.TipoCondicion = TipoCondicion

-- ============================================================================
-- UTILIDADES INTERNAS
-- ============================================================================

--- Registra un mensaje de debug
-- @param mensaje string - Mensaje a registrar
local function debug(mensaje)
    if AIT.FeatureFlags.Config.modoDebug then
        print(string.format("[AIT.FeatureFlags] [DEBUG] %s", mensaje))
    end
end

--- Registra un mensaje de advertencia
-- @param mensaje string - Mensaje a registrar
local function advertencia(mensaje)
    print(string.format("[AIT.FeatureFlags] [ADVERTENCIA] %s", mensaje))
end

--- Genera un hash simple para identificadores
-- @param texto string - Texto a hashear
-- @return number - Hash numerico entre 0 y 100
local function generarHash(texto)
    local hash = 0
    for i = 1, #texto do
        hash = (hash * 31 + string.byte(texto, i)) % 1000000
    end
    return hash % 100
end

--- Obtiene el timestamp actual
-- @return number - Timestamp en ms
local function obtenerTimestamp()
    return GetGameTimer()
end

--- Verifica si el cache es valido
-- @param clave string - Clave del cache
-- @return boolean - true si el cache es valido
local function cacheValido(clave)
    local entrada = cache[clave]
    if not entrada then return false end

    return (obtenerTimestamp() - entrada.timestamp) < AIT.FeatureFlags.Config.tiempoCacheMs
end

--- Guarda en cache
-- @param clave string - Clave del cache
-- @param valor any - Valor a guardar
local function guardarCache(clave, valor)
    cache[clave] = {
        valor = valor,
        timestamp = obtenerTimestamp(),
    }
end

--- Obtiene del cache
-- @param clave string - Clave del cache
-- @return any|nil - Valor del cache o nil
local function obtenerCache(clave)
    if cacheValido(clave) then
        return cache[clave].valor
    end
    return nil
end

-- ============================================================================
-- DEFINICION DE FLAGS
-- ============================================================================

--- Registra un nuevo feature flag
-- @param nombre string - Nombre unico del flag
-- @param definicion table - Definicion del flag
function AIT.FeatureFlags.Registrar(nombre, definicion)
    if not nombre or nombre == "" then
        advertencia("Nombre de flag invalido")
        return false
    end

    local flag = {
        nombre = nombre,
        descripcion = definicion.descripcion or "",
        habilitado = definicion.habilitado ~= false,
        condiciones = definicion.condiciones or {},
        variantes = definicion.variantes or nil,
        valorDefecto = definicion.valorDefecto or false,
        metadata = definicion.metadata or {},
        creadoEn = obtenerTimestamp(),
        actualizadoEn = obtenerTimestamp(),
    }

    flags[nombre] = flag
    metricas[nombre] = metricas[nombre] or {
        evaluaciones = 0,
        habilitados = 0,
        deshabilitados = 0,
        porVariante = {},
    }

    debug(string.format("Flag registrado: %s", nombre))
    return true
end

--- Actualiza un feature flag existente
-- @param nombre string - Nombre del flag
-- @param cambios table - Cambios a aplicar
function AIT.FeatureFlags.Actualizar(nombre, cambios)
    local flag = flags[nombre]
    if not flag then
        advertencia(string.format("Flag no encontrado: %s", nombre))
        return false
    end

    for clave, valor in pairs(cambios) do
        if clave ~= "nombre" and clave ~= "creadoEn" then
            flag[clave] = valor
        end
    end

    flag.actualizadoEn = obtenerTimestamp()

    -- Invalidar cache relacionado
    for clave in pairs(cache) do
        if string.find(clave, "^" .. nombre .. ":") then
            cache[clave] = nil
        end
    end

    debug(string.format("Flag actualizado: %s", nombre))
    return true
end

--- Elimina un feature flag
-- @param nombre string - Nombre del flag
function AIT.FeatureFlags.Eliminar(nombre)
    if flags[nombre] then
        flags[nombre] = nil
        debug(string.format("Flag eliminado: %s", nombre))
        return true
    end
    return false
end

--- Obtiene la definicion de un flag
-- @param nombre string - Nombre del flag
-- @return table|nil - Definicion del flag
function AIT.FeatureFlags.Obtener(nombre)
    return flags[nombre]
end

--- Lista todos los flags registrados
-- @return table - Lista de flags
function AIT.FeatureFlags.Listar()
    local lista = {}
    for nombre, flag in pairs(flags) do
        table.insert(lista, {
            nombre = nombre,
            descripcion = flag.descripcion,
            habilitado = flag.habilitado,
            tieneVariantes = flag.variantes ~= nil,
        })
    end
    return lista
end

-- ============================================================================
-- EVALUACION DE CONDICIONES
-- ============================================================================

--- Evalua una condicion especifica
-- @param condicion table - Condicion a evaluar
-- @param contexto table - Contexto del jugador
-- @return boolean - Resultado de la evaluacion
local function evaluarCondicion(condicion, contexto)
    local tipo = condicion.tipo

    if tipo == TipoCondicion.SIEMPRE then
        return true

    elseif tipo == TipoCondicion.NUNCA then
        return false

    elseif tipo == TipoCondicion.PORCENTAJE then
        local porcentaje = condicion.valor or 0
        local identificador = contexto.identificador or ""
        local hash = generarHash(identificador .. (condicion.semilla or ""))
        return hash < porcentaje

    elseif tipo == TipoCondicion.GRUPO then
        local gruposRequeridos = condicion.grupos or {}
        local gruposJugador = contexto.grupos or {}

        for _, grupoRequerido in ipairs(gruposRequeridos) do
            for _, grupoJugador in ipairs(gruposJugador) do
                if grupoRequerido == grupoJugador then
                    return true
                end
            end
        end
        return false

    elseif tipo == TipoCondicion.VIP then
        local nivelRequerido = condicion.nivel or 1
        local nivelJugador = contexto.nivelVip or 0
        return nivelJugador >= nivelRequerido

    elseif tipo == TipoCondicion.PERMISO then
        local permisosRequeridos = condicion.permisos or {}
        local permisosJugador = contexto.permisos or {}

        for _, permisoRequerido in ipairs(permisosRequeridos) do
            local tienePermiso = false
            for _, permisoJugador in ipairs(permisosJugador) do
                if permisoRequerido == permisoJugador then
                    tienePermiso = true
                    break
                end
            end
            if not tienePermiso then
                return false
            end
        end
        return true

    elseif tipo == TipoCondicion.IDENTIFICADOR then
        local identificadores = condicion.identificadores or {}
        local identificadorJugador = contexto.identificador

        for _, id in ipairs(identificadores) do
            if id == identificadorJugador then
                return true
            end
        end
        return false

    elseif tipo == TipoCondicion.FECHA then
        local fechaActual = os.date("*t")
        local diaActual = fechaActual.yday

        if condicion.desde and diaActual < condicion.desde then
            return false
        end
        if condicion.hasta and diaActual > condicion.hasta then
            return false
        end
        return true

    elseif tipo == TipoCondicion.HORA then
        local horaActual = tonumber(os.date("%H"))

        if condicion.desde and horaActual < condicion.desde then
            return false
        end
        if condicion.hasta and horaActual > condicion.hasta then
            return false
        end
        return true

    elseif tipo == TipoCondicion.PERSONALIZADO then
        if type(condicion.funcion) == "function" then
            local exito, resultado = pcall(condicion.funcion, contexto)
            if exito then
                return resultado == true
            else
                advertencia(string.format("Error en condicion personalizada: %s", resultado))
                return false
            end
        end
        return false
    end

    return false
end

--- Evalua todas las condiciones de un flag
-- @param flag table - Definicion del flag
-- @param contexto table - Contexto del jugador
-- @return boolean - true si todas las condiciones se cumplen
local function evaluarCondiciones(flag, contexto)
    local condiciones = flag.condiciones or {}

    -- Si no hay condiciones, usar valor por defecto
    if #condiciones == 0 then
        return flag.valorDefecto
    end

    -- Evaluar cada condicion (AND logico por defecto)
    for _, condicion in ipairs(condiciones) do
        local resultado = evaluarCondicion(condicion, contexto)

        -- Soporte para operador logico
        if condicion.operador == "OR" then
            if resultado then
                return true
            end
        else
            -- AND por defecto
            if not resultado then
                return false
            end
        end
    end

    return true
end

-- ============================================================================
-- API PRINCIPAL
-- ============================================================================

--- Verifica si un feature flag esta habilitado para un jugador
-- @param nombre string - Nombre del flag
-- @param contexto table - Contexto del jugador
-- @return boolean - true si esta habilitado
function AIT.FeatureFlags.EstaHabilitado(nombre, contexto)
    contexto = contexto or {}

    -- Verificar si el sistema esta habilitado
    if not AIT.FeatureFlags.Config.habilitado then
        return false
    end

    local flag = flags[nombre]
    if not flag then
        debug(string.format("Flag no encontrado: %s", nombre))
        return false
    end

    -- Verificar si el flag esta globalmente habilitado
    if not flag.habilitado then
        return false
    end

    -- Verificar cache
    local claveCache = string.format("%s:%s", nombre, contexto.identificador or "anonimo")
    local valorCache = obtenerCache(claveCache)
    if valorCache ~= nil then
        return valorCache
    end

    -- Evaluar condiciones
    local resultado = evaluarCondiciones(flag, contexto)

    -- Guardar en cache
    guardarCache(claveCache, resultado)

    -- Registrar metrica
    if AIT.FeatureFlags.Config.metricas.habilitadas then
        metricas[nombre].evaluaciones = metricas[nombre].evaluaciones + 1
        if resultado then
            metricas[nombre].habilitados = metricas[nombre].habilitados + 1
        else
            metricas[nombre].deshabilitados = metricas[nombre].deshabilitados + 1
        end
    end

    debug(string.format("Flag %s evaluado para %s: %s",
        nombre, contexto.identificador or "anonimo", tostring(resultado)))

    return resultado
end

--- Obtiene la variante activa de un flag para un jugador (A/B Testing)
-- @param nombre string - Nombre del flag
-- @param contexto table - Contexto del jugador
-- @return string|nil - Nombre de la variante activa
-- @return any - Valor de la variante
function AIT.FeatureFlags.ObtenerVariante(nombre, contexto)
    contexto = contexto or {}

    local flag = flags[nombre]
    if not flag then
        return nil, nil
    end

    -- Verificar si el flag esta habilitado primero
    if not AIT.FeatureFlags.EstaHabilitado(nombre, contexto) then
        return nil, nil
    end

    -- Verificar si tiene variantes configuradas
    local variantes = flag.variantes
    if not variantes or #variantes == 0 then
        return nil, flag.valorDefecto
    end

    -- Calcular variante basada en hash del identificador
    local identificador = contexto.identificador or "anonimo"
    local hash = generarHash(identificador .. nombre)

    local acumulado = 0
    for _, variante in ipairs(variantes) do
        acumulado = acumulado + (variante.porcentaje or 0)
        if hash < acumulado then
            -- Registrar metrica de variante
            if AIT.FeatureFlags.Config.metricas.habilitadas then
                local m = metricas[nombre].porVariante
                m[variante.nombre] = (m[variante.nombre] or 0) + 1
            end

            debug(string.format("Variante %s seleccionada para %s en flag %s",
                variante.nombre, identificador, nombre))

            return variante.nombre, variante.valor
        end
    end

    -- Si no se asigno variante, usar defecto
    return "defecto", flag.valorDefecto
end

-- ============================================================================
-- ROLLOUT GRADUAL
-- ============================================================================

--- Configura un rollout gradual para un flag
-- @param nombre string - Nombre del flag
-- @param configuracion table - Configuracion del rollout
function AIT.FeatureFlags.ConfigurarRollout(nombre, configuracion)
    local flag = flags[nombre]
    if not flag then
        advertencia(string.format("Flag no encontrado para rollout: %s", nombre))
        return false
    end

    local rollout = {
        porcentajeInicial = configuracion.porcentajeInicial or 0,
        porcentajeFinal = configuracion.porcentajeFinal or 100,
        incremento = configuracion.incremento or 10,
        intervaloMs = configuracion.intervaloMs or 3600000, -- 1 hora
        porcentajeActual = configuracion.porcentajeInicial or 0,
        ultimoIncremento = obtenerTimestamp(),
    }

    flag.rollout = rollout

    -- Actualizar condicion de porcentaje
    local condicionPorcentaje = nil
    for i, condicion in ipairs(flag.condiciones) do
        if condicion.tipo == TipoCondicion.PORCENTAJE then
            condicionPorcentaje = i
            break
        end
    end

    if condicionPorcentaje then
        flag.condiciones[condicionPorcentaje].valor = rollout.porcentajeActual
    else
        table.insert(flag.condiciones, {
            tipo = TipoCondicion.PORCENTAJE,
            valor = rollout.porcentajeActual,
        })
    end

    debug(string.format("Rollout configurado para %s: %d%% -> %d%%",
        nombre, rollout.porcentajeInicial, rollout.porcentajeFinal))

    return true
end

--- Avanza el rollout gradual de un flag
-- @param nombre string - Nombre del flag
-- @return number - Nuevo porcentaje
function AIT.FeatureFlags.AvanzarRollout(nombre)
    local flag = flags[nombre]
    if not flag or not flag.rollout then
        return nil
    end

    local rollout = flag.rollout
    local ahora = obtenerTimestamp()

    -- Verificar si es tiempo de incrementar
    if ahora - rollout.ultimoIncremento < rollout.intervaloMs then
        return rollout.porcentajeActual
    end

    -- Incrementar porcentaje
    local nuevoPorcentaje = math.min(
        rollout.porcentajeActual + rollout.incremento,
        rollout.porcentajeFinal
    )

    rollout.porcentajeActual = nuevoPorcentaje
    rollout.ultimoIncremento = ahora

    -- Actualizar condicion
    for _, condicion in ipairs(flag.condiciones) do
        if condicion.tipo == TipoCondicion.PORCENTAJE then
            condicion.valor = nuevoPorcentaje
            break
        end
    end

    -- Invalidar cache
    for clave in pairs(cache) do
        if string.find(clave, "^" .. nombre .. ":") then
            cache[clave] = nil
        end
    end

    debug(string.format("Rollout avanzado para %s: %d%%", nombre, nuevoPorcentaje))

    return nuevoPorcentaje
end

-- ============================================================================
-- A/B TESTING
-- ============================================================================

--- Configura variantes para A/B testing
-- @param nombre string - Nombre del flag
-- @param variantes table - Lista de variantes
function AIT.FeatureFlags.ConfigurarVariantes(nombre, variantes)
    local flag = flags[nombre]
    if not flag then
        advertencia(string.format("Flag no encontrado para variantes: %s", nombre))
        return false
    end

    -- Validar que los porcentajes sumen 100
    local totalPorcentaje = 0
    for _, variante in ipairs(variantes) do
        totalPorcentaje = totalPorcentaje + (variante.porcentaje or 0)
    end

    if totalPorcentaje ~= 100 then
        advertencia(string.format("Los porcentajes de variantes deben sumar 100 (actual: %d)", totalPorcentaje))
        return false
    end

    flag.variantes = variantes

    -- Inicializar metricas por variante
    metricas[nombre].porVariante = {}
    for _, variante in ipairs(variantes) do
        metricas[nombre].porVariante[variante.nombre] = 0
    end

    debug(string.format("Variantes configuradas para %s: %d variantes", nombre, #variantes))

    return true
end

-- ============================================================================
-- METRICAS Y ESTADISTICAS
-- ============================================================================

--- Obtiene las metricas de un flag
-- @param nombre string - Nombre del flag
-- @return table|nil - Metricas del flag
function AIT.FeatureFlags.ObtenerMetricas(nombre)
    return metricas[nombre]
end

--- Obtiene todas las metricas
-- @return table - Todas las metricas
function AIT.FeatureFlags.ObtenerTodasMetricas()
    return metricas
end

--- Reinicia las metricas de un flag
-- @param nombre string - Nombre del flag
function AIT.FeatureFlags.ReiniciarMetricas(nombre)
    if metricas[nombre] then
        metricas[nombre] = {
            evaluaciones = 0,
            habilitados = 0,
            deshabilitados = 0,
            porVariante = {},
        }
        debug(string.format("Metricas reiniciadas para: %s", nombre))
    end
end

-- ============================================================================
-- CONTEXTO DE JUGADOR
-- ============================================================================

--- Construye el contexto de un jugador para evaluacion
-- @param playerId number - ID del jugador
-- @return table - Contexto del jugador
function AIT.FeatureFlags.ConstruirContexto(playerId)
    local contexto = {
        playerId = playerId,
        identificador = nil,
        grupos = {},
        permisos = {},
        nivelVip = 0,
        metadata = {},
    }

    -- Obtener identificadores del jugador
    if playerId then
        local identificadores = GetPlayerIdentifiers(playerId)
        for _, id in ipairs(identificadores or {}) do
            if string.find(id, "license:") then
                contexto.identificador = id
                break
            end
        end

        -- Si no hay license, usar el primer identificador
        if not contexto.identificador and identificadores and #identificadores > 0 then
            contexto.identificador = identificadores[1]
        end
    end

    -- Intentar obtener datos de QBCore si esta disponible
    if QBCore and QBCore.Functions then
        local player = QBCore.Functions.GetPlayer(playerId)
        if player then
            -- Obtener grupo/job
            local job = player.PlayerData.job
            if job then
                table.insert(contexto.grupos, job.name)
                if job.grade then
                    table.insert(contexto.grupos, string.format("%s:%d", job.name, job.grade.level))
                end
            end

            -- Obtener metadata VIP si existe
            local metadata = player.PlayerData.metadata or {}
            contexto.nivelVip = metadata.viplevel or 0
            contexto.metadata = metadata
        end
    end

    return contexto
end

-- ============================================================================
-- PERSISTENCIA
-- ============================================================================

--- Exporta todas las definiciones de flags
-- @return table - Definiciones exportadas
function AIT.FeatureFlags.Exportar()
    local exportacion = {}

    for nombre, flag in pairs(flags) do
        -- Excluir funciones personalizadas que no se pueden serializar
        local flagExportado = {}
        for clave, valor in pairs(flag) do
            if type(valor) ~= "function" then
                flagExportado[clave] = valor
            end
        end
        exportacion[nombre] = flagExportado
    end

    return exportacion
end

--- Importa definiciones de flags
-- @param datos table - Definiciones a importar
function AIT.FeatureFlags.Importar(datos)
    if type(datos) ~= "table" then
        advertencia("Datos de importacion invalidos")
        return false
    end

    for nombre, definicion in pairs(datos) do
        AIT.FeatureFlags.Registrar(nombre, definicion)
    end

    debug(string.format("Importados %d flags", #datos))
    return true
end

--- Invalida todo el cache
function AIT.FeatureFlags.InvalidarCache()
    cache = {}
    debug("Cache invalidado completamente")
end

-- ============================================================================
-- HELPERS Y CONSTRUCTORES
-- ============================================================================

--- Crea una condicion de porcentaje
-- @param porcentaje number - Porcentaje (0-100)
-- @param semilla string - Semilla opcional para el hash
-- @return table - Condicion
function AIT.FeatureFlags.CondicionPorcentaje(porcentaje, semilla)
    return {
        tipo = TipoCondicion.PORCENTAJE,
        valor = porcentaje,
        semilla = semilla,
    }
end

--- Crea una condicion de grupo
-- @param grupos table - Lista de grupos permitidos
-- @return table - Condicion
function AIT.FeatureFlags.CondicionGrupo(grupos)
    return {
        tipo = TipoCondicion.GRUPO,
        grupos = type(grupos) == "table" and grupos or { grupos },
    }
end

--- Crea una condicion VIP
-- @param nivelMinimo number - Nivel VIP minimo requerido
-- @return table - Condicion
function AIT.FeatureFlags.CondicionVIP(nivelMinimo)
    return {
        tipo = TipoCondicion.VIP,
        nivel = nivelMinimo,
    }
end

--- Crea una condicion de permiso
-- @param permisos table - Lista de permisos requeridos
-- @return table - Condicion
function AIT.FeatureFlags.CondicionPermiso(permisos)
    return {
        tipo = TipoCondicion.PERMISO,
        permisos = type(permisos) == "table" and permisos or { permisos },
    }
end

--- Crea una condicion de identificadores especificos
-- @param identificadores table - Lista de identificadores
-- @return table - Condicion
function AIT.FeatureFlags.CondicionIdentificador(identificadores)
    return {
        tipo = TipoCondicion.IDENTIFICADOR,
        identificadores = type(identificadores) == "table" and identificadores or { identificadores },
    }
end

--- Crea una condicion de horario
-- @param horaDesde number - Hora de inicio (0-23)
-- @param horaHasta number - Hora de fin (0-23)
-- @return table - Condicion
function AIT.FeatureFlags.CondicionHorario(horaDesde, horaHasta)
    return {
        tipo = TipoCondicion.HORA,
        desde = horaDesde,
        hasta = horaHasta,
    }
end

--- Crea una condicion personalizada
-- @param funcion function - Funcion que recibe contexto y devuelve boolean
-- @return table - Condicion
function AIT.FeatureFlags.CondicionPersonalizada(funcion)
    return {
        tipo = TipoCondicion.PERSONALIZADO,
        funcion = funcion,
    }
end

-- ============================================================================
-- INICIALIZACION
-- ============================================================================

print("[AIT.FeatureFlags] Sistema de Feature Flags inicializado")

return AIT.FeatureFlags
