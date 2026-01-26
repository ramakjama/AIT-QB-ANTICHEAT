--[[
    AIT-QB: Catálogo de Trabajos
    30+ trabajos legales e ilegales
    Servidor Español
]]

AIT = AIT or {}
AIT.Data = AIT.Data or {}
AIT.Data.Jobs = {}

-- TRABAJOS LEGALES
AIT.Data.Jobs.Legal = {
    -- SERVICIOS DE EMERGENCIA
    police = {
        label = 'Policía',
        description = 'Cuerpo de policía de Los Santos',
        type = 'government',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Cadete', payment = 450 },
            ['1'] = { name = 'Oficial', payment = 550 },
            ['2'] = { name = 'Oficial Superior', payment = 650 },
            ['3'] = { name = 'Sargento', payment = 750 },
            ['4'] = { name = 'Teniente', payment = 900 },
            ['5'] = { name = 'Capitán', payment = 1100 },
            ['6'] = { name = 'Comisario', payment = 1300, boss = true },
            ['7'] = { name = 'Jefe de Policía', payment = 1600, boss = true },
        },
        vehicles = { 'police', 'police2', 'police3', 'police4', 'policeb', 'policet', 'polmav' },
        armory = true,
        impound = true,
    },

    ambulance = {
        label = 'EMS',
        description = 'Servicios Médicos de Emergencia',
        type = 'government',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Paramédico en Prácticas', payment = 400 },
            ['1'] = { name = 'Paramédico', payment = 500 },
            ['2'] = { name = 'Paramédico Senior', payment = 600 },
            ['3'] = { name = 'Enfermero', payment = 700 },
            ['4'] = { name = 'Doctor', payment = 900 },
            ['5'] = { name = 'Cirujano', payment = 1100 },
            ['6'] = { name = 'Jefe Médico', payment = 1400, boss = true },
        },
        vehicles = { 'ambulance', 'lguard' },
        revive = true,
        heal = true,
    },

    fire = {
        label = 'Bomberos',
        description = 'Cuerpo de Bomberos de Los Santos',
        type = 'government',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Bombero en Prácticas', payment = 380 },
            ['1'] = { name = 'Bombero', payment = 480 },
            ['2'] = { name = 'Bombero Senior', payment = 580 },
            ['3'] = { name = 'Teniente', payment = 700 },
            ['4'] = { name = 'Capitán', payment = 850 },
            ['5'] = { name = 'Jefe de Bomberos', payment = 1100, boss = true },
        },
        vehicles = { 'firetruk' },
    },

    sheriff = {
        label = 'Sheriff',
        description = 'Oficina del Sheriff del Condado Blaine',
        type = 'government',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Cadete', payment = 420 },
            ['1'] = { name = 'Ayudante', payment = 520 },
            ['2'] = { name = 'Ayudante Senior', payment = 620 },
            ['3'] = { name = 'Sargento', payment = 720 },
            ['4'] = { name = 'Teniente', payment = 880 },
            ['5'] = { name = 'Sheriff', payment = 1200, boss = true },
        },
        vehicles = { 'sheriff', 'sheriff2' },
        armory = true,
        impound = true,
    },

    -- TRABAJOS DE OFICINA
    realestate = {
        label = 'Inmobiliaria',
        description = 'Agencia inmobiliaria Dynasty 8',
        type = 'business',
        defaultDuty = true,
        offDutyPay = true,
        grades = {
            ['0'] = { name = 'Agente Junior', payment = 300 },
            ['1'] = { name = 'Agente', payment = 400 },
            ['2'] = { name = 'Agente Senior', payment = 550 },
            ['3'] = { name = 'Director', payment = 750, boss = true },
        },
        sellHouses = true,
    },

    lawyer = {
        label = 'Abogado',
        description = 'Bufete de abogados',
        type = 'business',
        defaultDuty = true,
        offDutyPay = true,
        grades = {
            ['0'] = { name = 'Pasante', payment = 350 },
            ['1'] = { name = 'Abogado Junior', payment = 500 },
            ['2'] = { name = 'Abogado', payment = 700 },
            ['3'] = { name = 'Abogado Senior', payment = 950 },
            ['4'] = { name = 'Socio', payment = 1200, boss = true },
        },
        reduceSentence = true,
    },

    judge = {
        label = 'Juez',
        description = 'Tribunal de Los Santos',
        type = 'government',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Juez Asociado', payment = 1000 },
            ['1'] = { name = 'Juez', payment = 1500 },
            ['2'] = { name = 'Juez Superior', payment = 2000, boss = true },
        },
    },

    -- SERVICIOS
    mechanic = {
        label = 'Mecánico',
        description = 'Taller Los Santos Customs',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Aprendiz', payment = 250 },
            ['1'] = { name = 'Mecánico Junior', payment = 350 },
            ['2'] = { name = 'Mecánico', payment = 450 },
            ['3'] = { name = 'Mecánico Senior', payment = 600 },
            ['4'] = { name = 'Jefe de Taller', payment = 800, boss = true },
        },
        repairVehicles = true,
        tuning = true,
    },

    cardealer = {
        label = 'Concesionario',
        description = 'Premium Deluxe Motorsport',
        type = 'business',
        defaultDuty = true,
        offDutyPay = true,
        grades = {
            ['0'] = { name = 'Vendedor Junior', payment = 280 },
            ['1'] = { name = 'Vendedor', payment = 380 },
            ['2'] = { name = 'Vendedor Senior', payment = 520 },
            ['3'] = { name = 'Gerente', payment = 700, boss = true },
        },
        sellVehicles = true,
    },

    taxi = {
        label = 'Taxista',
        description = 'Downtown Cab Co.',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Conductor Novato', payment = 200 },
            ['1'] = { name = 'Conductor', payment = 280 },
            ['2'] = { name = 'Conductor Veterano', payment = 380 },
            ['3'] = { name = 'Supervisor', payment = 500, boss = true },
        },
        taxiMeter = true,
    },

    bus = {
        label = 'Autobús',
        description = 'Los Santos Transit',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Conductor en Prácticas', payment = 220 },
            ['1'] = { name = 'Conductor', payment = 320 },
            ['2'] = { name = 'Conductor Senior', payment = 420 },
            ['3'] = { name = 'Supervisor', payment = 550, boss = true },
        },
        busRoutes = true,
    },

    trucker = {
        label = 'Camionero',
        description = 'Transporte de mercancías',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Conductor Novato', payment = 250 },
            ['1'] = { name = 'Conductor', payment = 350 },
            ['2'] = { name = 'Conductor Experto', payment = 480 },
            ['3'] = { name = 'Jefe de Flota', payment = 650, boss = true },
        },
        deliveryMissions = true,
    },

    tow = {
        label = 'Grúa',
        description = 'Servicio de grúa',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Operador Junior', payment = 200 },
            ['1'] = { name = 'Operador', payment = 300 },
            ['2'] = { name = 'Operador Senior', payment = 420 },
            ['3'] = { name = 'Supervisor', payment = 550, boss = true },
        },
        towVehicles = true,
    },

    reporter = {
        label = 'Periodista',
        description = 'Weazel News',
        type = 'business',
        defaultDuty = true,
        offDutyPay = true,
        grades = {
            ['0'] = { name = 'Becario', payment = 200 },
            ['1'] = { name = 'Reportero Junior', payment = 320 },
            ['2'] = { name = 'Reportero', payment = 450 },
            ['3'] = { name = 'Reportero Senior', payment = 600 },
            ['4'] = { name = 'Editor Jefe', payment = 850, boss = true },
        },
        camera = true,
        microphone = true,
    },

    -- HOSTELERÍA Y COMERCIO
    burgershot = {
        label = 'Burger Shot',
        description = 'Restaurante de comida rápida',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Empleado', payment = 180 },
            ['1'] = { name = 'Cocinero', payment = 250 },
            ['2'] = { name = 'Encargado', payment = 350 },
            ['3'] = { name = 'Gerente', payment = 500, boss = true },
        },
        cooking = true,
    },

    pizzathis = {
        label = 'Pizza This',
        description = 'Pizzería',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Repartidor', payment = 180 },
            ['1'] = { name = 'Pizzero', payment = 260 },
            ['2'] = { name = 'Encargado', payment = 360 },
            ['3'] = { name = 'Gerente', payment = 520, boss = true },
        },
        cooking = true,
        delivery = true,
    },

    unicorn = {
        label = 'Vanilla Unicorn',
        description = 'Club nocturno',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Bailarín/a', payment = 200 },
            ['1'] = { name = 'Barman', payment = 280 },
            ['2'] = { name = 'Seguridad', payment = 350 },
            ['3'] = { name = 'Encargado', payment = 480 },
            ['4'] = { name = 'Gerente', payment = 650, boss = true },
        },
        bar = true,
    },

    casino = {
        label = 'Casino',
        description = 'Diamond Casino & Resort',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Crupier Junior', payment = 300 },
            ['1'] = { name = 'Crupier', payment = 420 },
            ['2'] = { name = 'Supervisor de Sala', payment = 580 },
            ['3'] = { name = 'Jefe de Seguridad', payment = 750 },
            ['4'] = { name = 'Director', payment = 1000, boss = true },
        },
        gambling = true,
    },

    -- RECURSOS Y PRODUCCIÓN
    miner = {
        label = 'Minero',
        description = 'Minas de Los Santos',
        type = 'labor',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Minero Novato', payment = 200 },
            ['1'] = { name = 'Minero', payment = 300 },
            ['2'] = { name = 'Minero Experto', payment = 420 },
            ['3'] = { name = 'Capataz', payment = 580, boss = true },
        },
        mining = true,
    },

    lumberjack = {
        label = 'Leñador',
        description = 'Industria maderera',
        type = 'labor',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Leñador Novato', payment = 180 },
            ['1'] = { name = 'Leñador', payment = 280 },
            ['2'] = { name = 'Leñador Experto', payment = 400 },
            ['3'] = { name = 'Supervisor', payment = 550, boss = true },
        },
        woodcutting = true,
    },

    farmer = {
        label = 'Granjero',
        description = 'Granjas del condado Blaine',
        type = 'labor',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Peón', payment = 150 },
            ['1'] = { name = 'Granjero', payment = 250 },
            ['2'] = { name = 'Granjero Senior', payment = 380 },
            ['3'] = { name = 'Dueño', payment = 550, boss = true },
        },
        farming = true,
        animals = true,
    },

    fisher = {
        label = 'Pescador',
        description = 'Pesca comercial',
        type = 'labor',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Pescador Novato', payment = 150 },
            ['1'] = { name = 'Pescador', payment = 250 },
            ['2'] = { name = 'Pescador Experto', payment = 380 },
            ['3'] = { name = 'Capitán', payment = 550, boss = true },
        },
        fishing = true,
    },

    hunter = {
        label = 'Cazador',
        description = 'Caza deportiva',
        type = 'labor',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Cazador Novato', payment = 180 },
            ['1'] = { name = 'Cazador', payment = 300 },
            ['2'] = { name = 'Cazador Experto', payment = 450 },
            ['3'] = { name = 'Guía', payment = 600, boss = true },
        },
        hunting = true,
    },

    vineyard = {
        label = 'Viñedo',
        description = 'Bodega de vinos',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recolector', payment = 180 },
            ['1'] = { name = 'Enólogo Junior', payment = 320 },
            ['2'] = { name = 'Enólogo', payment = 480 },
            ['3'] = { name = 'Dueño', payment = 700, boss = true },
        },
        winemaking = true,
    },

    -- GOBIERNO
    mayor = {
        label = 'Alcaldía',
        description = 'Gobierno de Los Santos',
        type = 'government',
        defaultDuty = false,
        offDutyPay = true,
        grades = {
            ['0'] = { name = 'Asistente', payment = 400 },
            ['1'] = { name = 'Secretario', payment = 550 },
            ['2'] = { name = 'Concejal', payment = 750 },
            ['3'] = { name = 'Vicealcalde', payment = 1000 },
            ['4'] = { name = 'Alcalde', payment = 1500, boss = true },
        },
        government = true,
    },
}

