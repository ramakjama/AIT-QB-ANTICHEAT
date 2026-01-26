-- =================================================================================================
-- ait-qb COMBAT ENGINE
-- Sistema de combate completo con dano, armadura, healing, knockdown y ragdoll
-- Optimizado para 2048 slots
-- =================================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Combat = AIT.Engines.Combat or {}

local Combat = {
    -- Cache de jugadores en combate
    playersInCombat = {},
    -- Cache de estado de salud
    healthCache = {},
    -- Cola de eventos de dano para procesamiento batch
    damageQueue = {},
    -- Configuracion activa
    config = {},
    -- Modificadores activos por jugador
    modifiers = {},
    -- Cooldowns de habilidades
    cooldowns = {},
    -- Estado de ragdoll/knockdown
    knockdownState = {},
    -- Procesando cola
    processing = false,
}

-- =================================================================================================
-- CONFIGURACION
-- =================================================================================================

Combat.Config = {
    -- Salud base
    BASE_HEALTH = 200,
    BASE_ARMOR = 0,
    MAX_HEALTH = 200,
    MAX_ARMOR = 100,

    -- Regeneracion
    HEALTH_REGEN_RATE = 0,           -- HP por segundo (0 = sin regen natural)
    HEALTH_REGEN_DELAY = 10000,      -- ms sin recibir dano para empezar regen
    ARMOR_REGEN_RATE = 0,            -- Armadura no se regenera

    -- Dano
    FRIENDLY_FIRE = false,           -- Dano entre misma faccion
    PVP_ENABLED = true,              -- PvP activo
    PVE_MULTIPLIER = 1.0,            -- Multiplicador dano PvE
    PVP_MULTIPLIER = 0.75,           -- Multiplicador dano PvP (reducido)

    -- Knockdown
    KNOCKDOWN_THRESHOLD = 25,        -- HP para entrar en knockdown
    KNOCKDOWN_DURATION = 30000,      -- Duracion maxima en knockdown (ms)
    RAGDOLL_DURATION = 3000,         -- Duracion ragdoll por impacto fuerte
    RAGDOLL_DAMAGE_THRESHOLD = 50,   -- Dano para causar ragdoll

    -- Bleedout (vinculado a death.lua)
    BLEEDOUT_ENABLED = true,
    BLEEDOUT_RATE = 1,               -- HP perdido por segundo en bleedout

    -- Armadura
    ARMOR_ABSORPTION = 0.5,          -- 50% del dano absorbido por armadura
    ARMOR_DEGRADATION = 1.0,         -- Degradacion de armadura por dano

    -- Zonas de dano
    DAMAGE_ZONES = {
        HEAD = 4.0,                  -- Multiplicador headshot
        TORSO = 1.0,
        ARMS = 0.6,
        LEGS = 0.7,
    },

    -- Tipos de dano
    DAMAGE_TYPES = {
        BULLET = { base = 1.0, armorPen = 0.3 },
        MELEE = { base = 0.8, armorPen = 0.1 },
        EXPLOSION = { base = 1.5, armorPen = 0.8 },
        FIRE = { base = 0.5, armorPen = 1.0, dot = true },
        FALL = { base = 1.0, armorPen = 1.0 },
        DROWN = { base = 1.0, armorPen = 1.0 },
        VEHICLE = { base = 1.2, armorPen = 0.5 },
        ELECTRIC = { base = 0.7, armorPen = 0.9, stun = true },
    },

    -- Healing
    HEALING_COOLDOWN = 5000,         -- Cooldown entre usos de items curativos
    MAX_HEAL_STACKS = 3,             -- Maximo de efectos curativos simultaneos
}

-- =================================================================================================
-- INICIALIZACION
-- =================================================================================================

