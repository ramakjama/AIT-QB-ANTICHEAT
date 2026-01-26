-- ═══════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - PANEL SERVER HANDLERS
-- Handlers del servidor para el panel NUI de administración
-- ═══════════════════════════════════════════════════════════════════════════════

local QBCore = exports['qb-core']:GetCoreObject()
local Config = Config or {}

-- Módulos activos (estado en memoria)
local ActiveModules = {
    teleport = true,
    speed = true,
    godmode = true,
    weapons = true,
    money = true,
    vehicles = true
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERMISOS
-- ═══════════════════════════════════════════════════════════════════════════════

local function HasPanelAccess(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local permission = Player.PlayerData.permission
    if permission == 'god' or permission == 'admin' then
        return true
    end

    -- Verificar whitelist de anticheat
    local identifier = QBCore.Functions.GetIdentifier(source, 'license')
    if Config.Anticheat and Config.Anticheat.Whitelist and Config.Anticheat.Whitelist.Players then
        for _, id in ipairs(Config.Anticheat.Whitelist.Players) do
            if id == identifier then
                return true
            end
        end
    end

    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE DATOS
-- ═══════════════════════════════════════════════════════════════════════════════

local function GetPlayersData()
    local players = {}
    local qbPlayers = QBCore.Functions.GetPlayers()

    for _, playerId in ipairs(qbPlayers) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            local suspicion = 0

            -- Obtener suspicion de Anticheat si está disponible
            if Anticheat and Anticheat.PlayerProfiles then
                local profile = Anticheat.PlayerProfiles[playerId]
                if profile then
                    suspicion = profile.suspicionScore or 0
                end
            end

            table.insert(players, {
                id = playerId,
                name = Player.PlayerData.name or GetPlayerName(playerId) or 'Desconocido',
                identifier = QBCore.Functions.GetIdentifier(playerId, 'license') or 'N/A',
                suspicion = suspicion,
                ping = GetPlayerPing(playerId)
            })
        end
    end

    return players
end

local function GetLogsData()
    local logs = {}

    -- Intentar obtener logs de la base de datos
    if MySQL and MySQL.Sync then
        local result = MySQL.Sync.fetchAll('SELECT * FROM ait_anticheat_logs ORDER BY timestamp DESC LIMIT 100')
        if result then
            for _, log in ipairs(result) do
                table.insert(logs, {
                    time = log.timestamp,
                    type = log.detection_type,
                    player = log.player_name,
                    details = log.details,
                    severity = log.severity or 'medium'
                })
            end
        end
    end

    return logs
end

local function GetStatsData()
    local stats = {
        players = #QBCore.Functions.GetPlayers(),
        bans = 0,
        detections = 0,
        kicks = 0
    }

    -- Obtener estadísticas de la base de datos
    if MySQL and MySQL.Sync then
        -- Bans activos
        local bansResult = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ait_anticheat_bans WHERE active = 1')
        stats.bans = bansResult or 0

        -- Detecciones últimas 24h
        local detectionsResult = MySQL.Sync.fetchScalar([[
            SELECT COUNT(*) FROM ait_anticheat_logs
            WHERE timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ]])
        stats.detections = detectionsResult or 0

        -- Kicks últimas 24h
        local kicksResult = MySQL.Sync.fetchScalar([[
            SELECT COUNT(*) FROM ait_anticheat_logs
            WHERE action = 'kick' AND timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ]])
        stats.kicks = kicksResult or 0
    end

    return stats
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

-- Solicitud para abrir el panel
RegisterNetEvent('ait-qb:anticheat:requestOpenPanel', function()
    local source = source

    if not HasPanelAccess(source) then
        TriggerClientEvent('QBCore:Notify', source, 'No tienes permiso para usar el panel anticheat', 'error')
        return
    end

    local data = {
        players = GetPlayersData(),
        logs = GetLogsData(),
        stats = GetStatsData(),
        modules = ActiveModules
    }

    TriggerClientEvent('ait-qb:anticheat:openPanel', source, data)
end)

-- Solicitud de datos del panel
RegisterNetEvent('ait-qb:anticheat:requestPanelData', function()
    local source = source

    if not HasPanelAccess(source) then return end

    TriggerClientEvent('ait-qb:anticheat:updatePlayers', source, GetPlayersData())
    TriggerClientEvent('ait-qb:anticheat:updateStats', source, GetStatsData())
    TriggerClientEvent('ait-qb:anticheat:updateModules', source, ActiveModules)
end)

-- Solicitud de logs
RegisterNetEvent('ait-qb:anticheat:requestLogs', function()
    local source = source

    if not HasPanelAccess(source) then return end

    TriggerClientEvent('ait-qb:anticheat:updateLogs', source, GetLogsData())
end)

-- Toggle de módulo
RegisterNetEvent('ait-qb:anticheat:toggleModule', function(moduleName, enabled)
    local source = source

    if not HasPanelAccess(source) then return end

    if ActiveModules[moduleName] ~= nil then
        ActiveModules[moduleName] = enabled

        -- Notificar al admin
        local adminName = GetPlayerName(source) or 'Admin'
        local state = enabled and 'activado' or 'desactivado'
        print(('[AIT-QB Anticheat] %s ha %s el módulo: %s'):format(adminName, state, moduleName))

        -- Log en Discord si está disponible
        if Anticheat and Anticheat.SendDiscordAlert then
            Anticheat.SendDiscordAlert('module_toggle', {
                admin = adminName,
                module = moduleName,
                enabled = enabled
            })
        end
    end
end)

-- Ejecutar acción desde el panel
RegisterNetEvent('ait-qb:anticheat:executeAction', function(action, data)
    local source = source

    if not HasPanelAccess(source) then return end

    local adminName = GetPlayerName(source) or 'Admin'

    if action == 'ban' then
        local targetId = data.playerId
        local reason = data.reason or 'Sin razón especificada'
        local duration = data.duration or 0

        if Anticheat and Anticheat.BanPlayer then
            Anticheat.BanPlayer(targetId, reason, 'admin_panel', duration)
        else
            -- Fallback: usar comando de QBCore
            TriggerEvent('qb-admin:server:ban', source, targetId, duration, reason)
        end

        TriggerClientEvent('QBCore:Notify', source, 'Jugador baneado correctamente', 'success')

    elseif action == 'kick' then
        local targetId = data.playerId
        local reason = data.reason or 'Expulsado por administrador'

        if Anticheat and Anticheat.KickPlayer then
            Anticheat.KickPlayer(targetId, reason)
        else
            DropPlayer(targetId, reason)
        end

        TriggerClientEvent('QBCore:Notify', source, 'Jugador expulsado', 'success')

    elseif action == 'freeze' then
        local targetId = data.playerId
        TriggerClientEvent('ait-qb:anticheat:freeze', targetId)
        TriggerClientEvent('QBCore:Notify', source, 'Jugador congelado', 'success')

    elseif action == 'screenshot' then
        local targetId = data.playerId
        -- Usar screenshot-basic si está disponible
        if GetResourceState('screenshot-basic') == 'started' then
            exports['screenshot-basic']:requestClientScreenshot(targetId, {
                fileName = ('screenshot_%s_%s.jpg'):format(targetId, os.time())
            }, function(err, data)
                if not err then
                    TriggerClientEvent('QBCore:Notify', source, 'Screenshot capturada', 'success')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Error al capturar screenshot', 'error')
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', source, 'screenshot-basic no está instalado', 'error')
        end

    elseif action == 'spectate' then
        local targetId = data.playerId
        TriggerClientEvent('ait-qb:anticheat:spectate', source, targetId)

    elseif action == 'whitelist' then
        local identifier = data.identifier
        local wlAction = data.whitelistAction

        if wlAction == 'add' then
            if MySQL and MySQL.Async then
                MySQL.Async.execute('INSERT IGNORE INTO ait_anticheat_whitelist (identifier, added_by) VALUES (?, ?)',
                    { identifier, adminName })
            end
            TriggerClientEvent('QBCore:Notify', source, 'Añadido a whitelist', 'success')
        elseif wlAction == 'remove' then
            if MySQL and MySQL.Async then
                MySQL.Async.execute('DELETE FROM ait_anticheat_whitelist WHERE identifier = ?', { identifier })
            end
            TriggerClientEvent('QBCore:Notify', source, 'Eliminado de whitelist', 'success')
        end

    elseif action == 'unban' then
        local identifier = data.identifier

        if MySQL and MySQL.Async then
            MySQL.Async.execute('UPDATE ait_anticheat_bans SET active = 0 WHERE identifier = ? OR ban_id = ?',
                { identifier, identifier })
        end

        TriggerClientEvent('QBCore:Notify', source, 'Ban eliminado', 'success')

    elseif action == 'suspect' then
        local targetId = data.playerId
        local reason = data.reason or 'Marcado como sospechoso'

        if Anticheat and Anticheat.PlayerProfiles then
            local profile = Anticheat.PlayerProfiles[targetId]
            if profile then
                profile.suspicionScore = (profile.suspicionScore or 0) + 25
            end
        end

        -- Log en base de datos
        if MySQL and MySQL.Async then
            local targetName = GetPlayerName(targetId) or 'Desconocido'
            local targetIdentifier = QBCore.Functions.GetIdentifier(targetId, 'license') or 'unknown'

            MySQL.Async.execute([[
                INSERT INTO ait_anticheat_strikes (identifier, player_name, reason, admin_name)
                VALUES (?, ?, ?, ?)
            ]], { targetIdentifier, targetName, reason, adminName })
        end

        TriggerClientEvent('QBCore:Notify', source, 'Jugador marcado como sospechoso', 'success')

    elseif action == 'check' then
        local targetId = data.playerId

        -- Solicitar check de integridad
        TriggerClientEvent('ait-qb:anticheat:integrityCheck', targetId)
        TriggerClientEvent('QBCore:Notify', source, 'Check de integridad solicitado', 'primary')
    end

    -- Log de la acción
    print(('[AIT-QB Anticheat] Admin %s ejecutó acción: %s'):format(adminName, action))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTO-ACTUALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Enviar actualizaciones periódicas a admins con panel abierto
CreateThread(function()
    while true do
        Wait(10000) -- Cada 10 segundos

        local players = QBCore.Functions.GetPlayers()
        for _, playerId in ipairs(players) do
            if HasPanelAccess(playerId) then
                -- El cliente decide si el panel está abierto
                TriggerClientEvent('ait-qb:anticheat:updatePlayers', playerId, GetPlayersData())
                TriggerClientEvent('ait-qb:anticheat:updateStats', playerId, GetStatsData())
            end
        end
    end
end)

-- Export para acceso externo
exports('GetActiveModules', function()
    return ActiveModules
end)

exports('IsModuleActive', function(moduleName)
    return ActiveModules[moduleName] == true
end)

print('[AIT-QB Anticheat] Panel handlers loaded')
