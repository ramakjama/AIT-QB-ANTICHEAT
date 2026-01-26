-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - COMANDOS DE ADMINISTRACIÓN
-- Sistema de gestión completo del anticheat
-- ═══════════════════════════════════════════════════════════════════════════════════════

local ACCommands = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- REGISTRO DE COMANDOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ACCommands.Register()
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /ac - Menú principal del anticheat
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('ac', function(source, args, rawCommand)
        if source == 0 then
            ACCommands.ShowConsoleHelp()
            return
        end

        if not ACCommands.IsAdmin(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                args = {"[AC]", "No tienes permiso para usar este comando."}
            })
            return
        end

        local subCommand = args[1] and string.lower(args[1]) or "help"
        table.remove(args, 1)

        if ACCommands.SubCommands[subCommand] then
            ACCommands.SubCommands[subCommand](source, args)
        else
            ACCommands.SubCommands.help(source, args)
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acban - Ban rápido
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acban', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2) or "Uso de cheats"

        if not targetId then
            ACCommands.Message(source, "Uso: /acban [id] [razón]", "error")
            return
        end

        if _G.Anticheat then
            _G.Anticheat.BanPlayer(targetId, reason, "manual_admin", nil)
            ACCommands.Message(source, string.format("Jugador %d baneado: %s", targetId, reason), "success")
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /ackick - Kick rápido
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('ackick', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2) or "Comportamiento sospechoso"

        if not targetId then
            ACCommands.Message(source, "Uso: /ackick [id] [razón]", "error")
            return
        end

        if _G.Anticheat then
            _G.Anticheat.KickPlayer(targetId, reason)
            ACCommands.Message(source, string.format("Jugador %d expulsado: %s", targetId, reason), "success")
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acunban - Desbanear
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acunban', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local identifier = args[1]
        if not identifier then
            ACCommands.Message(source, "Uso: /acunban [identifier o ban_id]", "error")
            return
        end

        ACCommands.UnbanPlayer(source, identifier)
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acwhitelist - Gestionar whitelist
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acwhitelist', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local action = args[1]
        local target = args[2]

        if action == "add" and target then
            ACCommands.AddToWhitelist(source, target)
        elseif action == "remove" and target then
            ACCommands.RemoveFromWhitelist(source, target)
        elseif action == "list" then
            ACCommands.ListWhitelist(source)
        else
            ACCommands.Message(source, "Uso: /acwhitelist [add|remove|list] [identifier]", "error")
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acstatus - Estado del anticheat
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acstatus', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end
        ACCommands.ShowStatus(source)
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acmonitor - Monitorear jugador específico
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acmonitor', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local targetId = tonumber(args[1])
        if targetId then
            ACCommands.MonitorPlayer(source, targetId)
        else
            ACCommands.Message(source, "Uso: /acmonitor [id]", "error")
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /aclogs - Ver logs recientes
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('aclogs', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local count = tonumber(args[1]) or 10
        ACCommands.ShowRecentLogs(source, count)
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acscreenshot - Tomar screenshot de jugador
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acscreenshot', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local targetId = tonumber(args[1])
        if targetId then
            ACCommands.TakeScreenshot(source, targetId)
        else
            ACCommands.Message(source, "Uso: /acscreenshot [id]", "error")
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /actoggle - Activar/desactivar módulos
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('actoggle', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local module = args[1]
        if module then
            ACCommands.ToggleModule(source, module)
        else
            ACCommands.Message(source, "Módulos: teleport, speed, godmode, weapons, money, vehicles, explosions", "info")
            ACCommands.Message(source, "Uso: /actoggle [módulo]", "error")
        end
    end, false)

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- /acsuspect - Marcar jugador como sospechoso
    -- ═══════════════════════════════════════════════════════════════════════════════
    RegisterCommand('acsuspect', function(source, args, rawCommand)
        if source ~= 0 and not ACCommands.IsAdmin(source) then return end

        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2) or "Marcado por admin"

        if targetId then
            ACCommands.MarkSuspect(source, targetId, reason)
        else
            ACCommands.Message(source, "Uso: /acsuspect [id] [razón]", "error")
        end
    end, false)

    print("^2[AIT-QB ANTICHEAT]^0 Comandos de administración registrados")
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SUBCOMANDOS DE /ac
-- ═══════════════════════════════════════════════════════════════════════════════════════