function Combat.Initialize()
    -- Crear tablas si no existen
    Combat.EnsureTables()

    -- Cargar configuracion desde DB
    Combat.LoadConfig()

    -- Registrar jobs del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('combat_process_queue', {
            interval = 0.1,
            fn = Combat.ProcessDamageQueue
        })

        AIT.Scheduler.register('combat_update_states', {
            interval = 1,
            fn = Combat.UpdateCombatStates
        })

        AIT.Scheduler.register('combat_cleanup', {
            interval = 60,
            fn = Combat.CleanupExpired
        })
    end

    -- Thread de procesamiento de dano
    CreateThread(function()
        while true do
            Wait(100)
            Combat.ProcessDamageQueue()
        end
    end)

    -- Thread de actualizacion de estados
    CreateThread(function()
        while true do
            Wait(1000)
            Combat.UpdateCombatStates()
        end
    end)

    -- Suscribirse a eventos
    if AIT.EventBus then
        AIT.EventBus.on('player.spawned', Combat.OnPlayerSpawn)
        AIT.EventBus.on('player.disconnected', Combat.OnPlayerDisconnect)
        AIT.EventBus.on('character.selected', Combat.OnCharacterSelected)
    end

    if AIT.Log then
        AIT.Log.info('COMBAT', 'Combat engine initialized')
    end

    return true
end

