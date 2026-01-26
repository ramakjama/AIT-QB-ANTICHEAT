-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - ADVANCED SECURITY MODULE
-- Sistemas de seguridad de nivel empresarial
-- HWID Bans, VPN Detection, Player Profiling, Anti-Executor
-- ═══════════════════════════════════════════════════════════════════════════════════════

local AdvancedAC = {}
AdvancedAC.SuspiciousProfiles = {}
AdvancedAC.VPNCache = {}
AdvancedAC.HWIDDatabase = {}
AdvancedAC.ConnectionAttempts = {}
AdvancedAC.KnownBadActors = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE HWID BAN (Hardware ID)
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AdvancedAC.InitHWIDSystem()
    -- Cargar HWID baneados de la base de datos
    if MySQL and MySQL.Async then
        MySQL.Async.fetchAll([[
            SELECT hardware_ids FROM ait_anticheat_bans
            WHERE active = 1 AND hardware_ids IS NOT NULL
        ]], {}, function(results)
            if results then
                for _, row in ipairs(results) do
                    local hwids = json.decode(row.hardware_ids)
                    if hwids then
                        for _, hwid in ipairs(hwids) do
                            AdvancedAC.HWIDDatabase[hwid] = true
                        end
                    end
                end
                print(string.format("^2[AIT-QB ANTICHEAT]^0 Cargados %d HWIDs baneados", AdvancedAC.CountTable(AdvancedAC.HWIDDatabase)))
            end
        end)
    end
end

function AdvancedAC.GetAllPlayerHWIDs(source)
    local hwids = {}
    local identifiers = GetPlayerIdentifiers(source)
    local tokens = GetNumPlayerTokens(source)

    -- Añadir todos los identifiers
    for _, id in ipairs(identifiers) do
        table.insert(hwids, id)
    end

    -- Añadir todos los tokens (hardware tokens)
    for i = 0, tokens - 1 do
        local token = GetPlayerToken(source, i)
        if token then
            table.insert(hwids, "token:" .. token)
        end
    end

    return hwids
end

function AdvancedAC.CheckHWIDBan(source)
    local hwids = AdvancedAC.GetAllPlayerHWIDs(source)

    for _, hwid in ipairs(hwids) do
        if AdvancedAC.HWIDDatabase[hwid] then
            return true, hwid
        end
    end

    return false, nil
end

function AdvancedAC.AddHWIDBan(hwids)
    for _, hwid in ipairs(hwids) do
        AdvancedAC.HWIDDatabase[hwid] = true
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE DETECCIÓN DE VPN/PROXY
-- ═══════════════════════════════════════════════════════════════════════════════════════

AdvancedAC.VPNConfig = {
    Enabled = true,
    BlockVPN = false,           -- Bloquear VPNs (true = kick, false = solo log)
    WarnOnVPN = true,           -- Advertir a admins
    WhitelistedIPs = {},        -- IPs permitidas aunque sean VPN
    -- APIs gratuitas para verificar VPN (puedes añadir tu propia API key)
    APIs = {
        -- ip-api.com (gratuito, 45 requests/min)
        {
            url = "http://ip-api.com/json/%s?fields=proxy,hosting",
            parseResponse = function(response)
                local data = json.decode(response)
                if data then
                    return data.proxy or data.hosting
                end
                return false
            end
        },
    }
}

function AdvancedAC.CheckVPN(source, ip, callback)
    if not AdvancedAC.VPNConfig.Enabled then
        callback(false)
        return
    end

    -- Verificar cache
    if AdvancedAC.VPNCache[ip] ~= nil then
        callback(AdvancedAC.VPNCache[ip])
        return
    end

    -- Verificar whitelist
    for _, whitelistedIP in ipairs(AdvancedAC.VPNConfig.WhitelistedIPs) do
        if ip == whitelistedIP or ip:find(whitelistedIP) then
            AdvancedAC.VPNCache[ip] = false
            callback(false)
            return
        end
    end

    -- Verificar con APIs
    local api = AdvancedAC.VPNConfig.APIs[1]
    if api then
        local url = string.format(api.url, ip)
        PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
            local isVPN = false
            if errorCode == 200 and resultData then
                isVPN = api.parseResponse(resultData)
            end
            AdvancedAC.VPNCache[ip] = isVPN
            callback(isVPN)
        end, 'GET')
    else
        callback(false)
    end
end