ACCommands.SubCommands = {
    help = function(source, args)
        local messages = {
            "═══════════════════════════════════════",
            "^2AIT-QB ANTICHEAT - COMANDOS^0",
            "═══════════════════════════════════════",
            "^3/ac status^0 - Estado del sistema",
            "^3/ac stats^0 - Estadísticas",
            "^3/ac bans^0 - Lista de baneos",
            "^3/ac logs [n]^0 - Ver últimos N logs",
            "^3/ac check [id]^0 - Verificar jugador",
            "^3/ac freeze [id]^0 - Congelar jugador",
            "^3/ac unfreeze [id]^0 - Descongelar jugador",
            "═══════════════════════════════════════",
            "^3/acban [id] [razón]^0 - Banear jugador",
            "^3/ackick [id] [razón]^0 - Expulsar jugador",
            "^3/acunban [identifier]^0 - Desbanear",
            "^3/acwhitelist [add|remove|list]^0 - Whitelist",
            "^3/acmonitor [id]^0 - Monitorear jugador",
            "^3/acscreenshot [id]^0 - Tomar screenshot",
            "^3/actoggle [módulo]^0 - Activar/desactivar",
            "^3/acsuspect [id] [razón]^0 - Marcar sospechoso",
            "═══════════════════════════════════════",
        }

        for _, msg in ipairs(messages) do
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
            end
        end
    end,

    status = function(source, args)
        ACCommands.ShowStatus(source)
    end,

    stats = function(source, args)
        ACCommands.ShowStats(source)
    end,

    bans = function(source, args)
        ACCommands.ShowBans(source)
    end,

    logs = function(source, args)
        local count = tonumber(args[1]) or 10
        ACCommands.ShowRecentLogs(source, count)
    end,

    check = function(source, args)
        local targetId = tonumber(args[1])
        if targetId then
            ACCommands.CheckPlayer(source, targetId)
        else
            ACCommands.Message(source, "Uso: /ac check [id]", "error")
        end
    end,

    freeze = function(source, args)
        local targetId = tonumber(args[1])
        if targetId then
            ACCommands.FreezePlayer(source, targetId, true)
        else
            ACCommands.Message(source, "Uso: /ac freeze [id]", "error")
        end
    end,

    unfreeze = function(source, args)
        local targetId = tonumber(args[1])
        if targetId then
            ACCommands.FreezePlayer(source, targetId, false)
        else
            ACCommands.Message(source, "Uso: /ac unfreeze [id]", "error")
        end
    end,
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE COMANDOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ACCommands.IsAdmin(source)
    if not _G.Anticheat then return false end
    return _G.Anticheat.IsWhitelisted(source)
end

function ACCommands.Message(source, msg, msgType)
    local colors = {
        success = {0, 255, 0},
        error = {255, 0, 0},
        warning = {255, 165, 0},
        info = {0, 191, 255}
    }

    local color = colors[msgType] or colors.info

    if source == 0 then
        print(string.format("[AC] %s", msg))
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = color,
            args = {"[AC]", msg}
        })
    end
end

function ACCommands.ShowStatus(source)
    local status = Config.Anticheat.Enabled and "^2ACTIVO^0" or "^1DESACTIVADO^0"
    local bansCount = 0
    local playersMonitored = 0

    if _G.Anticheat then
        for _ in pairs(_G.Anticheat.BannedPlayers) do
            bansCount = bansCount + 1
        end
        for _ in pairs(_G.Anticheat.PlayerData) do
            playersMonitored = playersMonitored + 1
        end
    end

    local messages = {
        "═══════════════════════════════════════",
        "^2AIT-QB ANTICHEAT - STATUS^0",
        "═══════════════════════════════════════",
        string.format("Estado: %s", status),
        string.format("Jugadores monitoreados: ^3%d^0", playersMonitored),
        string.format("Baneos activos: ^1%d^0", bansCount),
        "═══════════════════════════════════════",
        "^3MÓDULOS:^0",
        string.format("  Teleport: %s", Config.Anticheat.Detection.Teleport.Enabled and "^2ON^0" or "^1OFF^0"),
        string.format("  Speed: %s", Config.Anticheat.Detection.Speed.Enabled and "^2ON^0" or "^1OFF^0"),
        string.format("  Godmode: %s", Config.Anticheat.Detection.Godmode.Enabled and "^2ON^0" or "^1OFF^0"),
        string.format("  Weapons: %s", Config.Anticheat.Detection.Weapons.Enabled and "^2ON^0" or "^1OFF^0"),
        string.format("  Money: %s", Config.Anticheat.Detection.Money.Enabled and "^2ON^0" or "^1OFF^0"),
        string.format("  Vehicles: %s", Config.Anticheat.Detection.Vehicles.Enabled and "^2ON^0" or "^1OFF^0"),
        string.format("  Explosions: %s", Config.Anticheat.Detection.Explosions.Enabled and "^2ON^0" or "^1OFF^0"),
        "═══════════════════════════════════════",
    }

    for _, msg in ipairs(messages) do
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
        end
    end
