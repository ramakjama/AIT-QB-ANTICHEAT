-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb MAIN CONFIGURATION
-- Configuración principal del framework
-- ═══════════════════════════════════════════════════════════════════════════════════════

return {
    -- ═══════════════════════════════════════════════════════════════════════════════════
    -- ait-qb V1.0 - SERVIDOR DE ALTA CAPACIDAD (2048 SLOTS)
    -- ═══════════════════════════════════════════════════════════════════════════════════

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- INFORMACIÓN DEL SERVIDOR
    -- ───────────────────────────────────────────────────────────────────────────────────
    server = {
        name = 'ait-qb Server',
        description = 'Servidor de roleplay avanzado - Alta capacidad',
        logo = 'https://your-server.com/logo.png',
        discord = 'https://discord.gg/your-server',
        website = 'https://your-server.com',
        maxPlayers = 2048, -- SLOTS MÁXIMOS
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MODO DE SERVIDOR
    -- Options: 'realistic', 'semi-realistic', 'freeroam', 'pvp', 'hybrid'
    -- ───────────────────────────────────────────────────────────────────────────────────
    serverMode = 'realistic',

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- CONFIGURACIÓN DE ALTA CAPACIDAD (2048 SLOTS)
    -- ───────────────────────────────────────────────────────────────────────────────────
    highCapacity = {
        enabled = true,
        maxPlayers = 2048,

        -- Routing buckets para instancias
        routingBuckets = {
            enabled = true,
            maxPerBucket = 256, -- Máximo jugadores por bucket
            defaultBucket = 0,
        },

        -- Optimizaciones de rendimiento
        performance = {
            -- Reducir frecuencia de sync para jugadores lejanos
            dynamicSyncDistance = true,
            maxSyncDistance = 500.0, -- metros
            reducedSyncDistance = 100.0, -- para lejanos

            -- Batch de operaciones DB
            dbBatchSize = 100,
            dbFlushInterval = 2000, -- ms

            -- Event throttling
            eventThrottleMs = 50,
            maxEventsPerSecond = 10000,

            -- Cache agresivo
            cachePlayerData = true,
            cacheTTL = 300, -- 5 minutos
        },

        -- Distribución de carga
        loadBalancing = {
            -- Zonas del mapa
            zones = {
                { name = 'Los Santos Centro', bucket = 0, maxPlayers = 512 },
                { name = 'Los Santos Este', bucket = 1, maxPlayers = 256 },
                { name = 'Los Santos Oeste', bucket = 2, maxPlayers = 256 },
                { name = 'Sandy Shores', bucket = 3, maxPlayers = 256 },
                { name = 'Paleto Bay', bucket = 4, maxPlayers = 256 },
                { name = 'Instancias', bucket = 10, maxPlayers = 512 },
            },
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- DEBUG
    -- ───────────────────────────────────────────────────────────────────────────────────
    debug = false,
    debugLevel = 1, -- 1 = errors only, 2 = warnings, 3 = info, 4 = verbose

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MÓDULOS ACTIVOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    modules = {
        -- Core (siempre activos)
        'ain_identity',
        'ain_economy',
        'ain_inventory',

        -- RP Core
        'ain_factions',
        'ain_territory',
        'ain_missions',
        'ain_events',
        'ain_jobs',
        'ain_business',

        -- Gameplay
        'ain_vehicles',
        'ain_housing',
        'ain_weapons',
        'ain_clothing',

        -- Criminal
        'ain_heists',
        'ain_drugs',
        'ain_blackmarket',

        -- Competitive
        'ain_arena',
        'ain_matchmaker',
        'ain_racing',

        -- Support
        'ain_admin',
        'ain_analytics',
        'ain_security',
        'ain_liveops',

        -- Premium
        'ain_marketplace',
        'ain_crypto',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- PERSONAJES
    -- ───────────────────────────────────────────────────────────────────────────────────
    characters = {
        multichar = true,
        maxSlots = 5,
        deleteEnabled = false, -- Require admin for character deletion
        nameRules = {
            minLength = 2,
            maxLength = 32,
            allowNumbers = false,
            allowSpecialChars = false,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- NUEVO JUGADOR
    -- ───────────────────────────────────────────────────────────────────────────────────
    newPlayer = {
        spawn = vector4(-1037.51, -2738.35, 13.76, 326.12), -- Airport
        money = {
            cash = 500,
            bank = 5000,
        },
        items = {
            { item = 'phone', count = 1 },
            { item = 'id_card', count = 1 },
            { item = 'bread', count = 2 },
            { item = 'water', count = 2 },
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- RESPAWN
    -- ───────────────────────────────────────────────────────────────────────────────────
    respawn = {
        timer = 300, -- 5 minutos para esperar EMS
        hospitals = {
            { name = 'Pillbox Hill', coords = vector3(311.6, -584.4, 43.3) },
            { name = 'Sandy Shores', coords = vector3(1839.0, 3672.0, 34.3) },
            { name = 'Paleto Bay', coords = vector3(-247.8, 6331.6, 32.4) },
        },
        cost = 5000, -- Costo de respawn sin EMS
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- DISCORD INTEGRATION
    -- ───────────────────────────────────────────────────────────────────────────────────
    discord = {
        enabled = true,
        guildId = '',
        botToken = '', -- Set via convar: set ait_discord_token ""
        webhooks = {
            audit = '', -- Critical actions webhook
            admin = '', -- Admin actions webhook
            economy = '', -- Large transactions webhook
            security = '', -- Security alerts webhook
        },
        roles = {
            vip = '',
            staff = '',
            admin = '',
            owner = '',
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- LOCALIZATION
    -- ───────────────────────────────────────────────────────────────────────────────────
    locale = 'es', -- Default locale
    supportedLocales = { 'es', 'en' },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- TIME & WEATHER
    -- ───────────────────────────────────────────────────────────────────────────────────
    time = {
        sync = true,
        multiplier = 1.0, -- 1 real minute = 1 in-game minute
        freeze = false,
    },

    weather = {
        sync = true,
        dynamic = true,
        seasonalEffects = true,
    },
}