-- TRABAJOS ILEGALES
AIT.Data.Jobs.Illegal = {
    cartel = {
        label = 'Cartel',
        description = 'Organización criminal',
        type = 'criminal',
        defaultDuty = false,
        grades = {
            ['0'] = { name = 'Sicario', payment = 0 },
            ['1'] = { name = 'Soldado', payment = 0 },
            ['2'] = { name = 'Teniente', payment = 0 },
            ['3'] = { name = 'Capo', payment = 0 },
            ['4'] = { name = 'Jefe', payment = 0, boss = true },
        },
        drugs = true,
        territory = true,
    },

    mafia = {
        label = 'Mafia',
        description = 'Familia criminal italiana',
        type = 'criminal',
        defaultDuty = false,
        grades = {
            ['0'] = { name = 'Asociado', payment = 0 },
            ['1'] = { name = 'Soldado', payment = 0 },
            ['2'] = { name = 'Caporegime', payment = 0 },
            ['3'] = { name = 'Underboss', payment = 0 },
            ['4'] = { name = 'Don', payment = 0, boss = true },
        },
        extortion = true,
        gambling = true,
    },

    gang = {
        label = 'Pandilla',
        description = 'Pandilla callejera',
        type = 'criminal',
        defaultDuty = false,
        grades = {
            ['0'] = { name = 'Novato', payment = 0 },
            ['1'] = { name = 'Miembro', payment = 0 },
            ['2'] = { name = 'Veterano', payment = 0 },
            ['3'] = { name = 'OG', payment = 0 },
            ['4'] = { name = 'Líder', payment = 0, boss = true },
        },
        drugs = true,
        territory = true,
        graffiti = true,
    },
}

