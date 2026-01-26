--[[
    AIT Framework - Sistema de Programacion de Tareas
    Scheduler avanzado tipo cron para FiveM

    Caracteristicas:
    - Programacion tipo cron (minuto, hora, dia, etc.)
    - Jobs recurrentes, unicos, delayed
    - Sistema de prioridades
    - Reintentos automaticos con backoff
    - Timeout configurable
    - Concurrencia limitada
    - Historial de ejecuciones

    Autor: AIT Framework
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.Scheduler = AIT.Scheduler or {}

-- ============================================================================
-- CONFIGURACION
-- ============================================================================

local Config = {
    -- General
    tickIntervalo = 1000, -- Verificar cada segundo
    maxConcurrencia = 5, -- Max tareas simultaneas
    maxHistorial = 100, -- Entradas en historial

    -- Reintentos
    maxReintentos = 3,
    reintentosBackoff = true, -- Incrementar tiempo entre reintentos
    reintentosBaseMs = 1000, -- Base para backoff exponencial

    -- Timeouts
    timeoutDefecto = 30000, -- 30 segundos
    timeoutMaximo = 300000, -- 5 minutos

    -- Prioridades (menor = mayor prioridad)
    prioridades = {
        CRITICA = 1,
        ALTA = 2,
        NORMAL = 3,
        BAJA = 4,
        MINIMA = 5
    },

    debug = false
}

-- ============================================================================
-- ESTADO INTERNO
-- ============================================================================

local Estado = {
    tareas = {},
    tareasEnEjecucion = {},
    colaPendiente = {},
    historial = {},
    contadorId = 0,
    iniciado = false,
    pausado = false,
    stats = {
        tareasCreadas = 0,
        tareasCompletadas = 0,
        tareasFallidas = 0,
        reintentos = 0,
        timeouts = 0
    }
}

-- ============================================================================
-- UTILIDADES
-- ============================================================================

local function Log(mensaje, ...)
    if Config.debug then
        print(string.format("[AIT.Scheduler] " .. mensaje, ...))
    end
end

local function LogError(mensaje, ...)
    print(string.format("^1[AIT.Scheduler ERROR] " .. mensaje .. "^0", ...))
end

local function GenerarId()
    Estado.contadorId = Estado.contadorId + 1
    return string.format("tarea_%d_%d", GetGameTimer(), Estado.contadorId)
end

local function ObtenerTiempoActual()
    return os.time()
end

local function ObtenerFechaActual()
    return os.date("*t")
end

-- ============================================================================
-- PARSER CRON
-- ============================================================================

local function ParsearCampoCron(campo, min, max)
    local valores = {}

    -- Asterisco = todos los valores
    if campo == "*" then
        for i = min, max do
            valores[i] = true
        end
        return valores
    end

    -- Rango con paso (*/5)
    local paso = campo:match("^%*/(%d+)$")
    if paso then
        paso = tonumber(paso)
        for i = min, max, paso do
            valores[i] = true
        end
        return valores
    end

    -- Rango (1-5)
    local inicio, fin = campo:match("^(%d+)-(%d+)$")
    if inicio and fin then
        inicio, fin = tonumber(inicio), tonumber(fin)
        for i = inicio, fin do
            if i >= min and i <= max then
                valores[i] = true
            end
        end
        return valores
    end

    -- Lista (1,3,5)
    for valor in campo:gmatch("(%d+)") do
        local num = tonumber(valor)
        if num >= min and num <= max then
            valores[num] = true
        end
    end

    return valores
end

local function ParsearExpressionCron(expresion)
    local partes = {}
    for parte in expresion:gmatch("%S+") do
        table.insert(partes, parte)
    end

    if #partes ~= 5 then
        LogError("Expresion cron invalida: %s (se esperan 5 campos)", expresion)
        return nil
    end

    return {
        minutos = ParsearCampoCron(partes[1], 0, 59),
        horas = ParsearCampoCron(partes[2], 0, 23),
        diasMes = ParsearCampoCron(partes[3], 1, 31),
        meses = ParsearCampoCron(partes[4], 1, 12),
        diasSemana = ParsearCampoCron(partes[5], 0, 6) -- 0 = Domingo
    }
end

local function CoincideCron(cronParseado, fecha)
    if not cronParseado then
        return false
    end

    fecha = fecha or ObtenerFechaActual()

    return cronParseado.minutos[fecha.min] and
           cronParseado.horas[fecha.hour] and
           cronParseado.diasMes[fecha.day] and
           cronParseado.meses[fecha.month] and
           cronParseado.diasSemana[fecha.wday - 1] -- Lua usa 1=Domingo, cron 0=Domingo
end

-- ============================================================================
-- GESTION DE TAREAS
-- ============================================================================

local function CrearTarea(opciones)
    local id = opciones.id or GenerarId()

    local tarea = {
        id = id,
        nombre = opciones.nombre or id,
        funcion = opciones.funcion,
        datos = opciones.datos,

        -- Programacion
        tipo = opciones.tipo or "unica", -- unica, recurrente, delayed, cron
        cron = opciones.cron,
        cronParseado = opciones.cron and ParsearExpressionCron(opciones.cron),
        intervalo = opciones.intervalo, -- Para recurrentes (ms)
        retraso = opciones.retraso, -- Para delayed (ms)
        proximaEjecucion = nil,

        -- Control
        prioridad = opciones.prioridad or Config.prioridades.NORMAL,
        timeout = math.min(opciones.timeout or Config.timeoutDefecto, Config.timeoutMaximo),
        maxReintentos = opciones.maxReintentos or Config.maxReintentos,
        reintentoActual = 0,

        -- Estado
        estado = "pendiente", -- pendiente, ejecutando, completada, fallida, cancelada
        habilitada = true,
        creadaEn = ObtenerTiempoActual(),
        ultimaEjecucion = nil,
        ejecuciones = 0,
        errores = 0
    }

    -- Calcular proxima ejecucion
    if tarea.tipo == "delayed" and tarea.retraso then
        tarea.proximaEjecucion = ObtenerTiempoActual() + (tarea.retraso / 1000)
    elseif tarea.tipo == "unica" then
        tarea.proximaEjecucion = ObtenerTiempoActual()
    elseif tarea.tipo == "recurrente" and tarea.intervalo then
        tarea.proximaEjecucion = ObtenerTiempoActual()
    elseif tarea.tipo == "cron" then
        tarea.proximaEjecucion = nil -- Se calcula en cada tick
    end

    return tarea
end

local function AgregarAlHistorial(tarea, exito, resultado, tiempoEjecucion)
    local entrada = {
        tareaId = tarea.id,
        nombre = tarea.nombre,
        timestamp = ObtenerTiempoActual(),
        exito = exito,
        resultado = resultado,
        tiempoEjecucion = tiempoEjecucion,
        reintentos = tarea.reintentoActual
    }

    table.insert(Estado.historial, 1, entrada)

    -- Limitar tamano del historial
    while #Estado.historial > Config.maxHistorial do
        table.remove(Estado.historial)
    end
end

local function EjecutarTarea(tarea)
    if not tarea.funcion then
        LogError("Tarea %s no tiene funcion definida", tarea.id)
        return false, "Sin funcion"
    end

    local inicio = GetGameTimer()
    local terminado = false
    local exito = false
    local resultado = nil

    -- Crear thread para la tarea con timeout
    CreateThread(function()
        local ok, res = pcall(tarea.funcion, tarea.datos)
        if not terminado then
            exito = ok
            resultado = ok and res or tostring(res)
            terminado = true
        end
    end)

    -- Esperar con timeout
    local tiempoEspera = 0
    while not terminado and tiempoEspera < tarea.timeout do
        Wait(100)
        tiempoEspera = tiempoEspera + 100
    end

    local tiempoEjecucion = GetGameTimer() - inicio

    if not terminado then
        -- Timeout
        terminado = true
        exito = false
        resultado = "Timeout"
        Estado.stats.timeouts = Estado.stats.timeouts + 1
        Log("Tarea %s: Timeout despues de %dms", tarea.id, tarea.timeout)
    end

    return exito, resultado, tiempoEjecucion
end

local function ProcesarResultadoTarea(tarea, exito, resultado, tiempoEjecucion)
    tarea.ultimaEjecucion = ObtenerTiempoActual()
    tarea.ejecuciones = tarea.ejecuciones + 1

    -- Remover de ejecucion
    Estado.tareasEnEjecucion[tarea.id] = nil

    if exito then
        tarea.estado = "completada"
        tarea.reintentoActual = 0
        Estado.stats.tareasCompletadas = Estado.stats.tareasCompletadas + 1
        Log("Tarea %s completada en %dms", tarea.nombre, tiempoEjecucion)

        -- Programar siguiente ejecucion si es recurrente
        if tarea.tipo == "recurrente" and tarea.intervalo then
            tarea.estado = "pendiente"
            tarea.proximaEjecucion = ObtenerTiempoActual() + (tarea.intervalo / 1000)
        elseif tarea.tipo == "cron" then
            tarea.estado = "pendiente"
        elseif tarea.tipo == "unica" or tarea.tipo == "delayed" then
            tarea.habilitada = false
        end
    else
        tarea.errores = tarea.errores + 1

        -- Verificar reintentos
        if tarea.reintentoActual < tarea.maxReintentos then
            tarea.reintentoActual = tarea.reintentoActual + 1
            Estado.stats.reintentos = Estado.stats.reintentos + 1

            -- Calcular delay para reintento (backoff exponencial)
            local delay = Config.reintentosBaseMs
            if Config.reintentosBackoff then
                delay = delay * (2 ^ (tarea.reintentoActual - 1))
            end

            tarea.estado = "pendiente"
            tarea.proximaEjecucion = ObtenerTiempoActual() + (delay / 1000)

            Log("Tarea %s fallida, reintento %d/%d en %dms: %s",
                tarea.nombre, tarea.reintentoActual, tarea.maxReintentos, delay, resultado)
        else
            tarea.estado = "fallida"
            Estado.stats.tareasFallidas = Estado.stats.tareasFallidas + 1
            LogError("Tarea %s fallida definitivamente: %s", tarea.nombre, resultado)

            if tarea.tipo == "recurrente" or tarea.tipo == "cron" then
                tarea.estado = "pendiente"
                tarea.reintentoActual = 0
                if tarea.intervalo then
                    tarea.proximaEjecucion = ObtenerTiempoActual() + (tarea.intervalo / 1000)
                end
            end
        end
    end

    AgregarAlHistorial(tarea, exito, resultado, tiempoEjecucion)
end

local function ContarTareasEnEjecucion()
    local count = 0
    for _ in pairs(Estado.tareasEnEjecucion) do
        count = count + 1
    end
    return count
end

local function ObtenerTareasPendientes()
    local pendientes = {}
    local ahora = ObtenerTiempoActual()
    local fechaActual = ObtenerFechaActual()

    for id, tarea in pairs(Estado.tareas) do
        if tarea.habilitada and tarea.estado == "pendiente" and not Estado.tareasEnEjecucion[id] then

            local debeProcesar = false

            if tarea.tipo == "cron" and tarea.cronParseado then
                debeProcesar = CoincideCron(tarea.cronParseado, fechaActual)
            elseif tarea.proximaEjecucion and tarea.proximaEjecucion <= ahora then
                debeProcesar = true
            end

            if debeProcesar then
                table.insert(pendientes, tarea)
            end
        end
    end

    -- Ordenar por prioridad
    table.sort(pendientes, function(a, b)
        if a.prioridad ~= b.prioridad then
            return a.prioridad < b.prioridad
        end
        return (a.proximaEjecucion or 0) < (b.proximaEjecucion or 0)
    end)

    return pendientes
end

-- ============================================================================
-- API PUBLICA
-- ============================================================================

--- Registra una nueva tarea
-- @param opciones table - Configuracion de la tarea
-- @return string - ID de la tarea
function AIT.Scheduler.Registrar(opciones)
    if not opciones.funcion then
        LogError("Se requiere una funcion para la tarea")
        return nil
    end

    local tarea = CrearTarea(opciones)
    Estado.tareas[tarea.id] = tarea
    Estado.stats.tareasCreadas = Estado.stats.tareasCreadas + 1

    Log("Tarea registrada: %s [%s] prioridad: %d", tarea.nombre, tarea.tipo, tarea.prioridad)

    return tarea.id
end

--- Programa una tarea para ejecutar una vez despues de un retraso
-- @param nombre string - Nombre de la tarea
-- @param funcion function - Funcion a ejecutar
-- @param retrasoMs number - Milisegundos de retraso
-- @param opciones table - Opciones adicionales
-- @return string - ID de la tarea
function AIT.Scheduler.Despues(nombre, funcion, retrasoMs, opciones)
    opciones = opciones or {}
    opciones.nombre = nombre
    opciones.funcion = funcion
    opciones.tipo = "delayed"
    opciones.retraso = retrasoMs

    return AIT.Scheduler.Registrar(opciones)
end

--- Programa una tarea recurrente
-- @param nombre string - Nombre de la tarea
-- @param funcion function - Funcion a ejecutar
-- @param intervaloMs number - Intervalo en milisegundos
-- @param opciones table - Opciones adicionales
-- @return string - ID de la tarea
function AIT.Scheduler.CadaMs(nombre, funcion, intervaloMs, opciones)
    opciones = opciones or {}
    opciones.nombre = nombre
    opciones.funcion = funcion
    opciones.tipo = "recurrente"
    opciones.intervalo = intervaloMs

    return AIT.Scheduler.Registrar(opciones)
end

--- Programa una tarea recurrente (en segundos)
-- @param nombre string - Nombre de la tarea
-- @param funcion function - Funcion a ejecutar
-- @param segundos number - Intervalo en segundos
-- @param opciones table - Opciones adicionales
-- @return string - ID de la tarea
function AIT.Scheduler.Cada(nombre, funcion, segundos, opciones)
    return AIT.Scheduler.CadaMs(nombre, funcion, segundos * 1000, opciones)
end

--- Programa una tarea con expresion cron
-- @param nombre string - Nombre de la tarea
-- @param funcion function - Funcion a ejecutar
-- @param expresionCron string - Expresion cron (minuto hora dia mes diaSemana)
-- @param opciones table - Opciones adicionales
-- @return string - ID de la tarea
function AIT.Scheduler.Cron(nombre, funcion, expresionCron, opciones)
    opciones = opciones or {}
    opciones.nombre = nombre
    opciones.funcion = funcion
    opciones.tipo = "cron"
    opciones.cron = expresionCron

    return AIT.Scheduler.Registrar(opciones)
end

--- Ejecuta una tarea inmediatamente (una sola vez)
-- @param nombre string - Nombre de la tarea
-- @param funcion function - Funcion a ejecutar
-- @param opciones table - Opciones adicionales
-- @return string - ID de la tarea
function AIT.Scheduler.Ahora(nombre, funcion, opciones)
    opciones = opciones or {}
    opciones.nombre = nombre
    opciones.funcion = funcion
    opciones.tipo = "unica"

    return AIT.Scheduler.Registrar(opciones)
end

--- Cancela una tarea
-- @param tareaId string - ID de la tarea
-- @return boolean - Exito
function AIT.Scheduler.Cancelar(tareaId)
    local tarea = Estado.tareas[tareaId]

    if not tarea then
        LogError("Tarea no encontrada: %s", tareaId)
        return false
    end

    tarea.estado = "cancelada"
    tarea.habilitada = false

    Log("Tarea cancelada: %s", tarea.nombre)
    return true
end

--- Pausa una tarea
-- @param tareaId string - ID de la tarea
-- @return boolean - Exito
function AIT.Scheduler.Pausar(tareaId)
    local tarea = Estado.tareas[tareaId]

    if not tarea then
        LogError("Tarea no encontrada: %s", tareaId)
        return false
    end

    tarea.habilitada = false
    Log("Tarea pausada: %s", tarea.nombre)
    return true
end

--- Reanuda una tarea pausada
-- @param tareaId string - ID de la tarea
-- @return boolean - Exito
function AIT.Scheduler.Reanudar(tareaId)
    local tarea = Estado.tareas[tareaId]

    if not tarea then
        LogError("Tarea no encontrada: %s", tareaId)
        return false
    end

    if tarea.estado == "cancelada" then
        LogError("No se puede reanudar tarea cancelada: %s", tareaId)
        return false
    end

    tarea.habilitada = true
    tarea.estado = "pendiente"
    Log("Tarea reanudada: %s", tarea.nombre)
    return true
end

--- Fuerza la ejecucion inmediata de una tarea
-- @param tareaId string - ID de la tarea
-- @return boolean - Exito
function AIT.Scheduler.ForzarEjecucion(tareaId)
    local tarea = Estado.tareas[tareaId]

    if not tarea then
        LogError("Tarea no encontrada: %s", tareaId)
        return false
    end

    tarea.proximaEjecucion = ObtenerTiempoActual()
    tarea.estado = "pendiente"

    Log("Forzando ejecucion de: %s", tarea.nombre)
    return true
end

--- Obtiene informacion de una tarea
-- @param tareaId string - ID de la tarea
-- @return table - Informacion de la tarea
function AIT.Scheduler.ObtenerTarea(tareaId)
    local tarea = Estado.tareas[tareaId]

    if not tarea then
        return nil
    end

    return {
        id = tarea.id,
        nombre = tarea.nombre,
        tipo = tarea.tipo,
        estado = tarea.estado,
        habilitada = tarea.habilitada,
        prioridad = tarea.prioridad,
        ejecuciones = tarea.ejecuciones,
        errores = tarea.errores,
        ultimaEjecucion = tarea.ultimaEjecucion,
        proximaEjecucion = tarea.proximaEjecucion,
        creadaEn = tarea.creadaEn
    }
end

--- Lista todas las tareas
-- @param filtro table - { estado, tipo, habilitada }
-- @return table - Lista de tareas
function AIT.Scheduler.ListarTareas(filtro)
    filtro = filtro or {}
    local lista = {}

    for id, tarea in pairs(Estado.tareas) do
        local incluir = true

        if filtro.estado and tarea.estado ~= filtro.estado then
            incluir = false
        end

        if filtro.tipo and tarea.tipo ~= filtro.tipo then
            incluir = false
        end

        if filtro.habilitada ~= nil and tarea.habilitada ~= filtro.habilitada then
            incluir = false
        end

        if incluir then
            table.insert(lista, AIT.Scheduler.ObtenerTarea(id))
        end
    end

    return lista
end

--- Obtiene el historial de ejecuciones
-- @param limite number - Numero maximo de entradas
-- @return table - Historial
function AIT.Scheduler.ObtenerHistorial(limite)
    limite = limite or Config.maxHistorial
    local historial = {}

    for i = 1, math.min(limite, #Estado.historial) do
        table.insert(historial, Estado.historial[i])
    end

    return historial
end

--- Obtiene estadisticas del scheduler
-- @return table - Estadisticas
function AIT.Scheduler.ObtenerEstadisticas()
    local tareasActivas = 0
    local tareasPendientes = 0

    for _, tarea in pairs(Estado.tareas) do
        if tarea.habilitada then
            tareasActivas = tareasActivas + 1
        end
        if tarea.estado == "pendiente" then
            tareasPendientes = tareasPendientes + 1
        end
    end

    return {
        tareasRegistradas = Estado.stats.tareasCreadas,
        tareasActivas = tareasActivas,
        tareasPendientes = tareasPendientes,
        tareasEnEjecucion = ContarTareasEnEjecucion(),
        tareasCompletadas = Estado.stats.tareasCompletadas,
        tareasFallidas = Estado.stats.tareasFallidas,
        reintentosTotales = Estado.stats.reintentos,
        timeouts = Estado.stats.timeouts,
        maxConcurrencia = Config.maxConcurrencia
    }
end

--- Pausa todo el scheduler
function AIT.Scheduler.PausarTodo()
    Estado.pausado = true
    Log("Scheduler pausado")
end

--- Reanuda el scheduler
function AIT.Scheduler.ReanudarTodo()
    Estado.pausado = false
    Log("Scheduler reanudado")
end

--- Limpia tareas completadas, fallidas o canceladas
-- @return number - Tareas eliminadas
function AIT.Scheduler.Limpiar()
    local eliminadas = 0

    for id, tarea in pairs(Estado.tareas) do
        if tarea.estado == "completada" or tarea.estado == "fallida" or tarea.estado == "cancelada" then
            if not Estado.tareasEnEjecucion[id] then
                Estado.tareas[id] = nil
                eliminadas = eliminadas + 1
            end
        end
    end

    Log("Limpieza: %d tareas eliminadas", eliminadas)
    return eliminadas
end

--- Configura el scheduler
-- @param nuevaConfig table - Nueva configuracion
function AIT.Scheduler.Configurar(nuevaConfig)
    for k, v in pairs(nuevaConfig) do
        if Config[k] ~= nil then
            Config[k] = v
        end
    end
    Log("Configuracion actualizada")
end

-- ============================================================================
-- LOOP PRINCIPAL
-- ============================================================================

local function LoopPrincipal()
    CreateThread(function()
        while true do
            Wait(Config.tickIntervalo)

            if Estado.pausado then
                goto continuar
            end

            local tareasEnEjecucion = ContarTareasEnEjecucion()

            if tareasEnEjecucion >= Config.maxConcurrencia then
                goto continuar
            end

            local pendientes = ObtenerTareasPendientes()
            local espaciosDisponibles = Config.maxConcurrencia - tareasEnEjecucion

            for i = 1, math.min(#pendientes, espaciosDisponibles) do
                local tarea = pendientes[i]

                -- Marcar como en ejecucion
                tarea.estado = "ejecutando"
                Estado.tareasEnEjecucion[tarea.id] = true

                -- Ejecutar en thread separado
                CreateThread(function()
                    Log("Ejecutando tarea: %s", tarea.nombre)
                    local exito, resultado, tiempo = EjecutarTarea(tarea)
                    ProcesarResultadoTarea(tarea, exito, resultado, tiempo)
                end)
            end

            ::continuar::
        end
    end)
end

-- ============================================================================
-- INICIALIZACION
-- ============================================================================

--- Inicia el scheduler
function AIT.Scheduler.Iniciar()
    if Estado.iniciado then
        Log("Scheduler ya iniciado")
        return
    end

    LoopPrincipal()
    Estado.iniciado = true

    Log("Scheduler iniciado (concurrencia max: %d)", Config.maxConcurrencia)
end

-- ============================================================================
-- HELPERS ADICIONALES
-- ============================================================================

-- Expresiones cron comunes
AIT.Scheduler.CRON = {
    CADA_MINUTO = "* * * * *",
    CADA_5_MINUTOS = "*/5 * * * *",
    CADA_10_MINUTOS = "*/10 * * * *",
    CADA_15_MINUTOS = "*/15 * * * *",
    CADA_30_MINUTOS = "*/30 * * * *",
    CADA_HORA = "0 * * * *",
    CADA_6_HORAS = "0 */6 * * *",
    CADA_12_HORAS = "0 */12 * * *",
    DIARIO_MEDIANOCHE = "0 0 * * *",
    DIARIO_MEDIODIA = "0 12 * * *",
    LUNES = "0 0 * * 1",
    SEMANAL = "0 0 * * 0", -- Domingo
    MENSUAL = "0 0 1 * *"
}

-- Constantes de prioridad
AIT.Scheduler.PRIORIDAD = Config.prioridades

-- ============================================================================
-- EXPORTACIONES
-- ============================================================================

exports('scheduler_registrar', AIT.Scheduler.Registrar)
exports('scheduler_despues', AIT.Scheduler.Despues)
exports('scheduler_cada', AIT.Scheduler.Cada)
exports('scheduler_cada_ms', AIT.Scheduler.CadaMs)
exports('scheduler_cron', AIT.Scheduler.Cron)
exports('scheduler_ahora', AIT.Scheduler.Ahora)
exports('scheduler_cancelar', AIT.Scheduler.Cancelar)
exports('scheduler_pausar', AIT.Scheduler.Pausar)
exports('scheduler_reanudar', AIT.Scheduler.Reanudar)
exports('scheduler_forzar', AIT.Scheduler.ForzarEjecucion)
exports('scheduler_tarea', AIT.Scheduler.ObtenerTarea)
exports('scheduler_listar', AIT.Scheduler.ListarTareas)
exports('scheduler_historial', AIT.Scheduler.ObtenerHistorial)
exports('scheduler_stats', AIT.Scheduler.ObtenerEstadisticas)
exports('scheduler_limpiar', AIT.Scheduler.Limpiar)

-- ============================================================================
-- AUTO-INICIO
-- ============================================================================

CreateThread(function()
    Wait(100)
    AIT.Scheduler.Iniciar()
end)

print("^2[AIT.Scheduler] Sistema de programacion de tareas cargado^0")
