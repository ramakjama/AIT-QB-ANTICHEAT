--[[
    AIT Framework - Sistema de Rate Limiting
    Rate Limiter avanzado con Token Bucket y Sliding Window

    Autor: AIT Development Team
    Version: 1.0.0

    Caracteristicas:
    - Token Bucket Algorithm
    - Sliding Window Counter
    - Limitacion por jugador, IP y accion
    - Sistema de penalizaciones
    - Whitelist/Blacklist
    - Cooldowns dinamicos
]]

AIT = AIT or {}
AIT.RateLimit = AIT.RateLimit or {}

-- ============================================================================
-- CONFIGURACION
-- ============================================================================

AIT.RateLimit.Config = {
    -- Configuracion general
    habilitado = true,
    modoDebug = false,

    -- Algoritmo por defecto ('token_bucket' o 'sliding_window')
    algoritmoDefecto = 'token_bucket',

    -- Configuracion Token Bucket
    tokenBucket = {
        tokensMaximos = 10,
        tokensRecarga = 1,
        intervaloRecarga = 1000, -- ms
    },

    -- Configuracion Sliding Window
    slidingWindow = {
        ventanaMs = 60000, -- 1 minuto
        maxPeticiones = 60,
    },

    -- Penalizaciones
    penalizaciones = {
        habilitadas = true,
        umbralViolaciones = 5,
        duracionBase = 30000, -- 30 segundos
        multiplicador = 2, -- Cada violacion duplica la duracion
        maxDuracion = 3600000, -- 1 hora maximo
    },

    -- Cooldowns por defecto (ms)
    cooldowns = {
        defecto = 1000,
        critico = 5000,
        moderado = 2000,
        ligero = 500,
    },

    -- Whitelist de identificadores
    whitelist = {
        identificadores = {},
        ips = {},
        acciones = {},
    },

    -- Blacklist de identificadores
    blacklist = {
        identificadores = {},
        ips = {},
    },
}

-- ============================================================================
-- ALMACENAMIENTO EN MEMORIA
-- ============================================================================

local buckets = {} -- Token buckets por jugador/accion
local ventanas = {} -- Sliding windows por jugador/accion
local penalizaciones = {} -- Penalizaciones activas
local violaciones = {} -- Contador de violaciones
local cooldownsActivos = {} -- Cooldowns activos
local ultimaLimpieza = 0

-- ============================================================================
-- UTILIDADES INTERNAS
-- ============================================================================

--- Genera una clave unica para identificar jugador + accion
-- @param identificador string - Identificador del jugador o IP
-- @param accion string - Nombre de la accion
-- @return string - Clave unica
local function generarClave(identificador, accion)
    return string.format("%s:%s", tostring(identificador), tostring(accion))
end

--- Obtiene el timestamp actual en milisegundos
-- @return number - Timestamp en ms
local function obtenerTimestamp()
    return GetGameTimer()
end

--- Registra un mensaje de debug
-- @param mensaje string - Mensaje a registrar
local function debug(mensaje)
    if AIT.RateLimit.Config.modoDebug then
        print(string.format("[AIT.RateLimit] [DEBUG] %s", mensaje))
    end
end

--- Registra un mensaje de advertencia
-- @param mensaje string - Mensaje a registrar
local function advertencia(mensaje)
    print(string.format("[AIT.RateLimit] [ADVERTENCIA] %s", mensaje))
end

--- Limpia datos expirados de memoria
local function limpiarDatosExpirados()
    local ahora = obtenerTimestamp()

    -- Limpiar cada 60 segundos
    if ahora - ultimaLimpieza < 60000 then
        return
    end

    ultimaLimpieza = ahora
    local ventanaMaxima = AIT.RateLimit.Config.slidingWindow.ventanaMs * 2

    -- Limpiar ventanas expiradas
    for clave, ventana in pairs(ventanas) do
        local peticionesValidas = {}
        for _, timestamp in ipairs(ventana.peticiones or {}) do
            if ahora - timestamp < ventanaMaxima then
                table.insert(peticionesValidas, timestamp)
            end
        end

        if #peticionesValidas == 0 then
            ventanas[clave] = nil
        else
            ventana.peticiones = peticionesValidas
        end
    end

    -- Limpiar penalizaciones expiradas
    for clave, penalizacion in pairs(penalizaciones) do
        if penalizacion.expira and penalizacion.expira < ahora then
            penalizaciones[clave] = nil
            debug(string.format("Penalizacion expirada para: %s", clave))
        end
    end

    -- Limpiar cooldowns expirados
    for clave, cooldown in pairs(cooldownsActivos) do
        if cooldown.expira and cooldown.expira < ahora then
            cooldownsActivos[clave] = nil
        end
    end

    debug("Limpieza de datos expirados completada")