-- TRABAJO DESEMPLEADO
AIT.Data.Jobs.Unemployed = {
    unemployed = {
        label = 'Desempleado',
        description = 'Sin trabajo',
        type = 'none',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Desempleado', payment = 0 },
        },
    },
}

-- Función para obtener trabajo por nombre
function AIT.Data.Jobs.Get(jobName)
    if AIT.Data.Jobs.Legal[jobName] then
        return AIT.Data.Jobs.Legal[jobName]
    elseif AIT.Data.Jobs.Illegal[jobName] then
        return AIT.Data.Jobs.Illegal[jobName]
    elseif AIT.Data.Jobs.Unemployed[jobName] then
        return AIT.Data.Jobs.Unemployed[jobName]
    end
    return nil
end

-- Función para obtener todos los trabajos legales
function AIT.Data.Jobs.GetLegal()
    return AIT.Data.Jobs.Legal
end

-- Función para obtener trabajos por tipo
function AIT.Data.Jobs.GetByType(jobType)
    local jobs = {}
    for name, job in pairs(AIT.Data.Jobs.Legal) do
        if job.type == jobType then
            jobs[name] = job
        end
    end
    for name, job in pairs(AIT.Data.Jobs.Illegal) do
        if job.type == jobType then
            jobs[name] = job
        end
    end
    return jobs
end

return AIT.Data.Jobs
