--[[
    AIT Framework - Sistema de Cache Multinivel
    Cache de alto rendimiento con soporte L1 (memoria) y L2 (KVS)

    Caracteristicas:
    - Cache multinivel (L1 memoria rapida, L2 persistente)
    - TTL configurable por entrada
    - Sistema de tags para invalidacion en grupo
    - Warm-up automatico al iniciar
    - Estadisticas detalladas
    - Compresion opcional para valores grandes
    - Limite de tamano configurable

    Autor: AIT Framework
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.Cache = AIT.Cache or {}

-- ============================================================================
-- CONFIGURACION
-- ============================================================================

local Config = {
    -- Cache L1 (Memoria)
    L1 = {
        habilitado = true,
        maxEntradas = 10000,
        maxTamanoBytes = 50 * 1024 * 1024, -- 50 MB
        ttlDefecto = 300, -- 5 minutos
        limpiezaIntervalo = 60 -- Cada 60 segundos
    },

    -- Cache L2 (KVS - Key Value Store)
    L2 = {
        habilitado = true,
        prefijo = "ait_cache_",
        ttlDefecto = 3600, -- 1 hora
        compresionMinBytes = 1024 -- Comprimir si > 1KB
    },

    -- General
    debug = false,
    statsHabilitadas = true
}

-- ============================================================================
-- ESTADO INTERNO
-- ============================================================================

local Estado = {
    -- Cache L1
    l1Data = {},
    l1Tags = {},
    l1Orden = {}, -- Para LRU
    l1TamanoActual = 0,
    l1Entradas = 0,

    -- Estadisticas
    stats = {
        hits = { l1 = 0, l2 = 0 },
        misses = 0,
        escrituras = { l1 = 0, l2 = 0 },
        evictions = 0,
        invalidaciones = 0,
        compresiones = 0,
        descompresiones = 0
    },

    -- Control
    iniciado = false,
    warmupCompletado = false
}

-- ============================================================================
-- UTILIDADES
-- ============================================================================

local function Log(mensaje, ...)
    if Config.debug then
        print(string.format("[AIT.Cache] " .. mensaje, ...))
    end
end

local function LogError(mensaje, ...)
    print(string.format("^1[AIT.Cache ERROR] " .. mensaje .. "^0", ...))
end

local function ObtenerTiempo()
    return os.time()
end

local function EstimarTamano(valor)
    local tipo = type(valor)

    if tipo == "string" then
        return #valor
    elseif tipo == "number" then
        return 8
    elseif tipo == "boolean" then
        return 1
    elseif tipo == "table" then
        local tamano = 0
        for k, v in pairs(valor) do
            tamano = tamano + EstimarTamano(k) + EstimarTamano(v)
        end
        return tamano
    else
        return 0
    end
end

local function Serializar(valor)
    local tipo = type(valor)

    if tipo == "nil" then
        return "nil"
    elseif tipo == "boolean" then
        return valor and "true" or "false"
    elseif tipo == "number" then
        return tostring(valor)
    elseif tipo == "string" then
        return string.format("%q", valor)
    elseif tipo == "table" then
        local partes = {}
        for k, v in pairs(valor) do
            local clave = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", tostring(k))
            table.insert(partes, clave .. "=" .. Serializar(v))
        end
        return "{" .. table.concat(partes, ",") .. "}"
    else
        return "nil"
    end
end

local function Deserializar(str)
    if not str or str == "" then
        return nil
    end

    local func, err = load("return " .. str)
    if func then
        local ok, resultado = pcall(func)
        if ok then
            return resultado
        end
    end

    return nil
end

-- Compresion simple usando Run-Length Encoding
local function Comprimir(datos)
    if type(datos) ~= "string" or #datos < Config.L2.compresionMinBytes then
        return datos, false
    end

    local resultado = {}
    local i = 1
    local longitud = #datos

    while i <= longitud do
        local char = datos:sub(i, i)
        local count = 1

        while i + count <= longitud and datos:sub(i + count, i + count) == char and count < 255 do
            count = count + 1
        end

        if count >= 3 then
            table.insert(resultado, string.format("\0%c%s", count, char))
        else
            for j = 1, count do
                table.insert(resultado, char)
            end
        end

        i = i + count
    end

    local comprimido = table.concat(resultado)

    if #comprimido < #datos then
        Estado.stats.compresiones = Estado.stats.compresiones + 1
        return comprimido, true
    end

    return datos, false
end

local function Descomprimir(datos, estaComprimido)
    if not estaComprimido then
        return datos
    end

    local resultado = {}
    local i = 1
    local longitud = #datos

    while i <= longitud do
        local char = datos:sub(i, i)

        if char == "\0" and i + 2 <= longitud then
            local count = datos:byte(i + 1)
            local repeatChar = datos:sub(i + 2, i + 2)
            table.insert(resultado, string.rep(repeatChar, count))
            i = i + 3
        else
            table.insert(resultado, char)
            i = i + 1
        end
    end

    Estado.stats.descompresiones = Estado.stats.descompresiones + 1
    return table.concat(resultado)
end

-- ============================================================================
-- CACHE L1 (MEMORIA)
-- ============================================================================

local function L1_ActualizarOrden(clave)
    -- Remover de posicion actual si existe
    for i, k in ipairs(Estado.l1Orden) do
        if k == clave then
            table.remove(Estado.l1Orden, i)
            break
        end
    end

    -- Agregar al final (mas reciente)
    table.insert(Estado.l1Orden, clave)
end

local function L1_Evictar()
    while Estado.l1Entradas > Config.L1.maxEntradas or
          Estado.l1TamanoActual > Config.L1.maxTamanoBytes do

        if #Estado.l1Orden == 0 then
            break
        end

        -- Remover el menos recientemente usado (primero en la lista)
        local claveEvictar = table.remove(Estado.l1Orden, 1)
        local entrada = Estado.l1Data[claveEvictar]

        if entrada then
            Estado.l1TamanoActual = Estado.l1TamanoActual - entrada.tamano
            Estado.l1Entradas = Estado.l1Entradas - 1

            -- Remover de tags
            if entrada.tags then
                for _, tag in ipairs(entrada.tags) do
                    if Estado.l1Tags[tag] then
                        Estado.l1Tags[tag][claveEvictar] = nil
                    end
                end
            end

            Estado.l1Data[claveEvictar] = nil
            Estado.stats.evictions = Estado.stats.evictions + 1

            Log("Evictado de L1: %s", claveEvictar)
        end
    end
end

local function L1_Establecer(clave, valor, ttl, tags)
    if not Config.L1.habilitado then
        return false
    end

    local tamano = EstimarTamano(valor)
    local ahora = ObtenerTiempo()

    -- Si ya existe, actualizar tamano
    local entradaExistente = Estado.l1Data[clave]
    if entradaExistente then
        Estado.l1TamanoActual = Estado.l1TamanoActual - entradaExistente.tamano
        Estado.l1Entradas = Estado.l1Entradas - 1

        -- Limpiar tags anteriores
        if entradaExistente.tags then
            for _, tag in ipairs(entradaExistente.tags) do
                if Estado.l1Tags[tag] then
                    Estado.l1Tags[tag][clave] = nil
                end
            end
        end
    end

    -- Crear nueva entrada
    local entrada = {
        valor = valor,
        expira = ahora + (ttl or Config.L1.ttlDefecto),
        tamano = tamano,
        tags = tags,
        creadoEn = ahora,
        accesos = 0
    }

    Estado.l1Data[clave] = entrada
    Estado.l1TamanoActual = Estado.l1TamanoActual + tamano
    Estado.l1Entradas = Estado.l1Entradas + 1

    -- Registrar tags
    if tags then
        for _, tag in ipairs(tags) do
            Estado.l1Tags[tag] = Estado.l1Tags[tag] or {}
            Estado.l1Tags[tag][clave] = true
        end
    end

    L1_ActualizarOrden(clave)
    L1_Evictar()

    Estado.stats.escrituras.l1 = Estado.stats.escrituras.l1 + 1
    Log("L1 SET: %s (TTL: %ds, Tamano: %d bytes)", clave, ttl or Config.L1.ttlDefecto, tamano)

    return true
end

local function L1_Obtener(clave)
    if not Config.L1.habilitado then
        return nil, false
    end

    local entrada = Estado.l1Data[clave]

    if not entrada then
        return nil, false
    end

    local ahora = ObtenerTiempo()

    -- Verificar expiracion
    if entrada.expira < ahora then
        -- Expirado, eliminar
        Estado.l1TamanoActual = Estado.l1TamanoActual - entrada.tamano
        Estado.l1Entradas = Estado.l1Entradas - 1

        if entrada.tags then
            for _, tag in ipairs(entrada.tags) do
                if Estado.l1Tags[tag] then
                    Estado.l1Tags[tag][clave] = nil
                end
            end
        end

        Estado.l1Data[clave] = nil
        Log("L1 EXPIRADO: %s", clave)
        return nil, false
    end

    -- Actualizar estadisticas y orden
    entrada.accesos = entrada.accesos + 1
    L1_ActualizarOrden(clave)
    Estado.stats.hits.l1 = Estado.stats.hits.l1 + 1

    Log("L1 HIT: %s (accesos: %d)", clave, entrada.accesos)
    return entrada.valor, true
end

local function L1_Eliminar(clave)
    local entrada = Estado.l1Data[clave]

    if entrada then
        Estado.l1TamanoActual = Estado.l1TamanoActual - entrada.tamano
        Estado.l1Entradas = Estado.l1Entradas - 1

        if entrada.tags then
            for _, tag in ipairs(entrada.tags) do
                if Estado.l1Tags[tag] then
                    Estado.l1Tags[tag][clave] = nil
                end
            end
        end

        -- Remover de orden
        for i, k in ipairs(Estado.l1Orden) do
            if k == clave then
                table.remove(Estado.l1Orden, i)
                break
            end
        end

        Estado.l1Data[clave] = nil
        Log("L1 DELETE: %s", clave)
        return true
    end

    return false
end

local function L1_LimpiarExpirados()
    local ahora = ObtenerTiempo()
    local eliminados = 0

    for clave, entrada in pairs(Estado.l1Data) do
        if entrada.expira < ahora then
            L1_Eliminar(clave)
            eliminados = eliminados + 1
        end
    end

    if eliminados > 0 then
        Log("L1 Limpieza: %d entradas expiradas eliminadas", eliminados)
    end

    return eliminados
end

-- ============================================================================
-- CACHE L2 (KVS - PERSISTENTE)
-- ============================================================================

local function L2_GenerarClave(clave)
    return Config.L2.prefijo .. clave
end

local function L2_Establecer(clave, valor, ttl)
    if not Config.L2.habilitado then
        return false
    end

    local claveKvs = L2_GenerarClave(clave)
    local ahora = ObtenerTiempo()

    local datos = Serializar(valor)
    local comprimido, fueComprimido = Comprimir(datos)

    local entrada = {
        d = comprimido, -- datos
        c = fueComprimido, -- comprimido
        e = ahora + (ttl or Config.L2.ttlDefecto), -- expira
        t = ahora -- timestamp
    }

    local entradaStr = Serializar(entrada)

    -- Usar KVS de FiveM
    local ok, err = pcall(function()
        SetResourceKvp(claveKvs, entradaStr)
    end)

    if ok then
        Estado.stats.escrituras.l2 = Estado.stats.escrituras.l2 + 1
        Log("L2 SET: %s (TTL: %ds)", clave, ttl or Config.L2.ttlDefecto)
        return true
    else
        LogError("Error al escribir en L2: %s - %s", clave, tostring(err))
        return false
    end
end

local function L2_Obtener(clave)
    if not Config.L2.habilitado then
        return nil, false
    end

    local claveKvs = L2_GenerarClave(clave)

    local ok, entradaStr = pcall(function()
        return GetResourceKvpString(claveKvs)
    end)

    if not ok or not entradaStr then
        return nil, false
    end

    local entrada = Deserializar(entradaStr)

    if not entrada then
        return nil, false
    end

    local ahora = ObtenerTiempo()

    -- Verificar expiracion
    if entrada.e < ahora then
        -- Expirado, eliminar
        pcall(function()
            DeleteResourceKvp(claveKvs)
        end)
        Log("L2 EXPIRADO: %s", clave)
        return nil, false
    end

    -- Descomprimir y deserializar
    local datos = Descomprimir(entrada.d, entrada.c)
    local valor = Deserializar(datos)

    Estado.stats.hits.l2 = Estado.stats.hits.l2 + 1
    Log("L2 HIT: %s", clave)

    return valor, true
end

local function L2_Eliminar(clave)
    if not Config.L2.habilitado then
        return false
    end

    local claveKvs = L2_GenerarClave(clave)

    local ok = pcall(function()
        DeleteResourceKvp(claveKvs)
    end)

    if ok then
        Log("L2 DELETE: %s", clave)
        return true
    end

    return false
end

-- ============================================================================
-- API PUBLICA
-- ============================================================================

--- Establece un valor en el cache
-- @param clave string - Clave unica
-- @param valor any - Valor a almacenar
-- @param opciones table - { ttl, tags, soloL1, soloL2 }
-- @return boolean - Exito
function AIT.Cache.Establecer(clave, valor, opciones)
    opciones = opciones or {}
    local ttl = opciones.ttl
    local tags = opciones.tags
    local soloL1 = opciones.soloL1
    local soloL2 = opciones.soloL2

    local exitoL1, exitoL2 = false, false

    -- Escribir en L1
    if not soloL2 then
        exitoL1 = L1_Establecer(clave, valor, ttl, tags)
    end

    -- Escribir en L2
    if not soloL1 then
        exitoL2 = L2_Establecer(clave, valor, ttl)
    end

    return exitoL1 or exitoL2
end

--- Obtiene un valor del cache
-- @param clave string - Clave a buscar
-- @param opciones table - { soloL1, soloL2, default }
-- @return any - Valor o default
function AIT.Cache.Obtener(clave, opciones)
    opciones = opciones or {}
    local soloL1 = opciones.soloL1
    local soloL2 = opciones.soloL2
    local valorDefault = opciones.default

    -- Intentar L1 primero (mas rapido)
    if not soloL2 then
        local valor, encontrado = L1_Obtener(clave)
        if encontrado then
            return valor
        end
    end

    -- Intentar L2
    if not soloL1 then
        local valor, encontrado = L2_Obtener(clave)
        if encontrado then
            -- Promover a L1 para acceso mas rapido
            if not soloL2 and Config.L1.habilitado then
                L1_Establecer(clave, valor)
            end
            return valor
        end
    end

    Estado.stats.misses = Estado.stats.misses + 1
    Log("MISS: %s", clave)

    return valorDefault
end

--- Verifica si una clave existe en el cache
-- @param clave string - Clave a verificar
-- @return boolean - Existe
function AIT.Cache.Existe(clave)
    local valor, encontradoL1 = L1_Obtener(clave)
    if encontradoL1 then
        return true
    end

    local valor2, encontradoL2 = L2_Obtener(clave)
    return encontradoL2
end

--- Elimina una clave del cache
-- @param clave string - Clave a eliminar
-- @return boolean - Exito
function AIT.Cache.Eliminar(clave)
    local exitoL1 = L1_Eliminar(clave)
    local exitoL2 = L2_Eliminar(clave)

    Estado.stats.invalidaciones = Estado.stats.invalidaciones + 1

    return exitoL1 or exitoL2
end

--- Invalida todas las entradas con un tag especifico
-- @param tag string - Tag a invalidar
-- @return number - Cantidad de entradas invalidadas
function AIT.Cache.InvalidarPorTag(tag)
    local invalidados = 0

    if Estado.l1Tags[tag] then
        for clave, _ in pairs(Estado.l1Tags[tag]) do
            if L1_Eliminar(clave) then
                L2_Eliminar(clave)
                invalidados = invalidados + 1
            end
        end
        Estado.l1Tags[tag] = nil
    end

    Estado.stats.invalidaciones = Estado.stats.invalidaciones + invalidados
    Log("Invalidados %d entradas con tag: %s", invalidados, tag)

    return invalidados
end

--- Obtiene o establece un valor (patron Remember)
-- @param clave string - Clave
-- @param generador function - Funcion que genera el valor si no existe
-- @param opciones table - Opciones de cache
-- @return any - Valor
function AIT.Cache.Recordar(clave, generador, opciones)
    local valor = AIT.Cache.Obtener(clave)

    if valor ~= nil then
        return valor
    end

    valor = generador()

    if valor ~= nil then
        AIT.Cache.Establecer(clave, valor, opciones)
    end

    return valor
end

--- Limpia todo el cache L1
function AIT.Cache.LimpiarL1()
    Estado.l1Data = {}
    Estado.l1Tags = {}
    Estado.l1Orden = {}
    Estado.l1TamanoActual = 0
    Estado.l1Entradas = 0

    Log("L1 completamente limpiado")
end

--- Limpia entradas expiradas
-- @return number - Entradas eliminadas
function AIT.Cache.LimpiarExpirados()
    return L1_LimpiarExpirados()
end

--- Obtiene estadisticas del cache
-- @return table - Estadisticas
function AIT.Cache.ObtenerEstadisticas()
    local totalHits = Estado.stats.hits.l1 + Estado.stats.hits.l2
    local totalPeticiones = totalHits + Estado.stats.misses
    local tasaAcierto = totalPeticiones > 0 and (totalHits / totalPeticiones * 100) or 0

    return {
        hits = {
            l1 = Estado.stats.hits.l1,
            l2 = Estado.stats.hits.l2,
            total = totalHits
        },
        misses = Estado.stats.misses,
        tasaAcierto = string.format("%.2f%%", tasaAcierto),
        escrituras = {
            l1 = Estado.stats.escrituras.l1,
            l2 = Estado.stats.escrituras.l2
        },
        evictions = Estado.stats.evictions,
        invalidaciones = Estado.stats.invalidaciones,
        compresiones = Estado.stats.compresiones,
        descompresiones = Estado.stats.descompresiones,
        l1 = {
            entradas = Estado.l1Entradas,
            tamanoBytes = Estado.l1TamanoActual,
            tamanoMB = string.format("%.2f MB", Estado.l1TamanoActual / 1024 / 1024),
            maxEntradas = Config.L1.maxEntradas,
            maxTamanoMB = Config.L1.maxTamanoBytes / 1024 / 1024
        }
    }
end

--- Resetea las estadisticas
function AIT.Cache.ResetearEstadisticas()
    Estado.stats = {
        hits = { l1 = 0, l2 = 0 },
        misses = 0,
        escrituras = { l1 = 0, l2 = 0 },
        evictions = 0,
        invalidaciones = 0,
        compresiones = 0,
        descompresiones = 0
    }

    Log("Estadisticas reseteadas")
end

--- Warm-up del cache con datos iniciales
-- @param datos table - { { clave, valor, opciones }, ... }
function AIT.Cache.WarmUp(datos)
    if not datos or #datos == 0 then
        return
    end

    Log("Iniciando warm-up con %d entradas...", #datos)

    for _, entrada in ipairs(datos) do
        if entrada.clave and entrada.valor then
            AIT.Cache.Establecer(entrada.clave, entrada.valor, entrada.opciones)
        end
    end

    Estado.warmupCompletado = true
    Log("Warm-up completado")
end

--- Configura el sistema de cache
-- @param nuevaConfig table - Nueva configuracion
function AIT.Cache.Configurar(nuevaConfig)
    if nuevaConfig.L1 then
        for k, v in pairs(nuevaConfig.L1) do
            Config.L1[k] = v
        end
    end

    if nuevaConfig.L2 then
        for k, v in pairs(nuevaConfig.L2) do
            Config.L2[k] = v
        end
    end

    if nuevaConfig.debug ~= nil then
        Config.debug = nuevaConfig.debug
    end

    Log("Configuracion actualizada")
end

--- Obtiene multiples valores de una vez
-- @param claves table - Lista de claves
-- @return table - { clave = valor, ... }
function AIT.Cache.ObtenerMultiple(claves)
    local resultados = {}

    for _, clave in ipairs(claves) do
        resultados[clave] = AIT.Cache.Obtener(clave)
    end

    return resultados
end

--- Establece multiples valores de una vez
-- @param datos table - { { clave, valor, opciones }, ... }
function AIT.Cache.EstablecerMultiple(datos)
    for _, entrada in ipairs(datos) do
        if entrada.clave and entrada.valor ~= nil then
            AIT.Cache.Establecer(entrada.clave, entrada.valor, entrada.opciones)
        end
    end
end

--- Incrementa un valor numerico en cache
-- @param clave string - Clave
-- @param cantidad number - Cantidad a incrementar (default 1)
-- @return number - Nuevo valor
function AIT.Cache.Incrementar(clave, cantidad)
    cantidad = cantidad or 1
    local valor = AIT.Cache.Obtener(clave) or 0

    if type(valor) ~= "number" then
        LogError("No se puede incrementar valor no numerico: %s", clave)
        return nil
    end

    local nuevoValor = valor + cantidad
    AIT.Cache.Establecer(clave, nuevoValor)

    return nuevoValor
end

--- Decrementa un valor numerico en cache
-- @param clave string - Clave
-- @param cantidad number - Cantidad a decrementar (default 1)
-- @return number - Nuevo valor
function AIT.Cache.Decrementar(clave, cantidad)
    return AIT.Cache.Incrementar(clave, -(cantidad or 1))
end

-- ============================================================================
-- INICIALIZACION Y THREADS
-- ============================================================================

local function IniciarLimpiezaAutomatica()
    CreateThread(function()
        while true do
            Wait(Config.L1.limpiezaIntervalo * 1000)
            AIT.Cache.LimpiarExpirados()
        end
    end)
end

--- Inicializa el sistema de cache
function AIT.Cache.Iniciar()
    if Estado.iniciado then
        Log("Cache ya iniciado")
        return
    end

    IniciarLimpiezaAutomatica()
    Estado.iniciado = true

    Log("Sistema de cache multinivel iniciado")
    Log("L1: %s (max %d entradas, %d MB)",
        Config.L1.habilitado and "Habilitado" or "Deshabilitado",
        Config.L1.maxEntradas,
        Config.L1.maxTamanoBytes / 1024 / 1024)
    Log("L2: %s", Config.L2.habilitado and "Habilitado" or "Deshabilitado")
end

-- ============================================================================
-- EXPORTACIONES
-- ============================================================================

exports('cache_establecer', AIT.Cache.Establecer)
exports('cache_obtener', AIT.Cache.Obtener)
exports('cache_existe', AIT.Cache.Existe)
exports('cache_eliminar', AIT.Cache.Eliminar)
exports('cache_invalidar_tag', AIT.Cache.InvalidarPorTag)
exports('cache_recordar', AIT.Cache.Recordar)
exports('cache_estadisticas', AIT.Cache.ObtenerEstadisticas)
exports('cache_limpiar_l1', AIT.Cache.LimpiarL1)
exports('cache_warmup', AIT.Cache.WarmUp)
exports('cache_incrementar', AIT.Cache.Incrementar)
exports('cache_decrementar', AIT.Cache.Decrementar)

-- ============================================================================
-- AUTO-INICIO
-- ============================================================================

CreateThread(function()
    Wait(100)
    AIT.Cache.Iniciar()
end)

print("^2[AIT.Cache] Sistema de cache multinivel cargado^0")