end

-- ============================================================================
-- TOKEN BUCKET
-- ============================================================================

--- Obtiene o crea un bucket para un identificador y accion
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param config table - Configuracion personalizada (opcional)
-- @return table - Bucket
local function obtenerBucket(identificador, accion, config)
    local clave = generarClave(identificador, accion)
    local cfg = config or AIT.RateLimit.Config.tokenBucket

    if not buckets[clave] then
        buckets[clave] = {
            tokens = cfg.tokensMaximos,
            ultimaRecarga = obtenerTimestamp(),
            tokensMaximos = cfg.tokensMaximos,
            tokensRecarga = cfg.tokensRecarga,
            intervaloRecarga = cfg.intervaloRecarga,
        }
        debug(string.format("Bucket creado para: %s", clave))
    end

    return buckets[clave]
end

--- Recarga tokens en un bucket basado en el tiempo transcurrido
-- @param bucket table - Bucket a recargar
local function recargarTokens(bucket)
    local ahora = obtenerTimestamp()
    local tiempoTranscurrido = ahora - bucket.ultimaRecarga
    local tokensARecargar = math.floor(tiempoTranscurrido / bucket.intervaloRecarga) * bucket.tokensRecarga

    if tokensARecargar > 0 then
        bucket.tokens = math.min(bucket.tokensMaximos, bucket.tokens + tokensARecargar)
        bucket.ultimaRecarga = ahora
        debug(string.format("Tokens recargados: +%d (total: %d)", tokensARecargar, bucket.tokens))
    end
end

--- Intenta consumir un token del bucket
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param cantidad number - Cantidad de tokens a consumir (defecto: 1)
-- @param config table - Configuracion personalizada (opcional)
-- @return boolean - true si se pudo consumir, false si no hay tokens
-- @return number - Tokens restantes
function AIT.RateLimit.ConsumirToken(identificador, accion, cantidad, config)
    cantidad = cantidad or 1
    local bucket = obtenerBucket(identificador, accion, config)

    recargarTokens(bucket)

    if bucket.tokens >= cantidad then
        bucket.tokens = bucket.tokens - cantidad
        debug(string.format("Token consumido para %s:%s (restantes: %d)", identificador, accion, bucket.tokens))
        return true, bucket.tokens
    end

    debug(string.format("Sin tokens para %s:%s", identificador, accion))
    return false, bucket.tokens
end

--- Obtiene el estado actual de un bucket
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @return table - Estado del bucket
function AIT.RateLimit.ObtenerEstadoBucket(identificador, accion)
    local bucket = obtenerBucket(identificador, accion)
    recargarTokens(bucket)

    return {
        tokens = bucket.tokens,
        tokensMaximos = bucket.tokensMaximos,
        proximaRecarga = bucket.ultimaRecarga + bucket.intervaloRecarga,
    }
end

-- ============================================================================
-- SLIDING WINDOW
-- ============================================================================

--- Obtiene o crea una ventana deslizante para un identificador y accion
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param config table - Configuracion personalizada (opcional)
-- @return table - Ventana
local function obtenerVentana(identificador, accion, config)
    local clave = generarClave(identificador, accion)
    local cfg = config or AIT.RateLimit.Config.slidingWindow

    if not ventanas[clave] then
        ventanas[clave] = {
            peticiones = {},
            ventanaMs = cfg.ventanaMs,
            maxPeticiones = cfg.maxPeticiones,
        }
        debug(string.format("Ventana creada para: %s", clave))
    end

    return ventanas[clave]
end