end

function ACCommands.ShowStats(source)
    if not MySQL or not MySQL.Async then
        ACCommands.Message(source, "MySQL no disponible", "error")
        return
    end

    MySQL.Async.fetchAll([[
        SELECT
            detection_type,
            COUNT(*) as count
        FROM ait_anticheat_logs
        WHERE timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
        GROUP BY detection_type
        ORDER BY count DESC
    ]], {}, function(results)
        local messages = {
            "═══════════════════════════════════════",
            "^2ESTADÍSTICAS (últimas 24h)^0",
            "═══════════════════════════════════════",
        }

        if results and #results > 0 then
            for _, row in ipairs(results) do
                table.insert(messages, string.format("  %s: ^3%d^0 detecciones", row.detection_type, row.count))
            end
        else
            table.insert(messages, "  No hay detecciones recientes")
        end

        table.insert(messages, "═══════════════════════════════════════")

        for _, msg in ipairs(messages) do
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
            end
        end
    end)
end

function ACCommands.ShowBans(source)
    if not _G.Anticheat then return end

    local messages = {
        "═══════════════════════════════════════",
        "^1BANEOS ACTIVOS^0",
        "═══════════════════════════════════════",
    }

    local count = 0
    for identifier, ban in pairs(_G.Anticheat.BannedPlayers) do
        count = count + 1
        if count <= 10 then
            table.insert(messages, string.format("  ^3%s^0", identifier:sub(1, 30)))
            table.insert(messages, string.format("    Razón: %s", ban.reason:sub(1, 40)))
            table.insert(messages, string.format("    Expira: %s", ban.expire_time or "Permanente"))
        end
    end

    if count == 0 then
        table.insert(messages, "  No hay baneos activos")
    elseif count > 10 then
        table.insert(messages, string.format("  ... y %d más", count - 10))
    end

    table.insert(messages, "═══════════════════════════════════════")

    for _, msg in ipairs(messages) do
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
        end
    end
end

function ACCommands.ShowRecentLogs(source, count)
    if not MySQL or not MySQL.Async then
        ACCommands.Message(source, "MySQL no disponible", "error")
        return
    end

    MySQL.Async.fetchAll([[
        SELECT player_name, detection_type, timestamp
        FROM ait_anticheat_logs
        ORDER BY timestamp DESC
        LIMIT ?
    ]], {count}, function(results)
        local messages = {
            "═══════════════════════════════════════",
            string.format("^3ÚLTIMOS %d LOGS^0", count),
            "═══════════════════════════════════════",
        }

        if results and #results > 0 then
            for _, row in ipairs(results) do
                table.insert(messages, string.format("  [%s] ^3%s^0 - %s",
                    row.timestamp:sub(12, 19), row.player_name, row.detection_type))
            end
        else
            table.insert(messages, "  No hay logs recientes")
        end

        table.insert(messages, "═══════════════════════════════════════")

        for _, msg in ipairs(messages) do
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
            end
        end
    end)
end

function ACCommands.CheckPlayer(source, targetId)
    if not _G.Anticheat then return end

    local player = _G.Anticheat.GetPlayerInfo(targetId)
    local playerData = _G.Anticheat.PlayerData[targetId]

    if not player or player.name == "Unknown" then
        ACCommands.Message(source, "Jugador no encontrado", "error")
        return
    end

    local ped = GetPlayerPed(targetId)
    local coords = GetEntityCoords(ped)
    local health = GetEntityHealth(ped)

    local messages = {
        "═══════════════════════════════════════",
        string.format("^2CHECK: %s (ID: %d)^0", player.name, targetId),
        "═══════════════════════════════════════",
        string.format("Identifier: ^3%s^0", player.identifier),
        string.format("Health: ^3%d^0", health),
        string.format("Posición: ^3%.1f, %.1f, %.1f^0", coords.x, coords.y, coords.z),
    }

    if playerData then
        table.insert(messages, string.format("Strikes: ^1%d^0", playerData.strikes or 0))
        table.insert(messages, string.format("Vehicle Spawns: ^3%d^0", playerData.vehicleSpawns or 0))
        table.insert(messages, string.format("Explosiones: ^3%d^0", playerData.explosions or 0))
    end

    local isWhitelisted = _G.Anticheat.IsWhitelisted(targetId)
    table.insert(messages, string.format("Whitelisted: %s", isWhitelisted and "^2SÍ^0" or "^1NO^0"))

    table.insert(messages, "═══════════════════════════════════════")

    for _, msg in ipairs(messages) do
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
        end
    end
