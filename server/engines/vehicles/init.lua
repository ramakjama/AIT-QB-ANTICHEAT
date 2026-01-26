-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb VEHICLES ENGINE
-- Sistema completo de vehiculos: spawn, despawn, persistencia, garajes, impound, llaves
-- Modificaciones, combustible, dano
-- Optimizado para 2048 slots
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Vehicles = AIT.Engines.Vehicles or {}

local Vehicles = {
    spawned = {},           -- Vehiculos spawneados actualmente {netId = data}
    playerVehicles = {},    -- Vehiculos por jugador {source = {netId1, netId2}}
    entityToData = {},      -- Mapeo de entidad a datos {entity = data}
    persistQueue = {},      -- Cola de persistencia
    processing = false,
    batchSize = 50,
    flushInterval = 5000,
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

Vehicles.Config = {
    -- Limites por jugador
    maxSpawnedPerPlayer = 1,
    maxOwnedVehicles = 10,
    maxGarageVehicles = 50,

    -- Tiempos
    despawnTimeout = 600,       -- 10 minutos sin conductor
    persistInterval = 30,       -- Guardar cada 30 segundos
    cleanupInterval = 300,      -- Limpiar cada 5 minutos

    -- Spawn
    defaultFuel = 100.0,
    defaultBody = 1000.0,
    defaultEngine = 1000.0,

    -- Impound
    impoundCostBase = 500,
    impoundCostPerHour = 100,
    impoundMaxTime = 168,       -- 7 dias maximo

    -- Categorias de vehiculos
    categories = {
        compact = { label = 'Compacto', maxSpeed = 160 },
        sedan = { label = 'Sedan', maxSpeed = 180 },
        suv = { label = 'SUV', maxSpeed = 170 },
        coupe = { label = 'Coupe', maxSpeed = 200 },
        muscle = { label = 'Muscle', maxSpeed = 210 },
        sport = { label = 'Deportivo', maxSpeed = 240 },
        super = { label = 'Super', maxSpeed = 280 },
        motorcycle = { label = 'Motocicleta', maxSpeed = 220 },
        offroad = { label = 'Todoterreno', maxSpeed = 150 },
        industrial = { label = 'Industrial', maxSpeed = 120 },
        commercial = { label = 'Comercial', maxSpeed = 130 },
        emergency = { label = 'Emergencias', maxSpeed = 200 },
        military = { label = 'Militar', maxSpeed = 180 },
        boat = { label = 'Barco', maxSpeed = 100 },
        helicopter = { label = 'Helicoptero', maxSpeed = 300 },
        plane = { label = 'Avion', maxSpeed = 400 },
    },

    -- Clases de vehiculos (FiveM)
    classes = {
        [0] = 'compact', [1] = 'sedan', [2] = 'suv', [3] = 'coupe',
        [4] = 'muscle', [5] = 'sport', [6] = 'sport', [7] = 'super',
        [8] = 'motorcycle', [9] = 'offroad', [10] = 'industrial',
        [11] = 'commercial', [12] = 'commercial', [13] = 'commercial',
        [14] = 'boat', [15] = 'helicopter', [16] = 'plane',
        [17] = 'emergency', [18] = 'emergency', [19] = 'military',
        [20] = 'commercial', [21] = 'commercial'
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Vehicles.Initialize()
    -- Asegurar tablas
    Vehicles.EnsureTables()

    -- Cargar configuracion desde DB si existe
    Vehicles.LoadConfiguration()

    -- Registrar jobs del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('vehicles_persist', {
            interval = Vehicles.Config.persistInterval,
            fn = Vehicles.PersistAll
        })

        AIT.Scheduler.register('vehicles_cleanup', {
            interval = Vehicles.Config.cleanupInterval,
            fn = Vehicles.CleanupAbandoned
        })

        AIT.Scheduler.register('vehicles_impound_check', {
            interval = 3600,
            fn = Vehicles.ProcessImpoundFees
        })
    end

    -- Thread de persistencia
    CreateThread(function()
        while true do
            Wait(Vehicles.flushInterval)
            Vehicles.FlushPersistQueue()
        end
    end)

    -- Eventos de jugador
    AddEventHandler('playerDropped', function(reason)
        local source = source
        Vehicles.OnPlayerDropped(source, reason)
    end)

    -- Suscribirse a eventos
    if AIT.EventBus then
        AIT.EventBus.on('character.selected', Vehicles.OnCharacterSelected)
        AIT.EventBus.on('character.unloaded', Vehicles.OnCharacterUnloaded)
    end

    if AIT.Log then
        AIT.Log.info('VEHICLES', 'Motor de vehiculos inicializado')
    end

    return true
end

function Vehicles.EnsureTables()
    -- Tabla principal de vehiculos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_vehicles (
            vehicle_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            owner_type ENUM('char', 'faction', 'business', 'rental', 'system') NOT NULL DEFAULT 'char',
            owner_id BIGINT NOT NULL,
            model VARCHAR(64) NOT NULL,
            plate VARCHAR(8) NOT NULL,
            vin VARCHAR(17) NOT NULL,
            category VARCHAR(32) NULL,
            label VARCHAR(128) NULL,

            -- Estado
            status ENUM('out', 'garaged', 'impound', 'destroyed', 'stolen') NOT NULL DEFAULT 'garaged',
            garage_id BIGINT NULL,
            impound_id BIGINT NULL,

            -- Propiedades
            fuel DECIMAL(5,2) NOT NULL DEFAULT 100.00,
            body_health DECIMAL(7,2) NOT NULL DEFAULT 1000.00,
            engine_health DECIMAL(7,2) NOT NULL DEFAULT 1000.00,
            mileage INT NOT NULL DEFAULT 0,

            -- Modificaciones
            mods JSON NULL,
            extras JSON NULL,
            color_primary JSON NULL,
            color_secondary JSON NULL,

            -- Posicion (si esta fuera)
            position JSON NULL,
            rotation JSON NULL,

            -- Metadata
            insurance_expires DATETIME NULL,
            last_driven DATETIME NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

            UNIQUE KEY idx_plate (plate),
            UNIQUE KEY idx_vin (vin),
            KEY idx_owner (owner_type, owner_id),
            KEY idx_status (status),
            KEY idx_garage (garage_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Historial de vehiculos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_vehicle_history (
            history_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            vehicle_id BIGINT NOT NULL,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            action ENUM('spawn', 'despawn', 'garage_in', 'garage_out', 'impound_in',
                       'impound_out', 'repair', 'modify', 'transfer', 'destroy', 'steal') NOT NULL,
            actor_player_id BIGINT NULL,
            actor_char_id BIGINT NULL,
            from_state VARCHAR(32) NULL,
            to_state VARCHAR(32) NULL,
            location JSON NULL,
            meta JSON NULL,
            KEY idx_vehicle (vehicle_id),
            KEY idx_ts (ts),
            KEY idx_action (action)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Impound
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_vehicle_impound (
            impound_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            vehicle_id BIGINT NOT NULL,
            lot_id INT NOT NULL DEFAULT 1,
            reason ENUM('police', 'abandoned', 'unpaid', 'admin') NOT NULL,
            reason_text TEXT NULL,
            impound_by_player_id BIGINT NULL,
            impound_by_char_id BIGINT NULL,
            impounded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            release_cost INT NOT NULL DEFAULT 0,
            released_at DATETIME NULL,
            released_by_char_id BIGINT NULL,
            meta JSON NULL,
            KEY idx_vehicle (vehicle_id),
            KEY idx_lot (lot_id),
            KEY idx_status (released_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Transferencias
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_vehicle_transfers (
            transfer_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            vehicle_id BIGINT NOT NULL,
            from_owner_type VARCHAR(32) NOT NULL,
            from_owner_id BIGINT NOT NULL,
            to_owner_type VARCHAR(32) NOT NULL,
            to_owner_id BIGINT NOT NULL,
            price INT NULL,
            transfer_type ENUM('sale', 'gift', 'trade', 'admin', 'auction') NOT NULL,
            transferred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_vehicle (vehicle_id),
            KEY idx_from (from_owner_type, from_owner_id),
            KEY idx_to (to_owner_type, to_owner_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Vehicles.LoadConfiguration()
    local config = MySQL.query.await([[
        SELECT config_key, config_value FROM ait_config WHERE config_group = 'vehicles'
    ]])

    if config then
        for _, row in ipairs(config) do
            local value = tonumber(row.config_value) or row.config_value
            Vehicles.Config[row.config_key] = value
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SPAWN / DESPAWN
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Spawna un vehiculo desde la base de datos
---@param source number ID del jugador
---@param vehicleId number ID del vehiculo en DB
---@param coords vector3|table Coordenadas de spawn
---@param heading number Rotacion
---@return boolean, number|string Exito y netId o error
function Vehicles.Spawn(source, vehicleId, coords, heading)
    -- Rate limiting
    if source and AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'vehicles.spawn')
        if not allowed then
            return false, 'Limite de acciones excedido'
        end
    end

    -- Verificar limite de vehiculos spawneados
    local playerVehs = Vehicles.playerVehicles[source] or {}
    if #playerVehs >= Vehicles.Config.maxSpawnedPerPlayer then
        return false, 'Ya tienes un vehiculo activo'
    end

    -- Obtener datos del vehiculo
    local vehicle = Vehicles.GetVehicleData(vehicleId)
    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar propiedad
    local charId = Vehicles.GetCharacterId(source)
    if vehicle.owner_type == 'char' and vehicle.owner_id ~= charId then
        return false, 'No eres el propietario de este vehiculo'
    end

    -- Verificar estado
    if vehicle.status == 'destroyed' then
        return false, 'Este vehiculo esta destruido'
    end

    if vehicle.status == 'impound' then
        return false, 'Este vehiculo esta en el deposito'
    end

    if vehicle.status == 'out' then
        return false, 'Este vehiculo ya esta fuera'
    end

    -- Crear vehiculo
    local modelHash = GetHashKey(vehicle.model)

    local entity = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading or 0.0, true, true)

    if not entity or entity == 0 then
        return false, 'Error al crear el vehiculo'
    end

    -- Esperar a que el vehiculo exista
    local timeout = 50
    while not DoesEntityExist(entity) and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end

    if not DoesEntityExist(entity) then
        return false, 'Timeout al crear vehiculo'
    end

    -- Configurar placa
    SetVehicleNumberPlateText(entity, vehicle.plate)

    -- Aplicar propiedades
    Vehicles.ApplyProperties(entity, vehicle)

    -- Aplicar modificaciones
    if vehicle.mods then
        local mods = type(vehicle.mods) == 'string' and json.decode(vehicle.mods) or vehicle.mods
        Vehicles.ApplyMods(entity, mods)
    end

    -- Obtener network ID
    local netId = NetworkGetNetworkIdFromEntity(entity)

    -- Registrar spawn
    local spawnData = {
        vehicleId = vehicleId,
        entity = entity,
        netId = netId,
        owner = source,
        charId = charId,
        model = vehicle.model,
        plate = vehicle.plate,
        spawnedAt = os.time(),
        lastDriver = nil,
        lastDriverTime = nil,
    }

    Vehicles.spawned[netId] = spawnData
    Vehicles.entityToData[entity] = spawnData

    if not Vehicles.playerVehicles[source] then
        Vehicles.playerVehicles[source] = {}
    end
    table.insert(Vehicles.playerVehicles[source], netId)

    -- Actualizar estado en DB
    MySQL.query([[
        UPDATE ait_vehicles SET status = 'out', garage_id = NULL, updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { vehicleId })

    -- Log historial
    Vehicles.LogHistory(vehicleId, 'spawn', source, charId, {
        location = { x = coords.x, y = coords.y, z = coords.z },
        netId = netId
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.spawned', {
            vehicleId = vehicleId,
            netId = netId,
            owner = source,
            model = vehicle.model,
            plate = vehicle.plate,
        })
    end

    if AIT.Log then
        AIT.Log.debug('VEHICLES', 'Vehiculo spawneado', {
            vehicleId = vehicleId,
            netId = netId,
            plate = vehicle.plate,
            owner = source
        })
    end

    return true, netId
end

--- Despawnea un vehiculo
---@param source number|nil ID del jugador (nil para sistema)
---@param netId number Network ID del vehiculo
---@param reason? string Razon del despawn
---@return boolean, string
function Vehicles.Despawn(source, netId, reason)
    local spawnData = Vehicles.spawned[netId]
    if not spawnData then
        return false, 'Vehiculo no registrado'
    end

    -- Verificar permisos
    if source and spawnData.owner ~= source then
        local hasPermission = AIT.RBAC and AIT.RBAC.HasPermission(source, 'vehicles.despawn.any')
        if not hasPermission then
            return false, 'No tienes permiso para despawnear este vehiculo'
        end
    end

    local entity = spawnData.entity

    -- Guardar estado actual antes de borrar
    if DoesEntityExist(entity) then
        Vehicles.SaveVehicleState(entity, spawnData.vehicleId)
        DeleteEntity(entity)
    end

    -- Limpiar registros
    Vehicles.spawned[netId] = nil
    Vehicles.entityToData[entity] = nil

    if Vehicles.playerVehicles[spawnData.owner] then
        for i, vNetId in ipairs(Vehicles.playerVehicles[spawnData.owner]) do
            if vNetId == netId then
                table.remove(Vehicles.playerVehicles[spawnData.owner], i)
                break
            end
        end
    end

    -- Log historial
    local charId = source and Vehicles.GetCharacterId(source) or nil
    Vehicles.LogHistory(spawnData.vehicleId, 'despawn', source, charId, {
        reason = reason or 'manual',
        duration = os.time() - spawnData.spawnedAt
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.despawned', {
            vehicleId = spawnData.vehicleId,
            netId = netId,
            reason = reason,
        })
    end

    return true, 'Vehiculo despawneado'
end

--- Guarda el estado actual de un vehiculo
---@param entity number Entidad del vehiculo
---@param vehicleId number ID en DB
function Vehicles.SaveVehicleState(entity, vehicleId)
    if not DoesEntityExist(entity) then return end

    local coords = GetEntityCoords(entity)
    local rotation = GetEntityRotation(entity)
    local bodyHealth = GetVehicleBodyHealth(entity)
    local engineHealth = GetVehicleEngineHealth(entity)

    -- Obtener combustible (depende del sistema)
    local fuel = 100.0
    if AIT.Engines.Vehicles.Fuel then
        fuel = AIT.Engines.Vehicles.Fuel.GetFuel(entity)
    end

    -- Obtener mods actuales
    local mods = Vehicles.GetVehicleMods(entity)

    table.insert(Vehicles.persistQueue, {
        vehicleId = vehicleId,
        fuel = fuel,
        bodyHealth = bodyHealth,
        engineHealth = engineHealth,
        position = { x = coords.x, y = coords.y, z = coords.z },
        rotation = { x = rotation.x, y = rotation.y, z = rotation.z },
        mods = mods,
        timestamp = os.time()
    })
end

--- Procesa la cola de persistencia
function Vehicles.FlushPersistQueue()
    if Vehicles.processing or #Vehicles.persistQueue == 0 then return end
    Vehicles.processing = true

    local batch = {}
    for i = 1, math.min(Vehicles.batchSize, #Vehicles.persistQueue) do
        table.insert(batch, table.remove(Vehicles.persistQueue, 1))
    end

    for _, data in ipairs(batch) do
        MySQL.query([[
            UPDATE ait_vehicles SET
                fuel = ?,
                body_health = ?,
                engine_health = ?,
                position = ?,
                rotation = ?,
                mods = ?,
                updated_at = NOW()
            WHERE vehicle_id = ?
        ]], {
            data.fuel,
            data.bodyHealth,
            data.engineHealth,
            json.encode(data.position),
            json.encode(data.rotation),
            json.encode(data.mods),
            data.vehicleId
        })
    end

    Vehicles.processing = false
end

--- Persiste todos los vehiculos spawneados
function Vehicles.PersistAll()
    for netId, spawnData in pairs(Vehicles.spawned) do
        if DoesEntityExist(spawnData.entity) then
            Vehicles.SaveVehicleState(spawnData.entity, spawnData.vehicleId)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- GESTION DE VEHICULOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene los datos de un vehiculo
---@param vehicleId number
---@return table|nil
function Vehicles.GetVehicleData(vehicleId)
    local cacheKey = 'vehicle:' .. vehicleId
    if AIT.Cache then
        local cached = AIT.Cache.get('vehicles', cacheKey)
        if cached then return cached end
    end

    local result = MySQL.query.await([[
        SELECT * FROM ait_vehicles WHERE vehicle_id = ?
    ]], { vehicleId })

    if result and result[1] then
        if AIT.Cache then
            AIT.Cache.set('vehicles', cacheKey, result[1], 60)
        end
        return result[1]
    end

    return nil
end

--- Obtiene un vehiculo por placa
---@param plate string
---@return table|nil
function Vehicles.GetVehicleByPlate(plate)
    local result = MySQL.query.await([[
        SELECT * FROM ait_vehicles WHERE plate = ?
    ]], { plate })

    return result and result[1] or nil
end

--- Obtiene todos los vehiculos de un propietario
---@param ownerType string
---@param ownerId number
---@return table
function Vehicles.GetOwnerVehicles(ownerType, ownerId)
    local vehicles = MySQL.query.await([[
        SELECT v.*, g.name as garage_name
        FROM ait_vehicles v
        LEFT JOIN ait_garages g ON v.garage_id = g.garage_id
        WHERE v.owner_type = ? AND v.owner_id = ?
        ORDER BY v.created_at DESC
    ]], { ownerType, ownerId })

    return vehicles or {}
end

--- Obtiene los vehiculos de un personaje
---@param charId number
---@return table
function Vehicles.GetCharacterVehicles(charId)
    return Vehicles.GetOwnerVehicles('char', charId)
end

--- Registra un nuevo vehiculo
---@param params table
---@return boolean, number|string
function Vehicles.RegisterVehicle(params)
    --[[
        params = {
            source = source,
            ownerType = 'char',
            ownerId = charId,
            model = 'sultan',
            plate = 'ABC123',
            garageId = 1,
            mods = {},
            metadata = {}
        }
    ]]

    -- Validar modelo
    if not params.model then
        return false, 'Modelo requerido'
    end

    -- Generar placa si no se proporciona
    local plate = params.plate or Vehicles.GeneratePlate()

    -- Verificar que la placa no exista
    local existing = Vehicles.GetVehicleByPlate(plate)
    if existing then
        return false, 'La placa ya existe'
    end

    -- Generar VIN
    local vin = Vehicles.GenerateVIN()

    -- Determinar categoria
    local category = params.category or Vehicles.GetModelCategory(params.model)

    -- Insertar
    local vehicleId = MySQL.insert.await([[
        INSERT INTO ait_vehicles
        (owner_type, owner_id, model, plate, vin, category, label, status, garage_id, fuel, mods)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'garaged', ?, ?, ?)
    ]], {
        params.ownerType or 'char',
        params.ownerId,
        params.model,
        plate,
        vin,
        category,
        params.label,
        params.garageId or 1,
        params.fuel or Vehicles.Config.defaultFuel,
        params.mods and json.encode(params.mods) or nil
    })

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.invalidateNamespace('vehicles')
    end

    -- Log
    local charId = params.source and Vehicles.GetCharacterId(params.source) or params.ownerId
    Vehicles.LogHistory(vehicleId, 'spawn', params.source, charId, {
        action = 'register',
        model = params.model,
        plate = plate
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.registered', {
            vehicleId = vehicleId,
            ownerType = params.ownerType or 'char',
            ownerId = params.ownerId,
            model = params.model,
            plate = plate,
        })
    end

    return true, vehicleId
end

--- Transfiere un vehiculo a otro propietario
---@param source number
---@param vehicleId number
---@param toOwnerType string
---@param toOwnerId number
---@param transferType? string
---@param price? number
---@return boolean, string
function Vehicles.Transfer(source, vehicleId, toOwnerType, toOwnerId, transferType, price)
    local vehicle = Vehicles.GetVehicleData(vehicleId)
    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar propiedad
    local charId = Vehicles.GetCharacterId(source)
    if vehicle.owner_type == 'char' and vehicle.owner_id ~= charId then
        local hasPermission = AIT.RBAC and AIT.RBAC.HasPermission(source, 'vehicles.transfer.any')
        if not hasPermission then
            return false, 'No eres el propietario'
        end
    end

    -- Verificar que no este fuera
    if vehicle.status == 'out' then
        return false, 'Guarda el vehiculo primero'
    end

    -- Registrar transferencia
    MySQL.insert.await([[
        INSERT INTO ait_vehicle_transfers
        (vehicle_id, from_owner_type, from_owner_id, to_owner_type, to_owner_id, price, transfer_type)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        vehicleId,
        vehicle.owner_type, vehicle.owner_id,
        toOwnerType, toOwnerId,
        price,
        transferType or 'sale'
    })

    -- Actualizar propietario
    MySQL.query.await([[
        UPDATE ait_vehicles SET owner_type = ?, owner_id = ?, updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { toOwnerType, toOwnerId, vehicleId })

    -- Transferir llaves
    if AIT.Engines.Vehicles.Keys then
        AIT.Engines.Vehicles.Keys.RevokeAllKeys(vehicleId)
        if toOwnerType == 'char' then
            AIT.Engines.Vehicles.Keys.GiveKey(nil, vehicleId, toOwnerId, true)
        end
    end

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.delete('vehicles', 'vehicle:' .. vehicleId)
    end

    -- Log
    Vehicles.LogHistory(vehicleId, 'transfer', source, charId, {
        fromType = vehicle.owner_type,
        fromId = vehicle.owner_id,
        toType = toOwnerType,
        toId = toOwnerId,
        price = price,
        transferType = transferType
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.transferred', {
            vehicleId = vehicleId,
            from = { type = vehicle.owner_type, id = vehicle.owner_id },
            to = { type = toOwnerType, id = toOwnerId },
            price = price,
        })
    end

    return true, 'Vehiculo transferido'
end

--- Destruye un vehiculo permanentemente
---@param source number|nil
---@param vehicleId number
---@param reason? string
---@return boolean, string
function Vehicles.Destroy(source, vehicleId, reason)
    local vehicle = Vehicles.GetVehicleData(vehicleId)
    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    -- Si esta spawneado, borrar entidad
    for netId, spawnData in pairs(Vehicles.spawned) do
        if spawnData.vehicleId == vehicleId then
            Vehicles.Despawn(source, netId, 'destroyed')
            break
        end
    end

    -- Actualizar estado
    MySQL.query.await([[
        UPDATE ait_vehicles SET status = 'destroyed', updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { vehicleId })

    -- Revocar llaves
    if AIT.Engines.Vehicles.Keys then
        AIT.Engines.Vehicles.Keys.RevokeAllKeys(vehicleId)
    end

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.delete('vehicles', 'vehicle:' .. vehicleId)
    end

    -- Log
    local charId = source and Vehicles.GetCharacterId(source) or nil
    Vehicles.LogHistory(vehicleId, 'destroy', source, charId, {
        reason = reason or 'unknown'
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.destroyed', {
            vehicleId = vehicleId,
            reason = reason,
        })
    end

    return true, 'Vehiculo destruido'
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- IMPOUND (DEPOSITO)
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Envia un vehiculo al deposito
---@param source number|nil
---@param vehicleId number
---@param reason string
---@param reasonText? string
---@param lotId? number
---@return boolean, string
function Vehicles.Impound(source, vehicleId, reason, reasonText, lotId)
    local vehicle = Vehicles.GetVehicleData(vehicleId)
    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    if vehicle.status == 'impound' then
        return false, 'El vehiculo ya esta en el deposito'
    end

    -- Si esta spawneado, despawnear
    for netId, spawnData in pairs(Vehicles.spawned) do
        if spawnData.vehicleId == vehicleId then
            Vehicles.Despawn(source, netId, 'impound')
            break
        end
    end

    -- Calcular costo
    local releaseCost = Vehicles.Config.impoundCostBase

    -- Crear registro de impound
    local impoundId = MySQL.insert.await([[
        INSERT INTO ait_vehicle_impound
        (vehicle_id, lot_id, reason, reason_text, impound_by_player_id, impound_by_char_id, release_cost)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        vehicleId,
        lotId or 1,
        reason,
        reasonText,
        source and AIT.RBAC and AIT.RBAC.GetPlayerId(source),
        source and Vehicles.GetCharacterId(source),
        releaseCost
    })

    -- Actualizar estado del vehiculo
    MySQL.query.await([[
        UPDATE ait_vehicles SET status = 'impound', impound_id = ?, garage_id = NULL, updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { impoundId, vehicleId })

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.delete('vehicles', 'vehicle:' .. vehicleId)
    end

    -- Log
    local charId = source and Vehicles.GetCharacterId(source) or nil
    Vehicles.LogHistory(vehicleId, 'impound_in', source, charId, {
        impoundId = impoundId,
        reason = reason,
        reasonText = reasonText,
        lotId = lotId,
        releaseCost = releaseCost
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.impounded', {
            vehicleId = vehicleId,
            impoundId = impoundId,
            reason = reason,
        })
    end

    return true, impoundId
end

--- Libera un vehiculo del deposito
---@param source number
---@param vehicleId number
---@param garageId? number
---@return boolean, string
function Vehicles.ReleaseFromImpound(source, vehicleId, garageId)
    local vehicle = Vehicles.GetVehicleData(vehicleId)
    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    if vehicle.status ~= 'impound' then
        return false, 'El vehiculo no esta en el deposito'
    end

    -- Verificar propiedad
    local charId = Vehicles.GetCharacterId(source)
    if vehicle.owner_type == 'char' and vehicle.owner_id ~= charId then
        return false, 'No eres el propietario'
    end

    -- Obtener registro de impound
    local impound = MySQL.query.await([[
        SELECT * FROM ait_vehicle_impound
        WHERE vehicle_id = ? AND released_at IS NULL
        ORDER BY impounded_at DESC LIMIT 1
    ]], { vehicleId })

    if not impound or not impound[1] then
        return false, 'Registro de deposito no encontrado'
    end

    impound = impound[1]

    -- Calcular costo total (base + tiempo)
    local hoursImpounded = math.floor((os.time() - os.time(impound.impounded_at)) / 3600)
    local totalCost = impound.release_cost + (hoursImpounded * Vehicles.Config.impoundCostPerHour)

    -- Cobrar
    if AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, totalCost, 'bank', 'fee', 'Liberacion de deposito')
        if not success then
            return false, 'No tienes suficiente dinero ($' .. totalCost .. ')'
        end
    end

    -- Actualizar impound
    MySQL.query.await([[
        UPDATE ait_vehicle_impound SET released_at = NOW(), released_by_char_id = ?
        WHERE impound_id = ?
    ]], { charId, impound.impound_id })

    -- Actualizar vehiculo
    MySQL.query.await([[
        UPDATE ait_vehicles SET status = 'garaged', impound_id = NULL, garage_id = ?, updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { garageId or 1, vehicleId })

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.delete('vehicles', 'vehicle:' .. vehicleId)
    end

    -- Log
    Vehicles.LogHistory(vehicleId, 'impound_out', source, charId, {
        impoundId = impound.impound_id,
        cost = totalCost,
        hoursImpounded = hoursImpounded,
        garageId = garageId
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.released_impound', {
            vehicleId = vehicleId,
            cost = totalCost,
        })
    end

    return true, 'Vehiculo liberado por $' .. totalCost
end

--- Procesa las tarifas de impound pendientes
function Vehicles.ProcessImpoundFees()
    -- Incrementar costo por hora para vehiculos que llevan mucho tiempo
    local result = MySQL.query.await([[
        SELECT i.impound_id, i.vehicle_id, i.release_cost, i.impounded_at,
               TIMESTAMPDIFF(HOUR, i.impounded_at, NOW()) as hours
        FROM ait_vehicle_impound i
        WHERE i.released_at IS NULL
        AND TIMESTAMPDIFF(HOUR, i.impounded_at, NOW()) > 24
    ]])

    for _, impound in ipairs(result or {}) do
        if impound.hours > Vehicles.Config.impoundMaxTime then
            -- Vehiculo abandonado, puede ser subastado
            if AIT.EventBus then
                AIT.EventBus.emit('vehicles.impound.expired', {
                    vehicleId = impound.vehicle_id,
                    impoundId = impound.impound_id,
                    hours = impound.hours
                })
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Genera una placa aleatoria
---@return string
function Vehicles.GeneratePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local nums = '0123456789'
    local plate = ''

    -- Formato: AAA 000
    for i = 1, 3 do
        local idx = math.random(1, #chars)
        plate = plate .. chars:sub(idx, idx)
    end
    plate = plate .. ' '
    for i = 1, 3 do
        local idx = math.random(1, #nums)
        plate = plate .. nums:sub(idx, idx)
    end

    -- Verificar que no exista
    local existing = Vehicles.GetVehicleByPlate(plate)
    if existing then
        return Vehicles.GeneratePlate() -- Recursivo hasta encontrar una unica
    end

    return plate
end

--- Genera un VIN aleatorio
---@return string
function Vehicles.GenerateVIN()
    local chars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789' -- Sin I, O, Q
    local vin = ''

    for i = 1, 17 do
        local idx = math.random(1, #chars)
        vin = vin .. chars:sub(idx, idx)
    end

    return vin
end

--- Obtiene la categoria de un modelo
---@param model string
---@return string
function Vehicles.GetModelCategory(model)
    local hash = GetHashKey(model)
    local class = GetVehicleClassFromName(hash)
    return Vehicles.Config.classes[class] or 'misc'
end

--- Obtiene el ID del personaje de un jugador
---@param source number
---@return number|nil
function Vehicles.GetCharacterId(source)
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

--- Aplica propiedades a un vehiculo
---@param entity number
---@param data table
function Vehicles.ApplyProperties(entity, data)
    if data.fuel and AIT.Engines.Vehicles.Fuel then
        AIT.Engines.Vehicles.Fuel.SetFuel(entity, data.fuel)
    end

    if data.body_health then
        SetVehicleBodyHealth(entity, data.body_health)
    end

    if data.engine_health then
        SetVehicleEngineHealth(entity, data.engine_health)
    end

    -- Colores
    if data.color_primary then
        local color = type(data.color_primary) == 'string' and json.decode(data.color_primary) or data.color_primary
        if color and color.r then
            SetVehicleCustomPrimaryColour(entity, color.r, color.g, color.b)
        end
    end

    if data.color_secondary then
        local color = type(data.color_secondary) == 'string' and json.decode(data.color_secondary) or data.color_secondary
        if color and color.r then
            SetVehicleCustomSecondaryColour(entity, color.r, color.g, color.b)
        end
    end
end

--- Aplica modificaciones a un vehiculo
---@param entity number
---@param mods table
function Vehicles.ApplyMods(entity, mods)
    if not mods then return end

    SetVehicleModKit(entity, 0)

    for modType, modIndex in pairs(mods) do
        if type(modType) == 'number' then
            SetVehicleMod(entity, modType, modIndex, false)
        elseif modType == 'windowTint' then
            SetVehicleWindowTint(entity, modIndex)
        elseif modType == 'wheels' then
            SetVehicleWheelType(entity, modIndex)
        elseif modType == 'neonEnabled' then
            for i = 0, 3 do
                SetVehicleNeonLightEnabled(entity, i, modIndex[i + 1] or false)
            end
        elseif modType == 'neonColor' then
            SetVehicleNeonLightsColour(entity, modIndex.r or 0, modIndex.g or 0, modIndex.b or 0)
        elseif modType == 'tyreSmokeColor' then
            SetVehicleTyreSmokeColor(entity, modIndex.r or 0, modIndex.g or 0, modIndex.b or 0)
        elseif modType == 'plateIndex' then
            SetVehicleNumberPlateTextIndex(entity, modIndex)
        elseif modType == 'livery' then
            SetVehicleLivery(entity, modIndex)
        end
    end

    -- Extras
    if mods.extras then
        for extraId, enabled in pairs(mods.extras) do
            SetVehicleExtra(entity, tonumber(extraId), not enabled)
        end
    end
end

--- Obtiene las modificaciones de un vehiculo
---@param entity number
---@return table
function Vehicles.GetVehicleMods(entity)
    if not DoesEntityExist(entity) then return {} end

    local mods = {}

    -- Mods estandar
    for i = 0, 49 do
        local mod = GetVehicleMod(entity, i)
        if mod >= 0 then
            mods[i] = mod
        end
    end

    -- Extras
    mods.extras = {}
    for i = 0, 14 do
        if DoesExtraExist(entity, i) then
            mods.extras[i] = IsVehicleExtraTurnedOn(entity, i)
        end
    end

    -- Otros
    mods.windowTint = GetVehicleWindowTint(entity)
    mods.wheels = GetVehicleWheelType(entity)
    mods.plateIndex = GetVehicleNumberPlateTextIndex(entity)
    mods.livery = GetVehicleLivery(entity)

    -- Neon
    mods.neonEnabled = {
        IsVehicleNeonLightEnabled(entity, 0),
        IsVehicleNeonLightEnabled(entity, 1),
        IsVehicleNeonLightEnabled(entity, 2),
        IsVehicleNeonLightEnabled(entity, 3)
    }

    local neonR, neonG, neonB = GetVehicleNeonLightsColour(entity)
    mods.neonColor = { r = neonR, g = neonG, b = neonB }

    local smokeR, smokeG, smokeB = GetVehicleTyreSmokeColor(entity)
    mods.tyreSmokeColor = { r = smokeR, g = smokeG, b = smokeB }

    return mods
end

--- Registra en el historial
---@param vehicleId number
---@param action string
---@param source number|nil
---@param charId number|nil
---@param meta table|nil
function Vehicles.LogHistory(vehicleId, action, source, charId, meta)
    MySQL.insert([[
        INSERT INTO ait_vehicle_history
        (vehicle_id, action, actor_player_id, actor_char_id, meta)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        vehicleId,
        action,
        source and AIT.RBAC and AIT.RBAC.GetPlayerId(source),
        charId,
        meta and json.encode(meta)
    })
end

--- Limpia vehiculos abandonados
function Vehicles.CleanupAbandoned()
    local now = os.time()
    local toClean = {}

    for netId, spawnData in pairs(Vehicles.spawned) do
        local entity = spawnData.entity

        if not DoesEntityExist(entity) then
            table.insert(toClean, netId)
        else
            -- Verificar si tiene conductor
            local ped = GetPedInVehicleSeat(entity, -1)

            if ped and ped ~= 0 then
                spawnData.lastDriver = ped
                spawnData.lastDriverTime = now
            else
                -- Sin conductor
                if spawnData.lastDriverTime then
                    local abandoned = now - spawnData.lastDriverTime
                    if abandoned > Vehicles.Config.despawnTimeout then
                        table.insert(toClean, netId)
                    end
                end
            end
        end
    end

    -- Limpiar
    for _, netId in ipairs(toClean) do
        local spawnData = Vehicles.spawned[netId]
        if spawnData then
            -- Enviar al garaje en lugar de borrar
            MySQL.query([[
                UPDATE ait_vehicles SET status = 'garaged', garage_id = 1, updated_at = NOW()
                WHERE vehicle_id = ?
            ]], { spawnData.vehicleId })

            Vehicles.Despawn(nil, netId, 'abandoned_cleanup')
        end
    end

    if #toClean > 0 and AIT.Log then
        AIT.Log.info('VEHICLES', 'Limpiados ' .. #toClean .. ' vehiculos abandonados')
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Vehicles.OnPlayerDropped(source, reason)
    -- Despawnear vehiculos del jugador
    local playerVehs = Vehicles.playerVehicles[source]
    if playerVehs then
        for _, netId in ipairs(playerVehs) do
            local spawnData = Vehicles.spawned[netId]
            if spawnData then
                -- Guardar estado
                if DoesEntityExist(spawnData.entity) then
                    Vehicles.SaveVehicleState(spawnData.entity, spawnData.vehicleId)
                end

                -- Despawnear
                Vehicles.Despawn(nil, netId, 'player_dropped')
            end
        end
        Vehicles.playerVehicles[source] = nil
    end
end

function Vehicles.OnCharacterSelected(event)
    -- Pre-cargar vehiculos del personaje en cache
    if event.payload and event.payload.charId then
        Vehicles.GetCharacterVehicles(event.payload.charId)
    end
end

function Vehicles.OnCharacterUnloaded(event)
    if event.payload and event.payload.source then
        Vehicles.OnPlayerDropped(event.payload.source, 'character_unloaded')
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS Y REGISTRO
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- API Publica
Vehicles.API = {
    Spawn = Vehicles.Spawn,
    Despawn = Vehicles.Despawn,
    GetVehicleData = Vehicles.GetVehicleData,
    GetVehicleByPlate = Vehicles.GetVehicleByPlate,
    GetOwnerVehicles = Vehicles.GetOwnerVehicles,
    GetCharacterVehicles = Vehicles.GetCharacterVehicles,
    RegisterVehicle = Vehicles.RegisterVehicle,
    Transfer = Vehicles.Transfer,
    Destroy = Vehicles.Destroy,
    Impound = Vehicles.Impound,
    ReleaseFromImpound = Vehicles.ReleaseFromImpound,
    GeneratePlate = Vehicles.GeneratePlate,
    GetSpawnedVehicles = function() return Vehicles.spawned end,
    GetSpawnedByNetId = function(netId) return Vehicles.spawned[netId] end,
}

-- Registrar engine
AIT.Engines.Vehicles = Vehicles

return Vehicles