--- Limpia peticiones expiradas de una ventana
-- @param ventana table - Ventana a limpiar
local function limpiarVentana(ventana)
    local ahora = obtenerTimestamp()
    local peticionesValidas = {}

    for _, timestamp in ipairs(ventana.peticiones) do
        if ahora - timestamp < ventana.ventanaMs then
            table.insert(peticionesValidas, timestamp)
        end
    end

    ventana.peticiones = peticionesValidas
end

--- Verifica si se puede realizar una peticion usando sliding window
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param config table - Configuracion personalizada (opcional)
-- @return boolean - true si se permite, false si excede el limite
-- @return number - Peticiones en la ventana actual
function AIT.RateLimit.VerificarVentana(identificador, accion, config)
    local ventana = obtenerVentana(identificador, accion, config)

    limpiarVentana(ventana)

    local peticionesActuales = #ventana.peticiones

    if peticionesActuales < ventana.maxPeticiones then
        table.insert(ventana.peticiones, obtenerTimestamp())
        debug(string.format("Peticion permitida para %s:%s (%d/%d)",
            identificador, accion, peticionesActuales + 1, ventana.maxPeticiones))
        return true, peticionesActuales + 1
    end

    debug(string.format("Peticion denegada para %s:%s (limite alcanzado)", identificador, accion))
    return false, peticionesActuales
end

--- Obtiene el estado actual de una ventana
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @return table - Estado de la ventana
function AIT.RateLimit.ObtenerEstadoVentana(identificador, accion)
    local ventana = obtenerVentana(identificador, accion)
    limpiarVentana(ventana)

    local peticionesActuales = #ventana.peticiones
    local proximaExpiracion = ventana.peticiones[1] and (ventana.peticiones[1] + ventana.ventanaMs) or nil

    return {
        peticiones = peticionesActuales,
        maxPeticiones = ventana.maxPeticiones,
        disponibles = ventana.maxPeticiones - peticionesActuales,
        proximaExpiracion = proximaExpiracion,
    }
end

-- ============================================================================
-- SISTEMA DE PENALIZACIONES
-- ============================================================================

--- Registra una violacion para un identificador
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param razon string - Razon de la violacion
function AIT.RateLimit.RegistrarViolacion(identificador, accion, razon)
    if not AIT.RateLimit.Config.penalizaciones.habilitadas then
        return
    end

    local clave = generarClave(identificador, accion)

    violaciones[clave] = violaciones[clave] or {
        contador = 0,
        historial = {},
    }

    violaciones[clave].contador = violaciones[clave].contador + 1
    table.insert(violaciones[clave].historial, {
        timestamp = obtenerTimestamp(),
        razon = razon,
    })

    advertencia(string.format("Violacion registrada para %s: %s (total: %d)",
        clave, razon, violaciones[clave].contador))

    -- Aplicar penalizacion si supera el umbral
    local cfg = AIT.RateLimit.Config.penalizaciones
    if violaciones[clave].contador >= cfg.umbralViolaciones then
        local multiplicadorActual = math.min(
            violaciones[clave].contador - cfg.umbralViolaciones + 1,
            math.log(cfg.maxDuracion / cfg.duracionBase) / math.log(cfg.multiplicador) + 1
        )
        local duracion = math.min(
            cfg.duracionBase * (cfg.multiplicador ^ (multiplicadorActual - 1)),
            cfg.maxDuracion
        )

        AIT.RateLimit.AplicarPenalizacion(identificador, accion, duracion, "Exceso de violaciones")
    end
end

--- Aplica una penalizacion a un identificador
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion (nil para todas)
-- @param duracionMs number - Duracion en milisegundos
-- @param razon string - Razon de la penalizacion
function AIT.RateLimit.AplicarPenalizacion(identificador, accion, duracionMs, razon)
    local clave = accion and generarClave(identificador, accion) or identificador

    penalizaciones[clave] = {
        inicio = obtenerTimestamp(),
        expira = obtenerTimestamp() + duracionMs,
        duracion = duracionMs,
        razon = razon,
        accion = accion,
    }

    advertencia(string.format("Penalizacion aplicada a %s por %dms: %s",
        clave, duracionMs, razon))
end

