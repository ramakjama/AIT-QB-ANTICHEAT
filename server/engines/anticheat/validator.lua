-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - EVENT VALIDATOR
-- Validación de todos los eventos del servidor
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Validator = {}
Validator.RateLimits = {}
Validator.LastEventCalls = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- RATE LIMITER
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Validator.CheckRateLimit(source, eventName, category)
    if not Config.Anticheat.EventProtection.Enabled then return true end

    local limits = Config.Anticheat.EventProtection.RateLimits[category] or
                   Config.Anticheat.EventProtection.RateLimits.default

    local key = string.format("%s:%s", source, eventName)
    local now = GetGameTimer()

    if not Validator.RateLimits[key] then
        Validator.RateLimits[key] = {
            calls = 0,
            windowStart = now
        }
    end

    local data = Validator.RateLimits[key]

    -- Reset window if expired
    if (now - data.windowStart) > (limits.perSeconds * 1000) then
        data.calls = 0
        data.windowStart = now
    end

    data.calls = data.calls + 1

    if data.calls > limits.maxCalls then
        -- Rate limit exceeded
        Validator.OnRateLimitExceeded(source, eventName, data.calls, limits.maxCalls)
        return false
    end

    return true
end

function Validator.OnRateLimitExceeded(source, eventName, calls, maxCalls)
    local player = _G.Anticheat and _G.Anticheat.GetPlayerInfo(source) or {name = "Unknown"}

    print(string.format("^3[AIT-ANTICHEAT] Rate limit excedido: %s - %s (%d/%d)^0",
        player.name, eventName, calls, maxCalls))

    if _G.Anticheat then
        _G.Anticheat.LogDetection(source, "event_spam", {
            event = eventName,
            calls = calls,
            max = maxCalls
        })
        _G.Anticheat.Punish(source, "event_spam", string.format("Spam de evento: %s", eventName))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- VALIDADORES ESPECÍFICOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Validar transacción de dinero
function Validator.ValidateMoney(source, amount, operation)
    if not Config.Anticheat.Detection.Money.Enabled then return true, nil end

    -- Verificar cantidad máxima
    if amount > Config.Anticheat.Detection.Money.MaxTransactionPerHour then
        return false, "Cantidad excede el límite por transacción"
    end

    -- Verificar si es negativo (exploit)
    if amount < 0 then
        return false, "Cantidad negativa detectada"
    end

    -- Verificar ganancia sospechosa
    if operation == "add" and amount > Config.Anticheat.Detection.Money.SuspiciousGainThreshold then
        -- Log sospechoso pero permitir
        if _G.Anticheat then
            _G.Anticheat.LogDetection(source, "suspicious_behavior", {
                type = "large_money_gain",
                amount = amount
            })
        end
    end

    return true, nil
end

-- Validar spawn de vehículo
function Validator.ValidateVehicleSpawn(source, model)
    if not Config.Anticheat.Detection.Vehicles.Enabled then return true, nil end

    local playerData = _G.Anticheat and _G.Anticheat.PlayerData[source]
    if not playerData then return true, nil end

    local now = GetGameTimer()

    -- Verificar rate de spawns
    if (now - playerData.lastVehicleSpawn) < 60000 then -- 1 minuto
        playerData.vehicleSpawns = playerData.vehicleSpawns + 1
    else
        playerData.vehicleSpawns = 1
    end
    playerData.lastVehicleSpawn = now

    if playerData.vehicleSpawns > Config.Anticheat.Detection.Vehicles.MaxSpawnsPerMinute then
        return false, "Demasiados vehículos spawneados"
    end

    -- Verificar modelo blacklisted
    for _, blacklisted in ipairs(Config.Anticheat.Detection.Vehicles.BlacklistedVehicles) do
        if model == blacklisted then
            return false, "Vehículo prohibido"
        end
    end

    return true, nil
end

-- Validar arma
function Validator.ValidateWeapon(source, weaponHash)
    if not Config.Anticheat.Detection.Weapons.Enabled then return true, nil end

    for _, blacklisted in ipairs(Config.Anticheat.Detection.Weapons.BlacklistedWeapons) do
        if weaponHash == blacklisted then
            return false, "Arma prohibida"
        end
    end

    return true, nil
end

