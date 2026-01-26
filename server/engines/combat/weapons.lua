-- =================================================================================================
-- ait-qb WEAPONS ENGINE
-- Sistema de gestion de armas con durabilidad, modificaciones, recoil y licencias
-- Optimizado para 2048 slots
-- =================================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Combat = AIT.Engines.Combat or {}

local Weapons = {
    -- Catalogo de armas
    catalog = {},
    -- Cache de armas equipadas por jugador
    equippedWeapons = {},
    -- Cache de modificaciones
    modsCache = {},
    -- Cache de licencias
    licensesCache = {},
    -- Cola de actualizaciones de durabilidad
    durabilityQueue = {},
    -- Procesando cola
    processing = false,
}

-- =================================================================================================
-- CONFIGURACION
-- =================================================================================================

Weapons.Config = {
    -- Durabilidad
    DURABILITY_ENABLED = true,
    DURABILITY_LOSS_PER_SHOT = 0.1,      -- Perdida por disparo
    DURABILITY_LOSS_PER_MELEE = 0.5,     -- Perdida por golpe cuerpo a cuerpo
    DURABILITY_DEGRADE_THRESHOLD = 50,   -- Umbral donde empieza a degradarse el rendimiento
    DURABILITY_BREAK_THRESHOLD = 5,      -- Umbral donde el arma deja de funcionar
    DURABILITY_REPAIR_COST_MULTIPLIER = 10, -- Costo base * multiplicador = costo reparacion

    -- Modificaciones
    MODS_ENABLED = true,
    MAX_MODS_PER_WEAPON = 5,             -- Maximo de mods por arma
    MOD_REMOVAL_DESTROYS = false,        -- Si quitar un mod lo destruye

    -- Recoil y spread personalizados
    CUSTOM_RECOIL_ENABLED = true,
    RECOIL_MULTIPLIER_BASE = 1.0,
    SPREAD_MULTIPLIER_BASE = 1.0,

    -- Licencias
    LICENSES_ENABLED = true,
    LICENSE_CHECK_ON_EQUIP = true,
    LICENSE_CHECK_ON_FIRE = false,
    ILLEGAL_WEAPON_ALERT = true,         -- Alertar a policia por armas ilegales

    -- Seriales
    SERIAL_ENABLED = true,
    SERIAL_TRACEABLE = true,             -- Seriales rastreables por policia
    SERIAL_SCRATCH_CHANCE = 0.0,         -- Probabilidad de que serial se borre al disparar

    -- Municion
    AMMO_TYPES_ENABLED = true,
    AMMO_IN_INVENTORY = true,            -- Municion como items de inventario

    -- Categorias de armas
    WEAPON_CATEGORIES = {
        PISTOL = { licenseRequired = 'weapon_license', legalWithLicense = true },
        SMG = { licenseRequired = 'weapon_license_smg', legalWithLicense = false },
        RIFLE = { licenseRequired = 'weapon_license_rifle', legalWithLicense = false },
        SHOTGUN = { licenseRequired = 'weapon_license_shotgun', legalWithLicense = true },
        SNIPER = { licenseRequired = 'weapon_license_sniper', legalWithLicense = false },
        HEAVY = { licenseRequired = nil, legalWithLicense = false },
        MELEE = { licenseRequired = nil, legalWithLicense = true },
        THROWABLE = { licenseRequired = nil, legalWithLicense = false },
    },
}

-- =================================================================================================
-- CATALOGO DE ARMAS POR DEFECTO
-- =================================================================================================