end

function ACCommands.FreezePlayer(source, targetId, freeze)
    TriggerClientEvent('ait-qb:client:anticheat:freeze', targetId, freeze)

    local action = freeze and "congelado" or "descongelado"
    ACCommands.Message(source, string.format("Jugador %d %s", targetId, action), "success")

    if _G.Anticheat then
        _G.Anticheat.LogDetection(targetId, "admin_action", {
            action = freeze and "freeze" or "unfreeze",
            by = source
        })
    end
end

function ACCommands.UnbanPlayer(source, identifier)
    if not MySQL or not MySQL.Async then
        if _G.Anticheat and _G.Anticheat.BannedPlayers[identifier] then
            _G.Anticheat.BannedPlayers[identifier] = nil
            ACCommands.Message(source, "Jugador desbaneado (solo cache)", "warning")
        end
        return
    end

    -- Buscar por identifier o ban_id
    MySQL.Async.execute([[
        UPDATE ait_anticheat_bans
        SET active = 0, unbanned_at = NOW(), unbanned_by = ?
        WHERE (identifier = ? OR ban_id = ?) AND active = 1
    ]], {
        source == 0 and "Console" or GetPlayerName(source),
        identifier,
        identifier
    }, function(rowsAffected)
        if rowsAffected > 0 then
            -- Remover del cache
            if _G.Anticheat then
                _G.Anticheat.BannedPlayers[identifier] = nil
            end
            ACCommands.Message(source, string.format("Jugador desbaneado: %s", identifier), "success")
        else
            ACCommands.Message(source, "No se encontró el ban", "error")
        end
    end)
end

function ACCommands.AddToWhitelist(source, identifier)
    if not Config.Anticheat.Whitelist.Players then
        Config.Anticheat.Whitelist.Players = {}
    end

    table.insert(Config.Anticheat.Whitelist.Players, identifier)

    if MySQL and MySQL.Async then
        MySQL.Async.execute([[
            INSERT INTO ait_anticheat_whitelist (identifier, added_by, added_at)
            VALUES (?, ?, NOW())
            ON DUPLICATE KEY UPDATE active = 1
        ]], {identifier, source == 0 and "Console" or GetPlayerName(source)})
    end

    ACCommands.Message(source, string.format("Añadido a whitelist: %s", identifier), "success")
end

function ACCommands.RemoveFromWhitelist(source, identifier)
    if Config.Anticheat.Whitelist.Players then
        for i, id in ipairs(Config.Anticheat.Whitelist.Players) do
            if id == identifier then
                table.remove(Config.Anticheat.Whitelist.Players, i)
                break
            end
        end
    end

    if MySQL and MySQL.Async then
        MySQL.Async.execute('UPDATE ait_anticheat_whitelist SET active = 0 WHERE identifier = ?', {identifier})
    end

    ACCommands.Message(source, string.format("Removido de whitelist: %s", identifier), "success")
end

function ACCommands.ListWhitelist(source)
    local messages = {
        "═══════════════════════════════════════",
        "^2WHITELIST^0",
        "═══════════════════════════════════════",
    }

    if Config.Anticheat.Whitelist.Players then
        for _, id in ipairs(Config.Anticheat.Whitelist.Players) do
            table.insert(messages, string.format("  ^3%s^0", id))
        end
    end

    if #messages == 3 then
        table.insert(messages, "  (vacía)")
    end

    table.insert(messages, "═══════════════════════════════════════")

    for _, msg in ipairs(messages) do
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {args = {"", msg}})
        end
    end
end

