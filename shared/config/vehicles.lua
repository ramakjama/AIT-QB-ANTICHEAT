--[[
    AIT-QB: Configuración de Vehículos
    Servidor Español
]]

Config = Config or {}
Config.Vehicles = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN GENERAL
-- ═══════════════════════════════════════════════════════════════

Config.Vehicles.General = {
    -- Llaves
    keysRequired = true,              -- ¿Se requieren llaves para conducir?
    lockpickEnabled = true,           -- ¿Se puede forzar cerraduras?
    hotwireEnabled = true,            -- ¿Se puede hacer puente?

    -- Combustible
    fuelEnabled = true,               -- Sistema de combustible activo
    fuelConsumption = 1.0,            -- Multiplicador de consumo (1.0 = normal)
    fuelPrice = 2.50,                 -- Precio por litro

    -- Daños
    damageEnabled = true,             -- Sistema de daños activo
    engineDamage = true,              -- Daño al motor
    bodyDamage = true,                -- Daño a la carrocería
    tireDamage = true,                -- Daño a los neumáticos

    -- Garajes
    maxVehiclesPerPlayer = 10,        -- Máximo de vehículos por jugador
    impoundTime = 24,                 -- Horas en el depósito
    impoundFee = 500,                 -- Tarifa base de depósito

    -- Persistencia
    saveVehicleState = true,          -- Guardar estado del vehículo
    despawnOnDisconnect = true,       -- Despawnear al desconectar
    despawnTime = 30,                 -- Minutos antes de despawnear abandonado
}

-- ═══════════════════════════════════════════════════════════════
-- GARAJES
-- ═══════════════════════════════════════════════════════════════

Config.Vehicles.Garages = {
    -- Garaje público principal
    public_pillbox = {
        label = 'Garaje Pillbox',
        type = 'public',
        coords = vector4(215.8, -810.0, 30.7, 340.0),
        spawn = vector4(223.0, -800.0, 30.5, 70.0),
        blip = { sprite = 357, color = 3, scale = 0.8 },
        categories = { 'compacts', 'sedans', 'coupes', 'sports', 'muscle', 'suv' },
    },

    public_airport = {
        label = 'Garaje Aeropuerto',
        type = 'public',
        coords = vector4(-796.0, -2024.0, 9.5, 55.0),
        spawn = vector4(-790.0, -2030.0, 8.5, 145.0),
        blip = { sprite = 357, color = 3, scale = 0.8 },
        categories = { 'compacts', 'sedans', 'coupes', 'sports', 'muscle', 'suv', 'super' },
    },

    public_sandy = {
        label = 'Garaje Sandy Shores',
        type = 'public',
        coords = vector4(1737.5, 3710.5, 34.0, 20.0),
        spawn = vector4(1745.0, 3715.0, 33.5, 110.0),
        blip = { sprite = 357, color = 3, scale = 0.8 },
        categories = { 'compacts', 'sedans', 'muscle', 'offroad' },
    },

    public_paleto = {
        label = 'Garaje Paleto Bay',
        type = 'public',
        coords = vector4(107.0, 6611.5, 32.0, 90.0),
        spawn = vector4(115.0, 6605.0, 31.5, 180.0),
        blip = { sprite = 357, color = 3, scale = 0.8 },
        categories = { 'compacts', 'sedans', 'muscle', 'offroad' },
    },

    -- Garaje de motos
    moto_downtown = {
        label = 'Garaje de Motos',
        type = 'public',
        coords = vector4(285.0, -1175.0, 29.3, 0.0),
        spawn = vector4(290.0, -1170.0, 29.0, 90.0),
        blip = { sprite = 226, color = 46, scale = 0.7 },
        categories = { 'motorcycles', 'cycles' },
    },

    -- Garaje de barcos
    boats_marina = {
        label = 'Marina Los Santos',
        type = 'boat',
        coords = vector4(-729.0, -1355.0, 1.6, 140.0),
        spawn = vector4(-719.0, -1330.0, 0.0, 230.0),
        blip = { sprite = 410, color = 26, scale = 0.8 },
        categories = { 'boats' },
    },

    -- Hangar de aviones
    hangar_lsia = {
        label = 'Hangar LSIA',
        type = 'aircraft',
        coords = vector4(-1274.0, -3412.0, 14.0, 330.0),
        spawn = vector4(-1290.0, -3400.0, 14.0, 330.0),
        blip = { sprite = 359, color = 69, scale = 0.8 },
        categories = { 'planes', 'helicopters' },
        restricted = true,
        job = nil, -- Requiere licencia de piloto
    },

    -- Garaje de policía
    police_mrpd = {
        label = 'Garaje MRPD',
        type = 'job',
        coords = vector4(454.5, -1017.5, 28.5, 90.0),
        spawn = vector4(440.0, -1025.0, 28.5, 180.0),
        blip = { sprite = 357, color = 29, scale = 0.7 },
        categories = { 'emergency' },
        restricted = true,
        job = 'police',
    },

    -- Garaje de EMS
    ems_pillbox = {
        label = 'Garaje EMS Pillbox',
        type = 'job',
        coords = vector4(325.0, -574.0, 28.8, 70.0),
        spawn = vector4(335.0, -580.0, 28.5, 160.0),
        blip = { sprite = 357, color = 1, scale = 0.7 },
        categories = { 'emergency' },
        restricted = true,
        job = 'ambulance',
    },

    -- Garaje de mecánicos
    mechanic_lscustoms = {
        label = 'Garaje LS Customs',
        type = 'job',
        coords = vector4(-347.0, -133.0, 39.0, 70.0),
        spawn = vector4(-355.0, -125.0, 38.5, 250.0),
        blip = { sprite = 357, color = 47, scale = 0.7 },
        categories = { 'compacts', 'sedans', 'coupes', 'sports', 'muscle', 'super', 'suv', 'vans', 'motorcycles' },
        restricted = true,
        job = 'mechanic',
    },
}