Weapons.DefaultCatalog = {
    -- Pistolas
    weapon_pistol = {
        id = 'weapon_pistol',
        name = 'Pistola',
        category = 'PISTOL',
        hash = GetHashKey('WEAPON_PISTOL'),
        maxDurability = 100,
        basePrice = 5000,
        ammoType = 'ammo_pistol',
        clipSize = 12,
        recoilBase = 1.0,
        spreadBase = 1.0,
        damageBase = 26,
        fireRate = 0.15,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'tint' },
    },
    weapon_pistol_mk2 = {
        id = 'weapon_pistol_mk2',
        name = 'Pistola Mk II',
        category = 'PISTOL',
        hash = GetHashKey('WEAPON_PISTOL_MK2'),
        maxDurability = 120,
        basePrice = 8000,
        ammoType = 'ammo_pistol',
        clipSize = 12,
        recoilBase = 0.9,
        spreadBase = 0.9,
        damageBase = 28,
        fireRate = 0.14,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'compensator', 'camo' },
    },
    weapon_combatpistol = {
        id = 'weapon_combatpistol',
        name = 'Pistola de Combate',
        category = 'PISTOL',
        hash = GetHashKey('WEAPON_COMBATPISTOL'),
        maxDurability = 110,
        basePrice = 7500,
        ammoType = 'ammo_pistol',
        clipSize = 12,
        recoilBase = 0.95,
        spreadBase = 0.85,
        damageBase = 27,
        fireRate = 0.14,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'tint' },
    },
    weapon_heavypistol = {
        id = 'weapon_heavypistol',
        name = 'Pistola Pesada',
        category = 'PISTOL',
        hash = GetHashKey('WEAPON_HEAVYPISTOL'),
        maxDurability = 100,
        basePrice = 9000,
        ammoType = 'ammo_pistol',
        clipSize = 18,
        recoilBase = 1.2,
        spreadBase = 0.8,
        damageBase = 32,
        fireRate = 0.16,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'tint' },
    },

    -- Subfusiles
    weapon_smg = {
        id = 'weapon_smg',
        name = 'Subfusil',
        category = 'SMG',
        hash = GetHashKey('WEAPON_SMG'),
        maxDurability = 90,
        basePrice = 15000,
        ammoType = 'ammo_smg',
        clipSize = 30,
        recoilBase = 1.1,
        spreadBase = 1.2,
        damageBase = 22,
        fireRate = 0.07,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'tint' },
    },
    weapon_smg_mk2 = {
        id = 'weapon_smg_mk2',
        name = 'Subfusil Mk II',
        category = 'SMG',
        hash = GetHashKey('WEAPON_SMG_MK2'),
        maxDurability = 110,
        basePrice = 20000,
        ammoType = 'ammo_smg',
        clipSize = 30,
        recoilBase = 1.0,
        spreadBase = 1.0,
        damageBase = 24,
        fireRate = 0.065,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'barrel', 'camo' },
    },
    weapon_microsmg = {
        id = 'weapon_microsmg',
        name = 'Micro Subfusil',
        category = 'SMG',
        hash = GetHashKey('WEAPON_MICROSMG'),
        maxDurability = 80,
        basePrice = 12000,
        ammoType = 'ammo_smg',
        clipSize = 16,
        recoilBase = 1.3,
        spreadBase = 1.4,
        damageBase = 21,
        fireRate = 0.06,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'tint' },
    },

    -- Rifles
    weapon_assaultrifle = {
        id = 'weapon_assaultrifle',
        name = 'Rifle de Asalto',
        category = 'RIFLE',
        hash = GetHashKey('WEAPON_ASSAULTRIFLE'),
        maxDurability = 100,
        basePrice = 25000,
        ammoType = 'ammo_rifle',
        clipSize = 30,
        recoilBase = 1.2,
        spreadBase = 0.9,
        damageBase = 30,
        fireRate = 0.08,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'grip', 'tint' },
    },
    weapon_assaultrifle_mk2 = {
        id = 'weapon_assaultrifle_mk2',
        name = 'Rifle de Asalto Mk II',
        category = 'RIFLE',
        hash = GetHashKey('WEAPON_ASSAULTRIFLE_MK2'),
        maxDurability = 120,
        basePrice = 35000,
        ammoType = 'ammo_rifle',
        clipSize = 30,
        recoilBase = 1.1,
        spreadBase = 0.8,
        damageBase = 32,
        fireRate = 0.075,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'grip', 'barrel', 'camo' },
    },
    weapon_carbinerifle = {
        id = 'weapon_carbinerifle',
        name = 'Rifle Carabina',
        category = 'RIFLE',
        hash = GetHashKey('WEAPON_CARBINERIFLE'),
        maxDurability = 110,
        basePrice = 28000,
        ammoType = 'ammo_rifle',
        clipSize = 30,
        recoilBase = 1.15,
        spreadBase = 0.85,
        damageBase = 32,
        fireRate = 0.08,
        legal = false,
        modsAllowed = { 'clip', 'flashlight', 'suppressor', 'scope', 'grip', 'tint' },
    },

    -- Escopetas
    weapon_pumpshotgun = {
        id = 'weapon_pumpshotgun',
        name = 'Escopeta de Bombeo',
        category = 'SHOTGUN',
        hash = GetHashKey('WEAPON_PUMPSHOTGUN'),
        maxDurability = 120,
        basePrice = 12000,
        ammoType = 'ammo_shotgun',
        clipSize = 8,
        recoilBase = 1.5,
        spreadBase = 1.8,
        damageBase = 58,
        fireRate = 0.8,
        legal = false,
        modsAllowed = { 'flashlight', 'suppressor', 'tint' },
    },
    weapon_sawnoffshotgun = {
        id = 'weapon_sawnoffshotgun',
        name = 'Escopeta Recortada',
        category = 'SHOTGUN',
        hash = GetHashKey('WEAPON_SAWNOFFSHOTGUN'),
        maxDurability = 100,
        basePrice = 8000,
        ammoType = 'ammo_shotgun',
        clipSize = 2,
        recoilBase = 1.8,
        spreadBase = 2.2,
        damageBase = 72,
        fireRate = 0.4,
        legal = false,
        modsAllowed = { 'tint' },
    },

    -- Francotirador
    weapon_sniperrifle = {
        id = 'weapon_sniperrifle',
        name = 'Rifle de Francotirador',
        category = 'SNIPER',
        hash = GetHashKey('WEAPON_SNIPERRIFLE'),
        maxDurability = 100,
        basePrice = 45000,
        ammoType = 'ammo_sniper',
        clipSize = 10,
        recoilBase = 2.0,
        spreadBase = 0.3,
        damageBase = 101,
        fireRate = 1.5,
        legal = false,
        modsAllowed = { 'suppressor', 'scope', 'tint' },
    },
    weapon_heavysniper = {
        id = 'weapon_heavysniper',
        name = 'Rifle Pesado de Francotirador',
        category = 'SNIPER',
        hash = GetHashKey('WEAPON_HEAVYSNIPER'),
        maxDurability = 90,
        basePrice = 75000,
        ammoType = 'ammo_sniper',
        clipSize = 6,
        recoilBase = 2.5,
        spreadBase = 0.2,
        damageBase = 150,
        fireRate = 2.0,
        legal = false,
        modsAllowed = { 'scope', 'tint' },
    },

    -- Cuerpo a cuerpo
    weapon_bat = {
        id = 'weapon_bat',
        name = 'Bate de Beisbol',
        category = 'MELEE',
        hash = GetHashKey('WEAPON_BAT'),
        maxDurability = 200,
        basePrice = 500,
        ammoType = nil,
        damageBase = 15,
        legal = true,
        modsAllowed = {},
    },
    weapon_knife = {
        id = 'weapon_knife',
        name = 'Cuchillo',
        category = 'MELEE',
        hash = GetHashKey('WEAPON_KNIFE'),
        maxDurability = 150,
        basePrice = 300,
        ammoType = nil,
        damageBase = 20,
        legal = false,
        modsAllowed = {},
    },
    weapon_machete = {
        id = 'weapon_machete',
        name = 'Machete',
        category = 'MELEE',
        hash = GetHashKey('WEAPON_MACHETE'),
        maxDurability = 180,
        basePrice = 800,
        ammoType = nil,
        damageBase = 30,
        legal = false,
        modsAllowed = {},
    },
    weapon_flashlight = {
        id = 'weapon_flashlight',
        name = 'Linterna',
        category = 'MELEE',
        hash = GetHashKey('WEAPON_FLASHLIGHT'),
        maxDurability = 500,
        basePrice = 100,
        ammoType = nil,
        damageBase = 5,
        legal = true,
        modsAllowed = {},
    },

    -- Lanzables
    weapon_grenade = {
        id = 'weapon_grenade',
        name = 'Granada',
        category = 'THROWABLE',
        hash = GetHashKey('WEAPON_GRENADE'),
        maxDurability = nil,
        basePrice = 2500,
        ammoType = nil,
        damageBase = 150,
        legal = false,
        consumable = true,
        modsAllowed = {},
    },
    weapon_molotov = {
        id = 'weapon_molotov',
        name = 'Coctel Molotov',
        category = 'THROWABLE',
        hash = GetHashKey('WEAPON_MOLOTOV'),
        maxDurability = nil,
        basePrice = 500,
        ammoType = nil,
        damageBase = 50,
        legal = false,
        consumable = true,
        modsAllowed = {},
    },
}

