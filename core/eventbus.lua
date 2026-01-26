-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb EVENT BUS
-- Sistema de eventos interno para comunicación entre módulos
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}

AIT.EventBus = {
    subscribers = {},
    pending = {},
    processing = false,
    eventCounter = 0,
    maxQueueSize = 1000,
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.EventBus.Initialize()
    AIT.EventBus.subscribers = {}
    AIT.EventBus.pending = {}
    AIT.EventBus.processing = false

    -- Procesar eventos en cola periódicamente
    CreateThread(function()
        while true do
            Wait(0)
            if #AIT.EventBus.pending > 0 and not AIT.EventBus.processing then
                AIT.EventBus.process()
            end
        end
    end)

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EMITIR EVENTO
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Emite un evento al bus
---@param topic string El topic del evento (ej: "economy.tx.created")
---@param payload table Los datos del evento
---@param options? table Opciones adicionales
function AIT.EventBus.emit(topic, payload, options)
    options = options or {}

    AIT.EventBus.eventCounter = AIT.EventBus.eventCounter + 1

    local event = {
        id = AIT.EventBus.eventCounter,
        topic = topic,
        ts = os.time() * 1000 + (GetGameTimer() % 1000),
        payload = payload or {},
        options = options,
    }

    -- Limitar tamaño de cola
    if #AIT.EventBus.pending >= AIT.EventBus.maxQueueSize then
        if AIT.Log then
            AIT.Log.warn('EVENTBUS', 'Queue full, dropping oldest event')
        end
        table.remove(AIT.EventBus.pending, 1)
    end

    table.insert(AIT.EventBus.pending, event)

    -- Procesar inmediatamente si no está procesando
    if not AIT.EventBus.processing then
        SetTimeout(0, function()
            AIT.EventBus.process()
        end)
    end

    return event.id
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SUSCRIBIRSE A EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Suscribe un handler a un patrón de topic
---@param pattern string Patrón (ej: "economy.*", "*.created", "*")
---@param handler function Función a ejecutar
---@param priority? number Prioridad (menor = primero)
---@return number subscriptionId
function AIT.EventBus.on(pattern, handler, priority)
    priority = priority or 100

    if not AIT.EventBus.subscribers[pattern] then
        AIT.EventBus.subscribers[pattern] = {}
    end

    local subId = #AIT.EventBus.subscribers[pattern] + 1

    table.insert(AIT.EventBus.subscribers[pattern], {
        id = subId,
        handler = handler,
        priority = priority,
        pattern = pattern,
    })

    -- Ordenar por prioridad
    table.sort(AIT.EventBus.subscribers[pattern], function(a, b)
        return a.priority < b.priority
    end)

    return subId
end

--- Alias de on
AIT.EventBus.subscribe = AIT.EventBus.on

--- Desuscribirse de un evento
---@param pattern string
---@param handler function
function AIT.EventBus.off(pattern, handler)
    if AIT.EventBus.subscribers[pattern] then
        for i = #AIT.EventBus.subscribers[pattern], 1, -1 do
            local sub = AIT.EventBus.subscribers[pattern][i]
            if sub.handler == handler then
                table.remove(AIT.EventBus.subscribers[pattern], i)
                break
            end
        end
    end
end

--- Alias de off
AIT.EventBus.unsubscribe = AIT.EventBus.off

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- PROCESAR EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.EventBus.process()
    if AIT.EventBus.processing then return end
    AIT.EventBus.processing = true

    local processedCount = 0
    local maxPerCycle = 100

    while #AIT.EventBus.pending > 0 and processedCount < maxPerCycle do
        local event = table.remove(AIT.EventBus.pending, 1)
        processedCount = processedCount + 1

        -- Encontrar todos los subscribers que coincidan
        for pattern, subs in pairs(AIT.EventBus.subscribers) do
            if AIT.EventBus.matchPattern(event.topic, pattern) then
                for _, sub in ipairs(subs) do
                    local success, err = pcall(sub.handler, event)
                    if not success then
                        if AIT.Log then
                            AIT.Log.error('EVENTBUS', 'Handler error', {
                                topic = event.topic,
                                pattern = pattern,
                                error = tostring(err)
                            })
                        end
                    end
                end
            end
        end
    end

    AIT.EventBus.processing = false
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- PATTERN MATCHING
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Comprueba si un topic coincide con un patrón
---@param topic string
---@param pattern string
---@return boolean
function AIT.EventBus.matchPattern(topic, pattern)
    -- Coincidencia exacta
    if pattern == topic then return true end

    -- Wildcard completo
    if pattern == '*' then return true end

    -- Wildcard al final (ej: "economy.*")
    if pattern:sub(-2) == '.*' then
        local prefix = pattern:sub(1, -3)
        return topic:sub(1, #prefix) == prefix
    end

    -- Wildcard al principio (ej: "*.created")
    if pattern:sub(1, 2) == '*.' then
        local suffix = pattern:sub(3)
        return topic:sub(-#suffix) == suffix
    end

    -- Wildcard en medio (ej: "economy.*.created")
    if pattern:find('%*') then
        local regexPattern = pattern:gsub('%.', '%%.'):gsub('%*', '.*')
        return topic:match('^' .. regexPattern .. '$') ~= nil
    end

    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Espera a que se emita un evento específico
---@param topic string
---@param timeout? number Timeout en ms
---@return table|nil event
function AIT.EventBus.waitFor(topic, timeout)
    timeout = timeout or 10000
    local result = nil
    local received = false

    local handler = function(event)
        result = event
        received = true
    end

    AIT.EventBus.on(topic, handler, 1)

    local startTime = GetGameTimer()
    while not received and (GetGameTimer() - startTime) < timeout do
        Wait(10)
    end

    AIT.EventBus.off(topic, handler)

    return result
end

--- Obtiene estadísticas del bus
---@return table
function AIT.EventBus.getStats()
    local subscriberCount = 0
    for _, subs in pairs(AIT.EventBus.subscribers) do
        subscriberCount = subscriberCount + #subs
    end

    return {
        pending = #AIT.EventBus.pending,
        subscribers = subscriberCount,
        patterns = AIT.Utils.TableSize(AIT.EventBus.subscribers),
        totalEvents = AIT.EventBus.eventCounter,
        processing = AIT.EventBus.processing,
    }
end

-- Helper
if not AIT.Utils then AIT.Utils = {} end
function AIT.Utils.TableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- RETURN
-- ═══════════════════════════════════════════════════════════════════════════════════════

return AIT.EventBus