-- ═══════════════════════════════════════════════════════════════
-- DEPÓSITOS (IMPOUND)
-- ═══════════════════════════════════════════════════════════════

Config.Vehicles.Impounds = {
    impound_main = {
        label = 'Depósito Municipal',
        coords = vector4(409.0, -1623.0, 29.3, 230.0),
        spawn = vector4(401.0, -1630.0, 29.0, 140.0),
        blip = { sprite = 68, color = 4, scale = 0.8 },
        fee = {
            base = 500,
            perDay = 100,
            max = 5000,
        },
    },

    impound_police = {
        label = 'Depósito Policial',
        coords = vector4(436.0, -1007.0, 27.3, 180.0),
        spawn = vector4(430.0, -1000.0, 27.0, 270.0),
        blip = { sprite = 68, color = 29, scale = 0.7 },
        restricted = true,
        job = 'police',
        fee = {
            base = 1000,
            perDay = 200,
            max = 10000,
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- GASOLINERAS
-- ═══════════════════════════════════════════════════════════════

Config.Vehicles.GasStations = {
    { coords = vector3(49.4, 2778.8, 58.0), blip = true },
    { coords = vector3(263.9, 2606.5, 45.0), blip = true },
    { coords = vector3(1039.9, 2671.1, 39.6), blip = true },
    { coords = vector3(1207.3, 2660.0, 37.9), blip = true },
    { coords = vector3(2539.7, 2594.4, 37.9), blip = true },
    { coords = vector3(2679.9, 3263.9, 55.2), blip = true },
    { coords = vector3(2005.0, 3774.0, 32.4), blip = true },
    { coords = vector3(1687.2, 4929.4, 42.1), blip = true },
    { coords = vector3(1701.8, 6416.1, 32.8), blip = true },
    { coords = vector3(179.9, 6602.8, 32.0), blip = true },
    { coords = vector3(-94.5, 6419.0, 31.5), blip = true },
    { coords = vector3(-2554.9, 2334.4, 33.1), blip = true },
    { coords = vector3(-1800.4, 803.7, 138.6), blip = true },
    { coords = vector3(-1437.6, -276.8, 46.2), blip = true },
    { coords = vector3(-2096.2, -320.3, 13.2), blip = true },
    { coords = vector3(-724.6, -935.2, 19.2), blip = true },
    { coords = vector3(-526.0, -1211.0, 18.2), blip = true },
    { coords = vector3(-70.2, -1761.8, 29.5), blip = true },
    { coords = vector3(265.6, -1261.3, 29.3), blip = true },
    { coords = vector3(819.7, -1027.9, 26.4), blip = true },
    { coords = vector3(1208.9, -1402.6, 35.2), blip = true },
    { coords = vector3(1181.4, -330.8, 69.3), blip = true },
    { coords = vector3(620.8, 269.0, 103.1), blip = true },
    { coords = vector3(2581.4, 362.0, 108.5), blip = true },
    { coords = vector3(176.6, -1562.0, 29.3), blip = true },
    { coords = vector3(-319.3, -1471.6, 30.5), blip = true },
}

-- ═══════════════════════════════════════════════════════════════
-- CONCESIONARIOS
-- ═══════════════════════════════════════════════════════════════

Config.Vehicles.Dealerships = {
    pdm = {
        label = 'Premium Deluxe Motorsport',
        coords = vector4(-56.5, -1097.0, 26.4, 70.0),
        spawn = vector4(-35.0, -1095.0, 26.0, 70.0),
        blip = { sprite = 225, color = 46, scale = 0.8 },
        categories = { 'compacts', 'sedans', 'coupes', 'sports', 'muscle', 'suv' },
        testDrive = {
            enabled = true,
            duration = 60, -- segundos
            route = {
                vector3(-50.0, -1100.0, 26.0),
                vector3(100.0, -1100.0, 29.0),
                vector3(200.0, -900.0, 30.0),
            },
        },
    },

    luxury = {
        label = 'Concesionario de Lujo',
        coords = vector4(-800.0, -223.0, 37.0, 120.0),
        spawn = vector4(-790.0, -230.0, 36.5, 210.0),
        blip = { sprite = 225, color = 5, scale = 0.8 },
        categories = { 'super', 'sportsclassics' },
        priceMultiplier = 1.2,
    },

    boats = {
        label = 'Concesionario Náutico',
        coords = vector4(-738.0, -1334.0, 1.6, 50.0),
        spawn = vector4(-720.0, -1325.0, 0.0, 140.0),
        blip = { sprite = 410, color = 26, scale = 0.8 },
        categories = { 'boats' },
    },

    aircraft = {
        label = 'Aeronaves Los Santos',
        coords = vector4(-1270.0, -3390.0, 14.0, 330.0),
        spawn = vector4(-1285.0, -3380.0, 14.0, 330.0),
        blip = { sprite = 359, color = 69, scale = 0.8 },
        categories = { 'planes', 'helicopters' },
        requireLicense = 'piloto',
    },

    motorcycles = {
        label = 'Motoshop',
        coords = vector4(280.0, -1165.0, 29.3, 0.0),
        spawn = vector4(275.0, -1160.0, 29.0, 90.0),
        blip = { sprite = 226, color = 46, scale = 0.7 },
        categories = { 'motorcycles', 'cycles' },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- TALLERES
-- ═══════════════════════════════════════════════════════════════

Config.Vehicles.Workshops = {
    lscustoms_burton = {
        label = 'LS Customs Burton',
        coords = vector4(-347.0, -127.0, 39.0, 70.0),
        blip = { sprite = 72, color = 46, scale = 0.8 },
        prices = {
            repair = { min = 100, max = 5000 },
            paint = 500,
            wheel = 200,
            turbo = 5000,
            engine = { [1] = 2500, [2] = 5000, [3] = 10000, [4] = 25000 },
        },
    },

    lscustoms_airport = {
        label = 'LS Customs Aeropuerto',
        coords = vector4(-1155.0, -2007.0, 13.2, 315.0),
        blip = { sprite = 72, color = 46, scale = 0.8 },
    },

    bennys = {
        label = 'Benny\'s Original Motor Works',
        coords = vector4(-211.0, -1320.0, 31.0, 270.0),
        blip = { sprite = 72, color = 5, scale = 0.8 },
        premium = true,
        priceMultiplier = 1.5,
    },
}

return Config.Vehicles
