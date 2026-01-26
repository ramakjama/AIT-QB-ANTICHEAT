-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb VEHICLES ENGINE - GARAGE
-- Sistema de garajes: guardar/sacar vehiculos, multiples garajes, transferencias
-- Namespace: AIT.Engines.Vehicles.Garage
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Vehicles = AIT.Engines.Vehicles or {}

local Garage = {
    garages = {},           -- Cache de garajes {garageId = data}
    garageZones = {},       -- Zonas de garajes para deteccion
    playerInGarage = {},    -- Jugadores actualmente en garajes {source = garageId}
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

Garage.Config = {
    -- Tipos de garajes
    types = {
        public = {
            label = 'Garaje Publico',
            maxSlots = 10,
            canStore = { 'compact', 'sedan', 'suv', 'coupe', 'muscle', 'sport', 'super', 'motorcycle', 'offroad' },
            storageFee = 0,
            retrieveFee = 0,
        },
        private = {
            label = 'Garaje Privado',
            maxSlots = 5,
            canStore = { 'compact', 'sedan', 'suv', 'coupe', 'muscle', 'sport', 'super', 'motorcycle', 'offroad' },
            storageFee = 0,
            retrieveFee = 0,
        },
        house = {
            label = 'Garaje de Casa',
            maxSlots = 2,
            canStore = { 'compact', 'sedan', 'suv', 'coupe', 'muscle', 'sport', 'motorcycle' },
            storageFee = 0,
            retrieveFee = 0,
        },
        faction = {
            label = 'Garaje de Faccion',
            maxSlots = 20,
            canStore = { 'compact', 'sedan', 'suv', 'coupe', 'muscle', 'sport', 'super', 'motorcycle', 'offroad', 'emergency', 'industrial' },
            storageFee = 0,
            retrieveFee = 0,
        },
        boat = {
            label = 'Puerto',
            maxSlots = 5,
            canStore = { 'boat' },
            storageFee = 100,
            retrieveFee = 50,
        },
        aircraft = {
            label = 'Hangar',
            maxSlots = 3,
            canStore = { 'helicopter', 'plane' },
            storageFee = 500,
            retrieveFee = 250,
        },
        impound = {
            label = 'Deposito',
            maxSlots = 100,
            canStore = { 'all' },
            storageFee = 0,
            retrieveFee = 500,
        },
    },

    -- Garajes predeterminados
    defaultGarages = {
        {
            name = 'garage_pillbox',
            label = 'Garaje Pillbox',
            type = 'public',
            coords = { x = 215.89, y = -810.05, z = 30.74 },
            spawn = { x = 227.31, y = -800.76, z = 30.59, h = 157.37 },
            blip = { sprite = 357, color = 3, scale = 0.8 },
        },
        {
            name = 'garage_legion',
            label = 'Garaje Legion Square',
            type = 'public',
            coords = { x = 215.43, y = -163.56, z = 54.38 },
            spawn = { x = 226.31, y = -169.15, z = 53.92, h = 160.21 },
            blip = { sprite = 357, color = 3, scale = 0.8 },
        },
        {
            name = 'garage_alta',
            label = 'Garaje Alta Street',
            type = 'public',
            coords = { x = -283.82, y = -886.73, z = 31.08 },
            spawn = { x = -290.19, y = -893.45, z = 31.08, h = 261.92 },
            blip = { sprite = 357, color = 3, scale = 0.8 },
        },
        {
            name = 'garage_sandy',
            label = 'Garaje Sandy Shores',
            type = 'public',
            coords = { x = 1737.83, y = 3710.33, z = 34.18 },
            spawn = { x = 1732.07, y = 3715.06, z = 34.18, h = 22.55 },
            blip = { sprite = 357, color = 3, scale = 0.8 },
        },
        {
            name = 'garage_paleto',
            label = 'Garaje Paleto Bay',
            type = 'public',
            coords = { x = 108.74, y = 6611.83, z = 32.0 },
            spawn = { x = 122.74, y = 6616.69, z = 31.87, h = 223.37 },
            blip = { sprite = 357, color = 3, scale = 0.8 },
        },
        {
            name = 'impound_main',
            label = 'Deposito Municipal',
            type = 'impound',
            coords = { x = 409.98, y = -1623.14, z = 29.29 },
            spawn = { x = 401.79, y = -1631.36, z = 29.29, h = 228.49 },
            blip = { sprite = 68, color = 1, scale = 0.8 },
        },
        {
            name = 'boat_vespucci',
            label = 'Puerto Vespucci',
            type = 'boat',
            coords = { x = -849.21, y = -1368.94, z = 1.6 },
            spawn = { x = -852.47, y = -1364.34, z = 0.0, h = 110.45 },
            blip = { sprite = 410, color = 3, scale = 0.8 },
        },
        {
            name = 'aircraft_lsia',
            label = 'Hangar LSIA',
            type = 'aircraft',
            coords = { x = -1650.76, y = -3143.54, z = 13.99 },
            spawn = { x = -1639.57, y = -3153.26, z = 13.99, h = 328.01 },
            blip = { sprite = 359, color = 3, scale = 0.8 },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Garage.Initialize()
    -- Asegurar tabla
    Garage.EnsureTables()

    -- Cargar garajes
    Garage.LoadGarages()

    -- Registrar en scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('garage_cache_refresh', {
            interval = 300,
            fn = Garage.RefreshCache
        })
    end

    if AIT.Log then
        AIT.Log.info('VEHICLES.GARAGE', 'Sistema de garajes inicializado con ' .. Garage.GetGarageCount() .. ' garajes')
    end

    return true
end

function Garage.EnsureTables()
    -- Tabla de garajes
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_garages (
            garage_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(64) NOT NULL,
            label VARCHAR(128) NOT NULL,
            type ENUM('public', 'private', 'house', 'faction', 'boat', 'aircraft', 'impound') NOT NULL DEFAULT 'public',

            -- Propietario (para privados)
            owner_type ENUM('system', 'char', 'faction', 'business', 'property') NOT NULL DEFAULT 'system',
            owner_id BIGINT NULL,

            -- Ubicacion
            coords JSON NOT NULL,
            spawn_coords JSON NOT NULL,
            return_coords JSON NULL,

            -- Configuracion
            max_slots INT NOT NULL DEFAULT 10,
            allowed_categories JSON NULL,
            storage_fee INT NOT NULL DEFAULT 0,
            retrieve_fee INT NOT NULL DEFAULT 0,

            -- Visual
            blip JSON NULL,
            marker JSON NULL,

            -- Estado
            status ENUM('active', 'closed', 'maintenance') NOT NULL DEFAULT 'active',
            access_list JSON NULL,

            -- Metadata
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

            UNIQUE KEY idx_name (name),
            KEY idx_owner (owner_type, owner_id),
            KEY idx_type (type)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Garage.LoadGarages()
    -- Cargar desde DB
    local dbGarages = MySQL.query.await('SELECT * FROM ait_garages WHERE status = "active"')

    Garage.garages = {}
    for _, g in ipairs(dbGarages or {}) do
        Garage.garages[g.garage_id] = {
            id = g.garage_id,
            name = g.name,
            label = g.label,
            type = g.type,
            ownerType = g.owner_type,
            ownerId = g.owner_id,
            coords = g.coords and json.decode(g.coords),
            spawnCoords = g.spawn_coords and json.decode(g.spawn_coords),
            returnCoords = g.return_coords and json.decode(g.return_coords),
            maxSlots = g.max_slots,
            allowedCategories = g.allowed_categories and json.decode(g.allowed_categories),
            storageFee = g.storage_fee,
            retrieveFee = g.retrieve_fee,
            blip = g.blip and json.decode(g.blip),
            marker = g.marker and json.decode(g.marker),
            accessList = g.access_list and json.decode(g.access_list),
        }
    end

    -- Insertar garajes por defecto si no existen
    if #dbGarages == 0 then
        Garage.InsertDefaultGarages()
    end
end

function Garage.InsertDefaultGarages()
    for _, garage in ipairs(Garage.Config.defaultGarages) do
        local typeConfig = Garage.Config.types[garage.type] or Garage.Config.types.public

        MySQL.insert.await([[
            INSERT IGNORE INTO ait_garages
            (name, label, type, coords, spawn_coords, max_slots, allowed_categories, storage_fee, retrieve_fee, blip)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            garage.name,
            garage.label,
            garage.type,
            json.encode(garage.coords),
            json.encode(garage.spawn),
            typeConfig.maxSlots,
            json.encode(typeConfig.canStore),
            typeConfig.storageFee,
            typeConfig.retrieveFee,
            garage.blip and json.encode(garage.blip)
        })
    end

    -- Recargar
    Garage.LoadGarages()
end

function Garage.RefreshCache()
    Garage.LoadGarages()
end

function Garage.GetGarageCount()
    local count = 0
    for _ in pairs(Garage.garages) do
        count = count + 1
    end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- OPERACIONES DE GARAJE
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene los datos de un garaje
---@param garageId number
---@return table|nil
function Garage.GetGarage(garageId)
    return Garage.garages[garageId]
end

--- Obtiene un garaje por nombre
---@param name string
---@return table|nil
function Garage.GetGarageByName(name)
    for _, garage in pairs(Garage.garages) do
        if garage.name == name then
            return garage
        end
    end
    return nil
end

--- Obtiene todos los garajes de un tipo
---@param garageType string
---@return table
function Garage.GetGaragesByType(garageType)
    local result = {}
    for _, garage in pairs(Garage.garages) do
        if garage.type == garageType then
            table.insert(result, garage)
        end
    end
    return result
end

--- Obtiene los garajes accesibles para un jugador
---@param source number
---@return table
function Garage.GetAccessibleGarages(source)
    local charId = Garage.GetCharacterId(source)
    local result = {}

    for _, garage in pairs(Garage.garages) do
        if Garage.CanAccess(source, garage.id) then
            table.insert(result, {
                id = garage.id,
                name = garage.name,
                label = garage.label,
                type = garage.type,
                coords = garage.coords,
                vehicleCount = Garage.GetVehicleCount(garage.id, charId),
                maxSlots = garage.maxSlots,
            })
        end
    end

    return result
end

--- Verifica si un jugador puede acceder a un garaje
---@param source number
---@param garageId number
---@return boolean
function Garage.CanAccess(source, garageId)
    local garage = Garage.GetGarage(garageId)
    if not garage then return false end

    local charId = Garage.GetCharacterId(source)

    -- Garajes publicos e impound accesibles para todos
    if garage.type == 'public' or garage.type == 'impound' then
        return true
    end

    -- Garajes del sistema
    if garage.ownerType == 'system' then
        return true
    end

    -- Garaje privado del personaje
    if garage.ownerType == 'char' and garage.ownerId == charId then
        return true
    end

    -- Garaje de faccion
    if garage.ownerType == 'faction' then
        if AIT.Engines.Factions then
            local factionId = AIT.Engines.Factions.GetCharacterFaction(charId)
            if factionId == garage.ownerId then
                return true
            end
        end
    end

    -- Lista de acceso
    if garage.accessList then
        for _, allowed in ipairs(garage.accessList) do
            if allowed.type == 'char' and allowed.id == charId then
                return true
            end
        end
    end

    -- Permisos admin
    if AIT.RBAC and AIT.RBAC.HasPermission(source, 'garage.access.any') then
        return true
    end

    return false
end

--- Obtiene el conteo de vehiculos en un garaje para un personaje
---@param garageId number
---@param charId number
---@return number
function Garage.GetVehicleCount(garageId, charId)
    local result = MySQL.query.await([[
        SELECT COUNT(*) as count FROM ait_vehicles
        WHERE garage_id = ? AND owner_type = 'char' AND owner_id = ? AND status = 'garaged'
    ]], { garageId, charId })

    return result and result[1] and result[1].count or 0
end

--- Obtiene los vehiculos de un personaje en un garaje
---@param source number
---@param garageId number
---@return table
function Garage.GetVehiclesInGarage(source, garageId)
    local garage = Garage.GetGarage(garageId)
    if not garage then
        return {}
    end

    if not Garage.CanAccess(source, garageId) then
        return {}
    end

    local charId = Garage.GetCharacterId(source)

    -- Para garajes de faccion, mostrar vehiculos de la faccion
    local ownerType = 'char'
    local ownerId = charId

    if garage.ownerType == 'faction' then
        ownerType = 'faction'
        ownerId = garage.ownerId
    end

    local vehicles = MySQL.query.await([[
        SELECT
            v.vehicle_id,
            v.model,
            v.plate,
            v.category,
            v.label,
            v.fuel,
            v.body_health,
            v.engine_health,
            v.mileage,
            v.mods,
            v.color_primary,
            v.color_secondary
        FROM ait_vehicles v
        WHERE v.garage_id = ?
        AND v.owner_type = ?
        AND v.owner_id = ?
        AND v.status = 'garaged'
        ORDER BY v.label, v.model
    ]], { garageId, ownerType, ownerId })

    -- Enriquecer datos
    local result = {}
    for _, v in ipairs(vehicles or {}) do
        table.insert(result, {
            id = v.vehicle_id,
            model = v.model,
            plate = v.plate,
            category = v.category,
            label = v.label or Garage.GetVehicleLabel(v.model),
            fuel = v.fuel,
            bodyHealth = v.body_health,
            engineHealth = v.engine_health,
            mileage = v.mileage,
            condition = Garage.CalculateCondition(v.body_health, v.engine_health),
        })
    end

    return result
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- GUARDAR / SACAR VEHICULOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Guarda un vehiculo en un garaje
---@param source number
---@param vehicleNetId number
---@param garageId number
---@return boolean, string
function Garage.StoreVehicle(source, vehicleNetId, garageId)
    -- Rate limiting
    if AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'garage.store')
        if not allowed then
            return false, 'Espera un momento antes de intentar de nuevo'
        end
    end

    local garage = Garage.GetGarage(garageId)
    if not garage then
        return false, 'Garaje no encontrado'
    end

    -- Verificar acceso
    if not Garage.CanAccess(source, garageId) then
        return false, 'No tienes acceso a este garaje'
    end

    -- Obtener datos del vehiculo spawneado
    local Vehicles = AIT.Engines.Vehicles
    local spawnData = Vehicles.spawned[vehicleNetId]

    if not spawnData then
        return false, 'Vehiculo no registrado'
    end

    -- Verificar propiedad
    local charId = Garage.GetCharacterId(source)
    local vehicle = Vehicles.GetVehicleData(spawnData.vehicleId)

    if not vehicle then
        return false, 'Datos del vehiculo no encontrados'
    end

    if vehicle.owner_type == 'char' and vehicle.owner_id ~= charId then
        local hasPermission = AIT.RBAC and AIT.RBAC.HasPermission(source, 'garage.store.any')
        if not hasPermission then
            return false, 'No eres el propietario de este vehiculo'
        end
    end

    -- Verificar categoria permitida
    if garage.allowedCategories and #garage.allowedCategories > 0 then
        local categoryAllowed = false
        for _, cat in ipairs(garage.allowedCategories) do
            if cat == 'all' or cat == vehicle.category then
                categoryAllowed = true
                break
            end
        end
        if not categoryAllowed then
            return false, 'Este tipo de vehiculo no puede guardarse aqui'
        end
    end

    -- Verificar slots disponibles
    local vehicleCount = Garage.GetVehicleCount(garageId, charId)
    if vehicleCount >= garage.maxSlots then
        return false, 'El garaje esta lleno'
    end

    -- Cobrar tarifa de almacenamiento
    if garage.storageFee > 0 and AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, garage.storageFee, 'cash', 'fee', 'Tarifa de garaje')
        if not success then
            return false, 'No tienes suficiente dinero para la tarifa ($' .. garage.storageFee .. ')'
        end
    end

    -- Guardar estado del vehiculo
    local entity = spawnData.entity
    if DoesEntityExist(entity) then
        Vehicles.SaveVehicleState(entity, spawnData.vehicleId)
    end

    -- Despawnear
    local despawnSuccess, despawnErr = Vehicles.Despawn(source, vehicleNetId, 'stored_in_garage')
    if not despawnSuccess then
        return false, despawnErr
    end

    -- Actualizar en DB
    MySQL.query.await([[
        UPDATE ait_vehicles
        SET status = 'garaged', garage_id = ?, position = NULL, rotation = NULL, updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { garageId, spawnData.vehicleId })

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.delete('vehicles', 'vehicle:' .. spawnData.vehicleId)
    end

    -- Log historial
    Vehicles.LogHistory(spawnData.vehicleId, 'garage_in', source, charId, {
        garageId = garageId,
        garageName = garage.name,
        fee = garage.storageFee
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.stored', {
            vehicleId = spawnData.vehicleId,
            garageId = garageId,
            plate = spawnData.plate,
        })
    end

    return true, 'Vehiculo guardado en ' .. garage.label
end

--- Saca un vehiculo del garaje
---@param source number
---@param vehicleId number
---@param garageId number
---@param spawnIndex? number Indice de punto de spawn alternativo
---@return boolean, number|string
function Garage.RetrieveVehicle(source, vehicleId, garageId, spawnIndex)
    -- Rate limiting
    if AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'garage.retrieve')
        if not allowed then
            return false, 'Espera un momento antes de intentar de nuevo'
        end
    end

    local garage = Garage.GetGarage(garageId)
    if not garage then
        return false, 'Garaje no encontrado'
    end

    -- Verificar acceso
    if not Garage.CanAccess(source, garageId) then
        return false, 'No tienes acceso a este garaje'
    end

    local Vehicles = AIT.Engines.Vehicles
    local vehicle = Vehicles.GetVehicleData(vehicleId)

    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar que este en este garaje
    if vehicle.garage_id ~= garageId then
        return false, 'El vehiculo no esta en este garaje'
    end

    if vehicle.status ~= 'garaged' then
        return false, 'El vehiculo no esta disponible'
    end

    -- Verificar propiedad
    local charId = Garage.GetCharacterId(source)
    if vehicle.owner_type == 'char' and vehicle.owner_id ~= charId then
        local hasPermission = AIT.RBAC and AIT.RBAC.HasPermission(source, 'garage.retrieve.any')
        if not hasPermission then
            return false, 'No eres el propietario de este vehiculo'
        end
    end

    -- Cobrar tarifa de recuperacion
    if garage.retrieveFee > 0 and AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, garage.retrieveFee, 'cash', 'fee', 'Tarifa de garaje')
        if not success then
            return false, 'No tienes suficiente dinero para la tarifa ($' .. garage.retrieveFee .. ')'
        end
    end

    -- Obtener coordenadas de spawn
    local spawnCoords = garage.spawnCoords
    if type(spawnCoords) == 'table' and spawnCoords[1] then
        -- Multiples puntos de spawn
        spawnCoords = spawnCoords[spawnIndex or 1] or spawnCoords[1]
    end

    if not spawnCoords then
        return false, 'Punto de spawn no configurado'
    end

    -- Verificar que el punto de spawn este libre
    local spawnPoint = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    if Garage.IsSpawnPointOccupied(spawnPoint) then
        return false, 'El punto de salida esta ocupado'
    end

    -- Spawnear vehiculo
    local success, netIdOrErr = Vehicles.Spawn(source, vehicleId, spawnPoint, spawnCoords.h or 0.0)

    if not success then
        -- Devolver la tarifa si falla
        if garage.retrieveFee > 0 and AIT.Engines.economy then
            AIT.Engines.economy.AddMoney(source, charId, garage.retrieveFee, 'cash', 'refund', 'Devolucion tarifa garaje')
        end
        return false, netIdOrErr
    end

    -- Log historial
    Vehicles.LogHistory(vehicleId, 'garage_out', source, charId, {
        garageId = garageId,
        garageName = garage.name,
        fee = garage.retrieveFee
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.retrieved', {
            vehicleId = vehicleId,
            garageId = garageId,
            netId = netIdOrErr,
            plate = vehicle.plate,
        })
    end

    return true, netIdOrErr
end

--- Verifica si un punto de spawn esta ocupado
---@param coords vector3
---@param radius? number
---@return boolean
function Garage.IsSpawnPointOccupied(coords, radius)
    radius = radius or 3.0

    local vehicles = GetAllVehicles()
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehCoords)
            if distance < radius then
                return true
            end
        end
    end

    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- TRANSFERENCIA ENTRE GARAJES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Transfiere un vehiculo entre garajes
---@param source number
---@param vehicleId number
---@param fromGarageId number
---@param toGarageId number
---@return boolean, string
function Garage.TransferVehicle(source, vehicleId, fromGarageId, toGarageId)
    -- Rate limiting
    if AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'garage.transfer')
        if not allowed then
            return false, 'Espera un momento antes de intentar de nuevo'
        end
    end

    local fromGarage = Garage.GetGarage(fromGarageId)
    local toGarage = Garage.GetGarage(toGarageId)

    if not fromGarage then
        return false, 'Garaje de origen no encontrado'
    end

    if not toGarage then
        return false, 'Garaje de destino no encontrado'
    end

    -- Verificar acceso a ambos garajes
    if not Garage.CanAccess(source, fromGarageId) then
        return false, 'No tienes acceso al garaje de origen'
    end

    if not Garage.CanAccess(source, toGarageId) then
        return false, 'No tienes acceso al garaje de destino'
    end

    local Vehicles = AIT.Engines.Vehicles
    local vehicle = Vehicles.GetVehicleData(vehicleId)

    if not vehicle then
        return false, 'Vehiculo no encontrado'
    end

    -- Verificar que este en el garaje de origen
    if vehicle.garage_id ~= fromGarageId then
        return false, 'El vehiculo no esta en el garaje de origen'
    end

    if vehicle.status ~= 'garaged' then
        return false, 'El vehiculo debe estar guardado para transferirlo'
    end

    -- Verificar propiedad
    local charId = Garage.GetCharacterId(source)
    if vehicle.owner_type == 'char' and vehicle.owner_id ~= charId then
        return false, 'No eres el propietario de este vehiculo'
    end

    -- Verificar categoria permitida en destino
    if toGarage.allowedCategories and #toGarage.allowedCategories > 0 then
        local categoryAllowed = false
        for _, cat in ipairs(toGarage.allowedCategories) do
            if cat == 'all' or cat == vehicle.category then
                categoryAllowed = true
                break
            end
        end
        if not categoryAllowed then
            return false, 'Este tipo de vehiculo no puede guardarse en el garaje de destino'
        end
    end

    -- Verificar slots en destino
    local vehicleCount = Garage.GetVehicleCount(toGarageId, charId)
    if vehicleCount >= toGarage.maxSlots then
        return false, 'El garaje de destino esta lleno'
    end

    -- Calcular costo de transferencia
    local transferFee = 0
    if fromGarage.type ~= toGarage.type then
        transferFee = 500 -- Tarifa base entre tipos diferentes
    end

    -- Distancia entre garajes (mayor distancia = mayor costo)
    if fromGarage.coords and toGarage.coords then
        local fromCoords = vector3(fromGarage.coords.x, fromGarage.coords.y, fromGarage.coords.z)
        local toCoords = vector3(toGarage.coords.x, toGarage.coords.y, toGarage.coords.z)
        local distance = #(fromCoords - toCoords)
        transferFee = transferFee + math.floor(distance * 0.5) -- $0.5 por metro
    end

    -- Cobrar tarifa
    if transferFee > 0 and AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, transferFee, 'bank', 'fee', 'Transferencia de garaje')
        if not success then
            return false, 'No tienes suficiente dinero para la transferencia ($' .. transferFee .. ')'
        end
    end

    -- Actualizar en DB
    MySQL.query.await([[
        UPDATE ait_vehicles SET garage_id = ?, updated_at = NOW()
        WHERE vehicle_id = ?
    ]], { toGarageId, vehicleId })

    -- Invalidar cache
    if AIT.Cache then
        AIT.Cache.delete('vehicles', 'vehicle:' .. vehicleId)
    end

    -- Log
    Vehicles.LogHistory(vehicleId, 'garage_out', source, charId, {
        action = 'transfer',
        fromGarageId = fromGarageId,
        toGarageId = toGarageId,
        fee = transferFee
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.transferred_garage', {
            vehicleId = vehicleId,
            fromGarageId = fromGarageId,
            toGarageId = toGarageId,
            fee = transferFee,
        })
    end

    return true, 'Vehiculo transferido a ' .. toGarage.label .. ' (Costo: $' .. transferFee .. ')'
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- GESTION DE GARAJES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Crea un nuevo garaje
---@param params table
---@return boolean, number|string
function Garage.CreateGarage(params)
    --[[
        params = {
            name = 'garage_custom_1',
            label = 'Mi Garaje',
            type = 'private',
            ownerType = 'char',
            ownerId = charId,
            coords = {x, y, z},
            spawnCoords = {x, y, z, h},
            maxSlots = 5,
        }
    ]]

    -- Validar nombre unico
    local existing = Garage.GetGarageByName(params.name)
    if existing then
        return false, 'Ya existe un garaje con ese nombre'
    end

    -- Obtener config del tipo
    local typeConfig = Garage.Config.types[params.type] or Garage.Config.types.private

    local garageId = MySQL.insert.await([[
        INSERT INTO ait_garages
        (name, label, type, owner_type, owner_id, coords, spawn_coords, max_slots, allowed_categories, storage_fee, retrieve_fee)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        params.name,
        params.label,
        params.type or 'private',
        params.ownerType or 'system',
        params.ownerId,
        json.encode(params.coords),
        json.encode(params.spawnCoords),
        params.maxSlots or typeConfig.maxSlots,
        json.encode(typeConfig.canStore),
        params.storageFee or typeConfig.storageFee,
        params.retrieveFee or typeConfig.retrieveFee
    })

    -- Recargar cache
    Garage.LoadGarages()

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('garage.created', {
            garageId = garageId,
            name = params.name,
            type = params.type,
        })
    end

    return true, garageId
end

--- Elimina un garaje
---@param garageId number
---@param moveVehiclesToGarageId? number
---@return boolean, string
function Garage.DeleteGarage(garageId, moveVehiclesToGarageId)
    local garage = Garage.GetGarage(garageId)
    if not garage then
        return false, 'Garaje no encontrado'
    end

    -- No permitir eliminar garajes del sistema
    if garage.ownerType == 'system' and garage.type == 'public' then
        return false, 'No se pueden eliminar garajes publicos del sistema'
    end

    -- Mover vehiculos a otro garaje
    local targetGarageId = moveVehiclesToGarageId or 1 -- Garaje principal por defecto

    MySQL.query.await([[
        UPDATE ait_vehicles SET garage_id = ?
        WHERE garage_id = ? AND status = 'garaged'
    ]], { targetGarageId, garageId })

    -- Marcar como cerrado
    MySQL.query.await([[
        UPDATE ait_garages SET status = 'closed', updated_at = NOW()
        WHERE garage_id = ?
    ]], { garageId })

    -- Recargar cache
    Garage.LoadGarages()

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('garage.deleted', {
            garageId = garageId,
            movedTo = targetGarageId,
        })
    end

    return true, 'Garaje eliminado'
end

--- Actualiza la configuracion de un garaje
---@param garageId number
---@param updates table
---@return boolean, string
function Garage.UpdateGarage(garageId, updates)
    local garage = Garage.GetGarage(garageId)
    if not garage then
        return false, 'Garaje no encontrado'
    end

    local fields = {}
    local values = {}

    if updates.label then
        table.insert(fields, 'label = ?')
        table.insert(values, updates.label)
    end

    if updates.maxSlots then
        table.insert(fields, 'max_slots = ?')
        table.insert(values, updates.maxSlots)
    end

    if updates.storageFee then
        table.insert(fields, 'storage_fee = ?')
        table.insert(values, updates.storageFee)
    end

    if updates.retrieveFee then
        table.insert(fields, 'retrieve_fee = ?')
        table.insert(values, updates.retrieveFee)
    end

    if updates.coords then
        table.insert(fields, 'coords = ?')
        table.insert(values, json.encode(updates.coords))
    end

    if updates.spawnCoords then
        table.insert(fields, 'spawn_coords = ?')
        table.insert(values, json.encode(updates.spawnCoords))
    end

    if updates.accessList then
        table.insert(fields, 'access_list = ?')
        table.insert(values, json.encode(updates.accessList))
    end

    if #fields == 0 then
        return false, 'Nada que actualizar'
    end

    table.insert(fields, 'updated_at = NOW()')
    table.insert(values, garageId)

    MySQL.query.await([[
        UPDATE ait_garages SET ]] .. table.concat(fields, ', ') .. [[
        WHERE garage_id = ?
    ]], values)

    -- Recargar cache
    Garage.LoadGarages()

    return true, 'Garaje actualizado'
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene el ID del personaje de un jugador
---@param source number
---@return number|nil
function Garage.GetCharacterId(source)
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

--- Obtiene el label de un modelo de vehiculo
---@param model string
---@return string
function Garage.GetVehicleLabel(model)
    local hash = GetHashKey(model)
    local displayName = GetDisplayNameFromVehicleModel(hash)
    if displayName and displayName ~= 'CARNOTFOUND' then
        return GetLabelText(displayName)
    end
    return model
end

--- Calcula la condicion general del vehiculo
---@param bodyHealth number
---@param engineHealth number
---@return string
function Garage.CalculateCondition(bodyHealth, engineHealth)
    local avg = (bodyHealth + engineHealth) / 2

    if avg >= 900 then
        return 'excelente'
    elseif avg >= 700 then
        return 'bueno'
    elseif avg >= 500 then
        return 'regular'
    elseif avg >= 300 then
        return 'malo'
    else
        return 'critico'
    end
end

--- Obtiene todos los garajes (para admin)
---@return table
function Garage.GetAllGarages()
    local result = {}
    for id, garage in pairs(Garage.garages) do
        table.insert(result, {
            id = id,
            name = garage.name,
            label = garage.label,
            type = garage.type,
            ownerType = garage.ownerType,
            ownerId = garage.ownerId,
            maxSlots = garage.maxSlots,
            coords = garage.coords,
        })
    end
    return result
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ═══════════════════════════════════════════════════════════════════════════════════════

Garage.API = {
    GetGarage = Garage.GetGarage,
    GetGarageByName = Garage.GetGarageByName,
    GetGaragesByType = Garage.GetGaragesByType,
    GetAccessibleGarages = Garage.GetAccessibleGarages,
    GetVehiclesInGarage = Garage.GetVehiclesInGarage,
    StoreVehicle = Garage.StoreVehicle,
    RetrieveVehicle = Garage.RetrieveVehicle,
    TransferVehicle = Garage.TransferVehicle,
    CanAccess = Garage.CanAccess,
    CreateGarage = Garage.CreateGarage,
    DeleteGarage = Garage.DeleteGarage,
    UpdateGarage = Garage.UpdateGarage,
    GetAllGarages = Garage.GetAllGarages,
}

-- Registrar en namespace
AIT.Engines.Vehicles.Garage = Garage

return Garage