-- =================================================================================================
-- CATALOGO DE MODIFICACIONES
-- =================================================================================================

Weapons.ModsCatalog = {
    -- Cargadores
    clip_default = { id = 'clip_default', type = 'clip', name = 'Cargador Estandar', effect = { clipSize = 0 } },
    clip_extended = { id = 'clip_extended', type = 'clip', name = 'Cargador Extendido', effect = { clipSize = 15 }, price = 2500 },
    clip_drum = { id = 'clip_drum', type = 'clip', name = 'Cargador de Tambor', effect = { clipSize = 30 }, price = 5000 },

    -- Linternas
    flashlight = { id = 'flashlight', type = 'flashlight', name = 'Linterna Tactica', effect = {}, price = 1000 },

    -- Supresores
    suppressor = { id = 'suppressor', type = 'suppressor', name = 'Supresor', effect = { recoil = -0.1, spread = 0.05 }, price = 5000 },
    suppressor_heavy = { id = 'suppressor_heavy', type = 'suppressor', name = 'Supresor Pesado', effect = { recoil = -0.15, spread = 0.08 }, price = 8000 },

    -- Miras
    scope_small = { id = 'scope_small', type = 'scope', name = 'Mira Holografica', effect = { spread = -0.1 }, price = 3000 },
    scope_medium = { id = 'scope_medium', type = 'scope', name = 'Mira ACOG', effect = { spread = -0.2 }, price = 5000 },
    scope_large = { id = 'scope_large', type = 'scope', name = 'Mira Telescopica', effect = { spread = -0.3 }, price = 8000 },

    -- Grips
    grip = { id = 'grip', type = 'grip', name = 'Agarre Vertical', effect = { recoil = -0.15 }, price = 2000 },
    grip_angled = { id = 'grip_angled', type = 'grip', name = 'Agarre Angular', effect = { recoil = -0.1, spread = -0.05 }, price = 2500 },

    -- Canones
    barrel_default = { id = 'barrel_default', type = 'barrel', name = 'Canon Estandar', effect = {} },
    barrel_heavy = { id = 'barrel_heavy', type = 'barrel', name = 'Canon Pesado', effect = { recoil = -0.2, fireRate = 0.02 }, price = 4000 },
    barrel_light = { id = 'barrel_light', type = 'barrel', name = 'Canon Ligero', effect = { recoil = 0.1, fireRate = -0.02 }, price = 3500 },

    -- Compensadores
    compensator = { id = 'compensator', type = 'compensator', name = 'Compensador', effect = { recoil = -0.2, spread = 0.05 }, price = 3000 },

    -- Camuflajes
    camo_digital = { id = 'camo_digital', type = 'camo', name = 'Camuflaje Digital', effect = {}, price = 1500 },
    camo_woodland = { id = 'camo_woodland', type = 'camo', name = 'Camuflaje Bosque', effect = {}, price = 1500 },
    camo_urban = { id = 'camo_urban', type = 'camo', name = 'Camuflaje Urbano', effect = {}, price = 1500 },
}