-- Validar teleport
function Validator.ValidateTeleport(source, fromCoords, toCoords)
    if not Config.Anticheat.Detection.Teleport.Enabled then return true, nil end

    -- Verificar si está en whitelist
    if _G.Anticheat and _G.Anticheat.IsWhitelisted(source) then
        return true, nil
    end

    -- Verificar si está en grace period
    if _G.Anticheat and _G.Anticheat.IsInGracePeriod(source) then
        return true, nil
    end

    local distance = #(toCoords - fromCoords)

    if distance > Config.Anticheat.Detection.Teleport.MaxDistancePerTick then
        -- Verificar si es zona whitelisted
        if _G.Anticheat and _G.Anticheat.IsWhitelistedZone(toCoords) then
            return true, nil
        end
        return false, string.format("Teleport detectado: %.0f metros", distance)
    end

    return true, nil
end

-- Validar explosión
function Validator.ValidateExplosion(source, explosionType)
    if not Config.Anticheat.Detection.Explosions.Enabled then return true, nil end

    local playerData = _G.Anticheat and _G.Anticheat.PlayerData[source]
    if not playerData then return true, nil end

    local now = GetGameTimer()

    -- Verificar rate de explosiones
    if (now - playerData.lastExplosion) < 60000 then
        playerData.explosions = playerData.explosions + 1
    else
        playerData.explosions = 1
    end
    playerData.lastExplosion = now

    if playerData.explosions > Config.Anticheat.Detection.Explosions.MaxExplosionsPerMinute then
        return false, "Demasiadas explosiones"
    end

    -- Verificar tipo blacklisted
    for _, blacklisted in ipairs(Config.Anticheat.Detection.Explosions.BlacklistedTypes) do
        if explosionType == blacklisted then
            return false, "Tipo de explosión prohibido"
        end
    end

    return true, nil
end

-- Validar health/armor
function Validator.ValidateHealth(source, health, armor)
    if not Config.Anticheat.Detection.Godmode.Enabled then return true, nil end

    -- Health máximo normal es 200 (100 base + 100 extra en algunos casos)
    if health > 300 then
        return false, "Health anormal detectado"
    end

    -- Armor máximo normal es 100
    if armor > 150 then
        return false, "Armor anormal detectado"
    end

    return true, nil
end

-- Validar spawn de entidades
function Validator.ValidateEntitySpawn(source, entityType, model)
    if not Config.Anticheat.Detection.EntitySpawn.Enabled then return true, nil end

    -- Verificar modelo blacklisted
    for _, blacklisted in ipairs(Config.Anticheat.Detection.EntitySpawn.BlacklistedModels) do
        if model == blacklisted then
            return false, "Modelo de entidad prohibido"
        end
    end

    return true, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MIDDLEWARE DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Crear wrapper seguro para eventos
function Validator.SecureEvent(eventName, category, handler)
    RegisterNetEvent(eventName)
    AddEventHandler(eventName, function(...)
        local source = source
        local args = {...}

        -- Verificar rate limit
        if not Validator.CheckRateLimit(source, eventName, category) then
            return -- Bloqueado por rate limit
        end

        -- Verificar si el evento está en la lista de protegidos
        local isProtected = false
        for _, protected in ipairs(Config.Anticheat.EventProtection.ProtectedEvents) do
            if eventName == protected then
                isProtected = true
                break
            end
        end

        -- Si está protegido, verificar permisos adicionales
        if isProtected then
            -- Aquí puedes agregar validaciones adicionales
            if Config.Anticheat.Debug then
                print(string.format("^5[AIT-ANTICHEAT] Evento protegido: %s por source %s^0", eventName, source))
            end
        end

        -- Ejecutar handler
        handler(source, table.unpack(args))
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

exports('AC_ValidateMoney', Validator.ValidateMoney)
exports('AC_ValidateVehicleSpawn', Validator.ValidateVehicleSpawn)
exports('AC_ValidateWeapon', Validator.ValidateWeapon)
exports('AC_ValidateTeleport', Validator.ValidateTeleport)
exports('AC_ValidateExplosion', Validator.ValidateExplosion)
exports('AC_ValidateHealth', Validator.ValidateHealth)
exports('AC_SecureEvent', Validator.SecureEvent)
exports('AC_CheckRateLimit', Validator.CheckRateLimit)

-- Exportar módulo
_G.AnticheatValidator = Validator

return Validator
