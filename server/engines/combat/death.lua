-- =================================================================================================
-- ait-qb DEATH ENGINE
-- Sistema de muerte con bleedout, revive, respawn, hospitales y penalizaciones
-- Optimizado para 2048 slots
-- =================================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Combat = AIT.Engines.Combat or {}

local Death = {
    -- Jugadores muertos/en bleedout
    deadPlayers = {},
    -- Jugadores en proceso de revive
    reviveInProgress = {},
    -- Timers de respawn
    respawnTimers = {},
    -- Cooldowns de respawn
    respawnCooldowns = {},
    -- Cache de hospitales
    hospitals = {},
    -- Penalizaciones pendientes
    pendingPenalties = {},
}

-- =================================================================================================
-- CONFIGURACION
-- =================================================================================================

Death.Config = {
    -- Bleedout
    BLEEDOUT_ENABLED = true,
    BLEEDOUT_DURATION = 300000,       -- 5 minutos en bleedout (ms)
    BLEEDOUT_HP_LOSS = 1,             -- HP perdido por segundo
    BLEEDOUT_MIN_HP = 0,              -- HP minimo durante bleedout

    -- Revive
    REVIVE_TIME = 10000,              -- Tiempo para completar revive (ms)
    REVIVE_CANCEL_DISTANCE = 3.0,     -- Distancia maxima para revive
    REVIVE_HEALTH_RESTORED = 50,      -- Salud al ser revivido
    REVIVE_BY_PLAYER_ENABLED = true,  -- Permitir revive por jugadores
    REVIVE_ITEMS_REQUIRED = {},       -- Items requeridos para revive (configurable)

    -- Respawn
    RESPAWN_ENABLED = true,
    RESPAWN_TIME_MIN = 30000,         -- Tiempo minimo antes de poder respawnear (ms)
    RESPAWN_TIME_MAX = 300000,        -- Tiempo maximo antes de forzar respawn (ms)
    RESPAWN_COOLDOWN = 60000,         -- Cooldown entre respawns (ms)
    RESPAWN_IN_HOSPITAL = true,       -- Respawnear en hospital
    RESPAWN_RANDOM_HOSPITAL = false,  -- Hospital aleatorio o mas cercano

    -- Hospitales
    HOSPITAL_HEAL_TIME = 5000,        -- Tiempo de curacion en hospital (ms)
    HOSPITAL_HEAL_COST = 500,         -- Costo base de curacion
    HOSPITAL_MAX_COST = 5000,         -- Costo maximo
    HOSPITAL_COST_PER_DEATH = 100,    -- Incremento por muerte reciente

    -- EMS
    EMS_ENABLED = true,
    EMS_JOBS = { 'ems', 'doctor', 'paramedic' },
    EMS_REVIVE_TIME = 5000,           -- Tiempo de revive por EMS (ms)
    EMS_FULL_HEAL = true,             -- EMS restaura salud completa
    EMS_NOTIFICATION_RADIUS = 500.0,  -- Radio para notificar a EMS

    -- Penalizaciones
    PENALTY_ENABLED = true,
    PENALTY_INVENTORY_LOSS = false,   -- Perder inventario al morir
    PENALTY_INVENTORY_LOSS_CHANCE = 0.0, -- Probabilidad de perder items
    PENALTY_MONEY_LOSS = true,        -- Perder dinero al morir
    PENALTY_MONEY_LOSS_PERCENT = 5,   -- Porcentaje de dinero perdido
    PENALTY_MONEY_LOSS_MAX = 5000,    -- Maximo dinero perdido
    PENALTY_XP_LOSS = false,          -- Perder XP al morir
    PENALTY_XP_LOSS_PERCENT = 1,      -- Porcentaje de XP perdido
    PENALTY_COOLDOWN_REDUCTION = true, -- Reducir cooldowns al morir

    -- Posiciones de hospitales
    HOSPITAL_LOCATIONS = {
        {
            id = 'pillbox',
            name = 'Pillbox Hill Medical Center',
            coords = { x = 311.7, y = -590.3, z = 43.3 },
            heading = 250.0,
            blip = true,
        },
        {
            id = 'sandy',
            name = 'Sandy Shores Medical Center',
            coords = { x = 1839.0, y = 3672.0, z = 34.3 },
            heading = 30.0,
            blip = true,
        },
        {
            id = 'paleto',
            name = 'Paleto Bay Medical Center',
            coords = { x = -247.0, y = 6331.0, z = 32.4 },
            heading = 310.0,
            blip = true,
        },
        {
            id = 'mount_zonah',
            name = 'Mount Zonah Medical Center',
            coords = { x = -497.0, y = -336.0, z = 34.5 },
            heading = 260.0,
            blip = true,
        },
    },
}