-- =================================================================================================
-- INICIALIZACION
-- =================================================================================================

function Weapons.Initialize()
    -- Crear tablas
    Weapons.EnsureTables()

    -- Cargar catalogo
    Weapons.LoadCatalog()

    -- Registrar jobs del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('weapons_flush_durability', {
            interval = 5,
            fn = Weapons.FlushDurabilityQueue
        })

        AIT.Scheduler.register('weapons_cleanup_cache', {
            interval = 300,
            fn = Weapons.CleanupCache
        })
    end

    -- Thread de flush de durabilidad
    CreateThread(function()
        while true do
            Wait(5000)
            Weapons.FlushDurabilityQueue()
        end
    end)

    -- Suscribirse a eventos
    if AIT.EventBus then
        AIT.EventBus.on('player.disconnected', Weapons.OnPlayerDisconnect)
        AIT.EventBus.on('character.selected', Weapons.OnCharacterSelected)
        AIT.EventBus.on('inventory.item.used', Weapons.OnItemUsed)
    end

    if AIT.Log then
        AIT.Log.info('WEAPONS', 'Weapons engine initialized with ' .. Weapons.GetCatalogCount() .. ' weapons')
    end

    return true
end

function Weapons.EnsureTables()
    -- Catalogo de armas (override de defaults)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_weapons_catalog (
            weapon_id VARCHAR(64) PRIMARY KEY,
            name VARCHAR(128) NOT NULL,
            category VARCHAR(32) NOT NULL,
            hash BIGINT NOT NULL,
            max_durability INT NOT NULL DEFAULT 100,
            base_price INT NOT NULL DEFAULT 0,
            ammo_type VARCHAR(64) NULL,
            clip_size INT NULL,
            recoil_base FLOAT NOT NULL DEFAULT 1.0,
            spread_base FLOAT NOT NULL DEFAULT 1.0,
            damage_base INT NOT NULL DEFAULT 25,
            fire_rate FLOAT NULL,
            legal TINYINT(1) NOT NULL DEFAULT 0,
            mods_allowed JSON NULL,
            meta JSON NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Instancias de armas (armas en el juego)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_weapons_instances (
            weapon_iid BIGINT AUTO_INCREMENT PRIMARY KEY,
            weapon_id VARCHAR(64) NOT NULL,
            item_iid BIGINT NULL,
            owner_char_id BIGINT NULL,
            serial VARCHAR(32) NOT NULL,
            durability INT NOT NULL DEFAULT 100,
            mods JSON NULL,
            tint INT NOT NULL DEFAULT 0,
            ammo_loaded INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            last_fired DATETIME NULL,
            total_shots INT NOT NULL DEFAULT 0,
            total_kills INT NOT NULL DEFAULT 0,
            meta JSON NULL,
            UNIQUE KEY idx_serial (serial),
            KEY idx_owner (owner_char_id),
            KEY idx_item (item_iid),
            KEY idx_weapon (weapon_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Licencias de armas
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_weapons_licenses (
            license_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            license_type VARCHAR(64) NOT NULL,
            issued_by BIGINT NULL,
            issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            expires_at DATETIME NULL,
            status ENUM('active', 'suspended', 'revoked', 'expired') NOT NULL DEFAULT 'active',
            revoked_by BIGINT NULL,
            revoked_at DATETIME NULL,
            revoke_reason VARCHAR(255) NULL,
            meta JSON NULL,
            UNIQUE KEY idx_char_type (char_id, license_type),
            KEY idx_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Log de uso de armas
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_weapons_log (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            weapon_iid BIGINT NOT NULL,
            serial VARCHAR(32) NOT NULL,
            char_id BIGINT NOT NULL,
            action ENUM('equip', 'unequip', 'fire', 'reload', 'repair', 'mod_add', 'mod_remove', 'transfer') NOT NULL,
            target_char_id BIGINT NULL,
            position JSON NULL,
            meta JSON NULL,
            KEY idx_ts (ts),
            KEY idx_weapon (weapon_iid),
            KEY idx_serial (serial),
            KEY idx_char (char_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Weapons.LoadCatalog()
    -- Cargar de la base de datos
    local dbWeapons = MySQL.query.await('SELECT * FROM ait_weapons_catalog')

    Weapons.catalog = {}

    -- Primero cargar defaults
    for weaponId, data in pairs(Weapons.DefaultCatalog) do
        Weapons.catalog[weaponId] = data
    end

    -- Override con datos de DB
    for _, w in ipairs(dbWeapons or {}) do
        Weapons.catalog[w.weapon_id] = {
            id = w.weapon_id,
            name = w.name,
            category = w.category,
            hash = w.hash,
            maxDurability = w.max_durability,
            basePrice = w.base_price,
            ammoType = w.ammo_type,
            clipSize = w.clip_size,
            recoilBase = w.recoil_base,
            spreadBase = w.spread_base,
            damageBase = w.damage_base,
            fireRate = w.fire_rate,
            legal = w.legal == 1,
            modsAllowed = w.mods_allowed and json.decode(w.mods_allowed) or {},
            meta = w.meta and json.decode(w.meta),
        }
    end
end

function Weapons.GetCatalogCount()
    local count = 0
    for _ in pairs(Weapons.catalog) do
        count = count + 1
    end
    return count
end

-- =================================================================================================
-- GESTION DE ARMAS
-- =================================================================================================

--- Obtiene datos de un arma del catalogo
---@param weaponId string ID del arma
---@return table|nil
function Weapons.GetWeaponData(weaponId)
    return Weapons.catalog[weaponId]
end

--- Obtiene una instancia de arma por serial
---@param serial string Serial del arma
---@return table|nil
function Weapons.GetWeaponBySerial(serial)
    local weapon = MySQL.query.await([[
        SELECT * FROM ait_weapons_instances WHERE serial = ?
    ]], { serial })

    if weapon and weapon[1] then
        local w = weapon[1]
        local catalogData = Weapons.catalog[w.weapon_id]

        return {
            iid = w.weapon_iid,
            id = w.weapon_id,
            serial = w.serial,
            durability = w.durability,
            mods = w.mods and json.decode(w.mods) or {},
            tint = w.tint,
            ammoLoaded = w.ammo_loaded,
            totalShots = w.total_shots,
            totalKills = w.total_kills,
            ownerCharId = w.owner_char_id,
            itemIid = w.item_iid,
            catalog = catalogData,
        }
    end

    return nil
end

--- Crea una nueva instancia de arma
---@param weaponId string ID del arma
---@param charId number ID del personaje propietario
---@param itemIid? number ID de instancia del item
---@return string|nil serial
function Weapons.CreateWeaponInstance(weaponId, charId, itemIid)
    local catalogData = Weapons.catalog[weaponId]
    if not catalogData then
        return nil
    end

    -- Generar serial unico
    local serial = Weapons.GenerateSerial()

    MySQL.insert.await([[
        INSERT INTO ait_weapons_instances
        (weapon_id, item_iid, owner_char_id, serial, durability, ammo_loaded)
        VALUES (?, ?, ?, ?, ?, 0)
    ]], { weaponId, itemIid, charId, serial, catalogData.maxDurability })

    if AIT.Log then
        AIT.Log.info('WEAPONS', 'Weapon instance created', {
            weaponId = weaponId,
            serial = serial,
            owner = charId,
        })
    end

    return serial
end

--- Genera un serial unico para un arma
---@return string
function Weapons.GenerateSerial()
    -- Formato: XXX-0000-XXXX (letras-numeros-mixto)
    local letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    local serial = ''

    -- 3 letras
    for i = 1, 3 do
        local idx = math.random(1, #letters)
        serial = serial .. letters:sub(idx, idx)
    end
    serial = serial .. '-'

    -- 4 numeros
    serial = serial .. string.format('%04d', math.random(0, 9999))
    serial = serial .. '-'

    -- 4 caracteres mixtos
    for i = 1, 4 do
        if math.random() > 0.5 then
            local idx = math.random(1, #letters)
            serial = serial .. letters:sub(idx, idx)
        else
            serial = serial .. tostring(math.random(0, 9))
        end
    end

    return serial
end

-- =================================================================================================
-- SISTEMA DE DURABILIDAD
-- =================================================================================================

--- Reduce la durabilidad de un arma
---@param serial string Serial del arma
---@param amount number Cantidad a reducir
function Weapons.ReduceDurability(serial, amount)
    if not Weapons.Config.DURABILITY_ENABLED then return end

    -- Anadir a cola para batch processing
    table.insert(Weapons.durabilityQueue, {
        serial = serial,
        amount = amount,
        timestamp = os.time(),
    })
end

--- Procesa la cola de durabilidad
function Weapons.FlushDurabilityQueue()
    if Weapons.processing or #Weapons.durabilityQueue == 0 then return end
    Weapons.processing = true

    -- Agrupar por serial
    local updates = {}
    while #Weapons.durabilityQueue > 0 do
        local item = table.remove(Weapons.durabilityQueue, 1)
        updates[item.serial] = (updates[item.serial] or 0) + item.amount
    end

    -- Ejecutar actualizaciones
    for serial, totalAmount in pairs(updates) do
        MySQL.query([[
            UPDATE ait_weapons_instances
            SET durability = GREATEST(0, durability - ?),
                total_shots = total_shots + 1,
                last_fired = NOW()
            WHERE serial = ?
        ]], { totalAmount, serial })
    end

    Weapons.processing = false
end

--- Repara un arma
---@param source number Server ID
---@param serial string Serial del arma
---@param amount? number Cantidad a reparar (nil = completo)
---@return boolean, string
function Weapons.RepairWeapon(source, serial, amount)
    local weapon = Weapons.GetWeaponBySerial(serial)
    if not weapon then
        return false, 'Arma no encontrada'
    end

    if not weapon.catalog then
        return false, 'Datos de arma no encontrados'
    end

    local maxDurability = weapon.catalog.maxDurability
    local currentDurability = weapon.durability
    local toRepair = amount or (maxDurability - currentDurability)

    if currentDurability >= maxDurability then
        return false, 'El arma ya esta en perfecto estado'
    end

    -- Calcular costo
    local repairCost = math.floor(toRepair * Weapons.Config.DURABILITY_REPAIR_COST_MULTIPLIER)

    -- Cobrar si hay sistema de economia
    if AIT.Engines.Economy then
        local charId = Weapons.GetCharId(source)
        if charId then
            local balance = AIT.Engines.Economy.GetBalance('char', charId, 'cash')
            if balance < repairCost then
                return false, 'No tienes suficiente dinero ($' .. repairCost .. ')'
            end

            AIT.Engines.Economy.RemoveMoney(source, charId, repairCost, 'cash', 'repair', 'Reparacion de arma')
        end
    end

    -- Reparar
    local newDurability = math.min(currentDurability + toRepair, maxDurability)

    MySQL.query([[
        UPDATE ait_weapons_instances SET durability = ? WHERE serial = ?
    ]], { newDurability, serial })

    Weapons.LogWeaponAction(weapon.iid, serial, Weapons.GetCharId(source), 'repair', nil, {
        oldDurability = currentDurability,
        newDurability = newDurability,
        cost = repairCost,
    })

    if AIT.EventBus then
        AIT.EventBus.emit('weapons.repaired', {
            source = source,
            serial = serial,
            durability = newDurability,
        })
    end

    return true, 'Arma reparada'
end

--- Obtiene el multiplicador de rendimiento basado en durabilidad
---@param durability number Durabilidad actual
---@param maxDurability number Durabilidad maxima
---@return table
function Weapons.GetDurabilityEffects(durability, maxDurability)
    local percent = (durability / maxDurability) * 100

    if percent <= Weapons.Config.DURABILITY_BREAK_THRESHOLD then
        return { canFire = false, recoil = 1.0, spread = 1.0, damage = 1.0 }
    end

    if percent <= Weapons.Config.DURABILITY_DEGRADE_THRESHOLD then
        local degradeFactor = 1 - (percent / Weapons.Config.DURABILITY_DEGRADE_THRESHOLD)
        return {
            canFire = true,
            recoil = 1.0 + (degradeFactor * 0.3),  -- Hasta +30% recoil
            spread = 1.0 + (degradeFactor * 0.5),   -- Hasta +50% spread
            damage = 1.0 - (degradeFactor * 0.2),   -- Hasta -20% damage
        }
    end

    return { canFire = true, recoil = 1.0, spread = 1.0, damage = 1.0 }
end

-- =================================================================================================
-- SISTEMA DE MODIFICACIONES
-- =================================================================================================

--- Anade una modificacion a un arma
---@param source number Server ID
---@param serial string Serial del arma
---@param modId string ID de la modificacion
---@return boolean, string
function Weapons.AddMod(source, serial, modId)
    if not Weapons.Config.MODS_ENABLED then
        return false, 'Sistema de mods desactivado'
    end

    local weapon = Weapons.GetWeaponBySerial(serial)
    if not weapon then
        return false, 'Arma no encontrada'
    end

    local mod = Weapons.ModsCatalog[modId]
    if not mod then
        return false, 'Modificacion no encontrada'
    end

    -- Verificar si el arma permite este tipo de mod
    if weapon.catalog and weapon.catalog.modsAllowed then
        local allowed = false
        for _, allowedType in ipairs(weapon.catalog.modsAllowed) do
            if allowedType == mod.type then
                allowed = true
                break
            end
        end
        if not allowed then
            return false, 'Esta arma no acepta este tipo de modificacion'
        end
    end

    -- Verificar limite de mods
    if #weapon.mods >= Weapons.Config.MAX_MODS_PER_WEAPON then
        return false, 'Limite de modificaciones alcanzado'
    end

    -- Verificar si ya tiene un mod del mismo tipo
    for _, existingMod in ipairs(weapon.mods) do
        local existingModData = Weapons.ModsCatalog[existingMod]
        if existingModData and existingModData.type == mod.type then
            return false, 'Ya tienes una modificacion de tipo ' .. mod.type
        end
    end

    -- Cobrar si tiene precio
    if mod.price and mod.price > 0 and AIT.Engines.Economy then
        local charId = Weapons.GetCharId(source)
        if charId then
            local balance = AIT.Engines.Economy.GetBalance('char', charId, 'cash')
            if balance < mod.price then
                return false, 'No tienes suficiente dinero ($' .. mod.price .. ')'
            end
            AIT.Engines.Economy.RemoveMoney(source, charId, mod.price, 'cash', 'purchase', 'Modificacion de arma: ' .. mod.name)
        end
    end

    -- Anadir mod
    local newMods = weapon.mods
    table.insert(newMods, modId)

    MySQL.query([[
        UPDATE ait_weapons_instances SET mods = ? WHERE serial = ?
    ]], { json.encode(newMods), serial })

    Weapons.LogWeaponAction(weapon.iid, serial, Weapons.GetCharId(source), 'mod_add', nil, { modId = modId })

    if AIT.EventBus then
        AIT.EventBus.emit('weapons.mod.added', {
            source = source,
            serial = serial,
            modId = modId,
        })
    end

    return true, 'Modificacion instalada'
end

--- Remueve una modificacion de un arma
---@param source number Server ID
---@param serial string Serial del arma
---@param modId string ID de la modificacion
---@return boolean, string
function Weapons.RemoveMod(source, serial, modId)
    local weapon = Weapons.GetWeaponBySerial(serial)
    if not weapon then
        return false, 'Arma no encontrada'
    end

    -- Buscar y remover mod
    local found = false
    local newMods = {}
    for _, existingMod in ipairs(weapon.mods) do
        if existingMod == modId and not found then
            found = true
        else
            table.insert(newMods, existingMod)
        end
    end

    if not found then
        return false, 'Modificacion no encontrada en el arma'
    end

    MySQL.query([[
        UPDATE ait_weapons_instances SET mods = ? WHERE serial = ?
    ]], { json.encode(newMods), serial })

    -- Devolver item si no se destruye
    if not Weapons.Config.MOD_REMOVAL_DESTROYS and AIT.Engines.Inventory then
        local charId = Weapons.GetCharId(source)
        if charId then
            -- Crear item de mod en inventario
            -- AIT.Engines.Inventory.GiveItem(source, 'char', charId, 'mod_' .. modId, 1)
        end
    end

    Weapons.LogWeaponAction(weapon.iid, serial, Weapons.GetCharId(source), 'mod_remove', nil, { modId = modId })

    return true, 'Modificacion removida'
end

--- Calcula los efectos totales de las modificaciones
---@param mods table Lista de IDs de mods
---@return table
function Weapons.CalculateModEffects(mods)
    local effects = {
        clipSize = 0,
        recoil = 0,
        spread = 0,
        damage = 0,
        fireRate = 0,
    }

    for _, modId in ipairs(mods or {}) do
        local mod = Weapons.ModsCatalog[modId]
        if mod and mod.effect then
            for stat, value in pairs(mod.effect) do
                if effects[stat] then
                    effects[stat] = effects[stat] + value
                end
            end
        end
    end

    return effects
end

-- =================================================================================================
-- SISTEMA DE LICENCIAS
-- =================================================================================================

--- Verifica si un personaje tiene licencia para un arma
---@param charId number ID del personaje
---@param weaponId string ID del arma
---@return boolean, string
function Weapons.HasLicense(charId, weaponId)
    if not Weapons.Config.LICENSES_ENABLED then
        return true, 'ok'
    end

    local weaponData = Weapons.catalog[weaponId]
    if not weaponData then
        return false, 'Arma no encontrada'
    end

    local category = Weapons.Config.WEAPON_CATEGORIES[weaponData.category]
    if not category or not category.licenseRequired then
        return true, 'ok'
    end

    -- Verificar cache
    local cacheKey = charId .. ':' .. category.licenseRequired
    if Weapons.licensesCache[cacheKey] then
        local cached = Weapons.licensesCache[cacheKey]
        if cached.expires > os.time() then
            return cached.hasLicense, cached.reason
        end
    end

    -- Verificar en DB
    local license = MySQL.query.await([[
        SELECT * FROM ait_weapons_licenses
        WHERE char_id = ? AND license_type = ? AND status = 'active'
        AND (expires_at IS NULL OR expires_at > NOW())
    ]], { charId, category.licenseRequired })

    local hasLicense = license and #license > 0
    local reason = hasLicense and 'ok' or 'Necesitas licencia: ' .. category.licenseRequired

    -- Guardar en cache
    Weapons.licensesCache[cacheKey] = {
        hasLicense = hasLicense,
        reason = reason,
        expires = os.time() + 60,
    }

    return hasLicense, reason
end

--- Otorga una licencia de armas
---@param charId number ID del personaje
---@param licenseType string Tipo de licencia
---@param issuedBy number|nil ID del personaje que otorga
---@param duration number|nil Duracion en dias (nil = permanente)
---@return boolean, string
function Weapons.GrantLicense(charId, licenseType, issuedBy, duration)
    local expiresAt = nil
    if duration then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 86400))
    end

    MySQL.insert.await([[
        INSERT INTO ait_weapons_licenses (char_id, license_type, issued_by, expires_at)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            status = 'active',
            issued_by = VALUES(issued_by),
            issued_at = NOW(),
            expires_at = VALUES(expires_at),
            revoked_by = NULL,
            revoked_at = NULL,
            revoke_reason = NULL
    ]], { charId, licenseType, issuedBy, expiresAt })

    -- Invalidar cache
    local cacheKey = charId .. ':' .. licenseType
    Weapons.licensesCache[cacheKey] = nil

    if AIT.EventBus then
        AIT.EventBus.emit('weapons.license.granted', {
            charId = charId,
            licenseType = licenseType,
            issuedBy = issuedBy,
        })
    end

    if AIT.Log then
        AIT.Log.info('WEAPONS', 'License granted', {
            charId = charId,
            licenseType = licenseType,
            issuedBy = issuedBy,
        })
    end

    return true, 'Licencia otorgada'
end

--- Revoca una licencia de armas
---@param charId number ID del personaje
---@param licenseType string Tipo de licencia
---@param revokedBy number|nil ID del personaje que revoca
---@param reason string|nil Razon de revocacion
---@return boolean, string
function Weapons.RevokeLicense(charId, licenseType, revokedBy, reason)
    MySQL.query.await([[
        UPDATE ait_weapons_licenses SET
            status = 'revoked',
            revoked_by = ?,
            revoked_at = NOW(),
            revoke_reason = ?
        WHERE char_id = ? AND license_type = ? AND status = 'active'
    ]], { revokedBy, reason, charId, licenseType })

    -- Invalidar cache
    local cacheKey = charId .. ':' .. licenseType
    Weapons.licensesCache[cacheKey] = nil

    if AIT.EventBus then
        AIT.EventBus.emit('weapons.license.revoked', {
            charId = charId,
            licenseType = licenseType,
            revokedBy = revokedBy,
            reason = reason,
        })
    end

    return true, 'Licencia revocada'
end

--- Obtiene todas las licencias de un personaje
---@param charId number ID del personaje
---@return table
function Weapons.GetLicenses(charId)
    local licenses = MySQL.query.await([[
        SELECT * FROM ait_weapons_licenses
        WHERE char_id = ? AND status = 'active'
        AND (expires_at IS NULL OR expires_at > NOW())
    ]], { charId })

    return licenses or {}
end

-- =================================================================================================
-- RECOIL Y SPREAD PERSONALIZADOS
-- =================================================================================================

--- Calcula los valores finales de recoil y spread para un arma
---@param weapon table Datos de la instancia del arma
---@return table
function Weapons.CalculateWeaponStats(weapon)
    local catalog = weapon.catalog
    if not catalog then
        return { recoil = 1.0, spread = 1.0, damage = 1.0, fireRate = 0.1 }
    end

    -- Stats base
    local recoil = catalog.recoilBase * Weapons.Config.RECOIL_MULTIPLIER_BASE
    local spread = catalog.spreadBase * Weapons.Config.SPREAD_MULTIPLIER_BASE
    local damage = catalog.damageBase
    local fireRate = catalog.fireRate or 0.1

    -- Aplicar efectos de mods
    local modEffects = Weapons.CalculateModEffects(weapon.mods)
    recoil = recoil + (recoil * modEffects.recoil)
    spread = spread + (spread * modEffects.spread)
    damage = damage + (damage * (modEffects.damage or 0))
    fireRate = fireRate + (modEffects.fireRate or 0)

    -- Aplicar efectos de durabilidad
    if Weapons.Config.DURABILITY_ENABLED and weapon.durability then
        local durabilityEffects = Weapons.GetDurabilityEffects(weapon.durability, catalog.maxDurability)
        recoil = recoil * durabilityEffects.recoil
        spread = spread * durabilityEffects.spread
        damage = damage * durabilityEffects.damage
    end

    return {
        recoil = math.max(recoil, 0.1),
        spread = math.max(spread, 0.1),
        damage = math.max(damage, 1),
        fireRate = math.max(fireRate, 0.01),
        clipSize = (catalog.clipSize or 12) + (modEffects.clipSize or 0),
    }
end

-- =================================================================================================
-- LOGGING
-- =================================================================================================

--- Registra una accion de arma
---@param weaponIid number ID de instancia del arma
---@param serial string Serial del arma
---@param charId number ID del personaje
---@param action string Accion realizada
---@param targetCharId number|nil ID del personaje objetivo
---@param meta table|nil Metadatos adicionales
function Weapons.LogWeaponAction(weaponIid, serial, charId, action, targetCharId, meta)
    MySQL.insert([[
        INSERT INTO ait_weapons_log
        (weapon_iid, serial, char_id, action, target_char_id, meta)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        weaponIid,
        serial,
        charId,
        action,
        targetCharId,
        meta and json.encode(meta)
    })
end

-- =================================================================================================
-- UTILIDADES
-- =================================================================================================

--- Obtiene el ID de personaje de un jugador
---@param source number Server ID
---@return number|nil
function Weapons.GetCharId(source)
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

function Weapons.OnPlayerDisconnect(event)
    local source = event.payload.source
    Weapons.equippedWeapons[source] = nil
end

function Weapons.OnCharacterSelected(event)
    local source = event.payload.source
    local charId = event.payload.charId

    -- Cargar licencias en cache
    local licenses = Weapons.GetLicenses(charId)
    for _, license in ipairs(licenses) do
        local cacheKey = charId .. ':' .. license.license_type
        Weapons.licensesCache[cacheKey] = {
            hasLicense = true,
            reason = 'ok',
            expires = os.time() + 300,
        }
    end
end

function Weapons.OnItemUsed(event)
    local payload = event.payload
    if payload.itemType == 'weapon' then
        -- El item es un arma, verificar serial y equipar
    end
end

-- =================================================================================================
-- LIMPIEZA
-- =================================================================================================

function Weapons.CleanupCache()
    local currentTime = os.time()

    -- Limpiar cache de licencias
    for key, cached in pairs(Weapons.licensesCache) do
        if cached.expires < currentTime then
            Weapons.licensesCache[key] = nil
        end
    end

    -- Limpiar cache de mods
    for key, cached in pairs(Weapons.modsCache) do
        if cached.expires and cached.expires < currentTime then
            Weapons.modsCache[key] = nil
        end
    end
end

-- =================================================================================================
-- API PUBLICA
-- =================================================================================================

Weapons.GetWeapon = Weapons.GetWeaponData
Weapons.GetInstance = Weapons.GetWeaponBySerial
Weapons.CreateInstance = Weapons.CreateWeaponInstance
Weapons.Repair = Weapons.RepairWeapon
Weapons.InstallMod = Weapons.AddMod
Weapons.UninstallMod = Weapons.RemoveMod
Weapons.CheckLicense = Weapons.HasLicense
Weapons.IssueLicense = Weapons.GrantLicense
Weapons.SuspendLicense = Weapons.RevokeLicense
Weapons.GetStats = Weapons.CalculateWeaponStats
Weapons.DegradeWeapon = Weapons.ReduceDurability

-- =================================================================================================
-- REGISTRAR ENGINE
-- =================================================================================================

AIT.Engines.Combat.Weapons = Weapons

return Weapons
