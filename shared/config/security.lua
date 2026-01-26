-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb SECURITY CONFIGURATION
-- Configuración de seguridad optimizada para 2048 slots
-- ═══════════════════════════════════════════════════════════════════════════════════════

return {
    -- ───────────────────────────────────────────────────────────────────────────────────
    -- RATE LIMITING (Optimizado para 2048 jugadores)
    -- ───────────────────────────────────────────────────────────────────────────────────
    rateLimits = {
        -- Acciones críticas (por jugador)
        ['economy.tx'] = { max = 30, window = 60 },      -- 30 transacciones/minuto
        ['inventory.move'] = { max = 60, window = 60 },  -- 60 movimientos/minuto
        ['inventory.give'] = { max = 20, window = 60 },  -- 20 dar items/minuto
        ['inventory.use'] = { max = 30, window = 60 },   -- 30 usos/minuto
        ['chat.message'] = { max = 10, window = 10 },    -- 10 mensajes/10 seg
        ['phone.call'] = { max = 5, window = 60 },       -- 5 llamadas/minuto
        ['vehicle.spawn'] = { max = 5, window = 60 },    -- 5 vehículos/minuto

        -- Acciones de admin
        ['admin.action'] = { max = 100, window = 60 },
        ['admin.give'] = { max = 50, window = 60 },

        -- Global (límites del servidor)
        ['global.tx_per_second'] = { max = 5000, window = 1 }, -- 5000 tx/seg total
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ANTI-CHEAT
    -- ───────────────────────────────────────────────────────────────────────────────────
    anticheat = {
        enabled = true,

        -- Detección de teleport
        teleportDetection = {
            enabled = true,
            maxDistancePerTick = 100.0, -- metros
            whitelistedEvents = {
                'teleport:admin',
                'mission:checkpoint',
                'spawn:hospital',
            },
        },

        -- Detección de speedhack
        speedDetection = {
            enabled = true,
            maxVehicleSpeed = 500.0, -- km/h
            maxRunSpeed = 15.0, -- m/s
        },

        -- Detección de god mode
        godModeDetection = {
            enabled = true,
            damageThreshold = 1000, -- daño mínimo que debe recibir
            checkInterval = 30000, -- ms
        },

        -- Detección de weapon mods
        weaponModDetection = {
            enabled = true,
            maxDamageMultiplier = 1.5,
            maxFireRateMultiplier = 2.0,
        },

        -- Detección de inyección NUI
        nuiInjectionDetection = {
            enabled = true,
            whitelistedOrigins = {
                'nui://ait-qb',
            },
        },

        -- Acciones
        actions = {
            warn = { threshold = 3, action = 'log' },
            kick = { threshold = 5, action = 'kick' },
            ban = { threshold = 10, action = 'ban', duration = 86400 }, -- 24h
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- INTEGRIDAD DE DATOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    integrity = {
        -- Verificación de inventario
        inventoryChecks = {
            enabled = true,
            checkInterval = 300000, -- 5 minutos
            maxDiscrepancy = 5, -- items
        },

        -- Verificación de economía
        economyChecks = {
            enabled = true,
            maxBalanceChange = 10000000, -- $10M por transacción
            suspiciousThreshold = 1000000, -- $1M
        },

        -- Anti-duplicación
        antiDupe = {
            enabled = true,
            lockTimeout = 5000, -- ms
            transactionValidation = true,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- WHITELIST / BANLIST
    -- ───────────────────────────────────────────────────────────────────────────────────
    access = {
        whitelistEnabled = false,
        whitelistMessage = 'Este servidor requiere whitelist. Solicítala en nuestro Discord.',

        -- Identificadores a verificar
        identifiers = {
            'license',
            'discord',
            'steam',
            'fivem',
        },

        -- Ban evasion detection
        banEvasion = {
            enabled = true,
            checkHwid = true,
            checkIp = true,
            riskScoreThreshold = 50,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- SAFE ADMIN MODE
    -- ───────────────────────────────────────────────────────────────────────────────────
    safeAdmin = {
        enabled = true,

        -- Acciones que requieren confirmación
        requireConfirmation = {
            'economy.balance.adjust',
            'inventory.give',
            'vehicle.spawn',
            'security.ban.create',
            'faction.delete',
            'admin.server.restart',
        },

        -- Acciones que requieren aprobación de otro admin (4-eyes principle)
        requireApproval = {
            'admin.server.restart',
            'economy.balance.adjust', -- si > $1M
            'security.ban.create', -- si permanente
        },

        -- Cooldown entre acciones críticas
        cooldowns = {
            ['economy.balance.adjust'] = 60, -- 1 minuto
            ['security.ban.create'] = 30,
            ['admin.server.restart'] = 300, -- 5 minutos
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- LOGGING Y ALERTAS
    -- ───────────────────────────────────────────────────────────────────────────────────
    logging = {
        -- Nivel de log
        level = 'info', -- debug, info, warn, error

        -- Retención
        retention = {
            debug = 1, -- días
            info = 30,
            warn = 90,
            error = 180,
            critical = 365,
        },

        -- Webhooks de Discord
        discordAlerts = {
            enabled = true,
            minSeverity = 'warn',
            channels = {
                security = '', -- Webhook URL
                economy = '',
                admin = '',
            },
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- PROTECCIÓN DDoS / FLOOD
    -- ───────────────────────────────────────────────────────────────────────────────────
    ddosProtection = {
        enabled = true,

        -- Límites de conexión
        maxConnectionsPerIp = 3,
        maxConnectionAttemptsPerMinute = 10,

        -- Límites de eventos
        maxEventsPerPlayerPerSecond = 100,
        maxEventPayloadSize = 65536, -- 64KB

        -- Auto-kick por flood
        floodThreshold = 500, -- eventos/segundo
        floodAction = 'kick',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ENCRIPTACIÓN
    -- ───────────────────────────────────────────────────────────────────────────────────
    encryption = {
        -- Tokens de sesión
        sessionTokenExpiry = 3600, -- 1 hora

        -- API keys
        apiKeyRotation = 86400, -- 24 horas

        -- Hashing
        hashAlgorithm = 'sha256',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- SCORING DE RIESGO
    -- ───────────────────────────────────────────────────────────────────────────────────
    riskScoring = {
        enabled = true,

        factors = {
            newAccount = 10,
            noDiscord = 5,
            vpnDetected = 20,
            previousBan = 30,
            sharedIp = 15,
            suspiciousName = 5,
            rapidWealth = 25,
            unusualActivity = 15,
        },

        thresholds = {
            low = 0,
            medium = 25,
            high = 50,
            critical = 75,
        },

        actions = {
            medium = 'monitor',
            high = 'restrict',
            critical = 'review',
        },
    },
}