function AdvancedAC.OnVPNDetected(source, ip)
    local player = _G.Anticheat and _G.Anticheat.GetPlayerInfo(source) or {name = GetPlayerName(source)}

    print(string.format("^3[AIT-QB ANTICHEAT]^0 VPN/Proxy detectado: %s (IP: %s)", player.name, ip))

    if _G.Anticheat then
        _G.Anticheat.LogDetection(source, "vpn_detected", {
            ip = ip,
            action = AdvancedAC.VPNConfig.BlockVPN and "blocked" or "warned"
        })

        if AdvancedAC.VPNConfig.WarnOnVPN then
            _G.Anticheat.NotifyAdmins(string.format("⚠️ VPN detectado: %s (IP: %s)", player.name, ip))
        end

        _G.Anticheat.SendDiscordAlert("vpn_detected", {
            player = player.name,
            identifier = player.identifier,
            reason = "VPN/Proxy detectado",
            ip = ip,
            severity = "medium"
        })
    end

    if AdvancedAC.VPNConfig.BlockVPN then
        DropPlayer(source, "VPN/Proxy no permitido en este servidor")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE PERFILADO DE JUGADORES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AdvancedAC.CreatePlayerProfile(source)
    local player = _G.Anticheat and _G.Anticheat.GetPlayerInfo(source) or {name = GetPlayerName(source), identifier = "unknown"}
    local hwids = AdvancedAC.GetAllPlayerHWIDs(source)

    local profile = {
        identifier = player.identifier,
        name = player.name,
        hwids = hwids,
        firstSeen = os.time(),
        lastSeen = os.time(),
        totalPlaytime = 0,
        -- Métricas de sospecha
        suspicionScore = 0,
        flags = {},
        -- Historial
        connections = 1,
        kicks = 0,
        warns = 0,
        previousBans = 0,
        -- Comportamiento
        avgSpeed = 0,
        maxSpeed = 0,
        teleportCount = 0,
        unusualActivity = {},
        -- Asociaciones (otros jugadores con mismos HWIDs)
        linkedAccounts = {},
    }

    return profile
end

function AdvancedAC.UpdatePlayerProfile(source, eventType, data)
    local player = _G.Anticheat and _G.Anticheat.GetPlayerInfo(source) or {identifier = "unknown"}
    local profile = AdvancedAC.SuspiciousProfiles[player.identifier]

    if not profile then
        profile = AdvancedAC.CreatePlayerProfile(source)
        AdvancedAC.SuspiciousProfiles[player.identifier] = profile
    end

    profile.lastSeen = os.time()

    -- Actualizar según tipo de evento
    if eventType == "detection" then
        profile.suspicionScore = profile.suspicionScore + (data.scoreIncrease or 10)
        table.insert(profile.flags, {
            type = data.type,
            timestamp = os.time(),
            details = data.details
        })
    elseif eventType == "kick" then
        profile.kicks = profile.kicks + 1
        profile.suspicionScore = profile.suspicionScore + 25
    elseif eventType == "warn" then
        profile.warns = profile.warns + 1
        profile.suspicionScore = profile.suspicionScore + 5
    elseif eventType == "speed" then
        if data.speed > profile.maxSpeed then
            profile.maxSpeed = data.speed
        end
    elseif eventType == "teleport" then
        profile.teleportCount = profile.teleportCount + 1
    end

    -- Verificar si el score de sospecha es muy alto
    if profile.suspicionScore >= 100 then
        AdvancedAC.OnHighSuspicionPlayer(source, profile)
    end
end

function AdvancedAC.OnHighSuspicionPlayer(source, profile)
    print(string.format("^1[AIT-QB ANTICHEAT]^0 Jugador con alta sospecha: %s (Score: %d)",
        profile.name, profile.suspicionScore))

    if _G.Anticheat then
        _G.Anticheat.NotifyAdmins(string.format(
            "🚨 ALERTA: %s tiene score de sospecha alto (%d). Considera monitorearlo.",
            profile.name, profile.suspicionScore))

        _G.Anticheat.SendDiscordAlert("high_suspicion", {
            player = profile.name,
            identifier = profile.identifier,
            reason = string.format("Score de sospecha: %d", profile.suspicionScore),
            severity = "critical"
        })
    end
end

function AdvancedAC.FindLinkedAccounts(hwids)
    local linked = {}

    if MySQL and MySQL.Sync then
        for _, hwid in ipairs(hwids) do
            local results = MySQL.Sync.fetchAll([[
                SELECT DISTINCT identifier, player_name
                FROM ait_anticheat_bans
                WHERE hardware_ids LIKE ?
            ]], {'%' .. hwid .. '%'})

            if results then
                for _, row in ipairs(results) do
                    linked[row.identifier] = row.player_name
                end
            end
        end
    end

    return linked
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA ANTI-EXECUTOR AVANZADO
-- ═══════════════════════════════════════════════════════════════════════════════════════