function Combat.EnsureTables()
    -- Tabla de log de combate
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_combat_log (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            attacker_char_id BIGINT NULL,
            victim_char_id BIGINT NOT NULL,
            damage_type VARCHAR(32) NOT NULL,
            weapon_id VARCHAR(64) NULL,
            damage_dealt INT NOT NULL,
            damage_blocked INT NOT NULL DEFAULT 0,
            body_zone VARCHAR(32) NULL,
            is_kill TINYINT(1) NOT NULL DEFAULT 0,
            position JSON NULL,
            meta JSON NULL,
            KEY idx_ts (ts),
            KEY idx_attacker (attacker_char_id),
            KEY idx_victim (victim_char_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estadisticas de combate
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_combat_stats (
            char_id BIGINT PRIMARY KEY,
            kills INT NOT NULL DEFAULT 0,
            deaths INT NOT NULL DEFAULT 0,
            assists INT NOT NULL DEFAULT 0,
            damage_dealt BIGINT NOT NULL DEFAULT 0,
            damage_received BIGINT NOT NULL DEFAULT 0,
            headshots INT NOT NULL DEFAULT 0,
            longest_kill_distance INT NOT NULL DEFAULT 0,
            knockdowns INT NOT NULL DEFAULT 0,
            revives_given INT NOT NULL DEFAULT 0,
            revives_received INT NOT NULL DEFAULT 0,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de configuracion de combate
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_combat_config (
            config_key VARCHAR(64) PRIMARY KEY,
            config_value TEXT NOT NULL,
            description VARCHAR(255) NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Combat.LoadConfig()
    local configs = MySQL.query.await('SELECT * FROM ait_combat_config')

    for _, cfg in ipairs(configs or {}) do
        local value = cfg.config_value
        -- Intentar parsear como JSON o numero
        if value:match('^%d+%.?%d*$') then
            value = tonumber(value)
        elseif value:match('^%{') or value:match('^%[') then
            value = json.decode(value)
        elseif value == 'true' then
            value = true
        elseif value == 'false' then
            value = false
        end
        Combat.config[cfg.config_key] = value
    end

    -- Merge con config por defecto
    for key, value in pairs(Combat.Config) do
        if Combat.config[key] == nil then
            Combat.config[key] = value
        end
    end
end

-- =================================================================================================
-- SISTEMA DE DANO
-- =================================================================================================

--- Aplica dano a un jugador
---@param source number Server ID del atacante (0 para ambiente)
---@param target number Server ID de la victima
---@param damage number Cantidad de dano base
---@param damageType string Tipo de dano (BULLET, MELEE, etc)
---@param weaponId? string ID del arma usada
---@param bodyZone? string Zona del cuerpo impactada
---@param meta? table Metadatos adicionales
---@return boolean, number Exito y dano final aplicado
function Combat.ApplyDamage(source, target, damage, damageType, weaponId, bodyZone, meta)
    if not target or target <= 0 then
        return false, 0
    end

    -- Rate limiting
    if source > 0 and AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'combat.damage')
        if not allowed then
            return false, 0
        end
    end

    -- Obtener IDs de personaje
    local attackerCharId = nil
    local victimCharId = nil

    if AIT.Core then
        if source > 0 then
            local attackerPlayer = AIT.Core.GetPlayer(source)
            if attackerPlayer and attackerPlayer.character then
                attackerCharId = attackerPlayer.character.id
            end
        end

        local victimPlayer = AIT.Core.GetPlayer(target)
        if victimPlayer and victimPlayer.character then
            victimCharId = victimPlayer.character.id
        end
    end

    if not victimCharId then
        return false, 0
    end

    -- Verificar friendly fire
    if source > 0 and not Combat.config.FRIENDLY_FIRE then
        if Combat.AreAllies(source, target) then
            return false, 0
        end
    end

    -- Verificar PvP
    if source > 0 and attackerCharId and not Combat.config.PVP_ENABLED then
        return false, 0
    end

    -- Calcular dano final
    local finalDamage, damageBlocked = Combat.CalculateDamage(
        target, damage, damageType, bodyZone, source > 0
    )

    -- Anadir a cola de procesamiento
    table.insert(Combat.damageQueue, {
        source = source,
        target = target,
        attackerCharId = attackerCharId,
        victimCharId = victimCharId,
        damage = finalDamage,
        damageBlocked = damageBlocked,
        damageType = damageType,
        weaponId = weaponId,
        bodyZone = bodyZone,
        meta = meta,
        timestamp = os.time(),
    })

    return true, finalDamage
end

--- Calcula el dano final considerando armadura, zona y modificadores
---@param target number Server ID de la victima
---@param baseDamage number Dano base
---@param damageType string Tipo de dano
---@param bodyZone? string Zona del cuerpo
---@param isPvP boolean Si es dano PvP
---@return number, number Dano final y dano bloqueado
function Combat.CalculateDamage(target, baseDamage, damageType, bodyZone, isPvP)
    local damage = baseDamage
    local blocked = 0

    -- Obtener configuracion del tipo de dano
    local typeConfig = Combat.config.DAMAGE_TYPES[damageType] or { base = 1.0, armorPen = 0.5 }

    -- Aplicar multiplicador base del tipo
    damage = damage * typeConfig.base

    -- Aplicar multiplicador de zona
    if bodyZone then
        local zoneMultiplier = Combat.config.DAMAGE_ZONES[bodyZone] or 1.0
        damage = damage * zoneMultiplier
    end

    -- Aplicar multiplicador PvP/PvE
    if isPvP then
        damage = damage * Combat.config.PVP_MULTIPLIER
    else
        damage = damage * Combat.config.PVE_MULTIPLIER
    end

    -- Obtener estado de salud actual
    local healthState = Combat.GetHealthState(target)

    -- Calcular absorcion de armadura
    if healthState.armor > 0 and typeConfig.armorPen < 1.0 then
        local armorAbsorption = Combat.config.ARMOR_ABSORPTION * (1 - typeConfig.armorPen)
        blocked = math.floor(damage * armorAbsorption)

        -- Limitar al armor disponible
        if blocked > healthState.armor then
            blocked = healthState.armor
        end

        damage = damage - blocked
    end

    -- Aplicar modificadores del jugador (buffs/debuffs)
    local mods = Combat.modifiers[target] or {}
    for _, mod in ipairs(mods) do
        if mod.type == 'damage_reduction' and mod.expires > os.time() then
            damage = damage * (1 - mod.value)
        elseif mod.type == 'damage_amplify' and mod.expires > os.time() then
            damage = damage * (1 + mod.value)
        end
    end

    -- Redondear
    damage = math.floor(damage)
    blocked = math.floor(blocked)

    return math.max(damage, 0), blocked
end

--- Procesa la cola de dano
function Combat.ProcessDamageQueue()
    if Combat.processing or #Combat.damageQueue == 0 then return end
    Combat.processing = true

    local batch = {}
    for i = 1, math.min(50, #Combat.damageQueue) do
        table.insert(batch, table.remove(Combat.damageQueue, 1))
    end

    for _, event in ipairs(batch) do
        Combat.ProcessDamageEvent(event)
    end

    Combat.processing = false
end

--- Procesa un evento de dano individual
---@param event table Evento de dano
function Combat.ProcessDamageEvent(event)
    local healthState = Combat.GetHealthState(event.target)

    -- Aplicar dano a armadura
    if event.damageBlocked > 0 then
        local newArmor = healthState.armor - math.floor(event.damageBlocked * Combat.config.ARMOR_DEGRADATION)
        Combat.SetArmor(event.target, math.max(newArmor, 0))
    end

    -- Aplicar dano a salud
    local newHealth = healthState.health - event.damage
    local isKill = false
    local isKnockdown = false

    if newHealth <= 0 then
        isKill = true
        newHealth = 0
    elseif newHealth <= Combat.config.KNOCKDOWN_THRESHOLD and not Combat.IsKnockedDown(event.target) then
        isKnockdown = true
    end

    Combat.SetHealth(event.target, newHealth)

    -- Marcar en combate
    Combat.SetInCombat(event.target, true)
    if event.source > 0 then
        Combat.SetInCombat(event.source, true)
    end

    -- Verificar ragdoll por dano alto
    if event.damage >= Combat.config.RAGDOLL_DAMAGE_THRESHOLD then
        Combat.ApplyRagdoll(event.target, Combat.config.RAGDOLL_DURATION)
    end

    -- Knockdown
    if isKnockdown then
        Combat.ApplyKnockdown(event.target)
    end

    -- Muerte
    if isKill then
        Combat.OnPlayerKilled(event)
    end

    -- Log de combate
    Combat.LogCombatEvent(event, isKill)

    -- Actualizar estadisticas
    Combat.UpdateStats(event, isKill)

    -- Emitir eventos
    if AIT.EventBus then
        AIT.EventBus.emit('combat.damage.applied', {
            source = event.source,
            target = event.target,
            damage = event.damage,
            damageType = event.damageType,
            isKill = isKill,
            isKnockdown = isKnockdown,
        })

        if isKnockdown then
            AIT.EventBus.emit('combat.knockdown', {
                target = event.target,
                charId = event.victimCharId,
            })
        end
    end

    -- Notificar al cliente
    TriggerClientEvent('ait:combat:damageReceived', event.target, {
        damage = event.damage,
        damageType = event.damageType,
        source = event.source,
        isKnockdown = isKnockdown,
    })
end

-- =================================================================================================
-- SISTEMA DE SALUD Y ARMADURA
-- =================================================================================================

--- Obtiene el estado de salud de un jugador
---@param source number Server ID
---@return table Estado de salud
function Combat.GetHealthState(source)
    local cacheKey = tostring(source)

    if Combat.healthCache[cacheKey] and Combat.healthCache[cacheKey].expires > os.time() then
        return Combat.healthCache[cacheKey].state
    end

    local player = GetPlayerPed(source)
    local health = GetEntityHealth(player) - 100 -- GTA usa 100-300, normalizar a 0-200
    local armor = GetPedArmour(player)

    local state = {
        health = math.max(health, 0),
        armor = math.max(armor, 0),
        maxHealth = Combat.config.MAX_HEALTH,
        maxArmor = Combat.config.MAX_ARMOR,
    }

    Combat.healthCache[cacheKey] = {
        state = state,
        expires = os.time() + 1
    }

    return state
end

--- Establece la salud de un jugador
---@param source number Server ID
---@param health number Nueva salud
function Combat.SetHealth(source, health)
    health = math.max(0, math.min(health, Combat.config.MAX_HEALTH))

    local player = GetPlayerPed(source)
    SetEntityHealth(player, health + 100) -- GTA usa 100-300

    -- Invalidar cache
    Combat.healthCache[tostring(source)] = nil
end

--- Establece la armadura de un jugador
---@param source number Server ID
---@param armor number Nueva armadura
function Combat.SetArmor(source, armor)
    armor = math.max(0, math.min(armor, Combat.config.MAX_ARMOR))

    local player = GetPlayerPed(source)
    SetPedArmour(player, armor)

    -- Invalidar cache
    Combat.healthCache[tostring(source)] = nil
end

--- Cura a un jugador
---@param source number Server ID del sanador (0 para sistema)
---@param target number Server ID del objetivo
---@param amount number Cantidad a curar
---@param healType? string Tipo de curacion
---@return boolean, number Exito y cantidad curada
function Combat.Heal(source, target, amount, healType)
    healType = healType or 'instant'

    -- Rate limiting
    if source > 0 and AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'combat.heal')
        if not allowed then
            return false, 0
        end
    end

    -- Verificar cooldown
    local cooldownKey = target .. ':heal'
    if Combat.cooldowns[cooldownKey] and Combat.cooldowns[cooldownKey] > os.time() * 1000 then
        return false, 0
    end

    local healthState = Combat.GetHealthState(target)

    -- No curar si esta en knockdown (requiere revive)
    if Combat.IsKnockedDown(target) and healType ~= 'revive' then
        return false, 0
    end

    -- Calcular curacion real
    local healAmount = math.min(amount, healthState.maxHealth - healthState.health)

    if healAmount <= 0 then
        return false, 0
    end

    -- Aplicar curacion
    Combat.SetHealth(target, healthState.health + healAmount)

    -- Establecer cooldown
    Combat.cooldowns[cooldownKey] = os.time() * 1000 + Combat.config.HEALING_COOLDOWN

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('combat.healed', {
            source = source,
            target = target,
            amount = healAmount,
            healType = healType,
        })
    end

    if AIT.Log then
        AIT.Log.debug('COMBAT', 'Player healed', {
            healer = source,
            target = target,
            amount = healAmount,
        })
    end

    return true, healAmount
end

--- Repara la armadura de un jugador
---@param source number Server ID
---@param target number Server ID del objetivo
---@param amount number Cantidad a reparar
---@return boolean, number Exito y cantidad reparada
function Combat.RepairArmor(source, target, amount)
    local healthState = Combat.GetHealthState(target)

    local repairAmount = math.min(amount, healthState.maxArmor - healthState.armor)

    if repairAmount <= 0 then
        return false, 0
    end

    Combat.SetArmor(target, healthState.armor + repairAmount)

    if AIT.EventBus then
        AIT.EventBus.emit('combat.armor.repaired', {
            source = source,
            target = target,
            amount = repairAmount,
        })
    end

    return true, repairAmount
end

-- =================================================================================================
-- SISTEMA DE KNOCKDOWN Y RAGDOLL
-- =================================================================================================

--- Aplica knockdown a un jugador
---@param source number Server ID
function Combat.ApplyKnockdown(source)
    if Combat.IsKnockedDown(source) then return end

    Combat.knockdownState[source] = {
        startTime = os.time() * 1000,
        duration = Combat.config.KNOCKDOWN_DURATION,
        bleedout = Combat.config.BLEEDOUT_ENABLED,
    }

    -- Notificar al cliente
    TriggerClientEvent('ait:combat:knockdown', source, {
        duration = Combat.config.KNOCKDOWN_DURATION,
    })

    -- Emitir para death.lua
    if AIT.EventBus then
        AIT.EventBus.emit('combat.knockdown.start', {
            source = source,
            duration = Combat.config.KNOCKDOWN_DURATION,
        })
    end

    if AIT.Log then
        AIT.Log.info('COMBAT', 'Player knocked down', { source = source })
    end
end

--- Verifica si un jugador esta en knockdown
---@param source number Server ID
---@return boolean
function Combat.IsKnockedDown(source)
    local state = Combat.knockdownState[source]
    if not state then return false end

    local elapsed = (os.time() * 1000) - state.startTime
    return elapsed < state.duration
end

--- Aplica ragdoll a un jugador
---@param source number Server ID
---@param duration number Duracion en ms
function Combat.ApplyRagdoll(source, duration)
    TriggerClientEvent('ait:combat:ragdoll', source, {
        duration = duration,
    })

    if AIT.EventBus then
        AIT.EventBus.emit('combat.ragdoll', {
            source = source,
            duration = duration,
        })
    end
end

--- Levanta a un jugador del knockdown (revive parcial)
---@param healer number Server ID del sanador
---@param target number Server ID del objetivo
---@return boolean
function Combat.ReviveFromKnockdown(healer, target)
    if not Combat.IsKnockedDown(target) then
        return false
    end

    -- Limpiar estado de knockdown
    Combat.knockdownState[target] = nil

    -- Restaurar algo de salud
    Combat.SetHealth(target, Combat.config.KNOCKDOWN_THRESHOLD + 10)

    -- Notificar al cliente
    TriggerClientEvent('ait:combat:revived', target, {
        healer = healer,
    })

    -- Actualizar estadisticas
    if healer > 0 then
        Combat.IncrementStat(healer, 'revives_given')
    end
    Combat.IncrementStat(target, 'revives_received')

    if AIT.EventBus then
        AIT.EventBus.emit('combat.revive', {
            healer = healer,
            target = target,
        })
    end

    return true
end

-- =================================================================================================
-- ESTADO DE COMBATE
-- =================================================================================================

--- Marca a un jugador en combate
---@param source number Server ID
---@param inCombat boolean
function Combat.SetInCombat(source, inCombat)
    if inCombat then
        Combat.playersInCombat[source] = {
            startTime = os.time(),
            lastActivity = os.time(),
        }
    else
        Combat.playersInCombat[source] = nil
    end

    -- Notificar al cliente
    TriggerClientEvent('ait:combat:state', source, { inCombat = inCombat })
end

--- Verifica si un jugador esta en combate
---@param source number Server ID
---@return boolean
function Combat.IsInCombat(source)
    local state = Combat.playersInCombat[source]
    if not state then return false end

    -- 10 segundos sin actividad = fuera de combate
    return (os.time() - state.lastActivity) < 10
end

--- Actualiza los estados de combate de todos los jugadores
function Combat.UpdateCombatStates()
    local currentTime = os.time()

    for source, state in pairs(Combat.playersInCombat) do
        -- Salir de combate despues de 10 segundos
        if currentTime - state.lastActivity >= 10 then
            Combat.SetInCombat(source, false)
        end
    end

    -- Actualizar knockdown y bleedout
    for source, state in pairs(Combat.knockdownState) do
        if Combat.IsKnockedDown(source) and state.bleedout then
            -- Aplicar bleedout
            local healthState = Combat.GetHealthState(source)
            if healthState.health > 0 then
                Combat.SetHealth(source, healthState.health - Combat.config.BLEEDOUT_RATE)
            end
        end
    end
end

--- Verifica si dos jugadores son aliados
---@param source1 number Server ID
---@param source2 number Server ID
---@return boolean
function Combat.AreAllies(source1, source2)
    if AIT.Engines.Factions then
        local faction1 = AIT.Engines.Factions.GetPlayerFaction(source1)
        local faction2 = AIT.Engines.Factions.GetPlayerFaction(source2)

        if faction1 and faction2 and faction1 == faction2 then
            return true
        end
    end

    return false
end

-- =================================================================================================
-- MODIFICADORES Y BUFFS
-- =================================================================================================

--- Aplica un modificador a un jugador
---@param source number Server ID
---@param modType string Tipo de modificador
---@param value number Valor del modificador
---@param duration number Duracion en segundos
---@param stackId? string ID para evitar stacking
function Combat.ApplyModifier(source, modType, value, duration, stackId)
    Combat.modifiers[source] = Combat.modifiers[source] or {}

    -- Verificar si ya existe con el mismo stackId
    if stackId then
        for i, mod in ipairs(Combat.modifiers[source]) do
            if mod.stackId == stackId then
                -- Actualizar en lugar de anadir
                Combat.modifiers[source][i] = {
                    type = modType,
                    value = value,
                    expires = os.time() + duration,
                    stackId = stackId,
                }
                return
            end
        end
    end

    table.insert(Combat.modifiers[source], {
        type = modType,
        value = value,
        expires = os.time() + duration,
        stackId = stackId,
    })

    if AIT.EventBus then
        AIT.EventBus.emit('combat.modifier.applied', {
            source = source,
            modType = modType,
            value = value,
            duration = duration,
        })
    end
end

--- Remueve modificadores expirados
---@param source number Server ID
function Combat.CleanupModifiers(source)
    local mods = Combat.modifiers[source]
    if not mods then return end

    local currentTime = os.time()
    local newMods = {}

    for _, mod in ipairs(mods) do
        if mod.expires > currentTime then
            table.insert(newMods, mod)
        end
    end

    Combat.modifiers[source] = #newMods > 0 and newMods or nil
end

-- =================================================================================================
-- LOGGING Y ESTADISTICAS
-- =================================================================================================

--- Registra un evento de combate en la base de datos
---@param event table Evento de dano
---@param isKill boolean Si resulto en muerte
function Combat.LogCombatEvent(event, isKill)
    local position = nil
    if event.target > 0 then
        local ped = GetPlayerPed(event.target)
        local coords = GetEntityCoords(ped)
        position = json.encode({ x = coords.x, y = coords.y, z = coords.z })
    end

    MySQL.insert([[
        INSERT INTO ait_combat_log
        (attacker_char_id, victim_char_id, damage_type, weapon_id, damage_dealt,
         damage_blocked, body_zone, is_kill, position, meta)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        event.attackerCharId,
        event.victimCharId,
        event.damageType,
        event.weaponId,
        event.damage,
        event.damageBlocked,
        event.bodyZone,
        isKill and 1 or 0,
        position,
        event.meta and json.encode(event.meta)
    })
end

--- Actualiza las estadisticas de combate
---@param event table Evento de dano
---@param isKill boolean Si resulto en muerte
function Combat.UpdateStats(event, isKill)
    -- Estadisticas del atacante
    if event.attackerCharId then
        MySQL.query([[
            INSERT INTO ait_combat_stats (char_id, damage_dealt, kills, headshots)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                damage_dealt = damage_dealt + VALUES(damage_dealt),
                kills = kills + VALUES(kills),
                headshots = headshots + VALUES(headshots)
        ]], {
            event.attackerCharId,
            event.damage,
            isKill and 1 or 0,
            (event.bodyZone == 'HEAD' and isKill) and 1 or 0
        })
    end

    -- Estadisticas de la victima
    if event.victimCharId then
        MySQL.query([[
            INSERT INTO ait_combat_stats (char_id, damage_received, deaths, knockdowns)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                damage_received = damage_received + VALUES(damage_received),
                deaths = deaths + VALUES(deaths),
                knockdowns = knockdowns + VALUES(knockdowns)
        ]], {
            event.victimCharId,
            event.damage,
            isKill and 1 or 0,
            Combat.IsKnockedDown(event.target) and 1 or 0
        })
    end
end

--- Incrementa una estadistica especifica
---@param source number Server ID
---@param stat string Nombre de la estadistica
function Combat.IncrementStat(source, stat)
    local charId = nil
    if AIT.Core then
        local player = AIT.Core.GetPlayer(source)
        if player and player.character then
            charId = player.character.id
        end
    end

    if not charId then return end

    MySQL.query([[
        INSERT INTO ait_combat_stats (char_id, ]] .. stat .. [[)
        VALUES (?, 1)
        ON DUPLICATE KEY UPDATE ]] .. stat .. [[ = ]] .. stat .. [[ + 1
    ]], { charId })
end

-- =================================================================================================
-- EVENT HANDLERS
-- =================================================================================================

function Combat.OnPlayerSpawn(event)
    local source = event.payload.source

    -- Restaurar salud completa
    Combat.SetHealth(source, Combat.config.MAX_HEALTH)
    Combat.SetArmor(source, 0)

    -- Limpiar estados
    Combat.knockdownState[source] = nil
    Combat.playersInCombat[source] = nil
    Combat.modifiers[source] = nil
end

function Combat.OnPlayerDisconnect(event)
    local source = event.payload.source

    -- Limpiar todos los estados
    Combat.healthCache[tostring(source)] = nil
    Combat.knockdownState[source] = nil
    Combat.playersInCombat[source] = nil
    Combat.modifiers[source] = nil
end

function Combat.OnCharacterSelected(event)
    local source = event.payload.source
    local charId = event.payload.charId

    -- Asegurar que existan estadisticas
    MySQL.insert([[
        INSERT IGNORE INTO ait_combat_stats (char_id) VALUES (?)
    ]], { charId })
end

function Combat.OnPlayerKilled(event)
    -- Emitir evento para death.lua
    if AIT.EventBus then
        AIT.EventBus.emit('combat.player.killed', {
            source = event.source,
            target = event.target,
            attackerCharId = event.attackerCharId,
            victimCharId = event.victimCharId,
            damageType = event.damageType,
            weaponId = event.weaponId,
        })
    end
end

-- =================================================================================================
-- LIMPIEZA
-- =================================================================================================

function Combat.CleanupExpired()
    local currentTime = os.time()

    -- Limpiar caches expirados
    for key, cached in pairs(Combat.healthCache) do
        if cached.expires < currentTime then
            Combat.healthCache[key] = nil
        end
    end

    -- Limpiar cooldowns expirados
    local currentMs = currentTime * 1000
    for key, expires in pairs(Combat.cooldowns) do
        if expires < currentMs then
            Combat.cooldowns[key] = nil
        end
    end

    -- Limpiar modificadores de todos los jugadores
    for source, _ in pairs(Combat.modifiers) do
        Combat.CleanupModifiers(source)
    end

    -- Limpiar knockdowns expirados
    for source, state in pairs(Combat.knockdownState) do
        local elapsed = currentMs - state.startTime
        if elapsed >= state.duration then
            Combat.knockdownState[source] = nil
        end
    end
end

-- =================================================================================================
-- API PUBLICA
-- =================================================================================================

Combat.Damage = Combat.ApplyDamage
Combat.HealPlayer = Combat.Heal
Combat.SetPlayerHealth = Combat.SetHealth
Combat.SetPlayerArmor = Combat.SetArmor
Combat.GetPlayerHealth = function(source)
    return Combat.GetHealthState(source).health
end
Combat.GetPlayerArmor = function(source)
    return Combat.GetHealthState(source).armor
end
Combat.Knockdown = Combat.ApplyKnockdown
Combat.Ragdoll = Combat.ApplyRagdoll
Combat.Revive = Combat.ReviveFromKnockdown
Combat.InCombat = Combat.IsInCombat
Combat.KnockedDown = Combat.IsKnockedDown

-- =================================================================================================
-- REGISTRAR ENGINE
-- =================================================================================================

AIT.Engines.Combat = Combat

return Combat
