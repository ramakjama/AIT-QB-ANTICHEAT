-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT ENGINE - SERVER SIDE
-- Sistema de defensa contra RedEngine, PhazeMenu, y todos los menús de hack
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Anticheat = {}
Anticheat.Detections = {}
Anticheat.PlayerData = {}
Anticheat.Strikes = {}
Anticheat.BannedPlayers = {}
Anticheat.RateLimits = {}
Anticheat.Initialized = false

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.Initialize()
    if Anticheat.Initialized then return end

    print("^2[AIT-QB ANTICHEAT]^0 Inicializando sistema de protección...")

    -- Verificar dependencia de MySQL
    if not MySQL then
        print("^1[AIT-QB ANTICHEAT]^0 ERROR: MySQL no está disponible. Algunas funciones estarán desactivadas.")
        print("^1[AIT-QB ANTICHEAT]^0 Asegúrate de tener oxmysql instalado y configurado.")
    end

    -- Cargar lista de baneos
    Anticheat.LoadBans()

    -- Iniciar monitores
    Anticheat.StartResourceMonitor()
    Anticheat.StartEventMonitor()
    Anticheat.StartPlayerMonitor()

    -- Registrar eventos
    Anticheat.RegisterEvents()

    -- Registrar exports
    Anticheat.RegisterExports()

    Anticheat.Initialized = true
    print("^2[AIT-QB ANTICHEAT]^0 Sistema de protección ACTIVO")
    print("^2[AIT-QB ANTICHEAT]^0 Protección contra: RedEngine, PhazeMenu, Eulen, Lynx, y más")
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CARGA DE BANEOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.LoadBans()
    if not MySQL or not MySQL.Async then
        print("^3[AIT-QB ANTICHEAT]^0 MySQL no disponible, baneos no cargados desde DB")
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM ait_anticheat_bans WHERE (expire_time IS NULL OR expire_time > NOW()) AND active = 1', {}, function(results)
        if results then
            for _, ban in ipairs(results) do
                Anticheat.BannedPlayers[ban.identifier] = {
                    reason = ban.reason,
                    banned_by = ban.banned_by,
                    ban_time = ban.ban_time,
                    expire_time = ban.expire_time,
                    detection_type = ban.detection_type,
                }
            end
            print(string.format("^2[AIT-QB ANTICHEAT]^0 Cargados %d baneos activos", #results))
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE RECURSOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.StartResourceMonitor()
    -- Detectar recursos de cheat al iniciar
    CreateThread(function()
        Wait(5000) -- Esperar a que carguen todos los recursos

        local numResources = GetNumResources()
        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName then
                Anticheat.CheckResource(resourceName)
            end
        end
    end)

    -- Detectar recursos nuevos que se inicien
    AddEventHandler('onResourceStart', function(resourceName)
        Anticheat.CheckResource(resourceName)
    end)
end

function Anticheat.CheckResource(resourceName)
    if not Config.Anticheat.Detection.ResourceInjection.Enabled then return end

    local lowerName = string.lower(resourceName)

    -- Verificar si es un recurso de cheat conocido
    for _, signature in ipairs(Config.Anticheat.CheatSignatures.Resources) do
        if string.find(lowerName, string.lower(signature)) then
            Anticheat.OnCheatResourceDetected(resourceName, signature)
            return
        end
    end

    -- Verificar si está en whitelist
    local isWhitelisted = false
    for _, allowed in ipairs(Config.Anticheat.Whitelist.Resources) do
        if lowerName == string.lower(allowed) then
            isWhitelisted = true
            break
        end
    end

    if not isWhitelisted and Config.Anticheat.Detection.ResourceInjection.BlockUnauthorizedResources then
        -- Recurso no autorizado
        print(string.format("^1[AIT-QB ANTICHEAT]^0 Recurso no autorizado detectado: %s", resourceName))
        Anticheat.LogDetection(nil, "resource_injection", {
            resource = resourceName,
            action = "blocked"
        })

        -- Detener el recurso
        StopResource(resourceName)
    end
end

function Anticheat.OnCheatResourceDetected(resourceName, signature)
    print(string.format("^1[AIT-QB ANTICHEAT] ¡ALERTA CRÍTICA! Recurso de cheat detectado: %s (firma: %s)^0", resourceName, signature))

    -- Detener el recurso inmediatamente
    StopResource(resourceName)

    -- Buscar quién lo inició
    Anticheat.LogDetection(nil, "cheat_menu", {
        resource = resourceName,
        signature = signature,
        severity = "CRITICAL"
    })

    -- Notificar a todos los admins
    Anticheat.NotifyAdmins(string.format("🚨 RECURSO CHEAT DETECTADO: %s", resourceName))

    -- Discord alert
    Anticheat.SendDiscordAlert("cheat_menu", {
        resource = resourceName,
        signature = signature,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.StartEventMonitor()
    -- Registrar handler para eventos bloqueados
    for _, eventName in ipairs(Config.Anticheat.EventProtection.BlockedEvents) do
        RegisterNetEvent(eventName)
        AddEventHandler(eventName, function(...)
            local source = source
            Anticheat.OnBlockedEventTriggered(source, eventName, {...})
        end)
    end
end

function Anticheat.OnBlockedEventTriggered(source, eventName, args)
    if not Config.Anticheat.EventProtection.Enabled then return end

    local player = Anticheat.GetPlayerInfo(source)

    print(string.format("^1[AIT-QB ANTICHEAT] Evento bloqueado ejecutado por %s: %s^0", player.name, eventName))

    Anticheat.LogDetection(source, "blocked_event", {
        event = eventName,
        args = json.encode(args)
    })

    -- Castigar
    Anticheat.Punish(source, "event_spam", string.format("Evento bloqueado: %s", eventName))
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE JUGADORES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.StartPlayerMonitor()
    CreateThread(function()
        while true do
            Wait(Config.Anticheat.Detection.Godmode.CheckInterval or 5000)

            for _, playerId in ipairs(GetPlayers()) do
                local source = tonumber(playerId)
                if source then
                    Anticheat.CheckPlayer(source)
                end
            end
        end
    end)
end

function Anticheat.CheckPlayer(source)
    local ped = GetPlayerPed(source)
    if not DoesEntityExist(ped) then return end

    local playerData = Anticheat.PlayerData[source]
    if not playerData then
        Anticheat.InitPlayerData(source)
        return
    end

    -- Verificar coordenadas para teleport
    local coords = GetEntityCoords(ped)
    if playerData.lastCoords then
        local distance = #(coords - playerData.lastCoords)
        local timeDelta = (GetGameTimer() - playerData.lastCheck) / 1000

        if timeDelta > 0 then
            local speed = distance / timeDelta

            -- Detección de teleport
            if distance > Config.Anticheat.Detection.Teleport.MaxDistancePerTick then
                if not Anticheat.IsInGracePeriod(source) and not Anticheat.IsWhitelistedZone(coords) then
                    Anticheat.OnTeleportDetected(source, playerData.lastCoords, coords, distance)
                end
            end

            -- Detección de speedhack
            if Config.Anticheat.Detection.Speed.Enabled then
                local maxSpeed = IsPedInAnyVehicle(ped, false) and
                    Config.Anticheat.Detection.Speed.MaxVehicleSpeed or
                    Config.Anticheat.Detection.Speed.MaxFootSpeed

                if speed > (maxSpeed * Config.Anticheat.Detection.Speed.Tolerance) then
                    Anticheat.OnSpeedHackDetected(source, speed, maxSpeed)
                end
            end
        end
    end

    playerData.lastCoords = coords
    playerData.lastCheck = GetGameTimer()
end

function Anticheat.InitPlayerData(source)
    local ped = GetPlayerPed(source)
    Anticheat.PlayerData[source] = {
        joinTime = GetGameTimer(),
        lastCoords = GetEntityCoords(ped),
        lastCheck = GetGameTimer(),
        lastHealth = GetEntityHealth(ped),
        lastArmor = GetPedArmour(ped),
        spawnTime = GetGameTimer(),
        detections = {},
        strikes = 0,
        vehicleSpawns = 0,
        lastVehicleSpawn = 0,
        explosions = 0,
        lastExplosion = 0,
        eventCalls = {},
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- DETECCIONES ESPECÍFICAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.OnTeleportDetected(source, oldCoords, newCoords, distance)
    local player = Anticheat.GetPlayerInfo(source)

    print(string.format("^3[AIT-QB ANTICHEAT] Teleport detectado: %s (%.2f metros)^0", player.name, distance))

    Anticheat.LogDetection(source, "teleport", {
        from = json.encode(oldCoords),
        to = json.encode(newCoords),
        distance = distance
    })

    Anticheat.Punish(source, "teleport", string.format("Teleport detectado: %.0f metros", distance))
end

function Anticheat.OnSpeedHackDetected(source, currentSpeed, maxSpeed)
    local player = Anticheat.GetPlayerInfo(source)

    print(string.format("^3[AIT-QB ANTICHEAT] SpeedHack detectado: %s (%.2f m/s, max: %.2f)^0",
        player.name, currentSpeed, maxSpeed))

    Anticheat.LogDetection(source, "speedhack", {
        speed = currentSpeed,
        max_allowed = maxSpeed
    })

    Anticheat.Punish(source, "speedhack", string.format("SpeedHack: %.0f m/s", currentSpeed))
end

function Anticheat.OnGodmodeDetected(source)
    local player = Anticheat.GetPlayerInfo(source)

    print(string.format("^1[AIT-QB ANTICHEAT] GODMODE detectado: %s^0", player.name))

    Anticheat.LogDetection(source, "godmode", {})

    Anticheat.Punish(source, "godmode", "Godmode detectado")
end

function Anticheat.OnWeaponExploit(source, weaponHash, reason)
    local player = Anticheat.GetPlayerInfo(source)

    print(string.format("^3[AIT-QB ANTICHEAT] Exploit de arma detectado: %s - %s^0", player.name, reason))

    Anticheat.LogDetection(source, "weapon_exploit", {
        weapon = weaponHash,
        reason = reason
    })

    Anticheat.Punish(source, "weapon_exploit", reason)
end

function Anticheat.OnMoneyExploit(source, amount, reason)
    local player = Anticheat.GetPlayerInfo(source)

    print(string.format("^1[AIT-QB ANTICHEAT] Exploit de dinero detectado: %s - $%d - %s^0",
        player.name, amount, reason))

    Anticheat.LogDetection(source, "money_exploit", {
        amount = amount,
        reason = reason
    })

    Anticheat.Punish(source, "money_exploit", reason)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CASTIGOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.Punish(source, detectionType, reason)
    if Anticheat.IsWhitelisted(source) then
        print(string.format("^2[AIT-QB ANTICHEAT] Jugador whitelisted, ignorando: %s^0", detectionType))
        return
    end

    local punishmentLevel = Config.Anticheat.Punishments.DetectionPunishments[detectionType] or "medium"
    local punishment = Config.Anticheat.Punishments.Levels[punishmentLevel]

    local player = Anticheat.GetPlayerInfo(source)

    -- Sistema de strikes
    if Config.Anticheat.Punishments.StrikeSystem.Enabled then
        Anticheat.AddStrike(source)
        local strikes = Anticheat.GetStrikes(source)

        if strikes >= Config.Anticheat.Punishments.StrikeSystem.MaxStrikes then
            punishment = {action = "permaban", duration = 0}
            reason = reason .. " (Máximo de strikes alcanzado)"
        end
    end

    -- Ejecutar castigo
    if punishment.action == "warn" then
        Anticheat.WarnPlayer(source, reason)
    elseif punishment.action == "kick" then
        Anticheat.KickPlayer(source, reason)
    elseif punishment.action == "tempban" then
        Anticheat.BanPlayer(source, reason, detectionType, punishment.duration)
    elseif punishment.action == "permaban" then
        Anticheat.BanPlayer(source, reason, detectionType, nil)
    end

    -- Discord alert
    Anticheat.SendDiscordAlert(detectionType, {
        player = player.name,
        identifier = player.identifier,
        reason = reason,
        action = punishment.action
    })
end

function Anticheat.WarnPlayer(source, reason)
    -- Enviar advertencia al jugador
    TriggerClientEvent('ait-qb:client:anticheat:warn', source, reason)

    local player = Anticheat.GetPlayerInfo(source)
    print(string.format("^3[AIT-QB ANTICHEAT] ADVERTENCIA a %s: %s^0", player.name, reason))
end

function Anticheat.KickPlayer(source, reason)
    local player = Anticheat.GetPlayerInfo(source)
    local kickMsg = string.format(Config.AnticheatMessages.KickMessage, reason)

    print(string.format("^1[AIT-QB ANTICHEAT] KICK a %s: %s^0", player.name, reason))

    DropPlayer(source, kickMsg)
end

function Anticheat.BanPlayer(source, reason, detectionType, duration)
    local player = Anticheat.GetPlayerInfo(source)
    local banId = Anticheat.GenerateBanId()

    local expireTime = nil
    if duration then
        expireTime = os.date("%Y-%m-%d %H:%M:%S", os.time() + duration)
    end

    -- Guardar en base de datos si está disponible
    if MySQL and MySQL.Async then
        MySQL.Async.execute([[
            INSERT INTO ait_anticheat_bans
            (ban_id, identifier, player_name, reason, detection_type, banned_by, ban_time, expire_time, active, hardware_ids)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), ?, 1, ?)
        ]], {
            banId,
            player.identifier,
            player.name,
            reason,
            detectionType,
            "AIT-Anticheat",
            expireTime,
            json.encode(player.hwids or {})
        })
    end

    -- Agregar a cache (funciona incluso sin DB)
    Anticheat.BannedPlayers[player.identifier] = {
        reason = reason,
        banned_by = "AIT-Anticheat",
        detection_type = detectionType,
        expire_time = expireTime
    }

    local banMsg = string.format(Config.AnticheatMessages.BanMessage, banId)
    print(string.format("^1[AIT-QB ANTICHEAT] BAN a %s: %s (ID: %s)^0", player.name, reason, banId))

    DropPlayer(source, banMsg)
end

function Anticheat.GenerateBanId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = "BAN-"
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        id = id .. string.sub(chars, rand, rand)
    end
    return id
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.GetPlayerInfo(source)
    if not source then
        return {name = "Server", identifier = "server", hwids = {}}
    end

    local identifiers = GetPlayerIdentifiers(source)
    local hwids = {}
    local mainIdentifier = nil

    for _, id in ipairs(identifiers) do
        if string.find(id, "license:") then
            mainIdentifier = id
        end
        table.insert(hwids, id)
    end

    return {
        name = GetPlayerName(source) or "Unknown",
        identifier = mainIdentifier or identifiers[1] or "unknown",
        hwids = hwids,
        source = source
    }
end

function Anticheat.IsWhitelisted(source)
    local player = Anticheat.GetPlayerInfo(source)

    for _, id in ipairs(Config.Anticheat.Whitelist.Players) do
        if player.identifier == id then
            return true
        end
        for _, hwid in ipairs(player.hwids) do
            if hwid == id then
                return true
            end
        end
    end

    return false
end

function Anticheat.IsInGracePeriod(source)
    local playerData = Anticheat.PlayerData[source]
    if not playerData then return true end

    local timeSinceSpawn = GetGameTimer() - playerData.spawnTime
    return timeSinceSpawn < Config.Anticheat.Detection.Teleport.GracePeriodOnSpawn
end

function Anticheat.IsWhitelistedZone(coords)
    for _, zone in ipairs(Config.Anticheat.Detection.Teleport.WhitelistedZones or {}) do
        if #(coords - zone.coords) < (zone.radius or 50.0) then
            return true
        end
    end
    return false
end

function Anticheat.AddStrike(source)
    local player = Anticheat.GetPlayerInfo(source)
    if not Anticheat.Strikes[player.identifier] then
        Anticheat.Strikes[player.identifier] = {count = 0, lastStrike = 0}
    end

    local strikeData = Anticheat.Strikes[player.identifier]

    -- Verificar si los strikes anteriores han expirado
    local decayTime = Config.Anticheat.Punishments.StrikeSystem.StrikeDecayHours * 3600 * 1000
    if (GetGameTimer() - strikeData.lastStrike) > decayTime then
        strikeData.count = 0
    end

    strikeData.count = strikeData.count + 1
    strikeData.lastStrike = GetGameTimer()
end

function Anticheat.GetStrikes(source)
    local player = Anticheat.GetPlayerInfo(source)
    if not Anticheat.Strikes[player.identifier] then
        return 0
    end
    return Anticheat.Strikes[player.identifier].count
end

function Anticheat.LogDetection(source, detectionType, data)
    local player = source and Anticheat.GetPlayerInfo(source) or {name = "Server", identifier = "server"}

    -- Guardar en base de datos si está disponible
    if MySQL and MySQL.Async then
        MySQL.Async.execute([[
            INSERT INTO ait_anticheat_logs
            (identifier, player_name, detection_type, data, timestamp)
            VALUES (?, ?, ?, ?, NOW())
        ]], {
            player.identifier,
            player.name,
            detectionType,
            json.encode(data)
        })
    end

    if Config.Anticheat.Debug then
        print(string.format("^5[AIT-QB ANTICHEAT DEBUG] %s: %s - %s^0",
            detectionType, player.name, json.encode(data)))
    end
end

function Anticheat.NotifyAdmins(message)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if Anticheat.IsWhitelisted(source) then
            TriggerClientEvent('ait-qb:client:anticheat:adminNotify', source, message)
        end
    end
end

function Anticheat.SendDiscordAlert(detectionType, data)
    if not Config.Anticheat.DiscordAlerts or Config.Anticheat.DiscordWebhook == "" then
        return
    end

    local embed = {
        title = Config.AnticheatMessages.Discord.DetectionTitle,
        description = string.format("**Tipo:** %s\n**Jugador:** %s\n**Razón:** %s",
            detectionType, data.player or "N/A", data.reason or "N/A"),
        color = 16711680, -- Rojo
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {text = "AIT-QB Anticheat System"}
    }

    PerformHttpRequest(Config.Anticheat.DiscordWebhook, function(err, text, headers) end, 'POST',
        json.encode({embeds = {embed}}), {['Content-Type'] = 'application/json'})
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.RegisterEvents()
    -- Jugador conectándose
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local source = source
        local identifiers = GetPlayerIdentifiers(source)

        deferrals.defer()
        Wait(0)
        deferrals.update("Verificando estado de cuenta...")

        -- Verificar si está baneado
        for _, id in ipairs(identifiers) do
            if Anticheat.BannedPlayers[id] then
                local ban = Anticheat.BannedPlayers[id]
                local banMsg = string.format("Estás baneado.\nRazón: %s\nExpira: %s",
                    ban.reason, ban.expire_time or "Permanente")
                deferrals.done(banMsg)
                return
            end
        end

        deferrals.done()
    end)

    -- Jugador conectado
    AddEventHandler('playerJoining', function()
        local source = source
        Anticheat.InitPlayerData(source)
    end)

    -- Jugador desconectado
    AddEventHandler('playerDropped', function(reason)
        local source = source
        Anticheat.PlayerData[source] = nil
    end)

    -- Recibir datos del cliente
    RegisterNetEvent('ait-qb:server:anticheat:clientCheck')
    AddEventHandler('ait-qb:server:anticheat:clientCheck', function(data)
        local source = source
        Anticheat.ProcessClientCheck(source, data)
    end)

    -- Detección del cliente
    RegisterNetEvent('ait-qb:server:anticheat:detection')
    AddEventHandler('ait-qb:server:anticheat:detection', function(detectionType, data)
        local source = source
        Anticheat.ProcessClientDetection(source, detectionType, data)
    end)

    -- Evento de spawn
    RegisterNetEvent('ait-qb:server:anticheat:playerSpawned')
    AddEventHandler('ait-qb:server:anticheat:playerSpawned', function()
        local source = source
        local playerData = Anticheat.PlayerData[source]
        if playerData then
            playerData.spawnTime = GetGameTimer()
        end
    end)
end

function Anticheat.ProcessClientCheck(source, data)
    -- Procesar datos del cliente para validación
    if not data then return end

    -- Verificar health/armor anomalías
    if data.health and data.health > 200 then
        Anticheat.OnGodmodeDetected(source)
    end

    -- Verificar armas
    if data.weapons then
        for _, weapon in ipairs(data.weapons) do
            for _, blacklisted in ipairs(Config.Anticheat.Detection.Weapons.BlacklistedWeapons) do
                if weapon == blacklisted then
                    Anticheat.OnWeaponExploit(source, weapon, "Arma prohibida")
                end
            end
        end
    end
end

function Anticheat.ProcessClientDetection(source, detectionType, data)
    -- El cliente detectó algo
    Anticheat.LogDetection(source, detectionType, data)
    Anticheat.Punish(source, detectionType, data.reason or "Detección del cliente")
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Anticheat.RegisterExports()
    exports('AC_BanPlayer', function(source, reason, duration)
        Anticheat.BanPlayer(source, reason, "manual", duration)
    end)

    exports('AC_KickPlayer', function(source, reason)
        Anticheat.KickPlayer(source, reason)
    end)

    exports('AC_UnbanPlayer', function(identifier)
        Anticheat.BannedPlayers[identifier] = nil
        MySQL.Async.execute('UPDATE ait_anticheat_bans SET active = 0 WHERE identifier = ?', {identifier})
        return true
    end)

    exports('AC_IsPlayerBanned', function(identifier)
        return Anticheat.BannedPlayers[identifier] ~= nil
    end)

    exports('AC_GetBanInfo', function(identifier)
        return Anticheat.BannedPlayers[identifier]
    end)

    exports('AC_WhitelistPlayer', function(identifier)
        table.insert(Config.Anticheat.Whitelist.Players, identifier)
    end)

    exports('AC_LogSuspicious', function(source, reason, data)
        Anticheat.LogDetection(source, "suspicious_behavior", {reason = reason, data = data})
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIAR
-- ═══════════════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    Anticheat.Initialize()
end)

-- Exportar módulo
_G.Anticheat = Anticheat

return Anticheat
