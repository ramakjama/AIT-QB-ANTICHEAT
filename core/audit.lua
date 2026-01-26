-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb AUDIT SYSTEM
-- Sistema de auditoría completo con trazabilidad total
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}

AIT.Audit = {
    queue = {},
    processing = false,
    batchSize = 50,
    flushInterval = 5000, -- 5 segundos
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT.Audit.Severities = {
    info = 1,
    warn = 2,
    high = 3,
    critical = 4
}

AIT.Audit.RetentionDays = {
    info = 30,
    warn = 90,
    high = 180,
    critical = 365
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.Audit.Initialize()
    -- Crear tabla de audit log
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_audit_log (
            audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            severity ENUM('info', 'warn', 'high', 'critical') NOT NULL DEFAULT 'info',

            actor_type ENUM('player', 'char', 'system', 'admin', 'api') NOT NULL,
            actor_id BIGINT NULL,

            target_type VARCHAR(32) NULL,
            target_id BIGINT NULL,

            action VARCHAR(128) NOT NULL,
            reason VARCHAR(512) NULL,
            payload JSON NULL,
            before_state JSON NULL,
            after_state JSON NULL,

            ip VARCHAR(64) NULL,
            license VARCHAR(64) NULL,
            sig CHAR(64) NULL,
            tags JSON NULL,

            KEY idx_ts (ts),
            KEY idx_severity (severity),
            KEY idx_actor (actor_type, actor_id),
            KEY idx_target (target_type, target_id),
            KEY idx_action (action),
            KEY idx_sig (sig)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Crear tabla de system log
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_system_log (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            level ENUM('DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL') NOT NULL,
            category VARCHAR(64) NOT NULL,
            message TEXT NOT NULL,
            data JSON NULL,

            KEY idx_ts (ts),
            KEY idx_level (level),
            KEY idx_category (category)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Registrar job de limpieza
    if AIT.Scheduler then
        AIT.Scheduler.register('audit_cleanup', {
            interval = 86400, -- Diario
            fn = AIT.Audit.Cleanup
        })

        AIT.Scheduler.register('audit_flush', {
            interval = 5, -- Cada 5 segundos
            fn = AIT.Audit.Flush
        })
    end

    -- Suscribirse a eventos importantes
    if AIT.EventBus then
        AIT.EventBus.on('economy.*', AIT.Audit.OnEconomyEvent, 1000)
        AIT.EventBus.on('inventory.*', AIT.Audit.OnInventoryEvent, 1000)
        AIT.EventBus.on('faction.*', AIT.Audit.OnFactionEvent, 1000)
        AIT.EventBus.on('security.*', AIT.Audit.OnSecurityEvent, 1000)
    end

    -- Thread de flush
    CreateThread(function()
        while true do
            Wait(AIT.Audit.flushInterval)
            AIT.Audit.Flush()
        end
    end)

    if AIT.Log then
        AIT.Log.info('AUDIT', 'Audit system initialized')
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- LOG DE AUDITORÍA
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Registra una entrada de auditoría
---@param source any Origen (source ID, 'system', etc.)
---@param action string Acción realizada
---@param target? any Objetivo de la acción
---@param payload? table Datos adicionales
---@param severity? string Severidad ('info', 'warn', 'high', 'critical')
---@param tags? table Tags adicionales
---@return string sig Signature del log
function AIT.Audit.Log(source, action, target, payload, severity, tags)
    severity = severity or 'info'

    -- Determinar actor
    local actorType = 'system'
    local actorId = 0
    local actorIp = nil
    local actorLicense = nil

    if type(source) == 'number' and source > 0 then
        actorType = 'player'
        actorId = AIT.RBAC and AIT.RBAC.GetPlayerId(source) or 0
        actorIp = GetPlayerEndpoint(source)
        actorLicense = GetPlayerIdentifierByType(source, 'license')
    elseif type(source) == 'string' then
        actorType = source
    elseif type(source) == 'table' then
        actorType = source.type or 'system'
        actorId = source.id or 0
    end

    -- Determinar target
    local targetType = nil
    local targetId = nil

    if type(target) == 'table' then
        targetType = target.type
        targetId = target.id
    elseif type(target) == 'number' then
        targetType = 'player'
        targetId = target
    elseif type(target) == 'string' then
        targetType = target
    end

    -- Extraer before/after si están en payload
    local beforeState = nil
    local afterState = nil

    if payload then
        if payload._before then
            beforeState = payload._before
            payload._before = nil
        end
        if payload._after then
            afterState = payload._after
            payload._after = nil
        end
    end

    -- Crear signature
    local sigData = string.format('%s:%s:%s:%d:%d',
        action,
        actorType,
        tostring(actorId),
        os.time(),
        math.random(1000000)
    )
    local sig = tostring(GetHashKey(sigData))

    -- Crear entrada
    local entry = {
        ts = os.date('%Y-%m-%d %H:%M:%S'),
        severity = severity,
        actorType = actorType,
        actorId = actorId,
        targetType = targetType,
        targetId = targetId,
        action = action,
        reason = payload and payload.reason,
        payload = payload and json.encode(payload),
        beforeState = beforeState and json.encode(beforeState),
        afterState = afterState and json.encode(afterState),
        ip = actorIp,
        license = actorLicense,
        sig = sig,
        tags = tags and json.encode(tags),
    }

    -- Añadir a cola
    table.insert(AIT.Audit.queue, entry)

    -- Flush inmediato para críticos
    if severity == 'critical' then
        AIT.Audit.Flush()
        AIT.Audit.SendToDiscord(action, actorType, actorId, targetType, targetId, payload)
    end

    return sig
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- LOG DE SISTEMA
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.Audit.LogSystem(level, category, message, data)
    MySQL.insert([[
        INSERT INTO ait_system_log (level, category, message, data)
        VALUES (?, ?, ?, ?)
    ]], {
        level,
        category,
        message,
        data and json.encode(data)
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FLUSH DE COLA
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.Audit.Flush()
    if AIT.Audit.processing or #AIT.Audit.queue == 0 then return end
    AIT.Audit.processing = true

    local batch = {}
    for i = 1, math.min(AIT.Audit.batchSize, #AIT.Audit.queue) do
        table.insert(batch, table.remove(AIT.Audit.queue, 1))
    end

    if #batch > 0 then
        -- Insertar en batch
        local values = {}
        local params = {}

        for _, entry in ipairs(batch) do
            table.insert(values, '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
            table.insert(params, entry.ts)
            table.insert(params, entry.severity)
            table.insert(params, entry.actorType)
            table.insert(params, entry.actorId)
            table.insert(params, entry.targetType)
            table.insert(params, entry.targetId)
            table.insert(params, entry.action)
            table.insert(params, entry.reason)
            table.insert(params, entry.payload)
            table.insert(params, entry.beforeState)
            table.insert(params, entry.afterState)
            table.insert(params, entry.ip)
            table.insert(params, entry.license)
            table.insert(params, entry.sig)
            table.insert(params, entry.tags)
        end

        local query = [[
            INSERT INTO ait_audit_log
            (ts, severity, actor_type, actor_id, target_type, target_id,
             action, reason, payload, before_state, after_state, ip, license, sig, tags)
            VALUES
        ]] .. table.concat(values, ', ')

        MySQL.insert(query, params)
    end

    AIT.Audit.processing = false
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Consulta logs de auditoría
---@param source number Quien consulta
---@param filters table Filtros
---@return table|nil, string?
function AIT.Audit.Query(source, filters)
    -- Verificar permiso
    if AIT.RBAC and not AIT.RBAC.HasPermission(source, 'audit.query') then
        return nil, 'Permission denied'
    end

    local query = 'SELECT * FROM ait_audit_log WHERE 1=1'
    local params = {}

    if filters.action then
        query = query .. ' AND action LIKE ?'
        table.insert(params, '%' .. filters.action .. '%')
    end

    if filters.actor_id then
        query = query .. ' AND actor_id = ?'
        table.insert(params, filters.actor_id)
    end

    if filters.target_id then
        query = query .. ' AND target_id = ?'
        table.insert(params, filters.target_id)
    end

    if filters.severity then
        query = query .. ' AND severity = ?'
        table.insert(params, filters.severity)
    end

    if filters.from_date then
        query = query .. ' AND ts >= ?'
        table.insert(params, filters.from_date)
    end

    if filters.to_date then
        query = query .. ' AND ts <= ?'
        table.insert(params, filters.to_date)
    end

    query = query .. ' ORDER BY ts DESC LIMIT ?'
    table.insert(params, filters.limit or 100)

    -- Log de esta consulta
    AIT.Audit.Log(source, 'AUDIT:Query', nil, { filters = filters })

    return MySQL.query.await(query, params)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- LIMPIEZA
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.Audit.Cleanup()
    local now = os.time()

    for severity, days in pairs(AIT.Audit.RetentionDays) do
        local cutoff = os.date('%Y-%m-%d', now - (days * 86400))

        local result = MySQL.query.await([[
            DELETE FROM ait_audit_log
            WHERE severity = ? AND ts < ?
            LIMIT 10000
        ]], { severity, cutoff })

        if result and result.affectedRows and result.affectedRows > 0 then
            if AIT.Log then
                AIT.Log.info('AUDIT', 'Cleaned up ' .. result.affectedRows .. ' ' .. severity .. ' logs')
            end
        end
    end

    -- Limpiar system logs (30 días para todos)
    MySQL.query.await([[
        DELETE FROM ait_system_log
        WHERE ts < DATE_SUB(NOW(), INTERVAL 30 DAY)
        LIMIT 10000
    ]])
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- DISCORD WEBHOOK
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.Audit.SendToDiscord(action, actorType, actorId, targetType, targetId, payload)
    local config = AIT.Config and AIT.Config.main and AIT.Config.main.discord
    if not config or not config.webhooks or not config.webhooks.audit then
        return
    end

    local embed = {
        title = '🔒 Audit Alert: ' .. action,
        color = 16711680, -- Rojo
        fields = {
            { name = 'Actor', value = actorType .. ':' .. tostring(actorId), inline = true },
            { name = 'Target', value = (targetType or 'none') .. ':' .. tostring(targetId or 'none'), inline = true },
            { name = 'Severity', value = 'CRITICAL', inline = true },
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    if payload then
        local payloadStr = json.encode(payload)
        if #payloadStr > 1000 then
            payloadStr = payloadStr:sub(1, 1000) .. '...'
        end
        table.insert(embed.fields, {
            name = 'Details',
            value = '```json\n' .. payloadStr .. '\n```',
            inline = false
        })
    end

    PerformHttpRequest(config.webhooks.audit, function() end, 'POST',
        json.encode({ embeds = { embed } }),
        { ['Content-Type'] = 'application/json' }
    )
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.Audit.OnEconomyEvent(event)
    AIT.Audit.Log(
        event.payload and event.payload.actor or 'system',
        'EVENT:' .. event.topic,
        event.payload and event.payload.target,
        event.payload,
        'info',
        { source = 'eventbus' }
    )
end

function AIT.Audit.OnInventoryEvent(event)
    local severity = 'info'
    if event.topic:match('dupe') then
        severity = 'critical'
    end

    AIT.Audit.Log(
        event.payload and event.payload.actor or 'system',
        'EVENT:' .. event.topic,
        event.payload and event.payload.target,
        event.payload,
        severity,
        { source = 'eventbus' }
    )
end

function AIT.Audit.OnFactionEvent(event)
    AIT.Audit.Log(
        event.payload and event.payload.actor or 'system',
        'EVENT:' .. event.topic,
        event.payload and event.payload.target,
        event.payload,
        'info',
        { source = 'eventbus' }
    )
end

function AIT.Audit.OnSecurityEvent(event)
    AIT.Audit.Log(
        event.payload and event.payload.actor or 'system',
        'EVENT:' .. event.topic,
        event.payload and event.payload.target,
        event.payload,
        'high',
        { source = 'eventbus' }
    )
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- RETURN
-- ═══════════════════════════════════════════════════════════════════════════════════════

return AIT.Audit