function ACCommands.MonitorPlayer(source, targetId)
    -- Activar monitoreo intensivo del jugador
    if not _G.Anticheat then return end

    local playerData = _G.Anticheat.PlayerData[targetId]
    if not playerData then
        ACCommands.Message(source, "Jugador no encontrado", "error")
        return
    end

    playerData.isMonitored = true
    playerData.monitoredBy = source

    ACCommands.Message(source, string.format("Monitoreando jugador %d. Recibirás alertas de su actividad.", targetId), "success")

    -- Notificar al admin de la actividad del jugador cada 30 segundos
    CreateThread(function()
        while playerData.isMonitored do
            Wait(30000)

            if not _G.Anticheat.PlayerData[targetId] then
                ACCommands.Message(source, string.format("Jugador %d desconectado, monitoreo terminado", targetId), "warning")
                break
            end

            local ped = GetPlayerPed(targetId)
            local coords = GetEntityCoords(ped)
            local health = GetEntityHealth(ped)

            ACCommands.Message(source,
                string.format("[MONITOR %d] Pos: %.0f,%.0f,%.0f | HP: %d | Strikes: %d",
                    targetId, coords.x, coords.y, coords.z, health, playerData.strikes or 0),
                "info")
        end
    end)
end

function ACCommands.TakeScreenshot(source, targetId)
    local screenshotResource = Config.Anticheat.Evidence.ScreenshotResource

    if GetResourceState(screenshotResource) ~= "started" then
        ACCommands.Message(source, string.format("Recurso %s no está iniciado", screenshotResource), "error")
        return
    end

    exports[screenshotResource]:requestClientScreenshot(targetId, {
        encoding = 'png',
        quality = 0.9
    }, function(err, data)
        if err then
            ACCommands.Message(source, "Error tomando screenshot: " .. tostring(err), "error")
            return
        end

        ACCommands.Message(source, string.format("Screenshot tomado de jugador %d", targetId), "success")

        -- Enviar a Discord si está configurado
        if Config.Anticheat.DiscordWebhook ~= "" and _G.Anticheat then
            local player = _G.Anticheat.GetPlayerInfo(targetId)
            _G.Anticheat.SendDiscordAlert("screenshot", {
                player = player.name,
                identifier = player.identifier,
                reason = "Screenshot manual por admin",
                screenshot = data
            })
        end
    end)
end

function ACCommands.ToggleModule(source, moduleName)
    local modules = {
        teleport = "Teleport",
        speed = "Speed",
        godmode = "Godmode",
        weapons = "Weapons",
        money = "Money",
        vehicles = "Vehicles",
        explosions = "Explosions",
        resources = "ResourceInjection",
        entities = "EntitySpawn"
    }

    local configKey = modules[string.lower(moduleName)]
    if not configKey then
        ACCommands.Message(source, "Módulo no encontrado", "error")
        return
    end

    local current = Config.Anticheat.Detection[configKey].Enabled
    Config.Anticheat.Detection[configKey].Enabled = not current

    local status = Config.Anticheat.Detection[configKey].Enabled and "ACTIVADO" or "DESACTIVADO"
    ACCommands.Message(source, string.format("Módulo %s: %s", moduleName, status), "success")
end

function ACCommands.MarkSuspect(source, targetId, reason)
    if not _G.Anticheat then return end

    _G.Anticheat.LogDetection(targetId, "marked_suspect", {
        reason = reason,
        marked_by = source == 0 and "Console" or GetPlayerName(source)
    })

    -- Añadir strike
    _G.Anticheat.AddStrike(targetId)

    local player = _G.Anticheat.GetPlayerInfo(targetId)
    ACCommands.Message(source, string.format("Jugador %s marcado como sospechoso: %s", player.name, reason), "warning")

    -- Notificar a otros admins
    _G.Anticheat.NotifyAdmins(string.format("⚠️ %s marcado como sospechoso: %s", player.name, reason))
end

function ACCommands.ShowConsoleHelp()
    print("═══════════════════════════════════════")
    print("AIT-QB ANTICHEAT - COMANDOS DE CONSOLA")
    print("═══════════════════════════════════════")
    print("ac help           - Mostrar ayuda")
    print("ac status         - Estado del sistema")
    print("ac stats          - Estadísticas")
    print("ac bans           - Lista de baneos")
    print("ac logs [n]       - Ver últimos N logs")
    print("acban [id] [razón] - Banear jugador")
    print("ackick [id] [razón] - Expulsar jugador")
    print("acunban [id]      - Desbanear jugador")
    print("═══════════════════════════════════════")
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIAR
-- ═══════════════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    ACCommands.Register()
end)

-- Evento del cliente para freeze
RegisterNetEvent('ait-qb:client:anticheat:freeze')

return ACCommands