--- Verifica si un identificador tiene penalizacion activa
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion (opcional)
-- @return boolean - true si tiene penalizacion activa
-- @return table|nil - Datos de la penalizacion si existe
function AIT.RateLimit.TienePenalizacion(identificador, accion)
    local ahora = obtenerTimestamp()

    -- Verificar penalizacion global
    local penGlobal = penalizaciones[identificador]
    if penGlobal and penGlobal.expira > ahora then
        return true, penGlobal
    end

    -- Verificar penalizacion especifica
    if accion then
        local clave = generarClave(identificador, accion)
        local penEspecifica = penalizaciones[clave]
        if penEspecifica and penEspecifica.expira > ahora then
            return true, penEspecifica
        end
    end

    return false, nil
end

--- Elimina una penalizacion
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion (opcional)
function AIT.RateLimit.EliminarPenalizacion(identificador, accion)
    local clave = accion and generarClave(identificador, accion) or identificador
    penalizaciones[clave] = nil
    debug(string.format("Penalizacion eliminada para: %s", clave))
end

-- ============================================================================
-- WHITELIST / BLACKLIST
-- ============================================================================

--- Agrega un identificador a la whitelist
-- @param tipo string - Tipo: 'identificador', 'ip', 'accion'
-- @param valor string - Valor a agregar
function AIT.RateLimit.AgregarWhitelist(tipo, valor)
    local lista = nil

    if tipo == 'identificador' then
        lista = AIT.RateLimit.Config.whitelist.identificadores
    elseif tipo == 'ip' then
        lista = AIT.RateLimit.Config.whitelist.ips
    elseif tipo == 'accion' then
        lista = AIT.RateLimit.Config.whitelist.acciones
    end

    if lista then
        lista[valor] = true
        debug(string.format("Agregado a whitelist (%s): %s", tipo, valor))
    end
end

--- Elimina un identificador de la whitelist
-- @param tipo string - Tipo: 'identificador', 'ip', 'accion'
-- @param valor string - Valor a eliminar
function AIT.RateLimit.EliminarWhitelist(tipo, valor)
    local lista = nil

    if tipo == 'identificador' then
        lista = AIT.RateLimit.Config.whitelist.identificadores
    elseif tipo == 'ip' then
        lista = AIT.RateLimit.Config.whitelist.ips
    elseif tipo == 'accion' then
        lista = AIT.RateLimit.Config.whitelist.acciones
    end

    if lista then
        lista[valor] = nil
        debug(string.format("Eliminado de whitelist (%s): %s", tipo, valor))
    end
end

--- Verifica si un identificador esta en whitelist
-- @param identificador string - Identificador a verificar
-- @param ip string - IP a verificar (opcional)
-- @param accion string - Accion a verificar (opcional)
-- @return boolean - true si esta en whitelist
function AIT.RateLimit.EstaEnWhitelist(identificador, ip, accion)
    local cfg = AIT.RateLimit.Config.whitelist

    if identificador and cfg.identificadores[identificador] then
        return true
    end

    if ip and cfg.ips[ip] then
        return true
    end

    if accion and cfg.acciones[accion] then
        return true
    end

    return false
end

--- Agrega un identificador a la blacklist
-- @param tipo string - Tipo: 'identificador', 'ip'
-- @param valor string - Valor a agregar
function AIT.RateLimit.AgregarBlacklist(tipo, valor)
    local lista = nil

    if tipo == 'identificador' then
        lista = AIT.RateLimit.Config.blacklist.identificadores
    elseif tipo == 'ip' then
        lista = AIT.RateLimit.Config.blacklist.ips
    end

    if lista then
        lista[valor] = true
        advertencia(string.format("Agregado a blacklist (%s): %s", tipo, valor))
    end
end

--- Verifica si un identificador esta en blacklist
-- @param identificador string - Identificador a verificar
-- @param ip string - IP a verificar (opcional)
-- @return boolean - true si esta en blacklist
function AIT.RateLimit.EstaEnBlacklist(identificador, ip)
    local cfg = AIT.RateLimit.Config.blacklist

    if identificador and cfg.identificadores[identificador] then
        return true
    end

    if ip and cfg.ips[ip] then
        return true
    end

    return false
end