AdvancedAC.ExecutorSignatures = {
    -- Patrones de nombres de recursos usados por executors
    resourcePatterns = {
        "^_", "^%.", "^[0-9]+$",             -- Nombres sospechosos
        "exec", "inject", "bypass",
        "loader", "cheat", "hack",
        "menu", "mod_menu", "trainer",
        "godmode", "aimbot", "esp",
    },

    -- Eventos que los executors suelen crear
    suspiciousEventPatterns = {
        "^_.*:execute",
        "^hack:",
        "^cheat:",
        "^inject:",
        "^bypass:",
    },

    -- Exports que los executors suelen exponer
    suspiciousExportPatterns = {
        "Execute", "Inject", "Bypass",
        "LoadScript", "RunCode", "Eval",
    }
}

function AdvancedAC.ScanForExecutors()
    local detections = {}

    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local isSuspicious, reason = AdvancedAC.IsResourceSuspicious(resourceName)
            if isSuspicious then
                table.insert(detections, {
                    resource = resourceName,
                    reason = reason
                })
            end
        end
    end

    return detections
end

function AdvancedAC.IsResourceSuspicious(resourceName)
    local lowerName = string.lower(resourceName)

    -- Verificar patrones de nombre
    for _, pattern in ipairs(AdvancedAC.ExecutorSignatures.resourcePatterns) do
        if string.match(lowerName, pattern) then
            return true, "Patrón de nombre sospechoso: " .. pattern
        end
    end

    -- Verificar si el recurso tiene metadata sospechoso
    local author = GetResourceMetadata(resourceName, 'author', 0)
    local description = GetResourceMetadata(resourceName, 'description', 0)

    if author then
        local lowerAuthor = string.lower(author)
        local suspiciousAuthors = {"unknown", "anonymous", "hacker", "cheater", "executor"}
        for _, sus in ipairs(suspiciousAuthors) do
            if lowerAuthor:find(sus) then
                return true, "Autor sospechoso: " .. author
            end
        end
    end

    return false, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE RATE LIMITING AVANZADO POR IP
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AdvancedAC.CheckConnectionRateLimit(ip)
    local now = os.time()
    local windowSeconds = 60  -- 1 minuto
    local maxAttempts = 5     -- 5 intentos por minuto

    if not AdvancedAC.ConnectionAttempts[ip] then
        AdvancedAC.ConnectionAttempts[ip] = {
            attempts = {},
            blocked = false,
            blockedUntil = 0
        }
    end

    local data = AdvancedAC.ConnectionAttempts[ip]

    -- Verificar si está bloqueado
    if data.blocked and data.blockedUntil > now then
        return false, "IP temporalmente bloqueada por demasiados intentos"
    elseif data.blocked then
        data.blocked = false
    end

    -- Limpiar intentos viejos
    local validAttempts = {}
    for _, attemptTime in ipairs(data.attempts) do
        if attemptTime > (now - windowSeconds) then
            table.insert(validAttempts, attemptTime)
        end
    end
    data.attempts = validAttempts

    -- Verificar límite
    if #data.attempts >= maxAttempts then
        data.blocked = true
        data.blockedUntil = now + 300 -- Bloquear por 5 minutos
        return false, "Demasiados intentos de conexión"
    end

    -- Registrar intento
    table.insert(data.attempts, now)

    return true, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE VERIFICACIÓN DE INTEGRIDAD
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AdvancedAC.RequestIntegrityCheck(source)
    -- Solicitar al cliente que envíe información de integridad
    TriggerClientEvent('ait-qb:client:anticheat:integrityCheck', source)
end

