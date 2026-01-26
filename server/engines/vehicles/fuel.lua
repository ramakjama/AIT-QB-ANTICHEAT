-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb VEHICLES ENGINE - FUEL
-- Sistema de combustible: consumo por tipo, gasolineras, jerry cans
-- Namespace: AIT.Engines.Vehicles.Fuel
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Vehicles = AIT.Engines.Vehicles or {}

local Fuel = {
    vehicleFuel = {},       -- Cache de combustible {netId = fuel}
    fuelStations = {},      -- Gasolineras
    fuelPrices = {},        -- Precios por tipo
    fuelConsumption = {},   -- Consumo por categoria
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

Fuel.Config = {
    -- Habilitar sistema
    enabled = true,

    -- Precio base por litro
    basePricePerLiter = 2.50,

    -- Capacidad de tanque por categoria (litros)
    tankCapacity = {
        compact = 45,
        sedan = 55,
        suv = 70,
        coupe = 50,
        muscle = 65,
        sport = 60,
        super = 80,
        motorcycle = 15,
        offroad = 80,
        industrial = 150,
        commercial = 100,
        emergency = 70,
        military = 120,
        boat = 200,
        helicopter = 400,
        plane = 1000,
    },

    -- Consumo por km por categoria (litros/km)
    consumptionRate = {
        compact = 0.06,
        sedan = 0.08,
        suv = 0.12,
        coupe = 0.09,
        muscle = 0.14,
        sport = 0.15,
        super = 0.20,
        motorcycle = 0.04,
        offroad = 0.16,
        industrial = 0.25,
        commercial = 0.18,
        emergency = 0.12,
        military = 0.22,
        boat = 0.30,
        helicopter = 0.80,
        plane = 1.50,
    },

    -- Multiplicadores de consumo
    consumptionMultipliers = {
        idle = 0.001,           -- Motor encendido sin moverse
        accelerating = 1.5,     -- Acelerando
        speeding = 2.0,         -- Alta velocidad (>100 km/h)
        offroad = 1.3,          -- Fuera de carretera
        damaged = 1.5,          -- Motor danado
    },

    -- Tipos de combustible
    fuelTypes = {
        regular = { label = 'Normal', priceMultiplier = 1.0, quality = 1.0 },
        premium = { label = 'Premium', priceMultiplier = 1.3, quality = 1.1 },
        diesel = { label = 'Diesel', priceMultiplier = 1.1, quality = 1.0 },
        electric = { label = 'Electrico', priceMultiplier = 0.8, quality = 1.0 },
        aviation = { label = 'Combustible de Aviacion', priceMultiplier = 2.0, quality = 1.0 },
    },

    -- Jerry Can
    jerryCanCapacity = 20,
    jerryCanItem = 'jerrycan',
    jerryCanFillTime = 5000,    -- ms para llenar

    -- Alertas
    lowFuelWarning = 20.0,      -- Porcentaje para alerta
    criticalFuelWarning = 10.0, -- Porcentaje critico

    -- Actualizacion
    updateInterval = 1000,      -- ms entre actualizaciones de consumo
    syncInterval = 10000,       -- ms entre sincronizaciones con servidor
}

-- Gasolineras predeterminadas
Fuel.DefaultStations = {
    { name = 'gas_pillbox', label = 'Gasolinera Pillbox', coords = { x = 265.65, y = -1261.85, z = 29.29 }, price = 2.50, fuelType = 'regular' },
    { name = 'gas_little_seoul', label = 'Gasolinera Little Seoul', coords = { x = -526.02, y = -1211.00, z = 18.18 }, price = 2.50, fuelType = 'regular' },
    { name = 'gas_mirror_park', label = 'Gasolinera Mirror Park', coords = { x = 1181.38, y = -330.85, z = 69.32 }, price = 2.40, fuelType = 'regular' },
    { name = 'gas_innocence', label = 'Gasolinera Innocence', coords = { x = 49.41, y = -1757.65, z = 29.44 }, price = 2.45, fuelType = 'regular' },
    { name = 'gas_grove', label = 'Gasolinera Grove Street', coords = { x = -70.21, y = -1761.79, z = 29.53 }, price = 2.45, fuelType = 'regular' },
    { name = 'gas_sandy', label = 'Gasolinera Sandy Shores', coords = { x = 1701.87, y = 6416.93, z = 32.76 }, price = 2.60, fuelType = 'regular' },
    { name = 'gas_paleto', label = 'Gasolinera Paleto', coords = { x = 180.73, y = 6602.83, z = 31.87 }, price = 2.55, fuelType = 'regular' },
    { name = 'gas_grapeseed', label = 'Gasolinera Grapeseed', coords = { x = 1687.15, y = 4929.40, z = 42.08 }, price = 2.55, fuelType = 'regular' },
    { name = 'gas_harmony', label = 'Gasolinera Harmony', coords = { x = 1039.96, y = 2671.13, z = 39.55 }, price = 2.50, fuelType = 'regular' },
    { name = 'gas_airport', label = 'Combustible Aeropuerto', coords = { x = -1606.44, y = -3104.73, z = 13.99 }, price = 5.00, fuelType = 'aviation' },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Fuel.Initialize()
    if not Fuel.Config.enabled then
        if AIT.Log then
            AIT.Log.info('VEHICLES.FUEL', 'Sistema de combustible deshabilitado')
        end
        return true
    end

    -- Asegurar tablas
    Fuel.EnsureTables()

    -- Cargar gasolineras
    Fuel.LoadStations()

    -- Cargar precios dinamicos
    Fuel.LoadPrices()

    -- Registrar jobs
    if AIT.Scheduler then
        AIT.Scheduler.register('fuel_price_update', {
            interval = 3600,    -- Cada hora
            fn = Fuel.UpdatePrices
        })

        AIT.Scheduler.register('fuel_sync', {
            interval = 30,
            fn = Fuel.SyncAll
        })
    end

    -- Registrar item jerry can
    if AIT.Engines.inventory then
        -- Asegurar que existe el item
        MySQL.insert.await([[
            INSERT IGNORE INTO ait_items_catalog
            (item_id, name, label, type, weight, stack_size, useable, base_price)
            VALUES ('jerrycan', 'Jerry Can', 'Bidon de Gasolina', 'tool', 2000, 1, 1, 500)
        ]], {})

        MySQL.insert.await([[
            INSERT IGNORE INTO ait_items_catalog
            (item_id, name, label, type, weight, stack_size, useable, base_price)
            VALUES ('jerrycan_empty', 'Empty Jerry Can', 'Bidon Vacio', 'tool', 500, 5, 1, 100)
        ]], {})
    end

    if AIT.Log then
        AIT.Log.info('VEHICLES.FUEL', 'Sistema de combustible inicializado')
    end

    return true
end

function Fuel.EnsureTables()
    -- Tabla de gasolineras
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_fuel_stations (
            station_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(64) NOT NULL,
            label VARCHAR(128) NOT NULL,
            coords JSON NOT NULL,
            fuel_type VARCHAR(32) NOT NULL DEFAULT 'regular',
            price_per_liter DECIMAL(6,2) NOT NULL DEFAULT 2.50,
            owner_type ENUM('system', 'char', 'faction', 'business') NOT NULL DEFAULT 'system',
            owner_id BIGINT NULL,
            stock INT NULL,
            max_stock INT NULL,
            status ENUM('active', 'closed', 'maintenance') NOT NULL DEFAULT 'active',
            blip JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY idx_name (name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de historial de repostaje
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_fuel_history (
            history_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            vehicle_id BIGINT NULL,
            station_id BIGINT NULL,
            char_id BIGINT NOT NULL,
            liters DECIMAL(6,2) NOT NULL,
            price_paid INT NOT NULL,
            fuel_type VARCHAR(32) NOT NULL,
            method ENUM('pump', 'jerrycan', 'admin') NOT NULL DEFAULT 'pump',
            KEY idx_vehicle (vehicle_id),
            KEY idx_station (station_id),
            KEY idx_ts (ts)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de precios dinamicos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_fuel_prices (
            price_id INT AUTO_INCREMENT PRIMARY KEY,
            fuel_type VARCHAR(32) NOT NULL,
            base_price DECIMAL(6,2) NOT NULL,
            current_price DECIMAL(6,2) NOT NULL,
            last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY idx_type (fuel_type)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Fuel.LoadStations()
    local stations = MySQL.query.await('SELECT * FROM ait_fuel_stations WHERE status = "active"')

    Fuel.fuelStations = {}
    for _, s in ipairs(stations or {}) do
        Fuel.fuelStations[s.station_id] = {
            id = s.station_id,
            name = s.name,
            label = s.label,
            coords = s.coords and json.decode(s.coords),
            fuelType = s.fuel_type,
            pricePerLiter = tonumber(s.price_per_liter),
            ownerType = s.owner_type,
            ownerId = s.owner_id,
            stock = s.stock,
            maxStock = s.max_stock,
        }
    end

    -- Insertar gasolineras por defecto si no existen
    if #stations == 0 then
        Fuel.InsertDefaultStations()
    end
end

function Fuel.InsertDefaultStations()
    for _, station in ipairs(Fuel.DefaultStations) do
        MySQL.insert.await([[
            INSERT IGNORE INTO ait_fuel_stations
            (name, label, coords, fuel_type, price_per_liter)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            station.name,
            station.label,
            json.encode(station.coords),
            station.fuelType,
            station.price
        })
    end

    -- Recargar
    Fuel.LoadStations()
end

function Fuel.LoadPrices()
    local prices = MySQL.query.await('SELECT * FROM ait_fuel_prices')

    Fuel.fuelPrices = {}
    for _, p in ipairs(prices or {}) do
        Fuel.fuelPrices[p.fuel_type] = {
            base = tonumber(p.base_price),
            current = tonumber(p.current_price),
        }
    end

    -- Insertar precios por defecto si no existen
    if #prices == 0 then
        for fuelType, config in pairs(Fuel.Config.fuelTypes) do
            local basePrice = Fuel.Config.basePricePerLiter * config.priceMultiplier
            MySQL.insert.await([[
                INSERT IGNORE INTO ait_fuel_prices (fuel_type, base_price, current_price)
                VALUES (?, ?, ?)
            ]], { fuelType, basePrice, basePrice })

            Fuel.fuelPrices[fuelType] = { base = basePrice, current = basePrice }
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- OPERACIONES DE COMBUSTIBLE
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene el combustible de un vehiculo
---@param vehicleEntity number
---@return number
function Fuel.GetFuel(vehicleEntity)
    if not DoesEntityExist(vehicleEntity) then
        return 0
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicleEntity)

    -- Primero buscar en cache
    if Fuel.vehicleFuel[netId] then
        return Fuel.vehicleFuel[netId]
    end

    -- Buscar en vehiculos spawneados
    local Vehicles = AIT.Engines.Vehicles
    if Vehicles and Vehicles.spawned[netId] then
        local spawnData = Vehicles.spawned[netId]
        local vehicleData = Vehicles.GetVehicleData(spawnData.vehicleId)
        if vehicleData then
            Fuel.vehicleFuel[netId] = vehicleData.fuel or 100.0
            return Fuel.vehicleFuel[netId]
        end
    end

    -- Default
    return 100.0
end

--- Establece el combustible de un vehiculo
---@param vehicleEntity number
---@param fuel number
function Fuel.SetFuel(vehicleEntity, fuel)
    if not DoesEntityExist(vehicleEntity) then return end

    fuel = math.max(0, math.min(100, fuel))

    local netId = NetworkGetNetworkIdFromEntity(vehicleEntity)
    Fuel.vehicleFuel[netId] = fuel

    -- Sincronizar con estado del servidor
    local Vehicles = AIT.Engines.Vehicles
    if Vehicles and Vehicles.spawned[netId] then
        -- Se guardara en el proximo flush de persistencia
    end

    -- Emitir evento si esta bajo
    if fuel <= Fuel.Config.criticalFuelWarning then
        if AIT.EventBus then
            AIT.EventBus.emit('vehicles.fuel.critical', {
                netId = netId,
                fuel = fuel,
            })
        end
    elseif fuel <= Fuel.Config.lowFuelWarning then
        if AIT.EventBus then
            AIT.EventBus.emit('vehicles.fuel.low', {
                netId = netId,
                fuel = fuel,
            })
        end
    end
end

--- Anade combustible a un vehiculo
---@param vehicleEntity number
---@param amount number Litros
---@return number Combustible final
function Fuel.AddFuel(vehicleEntity, amount)
    local currentFuel = Fuel.GetFuel(vehicleEntity)
    local newFuel = math.min(100, currentFuel + amount)
    Fuel.SetFuel(vehicleEntity, newFuel)
    return newFuel
end

--- Quita combustible de un vehiculo
---@param vehicleEntity number
---@param amount number Litros (o porcentaje)
---@return number Combustible restante
function Fuel.RemoveFuel(vehicleEntity, amount)
    local currentFuel = Fuel.GetFuel(vehicleEntity)
    local newFuel = math.max(0, currentFuel - amount)
    Fuel.SetFuel(vehicleEntity, newFuel)
    return newFuel
end

--- Calcula el consumo de combustible
---@param vehicleEntity number
---@param distance number Distancia recorrida
---@param speed number Velocidad actual
---@return number Combustible consumido
function Fuel.CalculateConsumption(vehicleEntity, distance, speed)
    if not DoesEntityExist(vehicleEntity) then return 0 end

    -- Obtener categoria del vehiculo
    local category = Fuel.GetVehicleCategory(vehicleEntity)
    local baseConsumption = Fuel.Config.consumptionRate[category] or 0.10

    -- Aplicar multiplicadores
    local multiplier = 1.0

    -- Alta velocidad
    if speed > 100 then
        multiplier = multiplier * Fuel.Config.consumptionMultipliers.speeding
    elseif speed > 50 then
        multiplier = multiplier * Fuel.Config.consumptionMultipliers.accelerating
    end

    -- Motor danado
    local engineHealth = GetVehicleEngineHealth(vehicleEntity)
    if engineHealth < 500 then
        multiplier = multiplier * Fuel.Config.consumptionMultipliers.damaged
    end

    -- Calcular consumo
    local consumption = baseConsumption * distance * multiplier

    -- Convertir a porcentaje del tanque
    local tankCapacity = Fuel.Config.tankCapacity[category] or 60
    local percentConsumed = (consumption / tankCapacity) * 100

    return percentConsumed
end

--- Obtiene la categoria de un vehiculo
---@param vehicleEntity number
---@return string
function Fuel.GetVehicleCategory(vehicleEntity)
    local class = GetVehicleClass(vehicleEntity)
    local Vehicles = AIT.Engines.Vehicles
    if Vehicles and Vehicles.Config and Vehicles.Config.classes then
        return Vehicles.Config.classes[class] or 'sedan'
    end
    return 'sedan'
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- GASOLINERAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene la gasolinera mas cercana
---@param coords vector3
---@return table|nil, number
function Fuel.GetNearestStation(coords)
    local nearest = nil
    local nearestDist = math.huge

    for _, station in pairs(Fuel.fuelStations) do
        if station.coords then
            local stationCoords = vector3(station.coords.x, station.coords.y, station.coords.z)
            local dist = #(coords - stationCoords)
            if dist < nearestDist then
                nearest = station
                nearestDist = dist
            end
        end
    end

    return nearest, nearestDist
end

--- Repostar en una gasolinera
---@param source number
---@param vehicleNetId number
---@param stationId number
---@param liters number|nil nil para llenar tanque
---@return boolean, string
function Fuel.RefuelAtStation(source, vehicleNetId, stationId, liters)
    -- Rate limiting
    if AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(source), 'fuel.refuel')
        if not allowed then
            return false, 'Espera un momento'
        end
    end

    local station = Fuel.fuelStations[stationId]
    if not station then
        return false, 'Gasolinera no encontrada'
    end

    -- Obtener vehiculo
    local Vehicles = AIT.Engines.Vehicles
    local spawnData = Vehicles and Vehicles.spawned[vehicleNetId]

    if not spawnData then
        return false, 'Vehiculo no encontrado'
    end

    local vehicleEntity = spawnData.entity
    if not DoesEntityExist(vehicleEntity) then
        return false, 'Vehiculo no existe'
    end

    -- Verificar que el jugador este cerca del vehiculo
    local charId = Fuel.GetCharacterId(source)

    -- Calcular combustible necesario
    local currentFuel = Fuel.GetFuel(vehicleEntity)
    local neededFuel = 100 - currentFuel

    if neededFuel <= 0 then
        return false, 'El tanque ya esta lleno'
    end

    -- Calcular litros a cargar
    local category = Fuel.GetVehicleCategory(vehicleEntity)
    local tankCapacity = Fuel.Config.tankCapacity[category] or 60

    local litersNeeded = (neededFuel / 100) * tankCapacity

    if liters then
        litersNeeded = math.min(liters, litersNeeded)
    end

    -- Verificar stock de la gasolinera
    if station.stock and station.stock < litersNeeded then
        litersNeeded = station.stock
        if litersNeeded <= 0 then
            return false, 'La gasolinera no tiene combustible'
        end
    end

    -- Calcular precio
    local pricePerLiter = Fuel.GetCurrentPrice(station.fuelType)
    local totalPrice = math.ceil(litersNeeded * pricePerLiter)

    -- Cobrar
    if AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, totalPrice, 'cash', 'purchase', 'Combustible')
        if not success then
            -- Intentar con banco
            success, err = AIT.Engines.economy.RemoveMoney(source, charId, totalPrice, 'bank', 'purchase', 'Combustible')
            if not success then
                return false, 'No tienes suficiente dinero ($' .. totalPrice .. ')'
            end
        end
    end

    -- Reducir stock de la gasolinera
    if station.stock then
        MySQL.query([[
            UPDATE ait_fuel_stations SET stock = stock - ? WHERE station_id = ?
        ]], { litersNeeded, stationId })
        station.stock = station.stock - litersNeeded
    end

    -- Agregar combustible
    local fuelToAdd = (litersNeeded / tankCapacity) * 100
    local newFuel = Fuel.AddFuel(vehicleEntity, fuelToAdd)

    -- Registrar historial
    MySQL.insert([[
        INSERT INTO ait_fuel_history
        (vehicle_id, station_id, char_id, liters, price_paid, fuel_type, method)
        VALUES (?, ?, ?, ?, ?, ?, 'pump')
    ]], {
        spawnData.vehicleId,
        stationId,
        charId,
        litersNeeded,
        totalPrice,
        station.fuelType
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.fuel.refueled', {
            vehicleId = spawnData.vehicleId,
            stationId = stationId,
            liters = litersNeeded,
            price = totalPrice,
            newFuel = newFuel,
        })
    end

    return true, string.format('Cargaste %.1f litros por $%d (%.0f%%)', litersNeeded, totalPrice, newFuel)
end

--- Repostar con jerry can
---@param source number
---@param vehicleNetId number
---@return boolean, string
function Fuel.RefuelWithJerryCan(source, vehicleNetId)
    local charId = Fuel.GetCharacterId(source)

    -- Verificar que tiene jerry can
    if AIT.Engines.inventory then
        local hasJerryCan = false
        local inventory = AIT.Engines.inventory.GetInventory('char', charId)

        for _, item in ipairs(inventory) do
            if item.id == Fuel.Config.jerryCanItem then
                hasJerryCan = true
                break
            end
        end

        if not hasJerryCan then
            return false, 'Necesitas un bidon de gasolina'
        end
    end

    -- Obtener vehiculo
    local Vehicles = AIT.Engines.Vehicles
    local spawnData = Vehicles and Vehicles.spawned[vehicleNetId]

    if not spawnData then
        return false, 'Vehiculo no encontrado'
    end

    local vehicleEntity = spawnData.entity
    if not DoesEntityExist(vehicleEntity) then
        return false, 'Vehiculo no existe'
    end

    -- Calcular combustible a agregar
    local category = Fuel.GetVehicleCategory(vehicleEntity)
    local tankCapacity = Fuel.Config.tankCapacity[category] or 60
    local fuelToAdd = (Fuel.Config.jerryCanCapacity / tankCapacity) * 100

    -- Agregar combustible
    local newFuel = Fuel.AddFuel(vehicleEntity, fuelToAdd)

    -- Quitar jerry can y dar bidon vacio
    if AIT.Engines.inventory then
        AIT.Engines.inventory.RemoveItem(source, 'char', charId, Fuel.Config.jerryCanItem, 1)
        AIT.Engines.inventory.GiveItem(source, 'char', charId, 'jerrycan_empty', 1)
    end

    -- Registrar historial
    MySQL.insert([[
        INSERT INTO ait_fuel_history
        (vehicle_id, char_id, liters, price_paid, fuel_type, method)
        VALUES (?, ?, ?, 0, 'regular', 'jerrycan')
    ]], {
        spawnData.vehicleId,
        charId,
        Fuel.Config.jerryCanCapacity
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('vehicles.fuel.jerrycan', {
            vehicleId = spawnData.vehicleId,
            liters = Fuel.Config.jerryCanCapacity,
            newFuel = newFuel,
        })
    end

    return true, string.format('Cargaste %d litros con el bidon (%.0f%%)', Fuel.Config.jerryCanCapacity, newFuel)
end

--- Llenar un jerry can en una gasolinera
---@param source number
---@param stationId number
---@return boolean, string
function Fuel.FillJerryCan(source, stationId)
    local charId = Fuel.GetCharacterId(source)

    -- Verificar que tiene bidon vacio
    if AIT.Engines.inventory then
        local hasEmptyCan = false
        local inventory = AIT.Engines.inventory.GetInventory('char', charId)

        for _, item in ipairs(inventory) do
            if item.id == 'jerrycan_empty' then
                hasEmptyCan = true
                break
            end
        end

        if not hasEmptyCan then
            return false, 'Necesitas un bidon vacio'
        end
    end

    local station = Fuel.fuelStations[stationId]
    if not station then
        return false, 'Gasolinera no encontrada'
    end

    -- Calcular precio
    local pricePerLiter = Fuel.GetCurrentPrice(station.fuelType)
    local totalPrice = math.ceil(Fuel.Config.jerryCanCapacity * pricePerLiter)

    -- Cobrar
    if AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, totalPrice, 'cash', 'purchase', 'Llenar bidon')
        if not success then
            return false, 'No tienes suficiente dinero ($' .. totalPrice .. ')'
        end
    end

    -- Cambiar item
    if AIT.Engines.inventory then
        AIT.Engines.inventory.RemoveItem(source, 'char', charId, 'jerrycan_empty', 1)
        AIT.Engines.inventory.GiveItem(source, 'char', charId, Fuel.Config.jerryCanItem, 1)
    end

    return true, string.format('Bidon lleno por $%d', totalPrice)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- PRECIOS DINAMICOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene el precio actual de un tipo de combustible
---@param fuelType string
---@return number
function Fuel.GetCurrentPrice(fuelType)
    fuelType = fuelType or 'regular'

    if Fuel.fuelPrices[fuelType] then
        return Fuel.fuelPrices[fuelType].current
    end

    return Fuel.Config.basePricePerLiter
end

--- Actualiza los precios del combustible
function Fuel.UpdatePrices()
    -- Simulacion simple de fluctuacion de precios
    for fuelType, priceData in pairs(Fuel.fuelPrices) do
        local basePrice = priceData.base
        local currentPrice = priceData.current

        -- Fluctuacion aleatoria de +/- 10%
        local fluctuation = (math.random() - 0.5) * 0.2
        local newPrice = basePrice * (1 + fluctuation)

        -- Limitar cambio maximo
        local maxChange = basePrice * 0.05
        local change = newPrice - currentPrice
        if math.abs(change) > maxChange then
            change = change > 0 and maxChange or -maxChange
        end

        newPrice = currentPrice + change

        -- Limitar rango
        newPrice = math.max(basePrice * 0.8, math.min(basePrice * 1.5, newPrice))

        -- Actualizar
        Fuel.fuelPrices[fuelType].current = newPrice

        MySQL.query([[
            UPDATE ait_fuel_prices SET current_price = ?, last_updated = NOW()
            WHERE fuel_type = ?
        ]], { newPrice, fuelType })
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('fuel.prices.updated', {
            prices = Fuel.fuelPrices
        })
    end

    if AIT.Log then
        AIT.Log.debug('VEHICLES.FUEL', 'Precios de combustible actualizados')
    end
end

--- Sincroniza el combustible de todos los vehiculos
function Fuel.SyncAll()
    local Vehicles = AIT.Engines.Vehicles
    if not Vehicles then return end

    for netId, fuel in pairs(Fuel.vehicleFuel) do
        local spawnData = Vehicles.spawned[netId]
        if spawnData then
            -- Se sincronizara en el proximo flush de persistencia
        else
            -- Vehiculo ya no existe, limpiar
            Fuel.vehicleFuel[netId] = nil
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene el ID del personaje de un jugador
---@param source number
---@return number|nil
function Fuel.GetCharacterId(source)
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

--- Obtiene todas las gasolineras
---@return table
function Fuel.GetAllStations()
    local result = {}
    for _, station in pairs(Fuel.fuelStations) do
        table.insert(result, {
            id = station.id,
            name = station.name,
            label = station.label,
            coords = station.coords,
            fuelType = station.fuelType,
            price = Fuel.GetCurrentPrice(station.fuelType),
        })
    end
    return result
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ═══════════════════════════════════════════════════════════════════════════════════════

Fuel.API = {
    GetFuel = Fuel.GetFuel,
    SetFuel = Fuel.SetFuel,
    AddFuel = Fuel.AddFuel,
    RemoveFuel = Fuel.RemoveFuel,
    CalculateConsumption = Fuel.CalculateConsumption,
    GetNearestStation = Fuel.GetNearestStation,
    RefuelAtStation = Fuel.RefuelAtStation,
    RefuelWithJerryCan = Fuel.RefuelWithJerryCan,
    FillJerryCan = Fuel.FillJerryCan,
    GetCurrentPrice = Fuel.GetCurrentPrice,
    GetAllStations = Fuel.GetAllStations,
}

-- Registrar en namespace
AIT.Engines.Vehicles.Fuel = Fuel

return Fuel
