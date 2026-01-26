-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb INVENTORY ENGINE
-- Sistema de inventario inteligente con items, stashes, crafting y anti-dupe
-- Optimizado para 2048 slots
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}

local Inventory = {
    catalog = {},
    itemCache = {},
    stashCache = {},
    txQueue = {},
    locks = {},
    processing = false,
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Inventory.Initialize()
    -- Crear tablas si no existen
    Inventory.EnsureTables()

    -- Cargar catálogo de items
    Inventory.LoadCatalog()

    -- Registrar jobs
    if AIT.Scheduler then
        AIT.Scheduler.register('inventory_cleanup', {
            interval = 3600,
            fn = Inventory.CleanupExpired
        })

        AIT.Scheduler.register('inventory_integrity', {
            interval = 300,
            fn = Inventory.IntegrityCheck
        })

        AIT.Scheduler.register('inventory_flush', {
            interval = 2,
            fn = Inventory.FlushTransactions
        })
    end

    -- Thread de flush
    CreateThread(function()
        while true do
            Wait(2000)
            Inventory.FlushTransactions()
        end
    end)

    if AIT.Log then
        AIT.Log.info('INVENTORY', 'Inventory engine initialized with ' .. #Inventory.catalog .. ' items')
    end

    return true
end

function Inventory.EnsureTables()
    -- Items catalog
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_items_catalog (
            item_id VARCHAR(64) PRIMARY KEY,
            name VARCHAR(128) NOT NULL,
            label VARCHAR(128) NOT NULL,
            description TEXT NULL,
            type ENUM('item', 'weapon', 'ammo', 'consumable', 'material', 'tool',
                      'clothing', 'accessory', 'key', 'document', 'drug', 'collectible',
                      'electronic', 'container', 'currency', 'misc') NOT NULL,
            category VARCHAR(64) NULL,
            rarity TINYINT NOT NULL DEFAULT 1,
            weight INT NOT NULL DEFAULT 100,
            stack_size INT NOT NULL DEFAULT 1,
            useable TINYINT(1) NOT NULL DEFAULT 0,
            unique_item TINYINT(1) NOT NULL DEFAULT 0,
            legal TINYINT(1) NOT NULL DEFAULT 1,
            base_price INT NOT NULL DEFAULT 0,
            can_sell TINYINT(1) NOT NULL DEFAULT 1,
            can_trade TINYINT(1) NOT NULL DEFAULT 1,
            can_drop TINYINT(1) NOT NULL DEFAULT 1,
            has_durability TINYINT(1) NOT NULL DEFAULT 0,
            max_durability INT NULL,
            has_decay TINYINT(1) NOT NULL DEFAULT 0,
            decay_rate INT NULL,
            effects JSON NULL,
            image VARCHAR(255) NULL,
            model VARCHAR(64) NULL,
            meta JSON NULL,
            KEY idx_type (type),
            KEY idx_category (category)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Item instances
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_item_instances (
            item_iid BIGINT AUTO_INCREMENT PRIMARY KEY,
            item_id VARCHAR(64) NOT NULL,
            owner_type ENUM('char', 'stash', 'vehicle', 'property', 'business',
                            'faction', 'system', 'ground', 'shop') NOT NULL,
            owner_id BIGINT NOT NULL,
            slot INT NULL,
            quantity INT NOT NULL DEFAULT 1,
            durability INT NULL,
            quality INT NULL,
            serial VARCHAR(64) NULL,
            metadata JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            expires_at DATETIME NULL,
            UNIQUE KEY idx_serial (serial),
            KEY idx_owner (owner_type, owner_id),
            KEY idx_item (item_id),
            KEY idx_slot (owner_type, owner_id, slot)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Transaction log
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_item_tx (
            itx_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            item_iid BIGINT NOT NULL,
            item_id VARCHAR(64) NOT NULL,
            from_type VARCHAR(32) NOT NULL,
            from_id BIGINT NOT NULL,
            to_type VARCHAR(32) NOT NULL,
            to_id BIGINT NOT NULL,
            quantity INT NOT NULL,
            action ENUM('create', 'move', 'split', 'merge', 'use', 'destroy', 'decay') NOT NULL,
            actor_player_id BIGINT NULL,
            actor_char_id BIGINT NULL,
            reason VARCHAR(255) NULL,
            meta JSON NULL,
            sig CHAR(64) NOT NULL,
            KEY idx_ts (ts),
            KEY idx_item (item_iid),
            KEY idx_from (from_type, from_id),
            KEY idx_to (to_type, to_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Stashes
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_stashes (
            stash_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            stash_key VARCHAR(64) NOT NULL,
            owner_type ENUM('char', 'property', 'vehicle', 'faction', 'business', 'public') NOT NULL,
            owner_id BIGINT NULL,
            label VARCHAR(128) NOT NULL,
            max_slots INT NOT NULL DEFAULT 50,
            max_weight INT NOT NULL DEFAULT 100000,
            access_type ENUM('owner', 'shared', 'public', 'faction', 'job') NOT NULL DEFAULT 'owner',
            access_list JSON NULL,
            position JSON NULL,
            is_evidence TINYINT(1) NOT NULL DEFAULT 0,
            status ENUM('active', 'locked', 'seized', 'deleted') NOT NULL DEFAULT 'active',
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            last_accessed DATETIME NULL,
            meta JSON NULL,
            UNIQUE KEY idx_key (stash_key),
            KEY idx_owner (owner_type, owner_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Inventory.LoadCatalog()
    local items = MySQL.query.await('SELECT * FROM ait_items_catalog')

    Inventory.catalog = {}
    for _, item in ipairs(items or {}) do
        Inventory.catalog[item.item_id] = {
            id = item.item_id,
            name = item.name,
            label = item.label,
            description = item.description,
            type = item.type,
            category = item.category,
            rarity = item.rarity,
            weight = item.weight,
            stackSize = item.stack_size,
            useable = item.useable == 1,
            unique = item.unique_item == 1,
            legal = item.legal == 1,
            basePrice = item.base_price,
            canSell = item.can_sell == 1,
            canTrade = item.can_trade == 1,
            canDrop = item.can_drop == 1,
            hasDurability = item.has_durability == 1,
            maxDurability = item.max_durability,
            hasDecay = item.has_decay == 1,
            decayRate = item.decay_rate,
            effects = item.effects and json.decode(item.effects),
            image = item.image,
            model = item.model,
            meta = item.meta and json.decode(item.meta),
        }
    end

    -- Cargar items por defecto si el catálogo está vacío
    if #items == 0 then
        Inventory.LoadDefaultItems()
    end
end

function Inventory.LoadDefaultItems()
    local defaultItems = {
        -- Básicos
        { id = 'phone', name = 'Phone', label = 'Teléfono', type = 'electronic', weight = 100, useable = 1, basePrice = 500 },
        { id = 'id_card', name = 'ID Card', label = 'Carnet de Identidad', type = 'document', weight = 10, basePrice = 100 },
        { id = 'driver_license', name = 'Driver License', label = 'Carnet de Conducir', type = 'document', weight = 10, basePrice = 500 },
        { id = 'weapon_license', name = 'Weapon License', label = 'Licencia de Armas', type = 'document', weight = 10, basePrice = 10000 },

        -- Comida
        { id = 'bread', name = 'Bread', label = 'Pan', type = 'consumable', weight = 100, stackSize = 10, useable = 1, basePrice = 10 },
        { id = 'water', name = 'Water', label = 'Agua', type = 'consumable', weight = 200, stackSize = 10, useable = 1, basePrice = 5 },
        { id = 'sandwich', name = 'Sandwich', label = 'Sandwich', type = 'consumable', weight = 150, stackSize = 5, useable = 1, basePrice = 25 },
        { id = 'burger', name = 'Burger', label = 'Hamburguesa', type = 'consumable', weight = 200, stackSize = 5, useable = 1, basePrice = 50 },
        { id = 'pizza', name = 'Pizza', label = 'Pizza', type = 'consumable', weight = 300, stackSize = 3, useable = 1, basePrice = 75 },
        { id = 'coffee', name = 'Coffee', label = 'Café', type = 'consumable', weight = 150, stackSize = 10, useable = 1, basePrice = 15 },
        { id = 'donut', name = 'Donut', label = 'Donut', type = 'consumable', weight = 100, stackSize = 6, useable = 1, basePrice = 20 },

        -- Médico
        { id = 'bandage', name = 'Bandage', label = 'Vendaje', type = 'consumable', weight = 50, stackSize = 20, useable = 1, basePrice = 100 },
        { id = 'firstaid', name = 'First Aid Kit', label = 'Botiquín', type = 'consumable', weight = 500, stackSize = 5, useable = 1, basePrice = 500 },
        { id = 'painkillers', name = 'Painkillers', label = 'Analgésicos', type = 'consumable', weight = 50, stackSize = 10, useable = 1, basePrice = 200 },

        -- Herramientas
        { id = 'lockpick', name = 'Lockpick', label = 'Ganzúa', type = 'tool', weight = 100, stackSize = 5, useable = 1, legal = 0, basePrice = 500 },
        { id = 'repairkit', name = 'Repair Kit', label = 'Kit de Reparación', type = 'tool', weight = 1000, stackSize = 1, useable = 1, basePrice = 1000 },
        { id = 'radio', name = 'Radio', label = 'Radio', type = 'electronic', weight = 500, useable = 1, basePrice = 250 },

        -- Materiales
        { id = 'steel', name = 'Steel', label = 'Acero', type = 'material', weight = 500, stackSize = 50, basePrice = 50 },
        { id = 'plastic', name = 'Plastic', label = 'Plástico', type = 'material', weight = 100, stackSize = 100, basePrice = 10 },
        { id = 'aluminum', name = 'Aluminum', label = 'Aluminio', type = 'material', weight = 200, stackSize = 50, basePrice = 30 },
        { id = 'rubber', name = 'Rubber', label = 'Goma', type = 'material', weight = 150, stackSize = 50, basePrice = 20 },
        { id = 'glass', name = 'Glass', label = 'Cristal', type = 'material', weight = 300, stackSize = 25, basePrice = 25 },
        { id = 'copper', name = 'Copper Wire', label = 'Cable de Cobre', type = 'material', weight = 100, stackSize = 50, basePrice = 40 },
        { id = 'electronics', name = 'Electronics', label = 'Componentes Electrónicos', type = 'material', weight = 200, stackSize = 25, basePrice = 100 },

        -- Armas (ejemplos)
        { id = 'weapon_pistol', name = 'Pistol', label = 'Pistola', type = 'weapon', weight = 1000, unique = 1, legal = 0, hasDurability = 1, maxDurability = 100, basePrice = 5000 },
        { id = 'weapon_smg', name = 'SMG', label = 'Subfusil', type = 'weapon', weight = 2000, unique = 1, legal = 0, hasDurability = 1, maxDurability = 100, basePrice = 15000 },
        { id = 'weapon_rifle', name = 'Rifle', label = 'Rifle', type = 'weapon', weight = 3000, unique = 1, legal = 0, hasDurability = 1, maxDurability = 100, basePrice = 25000 },

        -- Munición
        { id = 'ammo_pistol', name = 'Pistol Ammo', label = 'Munición de Pistola', type = 'ammo', weight = 10, stackSize = 250, basePrice = 10 },
        { id = 'ammo_smg', name = 'SMG Ammo', label = 'Munición de Subfusil', type = 'ammo', weight = 10, stackSize = 250, basePrice = 15 },
        { id = 'ammo_rifle', name = 'Rifle Ammo', label = 'Munición de Rifle', type = 'ammo', weight = 15, stackSize = 250, basePrice = 20 },

        -- Llaves
        { id = 'vehicle_key', name = 'Vehicle Key', label = 'Llave de Vehículo', type = 'key', weight = 50, unique = 1, canDrop = 0 },
        { id = 'house_key', name = 'House Key', label = 'Llave de Casa', type = 'key', weight = 50, unique = 1, canDrop = 0 },
    }

    for _, item in ipairs(defaultItems) do
        MySQL.insert.await([[
            INSERT IGNORE INTO ait_items_catalog
            (item_id, name, label, type, weight, stack_size, useable, unique_item, legal, has_durability, max_durability, base_price)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            item.id, item.name, item.label, item.type,
            item.weight or 100, item.stackSize or 1, item.useable or 0,
            item.unique or 0, item.legal == nil and 1 or item.legal,
            item.hasDurability or 0, item.maxDurability,
            item.basePrice or 0
        })
    end

    -- Recargar catálogo
    Inventory.LoadCatalog()
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- OPERACIONES DE INVENTARIO
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene el inventario de un propietario
---@param ownerType string
---@param ownerId number
---@return table
function Inventory.GetInventory(ownerType, ownerId)
    local cacheKey = ownerType .. ':' .. ownerId
    if Inventory.itemCache[cacheKey] then
        local cached = Inventory.itemCache[cacheKey]
        if cached.expires > os.time() then
            return cached.items
        end
    end

    local items = MySQL.query.await([[
        SELECT * FROM ait_item_instances
        WHERE owner_type = ? AND owner_id = ?
        ORDER BY slot ASC
    ]], { ownerType, ownerId })

    -- Enriquecer con datos del catálogo
    local enrichedItems = {}
    for _, item in ipairs(items or {}) do
        local catalogItem = Inventory.catalog[item.item_id]
        if catalogItem then
            table.insert(enrichedItems, {
                iid = item.item_iid,
                id = item.item_id,
                slot = item.slot,
                quantity = item.quantity,
                durability = item.durability,
                quality = item.quality,
                serial = item.serial,
                metadata = item.metadata and json.decode(item.metadata),
                -- Datos del catálogo
                name = catalogItem.name,
                label = catalogItem.label,
                type = catalogItem.type,
                weight = catalogItem.weight,
                rarity = catalogItem.rarity,
                image = catalogItem.image,
                useable = catalogItem.useable,
                unique = catalogItem.unique,
            })
        end
    end

    Inventory.itemCache[cacheKey] = {
        items = enrichedItems,
        expires = os.time() + 30
    }

    return enrichedItems
end

--- Obtiene el peso total de un inventario
---@param ownerType string
---@param ownerId number
---@return number
function Inventory.GetWeight(ownerType, ownerId)
    local items = Inventory.GetInventory(ownerType, ownerId)
    local weight = 0

    for _, item in ipairs(items) do
        weight = weight + (item.weight * item.quantity)
    end

    return weight
end

--- Da un item a un propietario
---@param source number
---@param ownerType string
---@param ownerId number
---@param itemId string
---@param quantity number
---@param metadata? table
---@return boolean, number|string
function Inventory.GiveItem(source, ownerType, ownerId, itemId, quantity, metadata)
    quantity = quantity or 1

    -- Verificar que el item existe en el catálogo
    local catalogItem = Inventory.catalog[itemId]
    if not catalogItem then
        return false, 'Item not found in catalog'
    end

    -- Rate limiting
    if source and AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'inventory.give')
        if not allowed then
            return false, 'Rate limit exceeded'
        end
    end

    -- Verificar peso
    local currentWeight = Inventory.GetWeight(ownerType, ownerId)
    local itemWeight = catalogItem.weight * quantity
    local maxWeight = 100000 -- Default max weight

    if ownerType == 'char' then
        maxWeight = 50000 -- 50kg para personajes
    end

    if currentWeight + itemWeight > maxWeight then
        return false, 'Inventory full (weight)'
    end

    -- Lock para anti-dupe
    local lockKey = ownerType .. ':' .. ownerId
    if Inventory.locks[lockKey] then
        return false, 'Inventory locked'
    end
    Inventory.locks[lockKey] = true

    -- Generar serial si es único
    local serial = nil
    if catalogItem.unique then
        serial = Inventory.GenerateSerial()
    end

    -- Encontrar slot disponible o stack existente
    local slot = nil
    local existingIid = nil

    if not catalogItem.unique and catalogItem.stackSize > 1 then
        -- Buscar stack existente
        local existing = MySQL.query.await([[
            SELECT item_iid, slot, quantity FROM ait_item_instances
            WHERE owner_type = ? AND owner_id = ? AND item_id = ? AND quantity < ?
            ORDER BY slot ASC LIMIT 1
        ]], { ownerType, ownerId, itemId, catalogItem.stackSize })

        if existing and existing[1] then
            existingIid = existing[1].item_iid
            slot = existing[1].slot

            -- Calcular cuánto cabe
            local canAdd = catalogItem.stackSize - existing[1].quantity
            if canAdd >= quantity then
                -- Todo cabe en el stack existente
                MySQL.query.await([[
                    UPDATE ait_item_instances SET quantity = quantity + ? WHERE item_iid = ?
                ]], { quantity, existingIid })

                Inventory.InvalidateCache(ownerType, ownerId)
                Inventory.locks[lockKey] = nil
                Inventory.LogTransaction(existingIid, itemId, 'system', 0, ownerType, ownerId, quantity, 'merge', source, nil, 'Give item')

                return true, existingIid
            end
        end
    end

    -- Encontrar slot vacío
    if not slot then
        local usedSlots = MySQL.query.await([[
            SELECT slot FROM ait_item_instances
            WHERE owner_type = ? AND owner_id = ?
        ]], { ownerType, ownerId })

        local occupied = {}
        for _, s in ipairs(usedSlots or {}) do
            occupied[s.slot] = true
        end

        for i = 1, 100 do -- Max 100 slots
            if not occupied[i] then
                slot = i
                break
            end
        end

        if not slot then
            Inventory.locks[lockKey] = nil
            return false, 'No available slots'
        end
    end

    -- Crear el item
    local durability = nil
    if catalogItem.hasDurability then
        durability = catalogItem.maxDurability or 100
    end

    local iid = MySQL.insert.await([[
        INSERT INTO ait_item_instances
        (item_id, owner_type, owner_id, slot, quantity, durability, quality, serial, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        itemId, ownerType, ownerId, slot, quantity,
        durability, metadata and metadata.quality or nil,
        serial, metadata and json.encode(metadata)
    })

    Inventory.InvalidateCache(ownerType, ownerId)
    Inventory.locks[lockKey] = nil

    Inventory.LogTransaction(iid, itemId, 'system', 0, ownerType, ownerId, quantity, 'create', source, nil, 'Give item')

    if AIT.EventBus then
        AIT.EventBus.emit('inventory.item.spawned', {
            iid = iid,
            itemId = itemId,
            owner = { type = ownerType, id = ownerId },
            quantity = quantity,
        })
    end

    return true, iid
end

--- Quita un item de un propietario
---@param source number
---@param ownerType string
---@param ownerId number
---@param itemId string
---@param quantity number
---@param iid? number
---@return boolean, string
function Inventory.RemoveItem(source, ownerType, ownerId, itemId, quantity, iid)
    quantity = quantity or 1

    -- Lock
    local lockKey = ownerType .. ':' .. ownerId
    if Inventory.locks[lockKey] then
        return false, 'Inventory locked'
    end
    Inventory.locks[lockKey] = true

    local query, params

    if iid then
        query = [[
            SELECT * FROM ait_item_instances
            WHERE item_iid = ? AND owner_type = ? AND owner_id = ?
        ]]
        params = { iid, ownerType, ownerId }
    else
        query = [[
            SELECT * FROM ait_item_instances
            WHERE item_id = ? AND owner_type = ? AND owner_id = ?
            ORDER BY quantity ASC LIMIT 1
        ]]
        params = { itemId, ownerType, ownerId }
    end

    local item = MySQL.query.await(query, params)

    if not item or not item[1] then
        Inventory.locks[lockKey] = nil
        return false, 'Item not found'
    end

    item = item[1]

    if item.quantity < quantity then
        Inventory.locks[lockKey] = nil
        return false, 'Not enough items'
    end

    if item.quantity == quantity then
        -- Eliminar completamente
        MySQL.query.await([[
            DELETE FROM ait_item_instances WHERE item_iid = ?
        ]], { item.item_iid })
    else
        -- Reducir cantidad
        MySQL.query.await([[
            UPDATE ait_item_instances SET quantity = quantity - ? WHERE item_iid = ?
        ]], { quantity, item.item_iid })
    end

    Inventory.InvalidateCache(ownerType, ownerId)
    Inventory.locks[lockKey] = nil

    Inventory.LogTransaction(item.item_iid, item.item_id, ownerType, ownerId, 'system', 0, quantity, 'destroy', source, nil, 'Remove item')

    if AIT.EventBus then
        AIT.EventBus.emit('inventory.item.destroyed', {
            iid = item.item_iid,
            itemId = item.item_id,
            owner = { type = ownerType, id = ownerId },
            quantity = quantity,
        })
    end

    return true, 'removed'
end

--- Mueve un item entre propietarios
---@param source number
---@param fromType string
---@param fromId number
---@param toType string
---@param toId number
---@param iid number
---@param quantity? number
---@param toSlot? number
---@return boolean, string
function Inventory.MoveItem(source, fromType, fromId, toType, toId, iid, quantity, toSlot)
    -- Rate limiting
    if source and AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'inventory.move')
        if not allowed then
            return false, 'Rate limit exceeded'
        end
    end

    -- Lock ambos inventarios
    local fromLock = fromType .. ':' .. fromId
    local toLock = toType .. ':' .. toId

    if Inventory.locks[fromLock] or Inventory.locks[toLock] then
        return false, 'Inventory locked'
    end

    Inventory.locks[fromLock] = true
    Inventory.locks[toLock] = true

    -- Obtener item
    local item = MySQL.query.await([[
        SELECT * FROM ait_item_instances WHERE item_iid = ? AND owner_type = ? AND owner_id = ?
    ]], { iid, fromType, fromId })

    if not item or not item[1] then
        Inventory.locks[fromLock] = nil
        Inventory.locks[toLock] = nil
        return false, 'Item not found'
    end

    item = item[1]
    quantity = quantity or item.quantity

    if quantity > item.quantity then
        Inventory.locks[fromLock] = nil
        Inventory.locks[toLock] = nil
        return false, 'Not enough items'
    end

    -- Verificar peso en destino
    local catalogItem = Inventory.catalog[item.item_id]
    if catalogItem then
        local destWeight = Inventory.GetWeight(toType, toId)
        local itemWeight = catalogItem.weight * quantity
        local maxWeight = toType == 'char' and 50000 or 100000

        if destWeight + itemWeight > maxWeight then
            Inventory.locks[fromLock] = nil
            Inventory.locks[toLock] = nil
            return false, 'Destination full (weight)'
        end
    end

    -- Encontrar slot en destino
    if not toSlot then
        local usedSlots = MySQL.query.await([[
            SELECT slot FROM ait_item_instances WHERE owner_type = ? AND owner_id = ?
        ]], { toType, toId })

        local occupied = {}
        for _, s in ipairs(usedSlots or {}) do
            occupied[s.slot] = true
        end

        for i = 1, 100 do
            if not occupied[i] then
                toSlot = i
                break
            end
        end

        if not toSlot then
            Inventory.locks[fromLock] = nil
            Inventory.locks[toLock] = nil
            return false, 'No available slots in destination'
        end
    end

    -- Mover
    if quantity == item.quantity then
        -- Mover todo el item
        MySQL.query.await([[
            UPDATE ait_item_instances
            SET owner_type = ?, owner_id = ?, slot = ?
            WHERE item_iid = ?
        ]], { toType, toId, toSlot, iid })
    else
        -- Split: reducir origen y crear nuevo en destino
        MySQL.query.await([[
            UPDATE ait_item_instances SET quantity = quantity - ? WHERE item_iid = ?
        ]], { quantity, iid })

        MySQL.insert.await([[
            INSERT INTO ait_item_instances
            (item_id, owner_type, owner_id, slot, quantity, durability, quality, serial, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            item.item_id, toType, toId, toSlot, quantity,
            item.durability, item.quality, nil, item.metadata
        })
    end

    Inventory.InvalidateCache(fromType, fromId)
    Inventory.InvalidateCache(toType, toId)
    Inventory.locks[fromLock] = nil
    Inventory.locks[toLock] = nil

    Inventory.LogTransaction(iid, item.item_id, fromType, fromId, toType, toId, quantity, 'move', source, nil, 'Move item')

    if AIT.EventBus then
        AIT.EventBus.emit('inventory.item.moved', {
            iid = iid,
            itemId = item.item_id,
            from = { type = fromType, id = fromId },
            to = { type = toType, id = toId },
            quantity = quantity,
        })
    end

    return true, 'moved'
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Inventory.GenerateSerial()
    return string.format('%08X%08X', math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF))
end

function Inventory.InvalidateCache(ownerType, ownerId)
    local cacheKey = ownerType .. ':' .. ownerId
    Inventory.itemCache[cacheKey] = nil

    if AIT.Cache then
        AIT.Cache.delete('inventory', cacheKey)
    end
end

function Inventory.LogTransaction(iid, itemId, fromType, fromId, toType, toId, quantity, action, source, charId, reason)
    local sig = tostring(GetHashKey(string.format('%d:%d:%s:%d', iid, os.time(), action, math.random(1000000))))

    table.insert(Inventory.txQueue, {
        iid = iid,
        itemId = itemId,
        fromType = fromType,
        fromId = fromId,
        toType = toType,
        toId = toId,
        quantity = quantity,
        action = action,
        playerId = source and AIT.RBAC and AIT.RBAC.GetPlayerId(source),
        charId = charId,
        reason = reason,
        sig = sig,
    })
end

function Inventory.FlushTransactions()
    if Inventory.processing or #Inventory.txQueue == 0 then return end
    Inventory.processing = true

    local batch = {}
    for i = 1, math.min(100, #Inventory.txQueue) do
        table.insert(batch, table.remove(Inventory.txQueue, 1))
    end

    if #batch > 0 then
        local values = {}
        local params = {}

        for _, tx in ipairs(batch) do
            table.insert(values, '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
            table.insert(params, tx.iid)
            table.insert(params, tx.itemId)
            table.insert(params, tx.fromType)
            table.insert(params, tx.fromId)
            table.insert(params, tx.toType)
            table.insert(params, tx.toId)
            table.insert(params, tx.quantity)
            table.insert(params, tx.action)
            table.insert(params, tx.playerId)
            table.insert(params, tx.charId)
            table.insert(params, tx.reason)
            table.insert(params, tx.sig)
        end

        MySQL.insert([[
            INSERT INTO ait_item_tx
            (item_iid, item_id, from_type, from_id, to_type, to_id, quantity, action, actor_player_id, actor_char_id, reason, sig)
            VALUES
        ]] .. table.concat(values, ', '), params)
    end

    Inventory.processing = false
end

function Inventory.CleanupExpired()
    MySQL.query.await([[
        DELETE FROM ait_item_instances
        WHERE expires_at IS NOT NULL AND expires_at < NOW()
    ]])

    if AIT.Log then
        AIT.Log.info('INVENTORY', 'Cleaned up expired items')
    end
end

function Inventory.IntegrityCheck()
    -- Buscar duplicados de seriales
    local dupes = MySQL.query.await([[
        SELECT serial, COUNT(*) as count FROM ait_item_instances
        WHERE serial IS NOT NULL
        GROUP BY serial
        HAVING COUNT(*) > 1
    ]])

    if dupes and #dupes > 0 then
        if AIT.Log then
            AIT.Log.critical('INVENTORY', 'Duplicate serials detected', { count = #dupes })
        end

        if AIT.EventBus then
            AIT.EventBus.emit('inventory.dupe.suspected', { dupes = dupes })
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- REGISTRAR ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT.Engines.inventory = Inventory

return Inventory