-- ============================================================================
-- SISTEMA DE COOLDOWNS
-- ============================================================================

--- Inicia un cooldown para un identificador y accion
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param duracionMs number - Duracion en ms (opcional, usa defecto)
function AIT.RateLimit.IniciarCooldown(identificador, accion, duracionMs)
    local clave = generarClave(identificador, accion)
    duracionMs = duracionMs or AIT.RateLimit.Config.cooldowns.defecto

    cooldownsActivos[clave] = {
        inicio = obtenerTimestamp(),
        expira = obtenerTimestamp() + duracionMs,
        duracion = duracionMs,
    }

    debug(string.format("Cooldown iniciado para %s: %dms", clave, duracionMs))
end

--- Verifica si hay un cooldown activo
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @return boolean - true si hay cooldown activo
-- @return number|nil - Tiempo restante en ms
function AIT.RateLimit.TieneCooldown(identificador, accion)
    local clave = generarClave(identificador, accion)
    local cooldown = cooldownsActivos[clave]

    if not cooldown then
        return false, nil
    end

    local ahora = obtenerTimestamp()
    if cooldown.expira > ahora then
        return true, cooldown.expira - ahora
    end

    -- Cooldown expirado, limpiar
    cooldownsActivos[clave] = nil
    return false, nil
end

--- Elimina un cooldown activo
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
function AIT.RateLimit.EliminarCooldown(identificador, accion)
    local clave = generarClave(identificador, accion)
    cooldownsActivos[clave] = nil
    debug(string.format("Cooldown eliminado para: %s", clave))
end

-- ============================================================================
-- FUNCION PRINCIPAL DE VERIFICACION
-- ============================================================================

--- Verifica si una accion esta permitida para un jugador
-- Combina todas las verificaciones: whitelist, blacklist, penalizaciones, cooldown y rate limit
-- @param identificador string - Identificador del jugador
-- @param accion string - Nombre de la accion
-- @param opciones table - Opciones adicionales
-- @return boolean - true si la accion esta permitida
-- @return string|nil - Razon del rechazo si no esta permitida
-- @return table|nil - Datos adicionales
function AIT.RateLimit.Verificar(identificador, accion, opciones)
    opciones = opciones or {}

    -- Verificar si el sistema esta habilitado
    if not AIT.RateLimit.Config.habilitado then
        return true, nil, nil
    end

    -- Limpiar datos expirados periodicamente
    limpiarDatosExpirados()

    local ip = opciones.ip

    -- Verificar whitelist
    if AIT.RateLimit.EstaEnWhitelist(identificador, ip, accion) then
        debug(string.format("Permitido por whitelist: %s", identificador))
        return true, nil, { razon = "whitelist" }
    end

    -- Verificar blacklist
    if AIT.RateLimit.EstaEnBlacklist(identificador, ip) then
        advertencia(string.format("Bloqueado por blacklist: %s", identificador))
        return false, "Acceso denegado (blacklist)", { razon = "blacklist" }
    end

    -- Verificar penalizaciones
    local tienePen, datosPen = AIT.RateLimit.TienePenalizacion(identificador, accion)
    if tienePen then
        local tiempoRestante = datosPen.expira - obtenerTimestamp()
        return false, string.format("Penalizado: %s (restante: %ds)", datosPen.razon, tiempoRestante / 1000),
            { razon = "penalizacion", datos = datosPen }
    end

    -- Verificar cooldown
    local tieneCd, tiempoRestante = AIT.RateLimit.TieneCooldown(identificador, accion)
    if tieneCd then
        return false, string.format("En cooldown (restante: %dms)", tiempoRestante),
            { razon = "cooldown", tiempoRestante = tiempoRestante }
    end

    -- Verificar rate limit segun algoritmo configurado
    local algoritmo = opciones.algoritmo or AIT.RateLimit.Config.algoritmoDefecto
    local permitido, cantidad

    if algoritmo == 'token_bucket' then
        permitido, cantidad = AIT.RateLimit.ConsumirToken(identificador, accion, opciones.tokens, opciones.configBucket)
        if not permitido then
            AIT.RateLimit.RegistrarViolacion(identificador, accion, "Sin tokens disponibles")
            return false, "Limite de peticiones excedido (token bucket)",
                { razon = "rate_limit", algoritmo = "token_bucket", tokensRestantes = cantidad }
        end
    elseif algoritmo == 'sliding_window' then
        permitido, cantidad = AIT.RateLimit.VerificarVentana(identificador, accion, opciones.configVentana)
        if not permitido then
            AIT.RateLimit.RegistrarViolacion(identificador, accion, "Ventana de peticiones llena")
            return false, "Limite de peticiones excedido (sliding window)",
                { razon = "rate_limit", algoritmo = "sliding_window", peticionesActuales = cantidad }
        end
    end

    -- Aplicar cooldown si esta configurado en opciones
    if opciones.cooldown then
        AIT.RateLimit.IniciarCooldown(identificador, accion, opciones.cooldown)
    end

    return true, nil, { razon = "permitido", algoritmo = algoritmo }
