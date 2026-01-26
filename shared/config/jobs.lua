--[[
    AIT-QB: Configuración de Trabajos
    Servidor Español
]]

Config = Config or {}
Config.Jobs = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN GENERAL
-- ═══════════════════════════════════════════════════════════════

Config.Jobs.General = {
    paycheckInterval = 15,            -- Minutos entre pagos
    offDutyMultiplier = 0.0,          -- Multiplicador de pago fuera de servicio (0 = sin pago)
    maxSecondaryJobs = 2,             -- Máximo de trabajos secundarios
    dutyBlips = true,                 -- Mostrar blips de jugadores en servicio
    bossMenuEnabled = true,           -- Menú de jefe habilitado
    societyBankEnabled = true,        -- Banco de sociedad habilitado
}

-- ═══════════════════════════════════════════════════════════════
-- UBICACIONES DE TRABAJOS
-- ═══════════════════════════════════════════════════════════════

Config.Jobs.Locations = {
    -- POLICÍA
    police = {
        duty = {
            { coords = vector3(441.0, -982.0, 30.7), label = 'Fichar (MRPD)' },
            { coords = vector3(1853.0, 3689.0, 34.3), label = 'Fichar (Sandy)' },
            { coords = vector3(-449.0, 6012.0, 31.7), label = 'Fichar (Paleto)' },
        },
        armory = {
            { coords = vector3(453.0, -980.0, 30.7), label = 'Armería MRPD' },
        },
        garage = {
            { coords = vector3(454.5, -1017.5, 28.5), label = 'Garaje MRPD' },
        },
        stash = {
            { coords = vector3(460.0, -998.0, 30.7), label = 'Taquilla MRPD' },
        },
        boss = {
            { coords = vector3(461.0, -973.0, 30.7), label = 'Oficina Jefe' },
        },
    },

    -- EMS
    ambulance = {
        duty = {
            { coords = vector3(311.0, -595.0, 43.3), label = 'Fichar (Pillbox)' },
        },
        armory = {
            { coords = vector3(307.0, -600.0, 43.3), label = 'Suministros Médicos' },
        },
        garage = {
            { coords = vector3(325.0, -574.0, 28.8), label = 'Garaje EMS' },
        },
        stash = {
            { coords = vector3(303.0, -598.0, 43.3), label = 'Taquilla EMS' },
        },
        boss = {
            { coords = vector3(309.0, -590.0, 43.3), label = 'Oficina Director' },
        },
        bed = {
            { coords = vector3(356.0, -593.0, 28.8), label = 'Cama Hospital' },
        },
    },

    -- MECÁNICO
    mechanic = {
        duty = {
            { coords = vector3(-347.0, -133.0, 39.0), label = 'Fichar (LS Customs)' },
        },
        stash = {
            { coords = vector3(-345.0, -135.0, 39.0), label = 'Almacén' },
        },
        crafting = {
            { coords = vector3(-340.0, -130.0, 39.0), label = 'Mesa de Trabajo' },
        },
        boss = {
            { coords = vector3(-350.0, -128.0, 39.0), label = 'Oficina Jefe' },
        },
    },

    -- TAXI
    taxi = {
        duty = {
            { coords = vector3(895.0, -179.0, 74.7), label = 'Fichar (Taxi)' },
        },
        garage = {
            { coords = vector3(910.0, -170.0, 74.0), label = 'Garaje Taxi' },
        },
        boss = {
            { coords = vector3(900.0, -175.0, 74.7), label = 'Oficina' },
        },
    },

    -- BURGER SHOT
    burgershot = {
        duty = {
            { coords = vector3(-1192.0, -894.0, 14.0), label = 'Fichar (Burger Shot)' },
        },
        stash = {
            { coords = vector3(-1195.0, -890.0, 14.0), label = 'Almacén' },
        },
        counter = {
            { coords = vector3(-1187.0, -896.0, 14.0), label = 'Mostrador' },
        },
        crafting = {
            { coords = vector3(-1199.0, -898.0, 14.0), label = 'Cocina' },
        },
        boss = {
            { coords = vector3(-1200.0, -885.0, 14.0), label = 'Oficina Gerente' },
        },
    },

    -- INMOBILIARIA
    realestate = {
        duty = {
            { coords = vector3(-706.0, 268.0, 83.1), label = 'Fichar (Dynasty 8)' },
        },
        boss = {
            { coords = vector3(-710.0, 270.0, 83.1), label = 'Oficina Director' },
        },
    },

    -- MINERÍA
    miner = {
        start = {
            { coords = vector3(2952.0, 2759.0, 43.5), label = 'Mina (Inicio)' },
        },
        process = {
            { coords = vector3(2960.0, 2770.0, 43.5), label = 'Procesadora' },
        },
        sell = {
            { coords = vector3(1110.0, -2008.0, 30.9), label = 'Venta Minerales' },
        },
    },

    -- LEÑADOR
    lumberjack = {
        start = {
            { coords = vector3(-538.0, 5403.0, 70.0), label = 'Aserradero' },
        },
        process = {
            { coords = vector3(-530.0, 5410.0, 70.0), label = 'Sierra' },
        },
        sell = {
            { coords = vector3(-478.0, 5420.0, 79.0), label = 'Venta Madera' },
        },
    },

    -- PESCA
    fisher = {
        start = {
            { coords = vector3(-1850.0, -1245.0, 8.6), label = 'Tienda Pesca' },
        },
        spots = {
            { coords = vector3(-1850.0, -1235.0, 0.0), label = 'Muelle 1' },
            { coords = vector3(-2080.0, -1020.0, 0.0), label = 'Muelle 2' },
            { coords = vector3(1300.0, 4220.0, 33.0), label = 'Lago Alamo' },
        },
        sell = {
            { coords = vector3(-1840.0, -1250.0, 8.6), label = 'Venta Pescado' },
        },
    },

    -- GRANJERO
    farmer = {
        fields = {
            { coords = vector3(2015.0, 4986.0, 41.0), label = 'Campo 1', crop = 'wheat' },
            { coords = vector3(2135.0, 4800.0, 40.5), label = 'Campo 2', crop = 'corn' },
            { coords = vector3(2432.0, 4975.0, 46.0), label = 'Campo 3', crop = 'tomato' },
        },
        barn = {
            { coords = vector3(2018.0, 4992.0, 41.0), label = 'Granero' },
        },
        sell = {
            { coords = vector3(2120.0, 4770.0, 40.5), label = 'Mercado Agrícola' },
        },
    },

    -- CAZADOR
    hunter = {
        start = {
            { coords = vector3(-681.0, 5835.0, 17.3), label = 'Tienda Caza' },
        },
        zones = {
            { coords = vector3(-2169.0, 4270.0, 49.0), radius = 200.0, label = 'Zona Norte' },
            { coords = vector3(1180.0, -2180.0, 45.0), radius = 150.0, label = 'Zona Este' },
        },
        sell = {
            { coords = vector3(-675.0, 5830.0, 17.3), label = 'Venta Pieles' },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- INVENTARIO DE TRABAJOS (Items especiales)
-- ═══════════════════════════════════════════════════════════════

Config.Jobs.Items = {
    police = {
        { item = 'weapon_pistol', amount = 1 },
        { item = 'weapon_stungun', amount = 1 },
        { item = 'weapon_nightstick', amount = 1 },
        { item = 'handcuffs', amount = 5 },
        { item = 'radio', amount = 1 },
        { item = 'armor', amount = 2 },
        { item = 'medikit', amount = 2 },
    },

    ambulance = {
        { item = 'medikit', amount = 10 },
        { item = 'bandage', amount = 20 },
        { item = 'painkillers', amount = 10 },
        { item = 'oxygen_tank', amount = 2 },
        { item = 'defibrillator', amount = 1 },
        { item = 'radio', amount = 1 },
    },

    mechanic = {
        { item = 'repairkit', amount = 5 },
        { item = 'advancedrepairkit', amount = 2 },
        { item = 'cleaningkit', amount = 5 },
        { item = 'tirekit', amount = 4 },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- VEHÍCULOS DE TRABAJO
-- ═══════════════════════════════════════════════════════════════

Config.Jobs.Vehicles = {
    police = {
        { model = 'police', label = 'Patrulla', grade = 0 },
        { model = 'police2', label = 'Buffalo Policía', grade = 1 },
        { model = 'police3', label = 'Interceptor', grade = 2 },
        { model = 'policeb', label = 'Moto Policía', grade = 2 },
        { model = 'policet', label = 'Transporte', grade = 3 },
        { model = 'riot', label = 'Antidisturbios', grade = 4 },
        { model = 'polmav', label = 'Helicóptero', grade = 5 },
    },

    ambulance = {
        { model = 'ambulance', label = 'Ambulancia', grade = 0 },
        { model = 'lguard', label = 'Vehículo Rápido', grade = 2 },
    },

    mechanic = {
        { model = 'towtruck', label = 'Grúa', grade = 0 },
        { model = 'flatbed', label = 'Plataforma', grade = 2 },
    },

    taxi = {
        { model = 'taxi', label = 'Taxi', grade = 0 },
    },
}

return Config.Jobs