function AdvancedAC.ProcessIntegrityReport(source, report)
    local issues = {}

    -- Verificar si hay problemas
    if report.modifiedFiles and #report.modifiedFiles > 0 then
        table.insert(issues, "Archivos modificados detectados")
    end

    if report.injectedCode then
        table.insert(issues, "Código inyectado detectado")
    end

    if report.suspiciousProcesses and #report.suspiciousProcesses > 0 then
        table.insert(issues, "Procesos sospechosos detectados")
    end

    if #issues > 0 then
        local player = _G.Anticheat and _G.Anticheat.GetPlayerInfo(source) or {name = "Unknown"}
        print(string.format("^1[AIT-QB ANTICHEAT]^0 Problemas de integridad para %s: %s",
            player.name, table.concat(issues, ", ")))

        if _G.Anticheat then
            _G.Anticheat.LogDetection(source, "integrity_failure", {
                issues = issues,
                report = report
            })
        end

        return false, issues
    end

    return true, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- HOOKS DE CONEXIÓN AVANZADOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AdvancedAC.OnPlayerConnecting(source, name, deferrals)
    local identifiers = GetPlayerIdentifiers(source)
    local ip = GetPlayerEndpoint(source)

    -- Limpiar IP (quitar puerto)
    if ip then
        ip = ip:match("([^:]+)")
    end

    -- 1. Verificar rate limit de conexión
    local allowed, rateLimitReason = AdvancedAC.CheckConnectionRateLimit(ip)
    if not allowed then
        deferrals.done(rateLimitReason)
        return false
    end

    -- 2. Verificar HWID ban
    local isHWIDBanned, bannedHWID = AdvancedAC.CheckHWIDBan(source)
    if isHWIDBanned then
        deferrals.done("Acceso denegado. Tu hardware está baneado.")
        print(string.format("^1[AIT-QB ANTICHEAT]^0 HWID ban: %s intentó conectar (HWID: %s)", name, bannedHWID))
        return false
    end

    -- 3. Verificar cuentas vinculadas
    local hwids = AdvancedAC.GetAllPlayerHWIDs(source)
    local linkedAccounts = AdvancedAC.FindLinkedAccounts(hwids)
    if AdvancedAC.CountTable(linkedAccounts) > 0 then
        -- Hay cuentas vinculadas baneadas
        for linkedId, linkedName in pairs(linkedAccounts) do
            if _G.Anticheat and _G.Anticheat.BannedPlayers[linkedId] then
                deferrals.done("Acceso denegado. Cuenta vinculada baneada.")
                print(string.format("^1[AIT-QB ANTICHEAT]^0 Cuenta vinculada baneada: %s vinculado a %s", name, linkedName))
                return false
            end
        end
    end

    -- 4. Verificar VPN (asíncrono)
    if ip and AdvancedAC.VPNConfig.Enabled then
        AdvancedAC.CheckVPN(source, ip, function(isVPN)
            if isVPN then
                AdvancedAC.OnVPNDetected(source, ip)
            end
        end)
    end

    -- 5. Crear/actualizar perfil del jugador
    local mainIdentifier = identifiers[1]
    for _, id in ipairs(identifiers) do
        if id:find("license:") then
            mainIdentifier = id
            break
        end
    end

    local profile = AdvancedAC.SuspiciousProfiles[mainIdentifier]
    if profile then
        profile.connections = profile.connections + 1
        profile.lastSeen = os.time()
    else
        AdvancedAC.SuspiciousProfiles[mainIdentifier] = AdvancedAC.CreatePlayerProfile(source)
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AdvancedAC.CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(3000) -- Esperar a que cargue el anticheat principal

    AdvancedAC.InitHWIDSystem()

    -- Escanear recursos sospechosos al inicio
    local detections = AdvancedAC.ScanForExecutors()
    if #detections > 0 then
        print("^1[AIT-QB ANTICHEAT]^0 ¡ALERTA! Recursos sospechosos detectados:")
        for _, detection in ipairs(detections) do
            print(string.format("  - %s: %s", detection.resource, detection.reason))
        end
    end

    print("^2[AIT-QB ANTICHEAT]^0 Módulo de seguridad avanzada ACTIVO")
    print("^2[AIT-QB ANTICHEAT]^0 - HWID Ban System: ON")
    print("^2[AIT-QB ANTICHEAT]^0 - VPN Detection: " .. (AdvancedAC.VPNConfig.Enabled and "ON" or "OFF"))
    print("^2[AIT-QB ANTICHEAT]^0 - Player Profiling: ON")
    print("^2[AIT-QB ANTICHEAT]^0 - Anti-Executor Scanner: ON")
end)

-- Hook de conexión
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source

    deferrals.defer()
    Wait(0)

    deferrals.update("🔒 Verificando seguridad avanzada...")

    local allowed = AdvancedAC.OnPlayerConnecting(source, name, deferrals)

    if allowed ~= false then
        deferrals.done()
    end
end)

-- Recibir reporte de integridad del cliente
RegisterNetEvent('ait-qb:server:anticheat:integrityReport')
AddEventHandler('ait-qb:server:anticheat:integrityReport', function(report)
    local source = source
    AdvancedAC.ProcessIntegrityReport(source, report)
end)

-- Exportar
_G.AdvancedAC = AdvancedAC
exports('AC_GetPlayerProfile', function(identifier) return AdvancedAC.SuspiciousProfiles[identifier] end)
exports('AC_CheckVPN', AdvancedAC.CheckVPN)
exports('AC_GetPlayerHWIDs', AdvancedAC.GetAllPlayerHWIDs)
exports('AC_IsHWIDBanned', AdvancedAC.CheckHWIDBan)

return AdvancedAC