end

-- ============================================================================
-- FUNCIONES DE ADMINISTRACION
-- ============================================================================

--- Reinicia todos los datos de rate limiting para un identificador
-- @param identificador string - Identificador del jugador
function AIT.RateLimit.ReiniciarJugador(identificador)
    -- Limpiar buckets
    for clave in pairs(buckets) do
        if string.find(clave, "^" .. identificador .. ":") then
            buckets[clave] = nil
        end
    end

    -- Limpiar ventanas
    for clave in pairs(ventanas) do
        if string.find(clave, "^" .. identificador .. ":") then
            ventanas[clave] = nil
        end
    end

    -- Limpiar violaciones
    for clave in pairs(violaciones) do
        if string.find(clave, "^" .. identificador .. ":") then
            violaciones[clave] = nil
        end
    end

    -- Limpiar penalizaciones
    penalizaciones[identificador] = nil
    for clave in pairs(penalizaciones) do
        if string.find(clave, "^" .. identificador .. ":") then
            penalizaciones[clave] = nil
        end
    end

    -- Limpiar cooldowns
    for clave in pairs(cooldownsActivos) do
        if string.find(clave, "^" .. identificador .. ":") then
            cooldownsActivos[clave] = nil
        end
    end

    debug(string.format("Datos reiniciados para jugador: %s", identificador))
end

--- Obtiene estadisticas generales del sistema
-- @return table - Estadisticas
function AIT.RateLimit.ObtenerEstadisticas()
    local numBuckets = 0
    local numVentanas = 0
    local numPenalizaciones = 0
    local numCooldowns = 0
    local numViolaciones = 0

    for _ in pairs(buckets) do numBuckets = numBuckets + 1 end
    for _ in pairs(ventanas) do numVentanas = numVentanas + 1 end
    for _ in pairs(penalizaciones) do numPenalizaciones = numPenalizaciones + 1 end
    for _ in pairs(cooldownsActivos) do numCooldowns = numCooldowns + 1 end
    for _, v in pairs(violaciones) do numViolaciones = numViolaciones + (v.contador or 0) end

    return {
        buckets = numBuckets,
        ventanas = numVentanas,
        penalizacionesActivas = numPenalizaciones,
        cooldownsActivos = numCooldowns,
        totalViolaciones = numViolaciones,
        ultimaLimpieza = ultimaLimpieza,
    }
end

--- Exporta la configuracion actual
-- @return table - Configuracion
function AIT.RateLimit.ExportarConfiguracion()
    return AIT.RateLimit.Config
end

--- Importa una configuracion
-- @param config table - Configuracion a importar
function AIT.RateLimit.ImportarConfiguracion(config)
    if type(config) ~= "table" then
        advertencia("Configuracion invalida para importar")
        return
    end

    for clave, valor in pairs(config) do
        if AIT.RateLimit.Config[clave] ~= nil then
            AIT.RateLimit.Config[clave] = valor
        end
    end

    debug("Configuracion importada correctamente")
end

-- ============================================================================
-- INICIALIZACION
-- ============================================================================

print("[AIT.RateLimit] Sistema de Rate Limiting inicializado")
print(string.format("[AIT.RateLimit] Algoritmo por defecto: %s", AIT.RateLimit.Config.algoritmoDefecto))

return AIT.RateLimit