-- =================================================================================================
-- INICIALIZACION
-- =================================================================================================

function Death.Initialize()
    -- Crear tablas si no existen
    Death.EnsureTables()

    -- Cargar configuracion
    Death.LoadConfig()

    -- Cargar hospitales
    Death.LoadHospitals()

    -- Registrar jobs del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('death_update_bleedout', {
            interval = 1,
            fn = Death.UpdateBleedout
        })

        AIT.Scheduler.register('death_check_respawns', {
            interval = 5,
            fn = Death.CheckForcedRespawns
        })

        AIT.Scheduler.register('death_cleanup', {
            interval = 60,
            fn = Death.CleanupExpired
        })
    end

    -- Thread de bleedout
    CreateThread(function()
        while true do
            Wait(1000)
            Death.UpdateBleedout()
        end
    end)

    -- Suscribirse a eventos
    if AIT.EventBus then
        AIT.EventBus.on('combat.player.killed', Death.OnPlayerKilled)
        AIT.EventBus.on('combat.knockdown.start', Death.OnKnockdown)
        AIT.EventBus.on('player.disconnected', Death.OnPlayerDisconnect)
        AIT.EventBus.on('character.selected', Death.OnCharacterSelected)
    end

    if AIT.Log then
        AIT.Log.info('DEATH', 'Death system initialized')
    end

    return true
end

