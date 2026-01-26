-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT CONFIGURATION
-- Sistema de defensa contra RedEngine, PhazeMenu, y todos los menús de hack
-- ═══════════════════════════════════════════════════════════════════════════════════════

Config = Config or {}

Config.Anticheat = {
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- CONFIGURACIÓN GENERAL
    -- ═══════════════════════════════════════════════════════════════════════════════
    Enabled = true,
    Debug = false,                    -- Activar logs de debug (solo desarrollo)
    BanOnDetection = true,           -- Banear automáticamente al detectar cheat
    KickOnSuspicion = true,          -- Kickear en comportamiento sospechoso

    -- Discord Webhook para alertas
    DiscordWebhook = "",              -- Configura tu webhook aquí
    DiscordAlerts = true,

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- FIRMAS DE MENÚS CHEAT CONOCIDOS (BLACKLIST)
    -- Estas son las firmas de RedEngine, PhazeMenu, y otros menús conocidos
    -- ═══════════════════════════════════════════════════════════════════════════════
    CheatSignatures = {
        -- RedEngine signatures
        Resources = {
            "redengine", "red-engine", "red_engine", "redmenu",
            "phazemenu", "phaze-menu", "phaze_menu", "phazem",
            "lynx", "lynxmenu", "lynx-menu",
            "eulen", "eulenmenu", "eulen-menu",
            "skid", "skidmenu", "skid-menu",
            "hammafia", "ham-mafia", "ham_mafia",
            "kiddion", "kiddions", "modest-menu",
            "paragon", "paragonmenu",
            "cherax", "cheraxmenu",
            "2take1", "2t1menu",
            "stand", "standmenu",
            "midnight", "midnightmenu",
            "ozark", "ozarkmenu",
            "impulse", "impulsemenu",
            "phantom-x", "phantomx",
            "disturbed", "disturbedmenu",
            "delusion", "delusionmenu",
            "brutan", "brutanmenu",
            "desudo", "desudomenu",
            "epsilon", "epsilonmenu",
            "luna", "lunamenu",
            "robust", "robustmenu",
            "conqueror", "conquermenu",
            "rebound", "reboundmenu",
            "xcheats", "x-cheats",
            "fivem-trainer", "fivemtrainer",
            "menyoo", "menyoosp",
            "lambda", "lambdamenu",
            "simple-trainer", "simpletrainer",
        },

        -- Exports sospechosos
        Exports = {
            "ExecuteLua", "ExecuteCode", "InjectScript",
            "TriggerCheat", "SpawnMoney", "GodMode",
            "Teleport", "NoClip", "SuperJump",
            "InfiniteAmmo", "NoReload", "AimBot",
            "SpawnVehicle", "DeleteVehicle", "RepairVehicle",
            "SetHealth", "SetArmor", "SetMoney",
            "GiveWeapon", "RemoveWeapon", "MaxAmmo",
            "Invisible", "FastRun", "SuperSpeed",
            "Fly", "FlyMode", "FreeCam",
        },

        -- Eventos maliciosos conocidos
        Events = {
            "esx:setJob", "esx:setMoney", "esx:addMoney",
            "qb-admin:server:setjob", "qb-admin:server:givemoney",
            "qb-core:server:setMoney", "qb-core:server:addMoney",
            "playerDropped_forceKick", "baseevents:onPlayerKilled",
            "_chat:messageEntered", "__cfx_internal:httpResponse",
            "txAdmin:menu:healPlayer", "txAdmin:menu:tpToCoords",
            "vMenu:SetWeather", "vMenu:SetTime",
            "es:getPlayerFromIdentifier", "es:setAccountMoney",
            "esx_society:depositMoney", "esx_society:withdrawMoney",
            "esx_billing:sendBill", "esx_policejob:forcehandcuff",
            "skinchanger:change", "skinchanger:loadDefaultModel",
            "qb-clothing:server:saveSkin", "qb-clothes:server:loadOutfit",
            "qb-multicharacter:server:loadCharacter",
            -- Bloquear triggers remotos maliciosos
            "__cfx_export_", "__cfx_nui:",
        },

        -- Natives peligrosos
        Natives = {
            "SET_ENTITY_INVINCIBLE",
            "SET_PLAYER_INVINCIBLE",
            "NETWORK_SET_FRIENDLY_FIRE_OPTION",
            "SET_ENTITY_VISIBLE",
            "SET_ENTITY_COLLISION",
            "SET_ENTITY_COMPLETELY_DISABLE_COLLISION",
            "SET_ENTITY_COORDS_NO_OFFSET",
            "SET_ENTITY_VELOCITY",
            "SET_PED_CAN_RAGDOLL",
            "SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT",
            "CLEAR_PED_TASKS_IMMEDIATELY",
            "SET_PED_INTO_VEHICLE",
            "SET_PED_AMMO",
            "SET_PED_INFINITE_AMMO",
            "SET_PED_INFINITE_AMMO_CLIP",
            "GIVE_WEAPON_TO_PED",
            "REMOVE_ALL_PED_WEAPONS",
            "SET_CURRENT_PED_WEAPON",
            "SET_ENTITY_HEALTH",
            "SET_ENTITY_MAX_HEALTH",
            "SET_PED_ARMOUR",
            "ADD_ARMOUR_TO_PED",
            "CREATE_VEHICLE",
            "DELETE_ENTITY",
            "DELETE_VEHICLE",
            "SET_VEHICLE_FIXED",
            "SET_VEHICLE_ENGINE_HEALTH",
            "SET_VEHICLE_BODY_HEALTH",
            "SET_VEHICLE_PETROL_TANK_HEALTH",
            "SET_VEHICLE_FORWARD_SPEED",
            "SET_VEHICLE_ON_GROUND_PROPERLY",
            "SET_VEHICLE_DOORS_LOCKED",
            "SET_VEHICLE_MOD_KIT",
            "SET_PLAYER_WANTED_LEVEL",
            "SET_PLAYER_WANTED_LEVEL_NOW",
            "SET_MAX_WANTED_LEVEL",
            "NETWORK_SESSION_KICK_PLAYER",
            "NETWORK_SESSION_BLOCK_JOIN_REQUESTS",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- DETECCIÓN DE COMPORTAMIENTO ANÓMALO
    -- ═══════════════════════════════════════════════════════════════════════════════
    Detection = {
        -- Teleport detection
        Teleport = {
            Enabled = true,
            MaxDistancePerTick = 500.0,     -- Distancia máxima permitida por tick
            MaxDistancePerSecond = 200.0,   -- Distancia máxima por segundo
            GracePeriodOnSpawn = 10000,     -- Ms de gracia al spawnear
            WhitelistedZones = {},          -- Coordenadas permitidas para TP
        },

        -- Speedhack detection
        Speed = {
            Enabled = true,
            MaxFootSpeed = 15.0,            -- Velocidad máxima a pie (m/s)
            MaxVehicleSpeed = 100.0,        -- Velocidad máxima en vehículo (m/s) ~360 km/h
            MaxAircraftSpeed = 200.0,       -- Velocidad máxima en avión (m/s)
            Tolerance = 1.2,                -- 20% de tolerancia
        },

        -- Godmode detection
        Godmode = {
            Enabled = true,
            CheckInterval = 5000,           -- Cada 5 segundos
            DamageThreshold = 1000,         -- Daño que debería matar
            MaxTimeWithoutDamage = 300000,  -- 5 minutos en combate sin daño = sospechoso
        },

        -- Weapon detection
        Weapons = {
            Enabled = true,
            BlacklistedWeapons = {          -- Armas prohibidas
                `WEAPON_RAILGUN`,
                `WEAPON_MINIGUN`,
                `WEAPON_RPG`,
                `WEAPON_GRENADELAUNCHER`,
                `WEAPON_HOMINGLAUNCHER`,
                `WEAPON_STICKYBOMB`,
                `WEAPON_PROXMINE`,
                `WEAPON_FIREWORK`,
            },
            MaxDamageMultiplier = 2.0,      -- Máximo multiplicador de daño
            DetectInfiniteAmmo = true,
            DetectRapidFire = true,
            MaxFireRate = 1.5,              -- Máximo multiplicador de rate of fire
        },

        -- Money detection
        Money = {
            Enabled = true,
            MaxCashOnHand = 10000000,        -- $10M máximo en mano
            MaxBankBalance = 100000000,      -- $100M máximo en banco
            MaxTransactionPerHour = 5000000, -- $5M máximo por hora
            SuspiciousGainThreshold = 100000, -- Ganancias sospechosas
        },

        -- Vehicle spawn detection
        Vehicles = {
            Enabled = true,
            BlacklistedVehicles = {         -- Vehículos prohibidos
                `cargoplane`, `jet`, `lazer`, `hydra`, `rhino`, `khanjali`,
                `insurgent3`, `apc`, `tampa3`, `oppressor`, `oppressor2`,
                `deluxo`, `vigilante`, `stromberg`, `ruiner2`, `scramjet`,
                `thruster`, `volatol`, `avenger`, `akula`, `hunter`,
                `savage`, `valkyrie`, `bombushka`,
            },
            MaxSpawnsPerMinute = 3,          -- Máximo spawns por minuto
            RequireOwnership = true,         -- Requiere propiedad del vehículo
        },

        -- Explosion detection
        Explosions = {
            Enabled = true,
            MaxExplosionsPerMinute = 10,
            BlacklistedTypes = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, -- Explosiones prohibidas
        },

        -- Resource injection detection
        ResourceInjection = {
            Enabled = true,
            MonitorNewResources = true,
            BlockUnauthorizedResources = true,
        },

        -- Entity spawn detection
        EntitySpawn = {
            Enabled = true,
            MaxPedsPerPlayer = 5,
            MaxObjectsPerPlayer = 20,
            MaxVehiclesPerPlayer = 3,
            BlacklistedModels = {},
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- PROTECCIÓN DE EVENTOS
    -- ═══════════════════════════════════════════════════════════════════════════════
    EventProtection = {
        Enabled = true,

        -- Rate limiting por evento
        RateLimits = {
            default = {maxCalls = 60, perSeconds = 60},      -- 1 por segundo
            economy = {maxCalls = 10, perSeconds = 60},      -- 10 por minuto
            inventory = {maxCalls = 30, perSeconds = 60},    -- 30 por minuto
            admin = {maxCalls = 5, perSeconds = 60},         -- 5 por minuto
        },

        -- Eventos protegidos (requieren validación extra)
        ProtectedEvents = {
            "ait-qb:server:addMoney",
            "ait-qb:server:removeMoney",
            "ait-qb:server:transfer",
            "ait-qb:server:giveItem",
            "ait-qb:server:removeItem",
            "ait-qb:server:setJob",
            "ait-qb:server:setGang",
            "ait-qb:server:spawnVehicle",
            "ait-qb:server:deleteVehicle",
            "ait-qb:server:revive",
            "ait-qb:server:heal",
            "ait-qb:server:setCoords",
        },

        -- Eventos bloqueados completamente
        BlockedEvents = {
            "esx:setJob",
            "esx:setAccountMoney",
            "qb-admin:server:setjob",
            "qb-admin:server:givemoney",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- ACCIONES Y CASTIGOS
    -- ═══════════════════════════════════════════════════════════════════════════════
    Punishments = {
        -- Niveles de castigo
        Levels = {
            low = {action = "warn", duration = 0},              -- Solo advertencia
            medium = {action = "kick", duration = 0},           -- Kick
            high = {action = "tempban", duration = 86400},      -- Ban 24 horas
            critical = {action = "permaban", duration = 0},     -- Ban permanente
        },

        -- Asignación de castigos por tipo de detección
        DetectionPunishments = {
            cheat_menu = "critical",
            resource_injection = "critical",
            teleport = "high",
            speedhack = "high",
            godmode = "high",
            money_exploit = "critical",
            weapon_exploit = "high",
            vehicle_exploit = "medium",
            explosion_spam = "medium",
            event_spam = "medium",
            suspicious_behavior = "low",
        },

        -- Acumulación de strikes
        StrikeSystem = {
            Enabled = true,
            MaxStrikes = 3,               -- Strikes antes de ban
            StrikeDecayHours = 24,        -- Horas para que expire un strike
            AutoBanOnMaxStrikes = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- WHITELIST
    -- ═══════════════════════════════════════════════════════════════════════════════
    Whitelist = {
        -- Jugadores inmunes al anticheat (admins)
        Players = {
            -- "license:xxxxx",
            -- "steam:xxxxx",
        },

        -- Recursos permitidos
        Resources = {
            "ait-qb",
            "qb-core",
            "ox_lib",
            "oxmysql",
            "ox_inventory",
            "qb-inventory",
            "qb-target",
            "ox_target",
            "qb-menu",
            "ox_doorlock",
            "qb-doorlock",
            "qb-banking",
            "qb-phone",
            "qb-policejob",
            "qb-ambulancejob",
            "qb-mechanicjob",
            "qb-vehicleshop",
            "qb-clothing",
            "qb-multicharacter",
            "qb-spawn",
            "qb-apartments",
            "qb-garages",
            "qb-hud",
            "qb-smallresources",
        },

        -- IPs del servidor (para internal requests)
        ServerIPs = {
            "127.0.0.1",
            "localhost",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════════
    -- SCREENSHOTS Y EVIDENCIA
    -- ═══════════════════════════════════════════════════════════════════════════════
    Evidence = {
        TakeScreenshot = true,           -- Tomar screenshot al detectar
        ScreenshotResource = "screenshot-basic", -- Recurso de screenshots
        SaveToDatabase = true,
        KeepLogsDays = 30,               -- Días para mantener logs
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MENSAJES DE ANTICHEAT
-- ═══════════════════════════════════════════════════════════════════════════════════════

Config.AnticheatMessages = {
    BanMessage = "Has sido baneado por uso de hacks/cheats. ID: %s",
    KickMessage = "Has sido expulsado por comportamiento sospechoso.",
    WarnMessage = "Advertencia: Comportamiento sospechoso detectado.",

    -- Mensajes de Discord
    Discord = {
        BanTitle = "🚨 JUGADOR BANEADO",
        KickTitle = "⚠️ JUGADOR EXPULSADO",
        WarnTitle = "📝 ADVERTENCIA",
        DetectionTitle = "🔍 DETECCIÓN DE CHEAT",
    },
}

return Config
