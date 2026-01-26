-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb CORE BOOTSTRAP
-- Sistema de inicialización del framework
-- Versión: 1.0.0
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Objeto global del framework
AIT = AIT or {}
AIT.Version = '1.0.0'
AIT.Ready = false
AIT.StartTime = os.time()

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES BÁSICAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT.Utils = AIT.Utils or {}

--- Genera un UUID v4
function AIT.Utils.UUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--- Deep copy de una tabla
function AIT.Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[AIT.Utils.DeepCopy(orig_key)] = AIT.Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, AIT.Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Merge de tablas
function AIT.Utils.Merge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            AIT.Utils.Merge(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FASES DE ARRANQUE
-- ═══════════════════════════════════════════════════════════════════════════════════════

local BootPhases = {
    { name = 'CONFIG',      fn = 'LoadConfiguration',   critical = true  },
    { name = 'LOGGER',      fn = 'InitializeLogger',    critical = true  },
    { name = 'DATABASE',    fn = 'ConnectDatabase',     critical = true  },
    { name = 'MIGRATIONS',  fn = 'RunMigrations',       critical = true  },
    { name = 'CACHE',       fn = 'InitializeCache',     critical = true  },
    { name = 'DI',          fn = 'InitializeDI',        critical = true  },
    { name = 'EVENTBUS',    fn = 'InitializeEventBus',  critical = true  },
    { name = 'STATE',       fn = 'InitializeState',     critical = true  },
    { name = 'RBAC',        fn = 'InitializeRBAC',      critical = true  },
    { name = 'AUDIT',       fn = 'InitializeAudit',     critical = true  },
    { name = 'RATELIMIT',   fn = 'InitializeRateLimit', critical = true  },
    { name = 'SCHEDULER',   fn = 'InitializeScheduler', critical = true  },
    { name = 'FEATURES',    fn = 'LoadFeatureFlags',    critical = true  },
    { name = 'RULES',       fn = 'InitializeRuleEngine',critical = false },
    { name = 'BRIDGES',     fn = 'LoadBridges',         critical = true  },
    { name = 'ENGINES',     fn = 'LoadEngines',         critical = true  },
    { name = 'MODULES',     fn = 'LoadModules',         critical = false },
    { name = 'EXPORTS',     fn = 'RegisterExports',     critical = true  },
    { name = 'HEALTH',      fn = 'StartHealthCheck',    critical = false },
    { name = 'READY',       fn = 'MarkReady',           critical = true  },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- IMPLEMENTACIONES DE FASES
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Boot = {}

--- Carga la configuración
function Boot.LoadConfiguration()
    AIT.Config = {}

    -- Cargar archivos de configuración
    local configModules = {
        'main', 'economy', 'inventory', 'factions', 'missions',
        'events', 'vehicles', 'weapons', 'clothing', 'housing',
        'pvp', 'security', 'features', 'marketplace'
    }

    for _, moduleName in ipairs(configModules) do
        local configPath = ('shared/config/%s.lua'):format(moduleName)
        local chunk = LoadResourceFile(GetCurrentResourceName(), configPath)
        if chunk then
            local configFn, err = load(chunk, configPath)
            if configFn then
                local success, config = pcall(configFn)
                if success then
                    AIT.Config[moduleName] = config
                else
                    print(('[AIT] Error loading config %s: %s'):format(moduleName, config))
                end
            else
                print(('[AIT] Error parsing config %s: %s'):format(moduleName, err))
            end
        end
    end

    -- Overrides por convars
    AIT.Config.Environment = GetConvar('ait_environment', 'production')
    AIT.Config.Debug = GetConvarInt('ait_debug', 0) == 1

    if AIT.Config.main then
        AIT.Config.main.debug = AIT.Config.Debug
    end

    return true
end

--- Inicializa el logger
function Boot.InitializeLogger()
    AIT.Log = {
        levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4, CRITICAL = 5 },
        currentLevel = AIT.Config.Debug and 1 or 2,
        colors = {
            DEBUG = '^5',
            INFO = '^2',
            WARN = '^3',
            ERROR = '^1',
            CRITICAL = '^1^*'
        },

        write = function(level, category, message, data)
            if AIT.Log.levels[level] < AIT.Log.currentLevel then return end

            local timestamp = os.date('%Y-%m-%d %H:%M:%S')
            local color = AIT.Log.colors[level] or '^7'

            -- Consola
            print(('%s[%s] [%s] [%s]^7 %s'):format(
                color, timestamp, level, category, message
            ))

            -- Data adicional
            if data and AIT.Config.Debug then
                print('^8' .. json.encode(data) .. '^7')
            end

            -- Log a base de datos para niveles importantes
            if level ~= 'DEBUG' and AIT.Audit then
                SetTimeout(0, function()
                    AIT.Audit.LogSystem(level, category, message, data)
                end)
            end

            -- Discord webhook para críticos
            if level == 'CRITICAL' and AIT.Discord then
                AIT.Discord.SendAlert('CRITICAL', category, message, data)
            end
        end,

        debug = function(cat, msg, data) AIT.Log.write('DEBUG', cat, msg, data) end,
        info = function(cat, msg, data) AIT.Log.write('INFO', cat, msg, data) end,
        warn = function(cat, msg, data) AIT.Log.write('WARN', cat, msg, data) end,
        error = function(cat, msg, data) AIT.Log.write('ERROR', cat, msg, data) end,
        critical = function(cat, msg, data) AIT.Log.write('CRITICAL', cat, msg, data) end,
    }

    return true
end

--- Conecta a la base de datos
function Boot.ConnectDatabase()
    if not MySQL then
        return false, 'MySQL (oxmysql) not available'
    end

    -- Test de conexión
    local result = MySQL.query.await('SELECT 1 as test')
    if not result or not result[1] then
        return false, 'Database connection failed'
    end

    -- Configuración de conexión
    MySQL.query.await("SET SESSION wait_timeout = 28800")
    MySQL.query.await("SET SESSION interactive_timeout = 28800")

    AIT.Log.info('DATABASE', 'Database connection established')
    return true
end

--- Ejecuta migraciones
function Boot.RunMigrations()
    -- Crear tabla de migraciones si no existe
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            version VARCHAR(32) NOT NULL,
            name VARCHAR(255) NOT NULL,
            executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            checksum BIGINT,
            UNIQUE KEY idx_version (version)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Obtener migraciones ejecutadas
    local executed = MySQL.query.await('SELECT version FROM ait_migrations ORDER BY id')
    local executedVersions = {}
    for _, row in ipairs(executed or {}) do
        executedVersions[row.version] = true
    end

    -- Lista de migraciones
    local migrations = {
        { version = '001', file = '001_initial.sql', name = 'Initial schema' },
        { version = '002', file = '002_economy.sql', name = 'Economy system' },
        { version = '003', file = '003_inventory.sql', name = 'Inventory system' },
        { version = '004', file = '004_factions.sql', name = 'Factions system' },
        { version = '005', file = '005_missions.sql', name = 'Missions system' },
        { version = '006', file = '006_vehicles.sql', name = 'Vehicles system' },
        { version = '007', file = '007_housing.sql', name = 'Housing system' },
        { version = '008', file = '008_marketplace.sql', name = 'Marketplace system' },
        { version = '009', file = '009_analytics.sql', name = 'Analytics system' },
        { version = '010', file = '010_security.sql', name = 'Security system' },
    }

    local migrationsPath = 'server/db/migrations'
    local migrationsRun = 0

    for _, migration in ipairs(migrations) do
        if not executedVersions[migration.version] then
            local sql = LoadResourceFile(GetCurrentResourceName(), migrationsPath .. '/' .. migration.file)
            if sql then
                local success, err = pcall(function()
                    -- Ejecutar cada statement por separado
                    for statement in sql:gmatch('[^;]+') do
                        statement = statement:match('^%s*(.-)%s*$')
                        if statement and #statement > 0 and not statement:match('^%-%-') then
                            MySQL.query.await(statement)
                        end
                    end
                end)

                if success then
                    MySQL.insert.await(
                        'INSERT INTO ait_migrations (version, name, checksum) VALUES (?, ?, ?)',
                        { migration.version, migration.name, GetHashKey(sql) }
                    )
                    AIT.Log.info('MIGRATIONS', 'Executed: ' .. migration.name)
                    migrationsRun = migrationsRun + 1
                else
                    return false, 'Migration failed: ' .. migration.file .. ' - ' .. tostring(err)
                end
            else
                AIT.Log.warn('MIGRATIONS', 'Migration file not found: ' .. migration.file)
            end
        end
    end

    if migrationsRun > 0 then
        AIT.Log.info('MIGRATIONS', ('Executed %d migrations'):format(migrationsRun))
    else
        AIT.Log.info('MIGRATIONS', 'Database is up to date')
    end

    return true
end

--- Inicializa la caché
function Boot.InitializeCache()
    -- Implementación delegada a core/cache.lua
    if AIT.Cache and AIT.Cache.Initialize then
        return AIT.Cache.Initialize()
    end

    -- Implementación básica si no está cargado
    AIT.Cache = {
        data = {},
        ttl = {},

        get = function(namespace, key)
            local fullKey = namespace .. ':' .. key
            local entry = AIT.Cache.data[fullKey]
            if entry then
                if AIT.Cache.ttl[fullKey] and os.time() > AIT.Cache.ttl[fullKey] then
                    AIT.Cache.data[fullKey] = nil
                    AIT.Cache.ttl[fullKey] = nil
                    return nil
                end
                return entry
            end
            return nil
        end,

        set = function(namespace, key, value, ttlSeconds)
            local fullKey = namespace .. ':' .. key
            AIT.Cache.data[fullKey] = value
            if ttlSeconds then
                AIT.Cache.ttl[fullKey] = os.time() + ttlSeconds
            end
        end,

        delete = function(namespace, key)
            local fullKey = namespace .. ':' .. key
            AIT.Cache.data[fullKey] = nil
            AIT.Cache.ttl[fullKey] = nil
        end,

        invalidateNamespace = function(namespace)
            local prefix = namespace .. ':'
            for key in pairs(AIT.Cache.data) do
                if key:sub(1, #prefix) == prefix then
                    AIT.Cache.data[key] = nil
                    AIT.Cache.ttl[key] = nil
                end
            end
        end,

        purgeExpired = function()
            local now = os.time()
            for key, expiry in pairs(AIT.Cache.ttl) do
                if now > expiry then
                    AIT.Cache.data[key] = nil
                    AIT.Cache.ttl[key] = nil
                end
            end
        end
    }

    -- Limpieza periódica
    CreateThread(function()
        while true do
            Wait(60000)
            AIT.Cache.purgeExpired()
        end
    end)

    return true
end

--- Inicializa el contenedor DI
function Boot.InitializeDI()
    -- Delegado a core/di.lua
    if AIT.DI and AIT.DI.Initialize then
        return AIT.DI.Initialize()
    end
    return true
end

--- Inicializa el Event Bus
function Boot.InitializeEventBus()
    -- Delegado a core/eventbus.lua
    if AIT.EventBus and AIT.EventBus.Initialize then
        return AIT.EventBus.Initialize()
    end
    return true
end

--- Inicializa el State Manager
function Boot.InitializeState()
    -- Delegado a core/state.lua
    if AIT.State and AIT.State.Initialize then
        return AIT.State.Initialize()
    end
    return true
end

--- Inicializa RBAC
function Boot.InitializeRBAC()
    -- Delegado a core/rbac.lua
    if AIT.RBAC and AIT.RBAC.Initialize then
        return AIT.RBAC.Initialize()
    end
    return true
end

--- Inicializa Audit
function Boot.InitializeAudit()
    -- Delegado a core/audit.lua
    if AIT.Audit and AIT.Audit.Initialize then
        return AIT.Audit.Initialize()
    end
    return true
end

--- Inicializa Rate Limiter
function Boot.InitializeRateLimit()
    -- Delegado a core/ratelimit.lua
    if AIT.RateLimit and AIT.RateLimit.Initialize then
        return AIT.RateLimit.Initialize()
    end
    return true
end

--- Inicializa el Scheduler
function Boot.InitializeScheduler()
    -- Delegado a core/scheduler.lua
    if AIT.Scheduler and AIT.Scheduler.Initialize then
        return AIT.Scheduler.Initialize()
    end
    return true
end

--- Carga Feature Flags
function Boot.LoadFeatureFlags()
    -- Delegado a core/featureflags.lua
    if AIT.Features and AIT.Features.Initialize then
        return AIT.Features.Initialize()
    end
    return true
end

--- Inicializa el Rule Engine
function Boot.InitializeRuleEngine()
    -- Delegado a core/rules.lua
    if AIT.Rules and AIT.Rules.Initialize then
        return AIT.Rules.Initialize()
    end
    return true
end

--- Carga los bridges
function Boot.LoadBridges()
    -- QBCore
    if GetResourceState('qb-core') == 'started' then
        AIT.QBCore = exports['qb-core']:GetCoreObject()
        AIT.Log.info('BRIDGE', 'QBCore bridge loaded')
    else
        AIT.Log.warn('BRIDGE', 'QBCore not found')
    end

    -- ox_lib
    if GetResourceState('ox_lib') == 'started' then
        AIT.OxLib = exports.ox_lib
        AIT.Log.info('BRIDGE', 'ox_lib bridge loaded')
    end

    -- Inventory
    if GetResourceState('ox_inventory') == 'started' then
        AIT.Inventory = exports.ox_inventory
        AIT.InventoryType = 'ox'
        AIT.Log.info('BRIDGE', 'ox_inventory bridge loaded')
    elseif GetResourceState('qb-inventory') == 'started' then
        AIT.Inventory = exports['qb-inventory']
        AIT.InventoryType = 'qb'
        AIT.Log.info('BRIDGE', 'qb-inventory bridge loaded')
    end

    return true
end

--- Carga los engines
function Boot.LoadEngines()
    AIT.Engines = AIT.Engines or {}

    local engines = {
        'economy', 'inventory', 'missions', 'events', 'factions',
        'vehicles', 'housing', 'combat', 'ai', 'justice'
    }

    for _, engineName in ipairs(engines) do
        local engine = AIT.Engines[engineName]
        if engine and engine.Initialize then
            local success, err = pcall(engine.Initialize)
            if success then
                AIT.Log.info('ENGINES', 'Engine initialized: ' .. engineName)
            else
                AIT.Log.error('ENGINES', 'Engine failed: ' .. engineName, { error = tostring(err) })
            end
        end
    end

    return true
end

--- Carga los módulos
function Boot.LoadModules()
    AIT.Modules = AIT.Modules or {}

    local modules = AIT.Config.main and AIT.Config.main.modules or {}

    for _, moduleName in ipairs(modules) do
        -- Verificar feature flag
        local featureKey = 'module.' .. moduleName
        if not AIT.Features or AIT.Features.isEnabled(featureKey) then
            local moduleObj = AIT.Modules[moduleName]
            if moduleObj and moduleObj.Initialize then
                local success, err = pcall(moduleObj.Initialize)
                if success then
                    AIT.Log.info('MODULES', 'Module initialized: ' .. moduleName)
                else
                    AIT.Log.error('MODULES', 'Module failed: ' .. moduleName, { error = tostring(err) })
                end
            end
        else
            AIT.Log.debug('MODULES', 'Module disabled by feature flag: ' .. moduleName)
        end
    end

    return true
end

--- Registra exports
function Boot.RegisterExports()
    -- Core
    exports('GetVersion', function() return AIT.Version end)
    exports('IsReady', function() return AIT.Ready end)
    exports('GetWorldState', function()
        return AIT.State and AIT.State.data and AIT.State.data.world or {}
    end)

    -- Los demás exports se registran en core/exports.lua
    AIT.Log.info('EXPORTS', 'Core exports registered')
    return true
end

--- Inicia health check
function Boot.StartHealthCheck()
    CreateThread(function()
        while true do
            Wait(30000)

            local health = {
                uptime = os.time() - AIT.StartTime,
                memory = collectgarbage('count'),
                players = #GetPlayers(),
                cacheSize = 0,
                eventQueueSize = AIT.EventBus and #AIT.EventBus.pending or 0,
            }

            -- Contar entradas de caché
            if AIT.Cache and AIT.Cache.data then
                for _ in pairs(AIT.Cache.data) do
                    health.cacheSize = health.cacheSize + 1
                end
            end

            if AIT.State then
                AIT.State.set('server.health', health)
            end

            -- Alertas
            if health.memory > 500000 then -- 500MB
                AIT.Log.warn('HEALTH', 'High memory usage', { kb = health.memory })
            end

            if health.eventQueueSize > 100 then
                AIT.Log.warn('HEALTH', 'Event queue backlog', { size = health.eventQueueSize })
            end
        end
    end)

    return true
end

--- Marca el sistema como ready
function Boot.MarkReady()
    AIT.Ready = true
    AIT.ReadyTime = os.time()

    local bootTime = AIT.ReadyTime - AIT.StartTime
    AIT.Log.info('CORE', ('ait-qb ready in %d seconds'):format(bootTime))

    if AIT.EventBus then
        AIT.EventBus.emit('core.boot.completed', {
            version = AIT.Version,
            bootTime = bootTime,
        })
    end

    -- Trigger event para otros recursos
    TriggerEvent('ait:ready')

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EJECUTAR SECUENCIA DE ARRANQUE
-- ═══════════════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    print('')
    print('^2═══════════════════════════════════════════════════════════════^7')
    print('^2  ait-qb V' .. AIT.Version .. ' - Starting...^7')
    print('^2═══════════════════════════════════════════════════════════════^7')
    print('')

    for _, phase in ipairs(BootPhases) do
        local startTime = GetGameTimer()

        local fn = Boot[phase.fn]
        if fn then
            local success, result = pcall(fn)

            local duration = GetGameTimer() - startTime

            if not success then
                print(('^1[BOOT] FAILED: %s - %s^7'):format(phase.name, tostring(result)))
                if phase.critical then
                    print('^1[BOOT] Critical phase failed. Aborting.^7')
                    return
                end
            elseif result == false then
                print(('^1[BOOT] FAILED: %s^7'):format(phase.name))
                if phase.critical then
                    print('^1[BOOT] Critical phase failed. Aborting.^7')
                    return
                end
            else
                print(('^2[BOOT] OK: %s (%dms)^7'):format(phase.name, duration))
            end
        else
            print(('^3[BOOT] SKIP: %s (not implemented)^7'):format(phase.name))
        end
    end

    print('')
    print('^2═══════════════════════════════════════════════════════════════^7')
    print('^2  ait-qb V' .. AIT.Version .. ' - READY^7')
    print('^2═══════════════════════════════════════════════════════════════^7')
    print('')

    -- Iniciar scheduler
    if AIT.Scheduler and AIT.Scheduler.start then
        AIT.Scheduler.start()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS GLOBALES
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Retornar el objeto AIT para require()
return AIT