function Death.EnsureTables()
    -- Tabla de registro de muertes
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_death_log (
            death_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            char_id BIGINT NOT NULL,
            killer_char_id BIGINT NULL,
            cause VARCHAR(64) NOT NULL,
            weapon_id VARCHAR(64) NULL,
            position JSON NULL,
            respawn_type ENUM('hospital', 'revive_player', 'revive_ems', 'admin', 'timeout') NULL,
            respawn_location VARCHAR(64) NULL,
            respawn_ts DATETIME NULL,
            bleedout_duration INT NULL,
            penalties_applied JSON NULL,
            meta JSON NULL,
            KEY idx_ts (ts),
            KEY idx_char (char_id),
            KEY idx_killer (killer_char_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estadisticas de muerte
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_death_stats (
            char_id BIGINT PRIMARY KEY,
            total_deaths INT NOT NULL DEFAULT 0,
            deaths_today INT NOT NULL DEFAULT 0,
            deaths_this_week INT NOT NULL DEFAULT 0,
            last_death DATETIME NULL,
            total_hospital_bills BIGINT NOT NULL DEFAULT 0,
            total_money_lost BIGINT NOT NULL DEFAULT 0,
            total_items_lost INT NOT NULL DEFAULT 0,
            total_revives_received INT NOT NULL DEFAULT 0,
            avg_bleedout_time INT NOT NULL DEFAULT 0,
            last_reset_daily DATE NULL,
            last_reset_weekly DATE NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de configuracion de hospitales
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_hospitals (
            hospital_id VARCHAR(32) PRIMARY KEY,
            name VARCHAR(128) NOT NULL,
            position JSON NOT NULL,
            heading FLOAT NOT NULL DEFAULT 0,
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            base_cost INT NOT NULL DEFAULT 500,
            has_ems TINYINT(1) NOT NULL DEFAULT 1,
            services JSON NULL,
            meta JSON NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Death.LoadConfig()
    local configs = MySQL.query.await([[
        SELECT * FROM ait_combat_config WHERE config_key LIKE 'death.%'
    ]])

    for _, cfg in ipairs(configs or {}) do
        local key = cfg.config_key:gsub('death%.', ''):upper()
        local value = cfg.config_value

        if value:match('^%d+%.?%d*$') then
            value = tonumber(value)
        elseif value:match('^%{') or value:match('^%[') then
            value = json.decode(value)
        elseif value == 'true' then
            value = true
        elseif value == 'false' then
            value = false
        end

        if Death.Config[key] ~= nil then
            Death.Config[key] = value
        end
    end
end

function Death.LoadHospitals()
    -- Cargar hospitales de la base de datos
    local hospitals = MySQL.query.await([[
        SELECT * FROM ait_hospitals WHERE is_active = 1
    ]])

    if hospitals and #hospitals > 0 then
        Death.hospitals = {}
        for _, h in ipairs(hospitals) do
            Death.hospitals[h.hospital_id] = {
                id = h.hospital_id,
                name = h.name,
                coords = json.decode(h.position),
                heading = h.heading,
                cost = h.base_cost,
                hasEms = h.has_ems == 1,
                services = h.services and json.decode(h.services),
            }
        end
    else
        -- Usar hospitales por defecto y guardarlos
        Death.hospitals = {}
        for _, h in ipairs(Death.Config.HOSPITAL_LOCATIONS) do
            Death.hospitals[h.id] = {
                id = h.id,
                name = h.name,
                coords = h.coords,
                heading = h.heading,
                cost = Death.Config.HOSPITAL_HEAL_COST,
                hasEms = true,
            }

            MySQL.insert([[
                INSERT IGNORE INTO ait_hospitals
                (hospital_id, name, position, heading, base_cost)
                VALUES (?, ?, ?, ?, ?)
            ]], {
                h.id, h.name, json.encode(h.coords), h.heading,
                Death.Config.HOSPITAL_HEAL_COST
            })
        end
    end
end

-- =================================================================================================
-- SISTEMA DE MUERTE
-- =================================================================================================

--- Mata a un jugador
---@param source number Server ID
---@param cause string Causa de muerte
---@param killerId? number Server ID del asesino
---@param weaponId? string ID del arma
function Death.Kill(source, cause, killerId, weaponId)
    if Death.IsDead(source) then return end

    local charId = Death.GetCharId(source)
    local killerCharId = killerId and Death.GetCharId(killerId)

    -- Registrar muerte
    local deathId = Death.LogDeath(charId, killerCharId, cause, weaponId, source)

    -- Iniciar estado de muerte/bleedout
    Death.deadPlayers[source] = {
        deathId = deathId,
        charId = charId,
        startTime = os.time() * 1000,
        cause = cause,
        killerId = killerId,
        killerCharId = killerCharId,
        weaponId = weaponId,
        inBleedout = Death.Config.BLEEDOUT_ENABLED,
        canRespawn = false,
        respawnAvailableAt = os.time() * 1000 + Death.Config.RESPAWN_TIME_MIN,
        forcedRespawnAt = os.time() * 1000 + Death.Config.RESPAWN_TIME_MAX,
    }

    -- Calcular penalizaciones
    if Death.Config.PENALTY_ENABLED then
        Death.CalculatePenalties(source, charId)
    end

    -- Notificar al cliente
    TriggerClientEvent('ait:death:died', source, {
        deathId = deathId,
        cause = cause,
        killerId = killerId,
        bleedoutEnabled = Death.Config.BLEEDOUT_ENABLED,
        bleedoutDuration = Death.Config.BLEEDOUT_DURATION,
        respawnTime = Death.Config.RESPAWN_TIME_MIN,
    })

    -- Notificar a EMS cercanos
    if Death.Config.EMS_ENABLED then
        Death.NotifyEMS(source)
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('death.player.died', {
            source = source,
            charId = charId,
            deathId = deathId,
            cause = cause,
            killerId = killerId,
        })
    end

    if AIT.Log then
        AIT.Log.info('DEATH', 'Player died', {
            source = source,
            charId = charId,
            cause = cause,
            killer = killerCharId,
        })
    end
end

--- Verifica si un jugador esta muerto
---@param source number Server ID
---@return boolean
function Death.IsDead(source)
    return Death.deadPlayers[source] ~= nil
end

--- Obtiene el estado de muerte de un jugador
---@param source number Server ID
---@return table|nil
function Death.GetDeathState(source)
    return Death.deadPlayers[source]
end

-- =================================================================================================
-- SISTEMA DE BLEEDOUT
-- =================================================================================================

--- Actualiza el estado de bleedout de todos los jugadores muertos
function Death.UpdateBleedout()
    local currentTime = os.time() * 1000

    for source, state in pairs(Death.deadPlayers) do
        if state.inBleedout then
            local elapsed = currentTime - state.startTime

            -- Verificar si termino el bleedout
            if elapsed >= Death.Config.BLEEDOUT_DURATION then
                state.inBleedout = false
                state.canRespawn = true

                TriggerClientEvent('ait:death:bleedoutEnded', source)

                if AIT.EventBus then
                    AIT.EventBus.emit('death.bleedout.ended', {
                        source = source,
                        charId = state.charId,
                    })
                end
            else
                -- Actualizar tiempo restante al cliente
                local remaining = Death.Config.BLEEDOUT_DURATION - elapsed
                TriggerClientEvent('ait:death:bleedoutUpdate', source, {
                    remaining = remaining,
                    elapsed = elapsed,
                })
            end
        end

        -- Verificar si puede respawnear
        if not state.canRespawn and currentTime >= state.respawnAvailableAt then
            state.canRespawn = true
            TriggerClientEvent('ait:death:canRespawn', source)
        end
    end
end

--- Verifica si un jugador puede ser revivido
---@param source number Server ID
---@return boolean, string
function Death.CanBeRevived(source)
    local state = Death.deadPlayers[source]

    if not state then
        return false, 'El jugador no esta muerto'
    end

    if Death.reviveInProgress[source] then
        return false, 'Ya hay un revive en progreso'
    end

    return true, 'ok'
end

-- =================================================================================================
-- SISTEMA DE REVIVE
-- =================================================================================================

--- Inicia el proceso de revive
---@param healer number Server ID del sanador
---@param target number Server ID del objetivo
---@param isEms boolean Si es personal medico
---@return boolean, string
function Death.StartRevive(healer, target, isEms)
    local canRevive, reason = Death.CanBeRevived(target)
    if not canRevive then
        return false, reason
    end

    -- Verificar si el sanador es EMS
    if not isEms and not Death.Config.REVIVE_BY_PLAYER_ENABLED then
        return false, 'Solo EMS puede revivir'
    end

    -- Verificar items requeridos (solo para no-EMS)
    if not isEms and #Death.Config.REVIVE_ITEMS_REQUIRED > 0 then
        local hasItems = Death.CheckReviveItems(healer)
        if not hasItems then
            return false, 'No tienes los items necesarios'
        end
    end

    -- Verificar distancia
    local healerPed = GetPlayerPed(healer)
    local targetPed = GetPlayerPed(target)
    local healerCoords = GetEntityCoords(healerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local distance = #(healerCoords - targetCoords)

    if distance > Death.Config.REVIVE_CANCEL_DISTANCE then
        return false, 'Estas muy lejos del jugador'
    end

    -- Iniciar revive
    local reviveTime = isEms and Death.Config.EMS_REVIVE_TIME or Death.Config.REVIVE_TIME

    Death.reviveInProgress[target] = {
        healer = healer,
        startTime = os.time() * 1000,
        duration = reviveTime,
        isEms = isEms,
    }

    -- Notificar a ambos jugadores
    TriggerClientEvent('ait:death:reviveStarted', healer, {
        target = target,
        duration = reviveTime,
    })

    TriggerClientEvent('ait:death:beingRevived', target, {
        healer = healer,
        duration = reviveTime,
    })

    -- Iniciar timer de revive
    SetTimeout(reviveTime, function()
        Death.CompleteRevive(healer, target, isEms)
    end)

    if AIT.EventBus then
        AIT.EventBus.emit('death.revive.started', {
            healer = healer,
            target = target,
            isEms = isEms,
        })
    end

    return true, 'ok'
end

--- Completa el proceso de revive
---@param healer number Server ID del sanador
---@param target number Server ID del objetivo
---@param isEms boolean Si es personal medico
function Death.CompleteRevive(healer, target, isEms)
    local reviveState = Death.reviveInProgress[target]
    if not reviveState or reviveState.healer ~= healer then
        return
    end

    local deathState = Death.deadPlayers[target]
    if not deathState then
        Death.reviveInProgress[target] = nil
        return
    end

    -- Verificar distancia final
    local healerPed = GetPlayerPed(healer)
    local targetPed = GetPlayerPed(target)
    local healerCoords = GetEntityCoords(healerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local distance = #(healerCoords - targetCoords)

    if distance > Death.Config.REVIVE_CANCEL_DISTANCE then
        Death.CancelRevive(healer, target, 'Distancia excedida')
        return
    end

    -- Consumir items si no es EMS
    if not isEms and #Death.Config.REVIVE_ITEMS_REQUIRED > 0 then
        Death.ConsumeReviveItems(healer)
    end

    -- Calcular salud a restaurar
    local healthRestored = Death.Config.REVIVE_HEALTH_RESTORED
    if isEms and Death.Config.EMS_FULL_HEAL then
        healthRestored = 200 -- Salud maxima
    end

    -- Revivir al jugador
    Death.Revive(target, 'revive_' .. (isEms and 'ems' or 'player'), healthRestored)

    -- Actualizar log de muerte
    local respawnType = isEms and 'revive_ems' or 'revive_player'
    Death.UpdateDeathLog(deathState.deathId, respawnType, nil, deathState.startTime)

    -- Actualizar estadisticas
    Death.IncrementStat(target, 'total_revives_received')

    -- Limpiar estados
    Death.reviveInProgress[target] = nil
    Death.deadPlayers[target] = nil

    -- Notificar
    TriggerClientEvent('ait:death:reviveCompleted', healer, { target = target })
    TriggerClientEvent('ait:death:revived', target, {
        healer = healer,
        health = healthRestored,
    })

    if AIT.EventBus then
        AIT.EventBus.emit('death.revive.completed', {
            healer = healer,
            target = target,
            isEms = isEms,
        })
    end

    if AIT.Log then
        AIT.Log.info('DEATH', 'Player revived', {
            healer = healer,
            target = target,
            isEms = isEms,
        })
    end
end

--- Cancela el proceso de revive
---@param healer number Server ID del sanador
---@param target number Server ID del objetivo
---@param reason string Razon de cancelacion
function Death.CancelRevive(healer, target, reason)
    Death.reviveInProgress[target] = nil

    TriggerClientEvent('ait:death:reviveCancelled', healer, { reason = reason })
    TriggerClientEvent('ait:death:reviveCancelled', target, { reason = reason })

    if AIT.EventBus then
        AIT.EventBus.emit('death.revive.cancelled', {
            healer = healer,
            target = target,
            reason = reason,
        })
    end
end

--- Revive a un jugador directamente
---@param source number Server ID
---@param respawnType string Tipo de respawn
---@param health? number Salud inicial
function Death.Revive(source, respawnType, health)
    health = health or Death.Config.REVIVE_HEALTH_RESTORED

    -- Restaurar salud
    if AIT.Engines.Combat then
        AIT.Engines.Combat.SetHealth(source, health)
        AIT.Engines.Combat.SetArmor(source, 0)
    else
        local ped = GetPlayerPed(source)
        SetEntityHealth(ped, health + 100)
        SetPedArmour(ped, 0)
    end

    -- Notificar al cliente para levantar
    TriggerClientEvent('ait:death:standup', source)
end

--- Verifica si el sanador tiene los items necesarios
---@param healer number Server ID
---@return boolean
function Death.CheckReviveItems(healer)
    if not AIT.Engines.Inventory then return true end

    local charId = Death.GetCharId(healer)
    if not charId then return false end

    for _, itemId in ipairs(Death.Config.REVIVE_ITEMS_REQUIRED) do
        local inventory = AIT.Engines.Inventory.GetInventory('char', charId)
        local hasItem = false

        for _, item in ipairs(inventory) do
            if item.id == itemId and item.quantity > 0 then
                hasItem = true
                break
            end
        end

        if not hasItem then
            return false
        end
    end

    return true
end

--- Consume los items de revive
---@param healer number Server ID
function Death.ConsumeReviveItems(healer)
    if not AIT.Engines.Inventory then return end

    local charId = Death.GetCharId(healer)
    if not charId then return end

    for _, itemId in ipairs(Death.Config.REVIVE_ITEMS_REQUIRED) do
        AIT.Engines.Inventory.RemoveItem(healer, 'char', charId, itemId, 1)
    end
end

-- =================================================================================================
-- SISTEMA DE RESPAWN
-- =================================================================================================

--- Solicita respawn en hospital
---@param source number Server ID
---@param hospitalId? string ID del hospital especifico
---@return boolean, string
function Death.RequestRespawn(source, hospitalId)
    local state = Death.deadPlayers[source]

    if not state then
        return false, 'No estas muerto'
    end

    if not state.canRespawn then
        local remaining = (state.respawnAvailableAt - os.time() * 1000) / 1000
        return false, 'Debes esperar ' .. math.ceil(remaining) .. ' segundos'
    end

    -- Verificar cooldown
    local cooldownKey = tostring(source)
    if Death.respawnCooldowns[cooldownKey] and Death.respawnCooldowns[cooldownKey] > os.time() * 1000 then
        return false, 'Debes esperar antes de respawnear de nuevo'
    end

    -- Determinar hospital
    local hospital = nil
    if hospitalId and Death.hospitals[hospitalId] then
        hospital = Death.hospitals[hospitalId]
    elseif Death.Config.RESPAWN_RANDOM_HOSPITAL then
        hospital = Death.GetRandomHospital()
    else
        hospital = Death.GetNearestHospital(source)
    end

    if not hospital then
        return false, 'No hay hospitales disponibles'
    end

    -- Calcular costo
    local cost = Death.CalculateHospitalCost(source)

    -- Aplicar penalizaciones pendientes
    Death.ApplyPenalties(source, state.charId)

    -- Cobrar hospital
    if cost > 0 and AIT.Engines.Economy then
        local charId = state.charId
        local balance = AIT.Engines.Economy.GetBalance('char', charId, 'bank')

        if balance >= cost then
            AIT.Engines.Economy.RemoveMoney(source, charId, cost, 'bank', 'hospital', 'Factura de hospital')
            Death.IncrementStat(source, 'total_hospital_bills', cost)
        else
            -- Cobrar lo que tenga
            if balance > 0 then
                AIT.Engines.Economy.RemoveMoney(source, charId, balance, 'bank', 'hospital', 'Factura de hospital')
                Death.IncrementStat(source, 'total_hospital_bills', balance)
            end
        end
    end

    -- Respawnear
    Death.DoRespawn(source, hospital, 'hospital')

    return true, 'ok'
end

--- Ejecuta el respawn
---@param source number Server ID
---@param hospital table Datos del hospital
---@param respawnType string Tipo de respawn
function Death.DoRespawn(source, hospital, respawnType)
    local state = Death.deadPlayers[source]
    if not state then return end

    -- Actualizar log de muerte
    local bleedoutDuration = nil
    if state.inBleedout == false then
        bleedoutDuration = (os.time() * 1000 - state.startTime)
    end
    Death.UpdateDeathLog(state.deathId, respawnType, hospital.id, state.startTime)

    -- Limpiar estados
    Death.deadPlayers[source] = nil
    Death.reviveInProgress[source] = nil

    -- Establecer cooldown
    Death.respawnCooldowns[tostring(source)] = os.time() * 1000 + Death.Config.RESPAWN_COOLDOWN

    -- Teleportar al hospital
    local ped = GetPlayerPed(source)
    SetEntityCoords(ped, hospital.coords.x, hospital.coords.y, hospital.coords.z, false, false, false, false)
    SetEntityHeading(ped, hospital.heading)

    -- Restaurar salud basica
    Wait(100)
    Death.Revive(source, respawnType, Death.Config.REVIVE_HEALTH_RESTORED)

    -- Notificar
    TriggerClientEvent('ait:death:respawned', source, {
        hospital = hospital.name,
        coords = hospital.coords,
    })

    if AIT.EventBus then
        AIT.EventBus.emit('death.player.respawned', {
            source = source,
            charId = state.charId,
            hospital = hospital.id,
            respawnType = respawnType,
        })
    end

    if AIT.Log then
        AIT.Log.info('DEATH', 'Player respawned', {
            source = source,
            hospital = hospital.id,
        })
    end
end

--- Verifica respawns forzados
function Death.CheckForcedRespawns()
    local currentTime = os.time() * 1000

    for source, state in pairs(Death.deadPlayers) do
        if currentTime >= state.forcedRespawnAt then
            local hospital = Death.GetNearestHospital(source)
            if hospital then
                Death.DoRespawn(source, hospital, 'timeout')
            end
        end
    end
end

-- =================================================================================================
-- SISTEMA DE HOSPITALES
-- =================================================================================================

--- Obtiene el hospital mas cercano a un jugador
---@param source number Server ID
---@return table|nil
function Death.GetNearestHospital(source)
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local nearest = nil
    local nearestDist = math.huge

    for _, hospital in pairs(Death.hospitals) do
        local dist = #(playerCoords - vector3(hospital.coords.x, hospital.coords.y, hospital.coords.z))
        if dist < nearestDist then
            nearestDist = dist
            nearest = hospital
        end
    end

    return nearest
end

--- Obtiene un hospital aleatorio
---@return table|nil
function Death.GetRandomHospital()
    local hospitalList = {}
    for _, h in pairs(Death.hospitals) do
        table.insert(hospitalList, h)
    end

    if #hospitalList == 0 then return nil end

    return hospitalList[math.random(#hospitalList)]
end

--- Calcula el costo de hospital
---@param source number Server ID
---@return number
function Death.CalculateHospitalCost(source)
    local baseCost = Death.Config.HOSPITAL_HEAL_COST
    local charId = Death.GetCharId(source)

    if not charId then return baseCost end

    -- Obtener muertes recientes
    local stats = MySQL.query.await([[
        SELECT deaths_today FROM ait_death_stats WHERE char_id = ?
    ]], { charId })

    local deathsToday = stats and stats[1] and stats[1].deaths_today or 0
    local additionalCost = deathsToday * Death.Config.HOSPITAL_COST_PER_DEATH

    local totalCost = baseCost + additionalCost

    return math.min(totalCost, Death.Config.HOSPITAL_MAX_COST)
end

-- =================================================================================================
-- SISTEMA DE EMS
-- =================================================================================================

--- Notifica a EMS cercanos sobre una muerte
---@param source number Server ID
function Death.NotifyEMS(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)

    local emsPlayers = Death.GetOnlineEMS()

    for _, emsSource in ipairs(emsPlayers) do
        local emsPed = GetPlayerPed(emsSource)
        local emsCoords = GetEntityCoords(emsPed)
        local distance = #(coords - emsCoords)

        if distance <= Death.Config.EMS_NOTIFICATION_RADIUS then
            TriggerClientEvent('ait:death:emsNotification', emsSource, {
                target = source,
                coords = { x = coords.x, y = coords.y, z = coords.z },
                distance = distance,
            })
        end
    end
end

--- Obtiene los jugadores EMS conectados
---@return table
function Death.GetOnlineEMS()
    local emsPlayers = {}

    if not AIT.Core then return emsPlayers end

    for _, playerId in ipairs(GetPlayers()) do
        local player = AIT.Core.GetPlayer(tonumber(playerId))
        if player and player.character and player.character.job then
            for _, emsJob in ipairs(Death.Config.EMS_JOBS) do
                if player.character.job == emsJob then
                    table.insert(emsPlayers, tonumber(playerId))
                    break
                end
            end
        end
    end

    return emsPlayers
end

--- Verifica si un jugador es EMS
---@param source number Server ID
---@return boolean
function Death.IsEMS(source)
    if not AIT.Core then return false end

    local player = AIT.Core.GetPlayer(source)
    if not player or not player.character or not player.character.job then
        return false
    end

    for _, emsJob in ipairs(Death.Config.EMS_JOBS) do
        if player.character.job == emsJob then
            return true
        end
    end

    return false
end

-- =================================================================================================
-- SISTEMA DE PENALIZACIONES
-- =================================================================================================

--- Calcula las penalizaciones por muerte
---@param source number Server ID
---@param charId number ID del personaje
function Death.CalculatePenalties(source, charId)
    local penalties = {
        money = 0,
        items = {},
        xp = 0,
    }

    -- Penalizacion de dinero
    if Death.Config.PENALTY_MONEY_LOSS then
        local balance = 0
        if AIT.Engines.Economy then
            balance = AIT.Engines.Economy.GetBalance('char', charId, 'cash')
        end

        local loss = math.floor(balance * (Death.Config.PENALTY_MONEY_LOSS_PERCENT / 100))
        penalties.money = math.min(loss, Death.Config.PENALTY_MONEY_LOSS_MAX)
    end

    -- Penalizacion de items (si esta activa)
    if Death.Config.PENALTY_INVENTORY_LOSS and math.random() < Death.Config.PENALTY_INVENTORY_LOSS_CHANCE then
        -- Implementar logica de perdida de items
        -- Por ahora solo marcamos que se perdera algo
        penalties.items = {}
    end

    -- Penalizacion de XP
    if Death.Config.PENALTY_XP_LOSS then
        -- Implementar logica de perdida de XP
        penalties.xp = 0
    end

    Death.pendingPenalties[source] = penalties
end

--- Aplica las penalizaciones pendientes
---@param source number Server ID
---@param charId number ID del personaje
function Death.ApplyPenalties(source, charId)
    local penalties = Death.pendingPenalties[source]
    if not penalties then return end

    local appliedPenalties = {}

    -- Aplicar penalizacion de dinero
    if penalties.money > 0 and AIT.Engines.Economy then
        AIT.Engines.Economy.RemoveMoney(source, charId, penalties.money, 'cash', 'death_penalty', 'Penalizacion por muerte')
        appliedPenalties.money = penalties.money
        Death.IncrementStat(source, 'total_money_lost', penalties.money)
    end

    -- Aplicar penalizacion de items
    if #penalties.items > 0 and AIT.Engines.Inventory then
        for _, item in ipairs(penalties.items) do
            AIT.Engines.Inventory.RemoveItem(source, 'char', charId, item.id, item.quantity)
        end
        appliedPenalties.items = penalties.items
        Death.IncrementStat(source, 'total_items_lost', #penalties.items)
    end

    -- Notificar al jugador
    if next(appliedPenalties) then
        TriggerClientEvent('ait:death:penaltiesApplied', source, appliedPenalties)
    end

    Death.pendingPenalties[source] = nil

    return appliedPenalties
end

-- =================================================================================================
-- LOGGING Y ESTADISTICAS
-- =================================================================================================

--- Registra una muerte en la base de datos
---@param charId number ID del personaje
---@param killerCharId number|nil ID del asesino
---@param cause string Causa de muerte
---@param weaponId string|nil ID del arma
---@param source number Server ID
---@return number ID del registro
function Death.LogDeath(charId, killerCharId, cause, weaponId, source)
    local position = nil
    if source then
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        position = json.encode({ x = coords.x, y = coords.y, z = coords.z })
    end

    local deathId = MySQL.insert.await([[
        INSERT INTO ait_death_log
        (char_id, killer_char_id, cause, weapon_id, position)
        VALUES (?, ?, ?, ?, ?)
    ]], { charId, killerCharId, cause, weaponId, position })

    -- Actualizar estadisticas
    Death.UpdateDeathStats(charId)

    return deathId
end

--- Actualiza el log de muerte con datos de respawn
---@param deathId number ID del registro
---@param respawnType string Tipo de respawn
---@param respawnLocation string|nil Ubicacion de respawn
---@param startTime number Tiempo de inicio de muerte
function Death.UpdateDeathLog(deathId, respawnType, respawnLocation, startTime)
    local bleedoutDuration = (os.time() * 1000 - startTime)

    MySQL.query([[
        UPDATE ait_death_log SET
            respawn_type = ?,
            respawn_location = ?,
            respawn_ts = NOW(),
            bleedout_duration = ?
        WHERE death_id = ?
    ]], { respawnType, respawnLocation, bleedoutDuration, deathId })
end

--- Actualiza las estadisticas de muerte
---@param charId number ID del personaje
function Death.UpdateDeathStats(charId)
    MySQL.query([[
        INSERT INTO ait_death_stats (char_id, total_deaths, deaths_today, deaths_this_week, last_death)
        VALUES (?, 1, 1, 1, NOW())
        ON DUPLICATE KEY UPDATE
            total_deaths = total_deaths + 1,
            deaths_today = deaths_today + 1,
            deaths_this_week = deaths_this_week + 1,
            last_death = NOW()
    ]], { charId })
end

--- Incrementa una estadistica especifica
---@param source number Server ID
---@param stat string Nombre de la estadistica
---@param amount? number Cantidad a incrementar
function Death.IncrementStat(source, stat, amount)
    amount = amount or 1
    local charId = Death.GetCharId(source)
    if not charId then return end

    MySQL.query([[
        INSERT INTO ait_death_stats (char_id, ]] .. stat .. [[)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE ]] .. stat .. [[ = ]] .. stat .. [[ + ?
    ]], { charId, amount, amount })
end

-- =================================================================================================
-- UTILIDADES
-- =================================================================================================

--- Obtiene el ID de personaje de un jugador
---@param source number Server ID
---@return number|nil
function Death.GetCharId(source)
    if AIT.Core then
        local player = AIT.Core.GetPlayer(source)
        if player and player.character then
            return player.character.id
        end
    end
    return nil
end

-- =================================================================================================
-- EVENT HANDLERS
-- =================================================================================================

function Death.OnPlayerKilled(event)
    local payload = event.payload
    Death.Kill(payload.target, payload.damageType or 'combat', payload.source, payload.weaponId)
end

function Death.OnKnockdown(event)
    local payload = event.payload
    -- El knockdown se maneja en init.lua, aqui solo escuchamos
end

function Death.OnPlayerDisconnect(event)
    local source = event.payload.source

    -- Limpiar todos los estados
    Death.deadPlayers[source] = nil
    Death.reviveInProgress[source] = nil
    Death.pendingPenalties[source] = nil
end

function Death.OnCharacterSelected(event)
    local source = event.payload.source
    local charId = event.payload.charId

    -- Asegurar que existan estadisticas
    MySQL.insert([[
        INSERT IGNORE INTO ait_death_stats (char_id) VALUES (?)
    ]], { charId })

    -- Resetear contadores diarios/semanales si es necesario
    MySQL.query([[
        UPDATE ait_death_stats SET
            deaths_today = CASE
                WHEN last_reset_daily < CURDATE() OR last_reset_daily IS NULL
                THEN 0 ELSE deaths_today
            END,
            deaths_this_week = CASE
                WHEN last_reset_weekly < DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
                OR last_reset_weekly IS NULL
                THEN 0 ELSE deaths_this_week
            END,
            last_reset_daily = CURDATE(),
            last_reset_weekly = DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
        WHERE char_id = ?
    ]], { charId })
end

-- =================================================================================================
-- LIMPIEZA
-- =================================================================================================

function Death.CleanupExpired()
    local currentTime = os.time() * 1000

    -- Limpiar cooldowns expirados
    for key, expires in pairs(Death.respawnCooldowns) do
        if expires < currentTime then
            Death.respawnCooldowns[key] = nil
        end
    end

    -- Limpiar revives abandonados (mas de 30 segundos)
    for target, state in pairs(Death.reviveInProgress) do
        if currentTime - state.startTime > 30000 then
            Death.reviveInProgress[target] = nil
        end
    end
end

-- =================================================================================================
-- API PUBLICA
-- =================================================================================================

Death.KillPlayer = Death.Kill
Death.IsPlayerDead = Death.IsDead
Death.RevivePlayer = Death.Revive
Death.StartPlayerRevive = Death.StartRevive
Death.RequestPlayerRespawn = Death.RequestRespawn
Death.GetDeathInfo = Death.GetDeathState
Death.CanRevive = Death.CanBeRevived
Death.CheckEMS = Death.IsEMS

-- =================================================================================================
-- REGISTRAR ENGINE
-- =================================================================================================

AIT.Engines.Combat.Death = Death

return Death
