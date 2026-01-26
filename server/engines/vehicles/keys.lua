-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb VEHICLES ENGINE - KEYS
-- Sistema de llaves: dar/quitar llaves, robo de vehiculos, lockpicking
-- Namespace: AIT.Engines.Vehicles.Keys
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Vehicles = AIT.Engines.Vehicles or {}

local Keys = {
    vehicleKeys = {},       -- Cache de llaves por vehiculo {vehicleId = {charId = keyData}}
    playerKeys = {},        -- Cache de llaves por jugador {charId = {vehicleId = keyData}}
    tempKeys = {},          -- Llaves temporales {keyId = data}
    lockpickAttempts = {},  -- Intentos de lockpick {source = {vehicleId = attempts}}
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

Keys.Config = {
    -- Items
    lockpickItem = 'lockpick',
    advancedLockpickItem = 'advanced_lockpick',
    hotwireKitItem = 'hotwire_kit',

    -- Lockpicking
    lockpickBaseChance = 25,        -- Probabilidad base (%)
    lockpickSkillMultiplier = 2,    -- Multiplicador por nivel de habilidad
    lockpickBreakChance = 40,       -- Probabilidad de romper ganzua
    lockpickCooldown = 30,          -- Segundos entre intentos
    maxLockpickAttempts = 3,        -- Maximo intentos antes de cooldown largo

    -- Hotwiring
    hotwireBaseTime = 15,           -- Segundos base
    hotwireMinTime = 5,             -- Tiempo minimo
    hotwireAlertChance = 60,        -- Probabilidad de alertar policia
    hotwireAlertRadius = 100.0,     -- Radio de alerta

    -- Por categoria de vehiculo
    categoryDifficulty = {
        compact = { lockpick = 1.0, hotwire = 1.0, alarm = false },
        sedan = { lockpick = 1.0, hotwire = 1.0, alarm = false },
        suv = { lockpick = 1.2, hotwire = 1.2, alarm = true },
        coupe = { lockpick = 1.3, hotwire = 1.3, alarm = true },
        muscle = { lockpick = 1.2, hotwire = 1.2, alarm = true },
        sport = { lockpick = 1.5, hotwire = 1.5, alarm = true },
        super = { lockpick = 2.0, hotwire = 2.0, alarm = true },
        motorcycle = { lockpick = 0.8, hotwire = 0.5, alarm = false },
        offroad = { lockpick = 1.0, hotwire = 1.0, alarm = false },
        industrial = { lockpick = 0.7, hotwire = 0.8, alarm = false },
        commercial = { lockpick = 0.8, hotwire = 0.9, alarm = false },
        emergency = { lockpick = 2.5, hotwire = 2.5, alarm = true },
        military = { lockpick = 3.0, hotwire = 3.0, alarm = true },
    },

    -- Llaves temporales
    tempKeyDuration = 3600,         -- Duracion en segundos (1 hora)

    -- Duplicar llaves
    duplicateKeyPrice = 500,
    duplicateKeyTime = 5000,        -- ms

    -- Alertas
    alertPoliceOnTheft = true,
    alertOwnerOnTheft = true,
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Keys.Initialize()
    -- Asegurar tablas
    Keys.EnsureTables()

    -- Limpiar llaves temporales expiradas
    Keys.CleanupExpiredKeys()

    -- Registrar jobs
    if AIT.Scheduler then
        AIT.Scheduler.register('keys_cleanup', {
            interval = 300,
            fn = Keys.CleanupExpiredKeys
        })

        AIT.Scheduler.register('keys_cache_refresh', {
            interval = 600,
            fn = Keys.RefreshCache
        })
    end

    -- Registrar items
    Keys.RegisterItems()

    if AIT.Log then
        AIT.Log.info('VEHICLES.KEYS', 'Sistema de llaves inicializado')
    end

    return true
end

function Keys.EnsureTables()
    -- Tabla de llaves
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_vehicle_keys (
            key_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            vehicle_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            key_type ENUM('owner', 'copy', 'temp', 'valet', 'faction') NOT NULL DEFAULT 'copy',
            label VARCHAR(128) NULL,
            can_give_copy TINYINT(1) NOT NULL DEFAULT 0,
            can_start TINYINT(1) NOT NULL DEFAULT 1,
            can_lock TINYINT(1) NOT NULL DEFAULT 1,
            can_trunk TINYINT(1) NOT NULL DEFAULT 1,
            granted_by_char_id BIGINT NULL,
            expires_at DATETIME NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            revoked_at DATETIME NULL,
            UNIQUE KEY idx_vehicle_char (vehicle_id, char_id),
            KEY idx_char (char_id),
            KEY idx_expires (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Historial de robos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_vehicle_theft_log (
            theft_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            vehicle_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            method ENUM('lockpick', 'hotwire', 'smash', 'force') NOT NULL,
            success TINYINT(1) NOT NULL,
            alerted_police TINYINT(1) NOT NULL DEFAULT 0,
            location JSON NULL,
            meta JSON NULL,
            KEY idx_vehicle (vehicle_id),
            KEY idx_char (char_id),
            KEY idx_ts (ts)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Keys.RegisterItems()
    if not AIT.Engines.inventory then return end

    -- Ganzua
    MySQL.insert.await([[
        INSERT IGNORE INTO ait_items_catalog
        (item_id, name, label, type, weight, stack_size, useable, legal, base_price)
        VALUES ('lockpick', 'Lockpick', 'Ganzua', 'tool', 100, 5, 1, 0, 500)
    ]], {})

    -- Ganzua avanzada
    MySQL.insert.await([[
        INSERT IGNORE INTO ait_items_catalog
        (item_id, name, label, type, weight, stack_size, useable, legal, base_price)
        VALUES ('advanced_lockpick', 'Advanced Lockpick', 'Ganzua Avanzada', 'tool', 150, 3, 1, 0, 2500)
    ]], {})

    -- Kit de hotwire
    MySQL.insert.await([[
        INSERT IGNORE INTO ait_items_catalog
        (item_id, name, label, type, weight, stack_size, useable, legal, base_price)
        VALUES ('hotwire_kit', 'Hotwire Kit', 'Kit de Puente', 'tool', 500, 1, 1, 0, 5000)
    ]], {})
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- GESTION DE LLAVES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Verifica si un personaje tiene llave de un vehiculo
---@param charId number
---@param vehicleId number
---@return boolean, table|nil
function Keys.HasKey(charId, vehicleId)
    -- Buscar en cache primero
    if Keys.playerKeys[charId] and Keys.playerKeys[charId][vehicleId] then
        local keyData = Keys.playerKeys[charId][vehicleId]
        -- Verificar si no ha expirado
        if not keyData.expiresAt or keyData.expiresAt > os.time() then
            return true, keyData
        end
    end

    -- Buscar en DB
    local key = MySQL.query.await([[
        SELECT * FROM ait_vehicle_keys
        WHERE vehicle_id = ? AND char_id = ? AND revoked_at IS NULL
        AND (expires_at IS NULL OR expires_at > NOW())
    ]], { vehicleId, charId })

    if key and key[1] then
        -- Guardar en cache
        Keys.CacheKey(charId, vehicleId, key[1])
        return true, key[1]
    end

    return false, nil
end

--- Verifica si un personaje puede arrancar un vehiculo
---@param charId number
---@param vehicleId number
---@return boolean
function Keys.CanStart(charId, vehicleId)
    local hasKey, keyData = Keys.HasKey(charId, vehicleId)
    if not hasKey then return false end
    return keyData.can_start == 1
end

--- Verifica si un personaje puede cerrar/abrir un vehiculo
---@param charId number
---@param vehicleId number
---@return boolean
function Keys.CanLock(charId, vehicleId)
    local hasKey, keyData = Keys.HasKey(charId, vehicleId)
    if not hasKey then return false end
    return keyData.can_lock == 1
end

--- Da una llave a un personaje
---@param source number|nil
---@param vehicleId number
---@param charId number
---@param isOwner? boolean
---@param options? table
---@return boolean, string
function Keys.GiveKey(source, vehicleId, charId, isOwner, options)
    options = options or {}

    -- Verificar que el vehiculo existe
    local Vehicles = AIT.Engines.Vehicles
    local vehicle = Vehicles and Vehicles.GetVehicleData(vehicleId)

    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar si ya tiene llave
    local hasKey = Keys.HasKey(charId, vehicleId)
    if hasKey then
        return false, 'Ya tiene llave de este vehiculo'
    end

    -- Determinar tipo de llave
    local keyType = 'copy'
    if isOwner then
        keyType = 'owner'
    elseif options.temp then
        keyType = 'temp'
    elseif options.valet then
        keyType = 'valet'
    elseif options.faction then
        keyType = 'faction'
    end

    -- Determinar permisos
    local canGiveCopy = isOwner and 1 or 0
    local canStart = options.canStart ~= false and 1 or 0
    local canLock = options.canLock ~= false and 1 or 0
    local canTrunk = options.canTrunk ~= false and 1 or 0

    -- Expiracion para llaves temporales
    local expiresAt = nil
    if keyType == 'temp' then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (options.duration or Keys.Config.tempKeyDuration))
    end

    -- Obtener charId del que da la llave
    local grantedBy = source and Keys.GetCharacterId(source) or nil

    -- Insertar
    local keyId = MySQL.insert.await([[
        INSERT INTO ait_vehicle_keys
        (vehicle_id, char_id, key_type, label, can_give_copy, can_start, can_lock, can_trunk, granted_by_char_id, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        vehicleId,
        charId,
        keyType,
        options.label or vehicle.plate,
        canGiveCopy,
        canStart,
        canLock,
        canTrunk,
        grantedBy,
        expiresAt
    })

    -- Actualizar cache
    Keys.CacheKey(charId, vehicleId, {
        key_id = keyId,
        vehicle_id = vehicleId,
        char_id = charId,
        key_type = keyType,
        can_give_copy = canGiveCopy,
        can_start = canStart,
        can_lock = canLock,
        can_trunk = canTrunk,
        expires_at = expiresAt,
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.keys.given', {
            vehicleId = vehicleId,
            charId = charId,
            keyType = keyType,
            grantedBy = grantedBy,
        })
    end

    if AIT.Log then
        AIT.Log.debug('VEHICLES.KEYS', 'Llave dada', {
            vehicleId = vehicleId,
            charId = charId,
            keyType = keyType
        })
    end

    return true, 'Llave entregada'
end

--- Quita una llave a un personaje
---@param source number|nil
---@param vehicleId number
---@param charId number
---@return boolean, string
function Keys.RevokeKey(source, vehicleId, charId)
    -- Verificar que tiene la llave
    local hasKey, keyData = Keys.HasKey(charId, vehicleId)
    if not hasKey then
        return false, 'No tiene llave de este vehiculo'
    end

    -- No se puede revocar llave de propietario directamente
    if keyData.key_type == 'owner' then
        -- Verificar permisos
        if source then
            local hasPermission = AIT.RBAC and AIT.RBAC.HasPermission(source, 'vehicles.keys.revoke.owner')
            if not hasPermission then
                return false, 'No puedes revocar la llave del propietario'
            end
        end
    end

    -- Revocar
    MySQL.query.await([[
        UPDATE ait_vehicle_keys SET revoked_at = NOW()
        WHERE vehicle_id = ? AND char_id = ? AND revoked_at IS NULL
    ]], { vehicleId, charId })

    -- Limpiar cache
    if Keys.playerKeys[charId] then
        Keys.playerKeys[charId][vehicleId] = nil
    end
    if Keys.vehicleKeys[vehicleId] then
        Keys.vehicleKeys[vehicleId][charId] = nil
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.keys.revoked', {
            vehicleId = vehicleId,
            charId = charId,
        })
    end

    return true, 'Llave revocada'
end

--- Revoca todas las llaves de un vehiculo
---@param vehicleId number
---@return boolean, number
function Keys.RevokeAllKeys(vehicleId)
    local result = MySQL.query.await([[
        UPDATE ait_vehicle_keys SET revoked_at = NOW()
        WHERE vehicle_id = ? AND revoked_at IS NULL
    ]], { vehicleId })

    -- Limpiar cache
    Keys.vehicleKeys[vehicleId] = nil

    -- Limpiar de playerKeys
    for charId, vehicles in pairs(Keys.playerKeys) do
        if vehicles[vehicleId] then
            vehicles[vehicleId] = nil
        end
    end

    local count = result and result.affectedRows or 0

    if AIT.Log then
        AIT.Log.debug('VEHICLES.KEYS', 'Todas las llaves revocadas', {
            vehicleId = vehicleId,
            count = count
        })
    end

    return true, count
end

--- Obtiene todas las llaves de un personaje
---@param charId number
---@return table
function Keys.GetCharacterKeys(charId)
    local keys = MySQL.query.await([[
        SELECT k.*, v.model, v.plate, v.label as vehicle_label
        FROM ait_vehicle_keys k
        JOIN ait_vehicles v ON k.vehicle_id = v.vehicle_id
        WHERE k.char_id = ? AND k.revoked_at IS NULL
        AND (k.expires_at IS NULL OR k.expires_at > NOW())
        ORDER BY k.key_type, v.plate
    ]], { charId })

    local result = {}
    for _, key in ipairs(keys or {}) do
        table.insert(result, {
            keyId = key.key_id,
            vehicleId = key.vehicle_id,
            model = key.model,
            plate = key.plate,
            label = key.vehicle_label or key.label,
            keyType = key.key_type,
            canGiveCopy = key.can_give_copy == 1,
            canStart = key.can_start == 1,
            canLock = key.can_lock == 1,
            expiresAt = key.expires_at,
        })

        -- Actualizar cache
        Keys.CacheKey(charId, key.vehicle_id, key)
    end

    return result
end

--- Obtiene todas las llaves de un vehiculo
---@param vehicleId number
---@return table
function Keys.GetVehicleKeys(vehicleId)
    local keys = MySQL.query.await([[
        SELECT k.*, c.name as char_name
        FROM ait_vehicle_keys k
        LEFT JOIN ait_characters c ON k.char_id = c.char_id
        WHERE k.vehicle_id = ? AND k.revoked_at IS NULL
        AND (k.expires_at IS NULL OR k.expires_at > NOW())
        ORDER BY k.key_type, k.created_at
    ]], { vehicleId })

    return keys or {}
end

--- Dar una copia de llave a otro jugador
---@param source number
---@param vehicleId number
---@param targetCharId number
---@param options? table
---@return boolean, string
function Keys.GiveCopy(source, vehicleId, targetCharId, options)
    local charId = Keys.GetCharacterId(source)

    -- Verificar que tiene llave con permiso de dar copias
    local hasKey, keyData = Keys.HasKey(charId, vehicleId)
    if not hasKey then
        return false, 'No tienes llave de este vehiculo'
    end

    if keyData.can_give_copy ~= 1 and keyData.key_type ~= 'owner' then
        return false, 'Tu llave no permite hacer copias'
    end

    -- No darse llave a si mismo
    if charId == targetCharId then
        return false, 'No puedes darte llave a ti mismo'
    end

    -- Dar la copia
    return Keys.GiveKey(source, vehicleId, targetCharId, false, options)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- LOCKPICKING
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Intenta abrir un vehiculo con ganzua
---@param source number
---@param vehicleNetId number
---@param isAdvanced? boolean
---@return boolean, string
function Keys.AttemptLockpick(source, vehicleNetId, isAdvanced)
    local charId = Keys.GetCharacterId(source)

    -- Verificar item
    local requiredItem = isAdvanced and Keys.Config.advancedLockpickItem or Keys.Config.lockpickItem
    if AIT.Engines.inventory then
        local inventory = AIT.Engines.inventory.GetInventory('char', charId)
        local hasItem = false
        for _, item in ipairs(inventory) do
            if item.id == requiredItem then
                hasItem = true
                break
            end
        end
        if not hasItem then
            return false, 'Necesitas una ganzua'
        end
    end

    -- Obtener vehiculo
    local Vehicles = AIT.Engines.Vehicles
    local spawnData = Vehicles and Vehicles.spawned[vehicleNetId]

    if not spawnData then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar cooldown
    if not Keys.lockpickAttempts[source] then
        Keys.lockpickAttempts[source] = {}
    end

    local lastAttempt = Keys.lockpickAttempts[source][spawnData.vehicleId]
    if lastAttempt then
        local cooldown = os.time() - lastAttempt.time
        if cooldown < Keys.Config.lockpickCooldown then
            return false, 'Espera ' .. (Keys.Config.lockpickCooldown - cooldown) .. ' segundos'
        end

        -- Cooldown largo si muchos intentos fallidos
        if lastAttempt.attempts >= Keys.Config.maxLockpickAttempts then
            if cooldown < Keys.Config.lockpickCooldown * 5 then
                return false, 'Demasiados intentos fallidos. Espera mas tiempo.'
            end
            lastAttempt.attempts = 0
        end
    end

    -- Obtener dificultad del vehiculo
    local category = Keys.GetVehicleCategory(spawnData.entity)
    local difficulty = Keys.Config.categoryDifficulty[category] or { lockpick = 1.0, alarm = false }

    -- Calcular probabilidad
    local baseChance = Keys.Config.lockpickBaseChance
    if isAdvanced then
        baseChance = baseChance * 1.5
    end

    local chance = baseChance / difficulty.lockpick

    -- Aplicar habilidad del personaje si existe sistema de skills
    -- TODO: Integrar con sistema de habilidades

    -- Intentar
    local success = math.random(100) <= chance

    -- Registrar intento
    if not Keys.lockpickAttempts[source][spawnData.vehicleId] then
        Keys.lockpickAttempts[source][spawnData.vehicleId] = { attempts = 0, time = 0 }
    end
    Keys.lockpickAttempts[source][spawnData.vehicleId].attempts =
        Keys.lockpickAttempts[source][spawnData.vehicleId].attempts + 1
    Keys.lockpickAttempts[source][spawnData.vehicleId].time = os.time()

    -- Probabilidad de romper ganzua
    local breakChance = Keys.Config.lockpickBreakChance
    if isAdvanced then
        breakChance = breakChance * 0.5
    end

    if math.random(100) <= breakChance then
        -- Romper ganzua
        if AIT.Engines.inventory then
            AIT.Engines.inventory.RemoveItem(source, 'char', charId, requiredItem, 1)
        end

        if not success then
            -- Log intento
            Keys.LogTheftAttempt(spawnData.vehicleId, charId, 'lockpick', false, spawnData.entity)
            return false, 'La ganzua se rompio y no pudiste abrir el vehiculo'
        end
    end

    if success then
        -- Abrir vehiculo
        SetVehicleDoorsLocked(spawnData.entity, 1) -- Desbloqueado

        -- Dar llave temporal
        Keys.GiveKey(nil, spawnData.vehicleId, charId, false, {
            temp = true,
            duration = Keys.Config.tempKeyDuration,
            label = 'Llave temporal (robado)',
            canGiveCopy = false,
            canStart = false, -- Necesita hotwire
            canLock = true,
            canTrunk = true,
        })

        -- Alertar si tiene alarma
        if difficulty.alarm and Keys.Config.alertPoliceOnTheft then
            Keys.AlertPolice(spawnData, 'lockpick')
        end

        -- Alertar propietario
        if Keys.Config.alertOwnerOnTheft then
            Keys.AlertOwner(spawnData)
        end

        -- Log
        Keys.LogTheftAttempt(spawnData.vehicleId, charId, 'lockpick', true, spawnData.entity)

        -- Emitir evento
        if AIT.EventBus then
            AIT.EventBus.emit('vehicles.lockpicked', {
                vehicleId = spawnData.vehicleId,
                charId = charId,
                plate = spawnData.plate,
            })
        end

        return true, 'Abriste el vehiculo. Necesitas hacer puente para arrancarlo.'
    else
        -- Log intento fallido
        Keys.LogTheftAttempt(spawnData.vehicleId, charId, 'lockpick', false, spawnData.entity)
        return false, 'No pudiste abrir el vehiculo'
    end
end

--- Intenta hacer puente a un vehiculo
---@param source number
---@param vehicleNetId number
---@return boolean, string
function Keys.AttemptHotwire(source, vehicleNetId)
    local charId = Keys.GetCharacterId(source)

    -- Verificar item
    if AIT.Engines.inventory then
        local inventory = AIT.Engines.inventory.GetInventory('char', charId)
        local hasItem = false
        for _, item in ipairs(inventory) do
            if item.id == Keys.Config.hotwireKitItem then
                hasItem = true
                break
            end
        end
        if not hasItem then
            return false, 'Necesitas un kit de puente'
        end
    end

    -- Obtener vehiculo
    local Vehicles = AIT.Engines.Vehicles
    local spawnData = Vehicles and Vehicles.spawned[vehicleNetId]

    if not spawnData then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar que ya tiene llave (abrio el vehiculo)
    local hasKey, keyData = Keys.HasKey(charId, spawnData.vehicleId)
    if not hasKey then
        return false, 'Primero debes abrir el vehiculo'
    end

    if keyData.can_start == 1 then
        return false, 'Ya puedes arrancar este vehiculo'
    end

    -- Obtener dificultad
    local category = Keys.GetVehicleCategory(spawnData.entity)
    local difficulty = Keys.Config.categoryDifficulty[category] or { hotwire = 1.0, alarm = false }

    -- Calcular tiempo
    local hotwireTime = Keys.Config.hotwireBaseTime * difficulty.hotwire
    hotwireTime = math.max(Keys.Config.hotwireMinTime, hotwireTime)

    -- El minigame se hace en el cliente, aqui solo validamos el resultado
    -- TODO: Implementar validacion de minigame

    -- Simular exito basado en tiempo
    local success = math.random(100) <= (70 / difficulty.hotwire)

    if success then
        -- Actualizar llave para permitir arranque
        MySQL.query.await([[
            UPDATE ait_vehicle_keys SET can_start = 1
            WHERE vehicle_id = ? AND char_id = ? AND revoked_at IS NULL
        ]], { spawnData.vehicleId, charId })

        -- Actualizar cache
        if Keys.playerKeys[charId] and Keys.playerKeys[charId][spawnData.vehicleId] then
            Keys.playerKeys[charId][spawnData.vehicleId].can_start = 1
        end

        -- Alertar policia
        if difficulty.alarm and Keys.Config.alertPoliceOnTheft then
            if math.random(100) <= Keys.Config.hotwireAlertChance then
                Keys.AlertPolice(spawnData, 'hotwire')
            end
        end

        -- Log
        Keys.LogTheftAttempt(spawnData.vehicleId, charId, 'hotwire', true, spawnData.entity)

        -- Emitir evento
        if AIT.EventBus then
            AIT.EventBus.emit('vehicles.hotwired', {
                vehicleId = spawnData.vehicleId,
                charId = charId,
                plate = spawnData.plate,
            })
        end

        return true, 'Hiciste puente al vehiculo. Ahora puedes arrancarlo.'
    else
        -- Probabilidad de danar el sistema electrico
        if math.random(100) <= 30 then
            -- Danar motor
            local engineHealth = GetVehicleEngineHealth(spawnData.entity)
            SetVehicleEngineHealth(spawnData.entity, engineHealth - 100)
        end

        -- Log
        Keys.LogTheftAttempt(spawnData.vehicleId, charId, 'hotwire', false, spawnData.entity)

        return false, 'No pudiste hacer puente. El sistema puede estar danado.'
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ALERTAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Alerta a la policia sobre intento de robo
---@param spawnData table
---@param method string
function Keys.AlertPolice(spawnData, method)
    local coords = GetEntityCoords(spawnData.entity)

    -- Emitir evento para sistema de policia
    if AIT.EventBus then
        AIT.EventBus.emit('police.alert', {
            type = 'vehicle_theft',
            method = method,
            vehicleId = spawnData.vehicleId,
            plate = spawnData.plate,
            model = spawnData.model,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            radius = Keys.Config.hotwireAlertRadius,
        })
    end

    if AIT.Log then
        AIT.Log.info('VEHICLES.KEYS', 'Alerta de robo enviada a policia', {
            plate = spawnData.plate,
            method = method
        })
    end
end

--- Alerta al propietario sobre intento de robo
---@param spawnData table
function Keys.AlertOwner(spawnData)
    local Vehicles = AIT.Engines.Vehicles
    local vehicle = Vehicles and Vehicles.GetVehicleData(spawnData.vehicleId)

    if not vehicle then return end

    if vehicle.owner_type == 'char' then
        -- Buscar si el propietario esta online
        local ownerSource = Keys.GetSourceByCharId(vehicle.owner_id)

        if ownerSource then
            -- Notificar
            TriggerClientEvent('ait:notify', ownerSource, {
                type = 'warning',
                title = 'Alerta de Vehiculo',
                message = 'Tu vehiculo ' .. vehicle.plate .. ' esta siendo robado!',
                duration = 10000,
            })
        end
    end
end

--- Registra intento de robo
---@param vehicleId number
---@param charId number
---@param method string
---@param success boolean
---@param entity number
function Keys.LogTheftAttempt(vehicleId, charId, method, success, entity)
    local coords = DoesEntityExist(entity) and GetEntityCoords(entity) or vector3(0, 0, 0)

    MySQL.insert([[
        INSERT INTO ait_vehicle_theft_log
        (vehicle_id, char_id, method, success, location)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        vehicleId,
        charId,
        method,
        success and 1 or 0,
        json.encode({ x = coords.x, y = coords.y, z = coords.z })
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Guarda llave en cache
---@param charId number
---@param vehicleId number
---@param keyData table
function Keys.CacheKey(charId, vehicleId, keyData)
    -- Cache por jugador
    if not Keys.playerKeys[charId] then
        Keys.playerKeys[charId] = {}
    end
    Keys.playerKeys[charId][vehicleId] = {
        keyId = keyData.key_id,
        keyType = keyData.key_type,
        can_give_copy = keyData.can_give_copy,
        can_start = keyData.can_start,
        can_lock = keyData.can_lock,
        can_trunk = keyData.can_trunk,
        expiresAt = keyData.expires_at and os.time(keyData.expires_at) or nil,
    }

    -- Cache por vehiculo
    if not Keys.vehicleKeys[vehicleId] then
        Keys.vehicleKeys[vehicleId] = {}
    end
    Keys.vehicleKeys[vehicleId][charId] = Keys.playerKeys[charId][vehicleId]
end

--- Limpia llaves temporales expiradas
function Keys.CleanupExpiredKeys()
    MySQL.query.await([[
        UPDATE ait_vehicle_keys SET revoked_at = NOW()
        WHERE expires_at IS NOT NULL AND expires_at < NOW() AND revoked_at IS NULL
    ]])

    -- Limpiar cache
    local now = os.time()
    for charId, vehicles in pairs(Keys.playerKeys) do
        for vehicleId, keyData in pairs(vehicles) do
            if keyData.expiresAt and keyData.expiresAt < now then
                vehicles[vehicleId] = nil
                if Keys.vehicleKeys[vehicleId] then
                    Keys.vehicleKeys[vehicleId][charId] = nil
                end
            end
        end
    end
end

--- Refresca el cache
function Keys.RefreshCache()
    Keys.playerKeys = {}
    Keys.vehicleKeys = {}
end

--- Obtiene el ID del personaje de un jugador
---@param source number
---@return number|nil
function Keys.GetCharacterId(source)
    if AIT.State then
        local playerState = AIT.State.get('player:' .. source)
        if playerState and playerState.charId then
            return playerState.charId
        end
    end

    if AIT.QBCore then
        local Player = AIT.QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid
        end
    end

    return nil
end

--- Obtiene el source de un charId
---@param charId number
---@return number|nil
function Keys.GetSourceByCharId(charId)
    for _, playerId in ipairs(GetPlayers()) do
        local pCharId = Keys.GetCharacterId(tonumber(playerId))
        if pCharId == charId then
            return tonumber(playerId)
        end
    end
    return nil
end

--- Obtiene la categoria de un vehiculo
---@param vehicleEntity number
---@return string
function Keys.GetVehicleCategory(vehicleEntity)
    local class = GetVehicleClass(vehicleEntity)
    local Vehicles = AIT.Engines.Vehicles
    if Vehicles and Vehicles.Config and Vehicles.Config.classes then
        return Vehicles.Config.classes[class] or 'sedan'
    end
    return 'sedan'
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ═══════════════════════════════════════════════════════════════════════════════════════

Keys.API = {
    HasKey = Keys.HasKey,
    CanStart = Keys.CanStart,
    CanLock = Keys.CanLock,
    GiveKey = Keys.GiveKey,
    RevokeKey = Keys.RevokeKey,
    RevokeAllKeys = Keys.RevokeAllKeys,
    GetCharacterKeys = Keys.GetCharacterKeys,
    GetVehicleKeys = Keys.GetVehicleKeys,
    GiveCopy = Keys.GiveCopy,
    AttemptLockpick = Keys.AttemptLockpick,
    AttemptHotwire = Keys.AttemptHotwire,
}

-- Registrar en namespace
AIT.Engines.Vehicles.Keys = Keys

return Keys
