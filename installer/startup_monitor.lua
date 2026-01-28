--[[
    AIT-QB: Sistema de Monitoreo de Arranque
    IMPORTANTE: Este script NO carga módulos, solo MONITOREA la carga
    Los scripts se cargan automáticamente por FiveM desde fxmanifest.lua
    Servidor Español
]]

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local VERSION = "1.0.0"
local START_TIME = os.time()

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES DE LOGGING
-- ═══════════════════════════════════════════════════════════════

local function Log(message, level)
    level = level or "INFO"
    local colors = {
        INFO = "^5",
        SUCCESS = "^2",
        WARNING = "^3",
        ERROR = "^1",
        HEADER = "^6",
    }

    print(string.format("%s[AIT-QB] [%s] %s^7", colors[level] or "^7", level, message))
end

local function PrintSeparator()
    print("^5═══════════════════════════════════════════════^7")
end

-- ═══════════════════════════════════════════════════════════════
-- VERIFICACIÓN DE ARCHIVOS CRÍTICOS
-- ═══════════════════════════════════════════════════════════════

local CriticalFiles = {
    -- Core
    "core/bootstrap.lua",
    "core/di.lua",
    "core/eventbus.lua",

    -- Config
    "shared/config/main.lua",
    "shared/config/economy.lua",

    -- Database
    "server/db/connection.lua",

    -- Engines básicos
    "server/engines/economy/init.lua",
    "server/engines/inventory/init.lua",

    -- Cliente
    "client/main.lua",
    "server/main.lua",
}

local function VerifyFiles()
    Log("Verificando archivos críticos...", "INFO")
    local missing = {}
    local found = 0

    for _, file in ipairs(CriticalFiles) do
        local content = LoadResourceFile(GetCurrentResourceName(), file)
        if content then
            found = found + 1
        else
            table.insert(missing, file)
        end
    end

    if #missing == 0 then
        Log(string.format("✓ Todos los archivos críticos encontrados (%d/%d)", found, #CriticalFiles), "SUCCESS")
        return true
    else
        Log(string.format("✗ Archivos faltantes: %d de %d", #missing, #CriticalFiles), "ERROR")
        for _, file in ipairs(missing) do
            Log(string.format("  - %s", file), "ERROR")
        end
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CARGA DE CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local function LoadConfig()
    local configFile = LoadResourceFile(GetCurrentResourceName(), "installer/startup_config.json")
    if not configFile then
        Log("⚠ No se encontró startup_config.json, usando defaults", "WARNING")
        return {
            mode = "normal",
            engines = {},
            jobs = {},
            modules = {}
        }
    end

    local success, config = pcall(json.decode, configFile)
    if not success then
        Log("✗ Error al parsear startup_config.json", "ERROR")
        return nil
    end

    Log("✓ Configuración cargada correctamente", "SUCCESS")
    return config
end

-- ═══════════════════════════════════════════════════════════════
-- REPORTE DE INICIO
-- ═══════════════════════════════════════════════════════════════

local function GenerateStartupReport()
    local config = LoadConfig()
    if not config then return end

    PrintSeparator()
    Log("REPORTE DE ARRANQUE", "HEADER")
    PrintSeparator()

    Log(string.format("Versión: %s", VERSION), "INFO")
    Log(string.format("Modo: %s", config.mode or "normal"), "INFO")

    -- Contar engines activos
    local engineCount = 0
    if config.engines then
        for engine, enabled in pairs(config.engines) do
            if enabled then engineCount = engineCount + 1 end
        end
    end
    Log(string.format("Engines activos: %d", engineCount), "INFO")

    -- Contar jobs activos
    local jobCount = 0
    if config.jobs then
        for category, jobs in pairs(config.jobs) do
            if type(jobs) == "table" then
                for job, enabled in pairs(jobs) do
                    if enabled then jobCount = jobCount + 1 end
                end
            end
        end
    end
    Log(string.format("Jobs activos: %d", jobCount), "INFO")

    PrintSeparator()
end

-- ═══════════════════════════════════════════════════════════════
-- MONITOREO DE RECURSOS
-- ═══════════════════════════════════════════════════════════════

local function MonitorResources()
    -- Esperar a que el servidor esté completamente cargado
    CreateThread(function()
        Wait(5000) -- Esperar 5 segundos

        local memUsage = collectgarbage("count")
        Log(string.format("Uso de memoria: %.2f MB", memUsage / 1024), "INFO")

        local endTime = os.time()
        local loadTime = endTime - START_TIME
        Log(string.format("Tiempo de carga total: %d segundos", loadTime), "INFO")

        PrintSeparator()
        Log("✓ SISTEMA INICIADO CORRECTAMENTE", "SUCCESS")
        PrintSeparator()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE UTILIDAD
-- ═══════════════════════════════════════════════════════════════

RegisterCommand("aitqb:status", function(source)
    if source == 0 then -- Solo consola
        PrintSeparator()
        Log("ESTADO DEL SISTEMA", "HEADER")
        PrintSeparator()

        Log(string.format("Versión: %s", VERSION), "INFO")

        local uptime = os.time() - START_TIME
        local hours = math.floor(uptime / 3600)
        local minutes = math.floor((uptime % 3600) / 60)
        local seconds = uptime % 60

        Log(string.format("Uptime: %02d:%02d:%02d", hours, minutes, seconds), "INFO")

        local memUsage = collectgarbage("count")
        Log(string.format("Memoria: %.2f MB", memUsage / 1024), "INFO")

        -- Verificar archivos
        VerifyFiles()

        PrintSeparator()
    end
end, true)

RegisterCommand("aitqb:config", function(source)
    if source == 0 then -- Solo consola
        local config = LoadConfig()
        if config then
            PrintSeparator()
            Log("CONFIGURACIÓN ACTUAL", "HEADER")
            PrintSeparator()

            Log(string.format("Modo: %s", config.mode or "normal"), "INFO")

            if config.server then
                Log(string.format("Servidor: %s", config.server.name or "AIT-QB"), "INFO")
                Log(string.format("Max jugadores: %d", config.server.maxPlayers or 128), "INFO")
            end

            if config.engines then
                Log("Engines:", "INFO")
                for engine, enabled in pairs(config.engines) do
                    local status = enabled and "✓" or "✗"
                    Log(string.format("  %s %s", status, engine), enabled and "SUCCESS" or "WARNING")
                end
            end

            PrintSeparator()
        end
    end
end, true)

RegisterCommand("aitqb:verify", function(source)
    if source == 0 then -- Solo consola
        PrintSeparator()
        Log("VERIFICACIÓN DE ARCHIVOS", "HEADER")
        PrintSeparator()

        local allOk = VerifyFiles()

        PrintSeparator()
        if allOk then
            Log("✓ Verificación completada - Sin errores", "SUCCESS")
        else
            Log("✗ Verificación completada - Errores encontrados", "ERROR")
            Log("Reinstala los archivos faltantes", "WARNING")
        end
        PrintSeparator()
    end
end, true)

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000) -- Esperar 1 segundo para que otros scripts se carguen

    PrintSeparator()
    Log("AIT-QB - Advanced Intelligence Technology", "HEADER")
    Log(string.format("Sistema de Monitoreo v%s", VERSION), "HEADER")
    PrintSeparator()

    -- Verificar archivos críticos
    local filesOk = VerifyFiles()

    if not filesOk then
        Log("", "ERROR")
        Log("⚠ ADVERTENCIA: Archivos críticos faltantes", "ERROR")
        Log("El servidor puede no funcionar correctamente", "ERROR")
        Log("Ejecuta: INSTALL.bat -> Opción 4 para verificar", "WARNING")
        Log("", "ERROR")
    end

    -- Generar reporte
    GenerateStartupReport()

    -- Monitorear recursos
    MonitorResources()

    Log("", "INFO")
    Log("Comandos disponibles:", "INFO")
    Log("  aitqb:status  - Ver estado del sistema", "INFO")
    Log("  aitqb:config  - Ver configuración actual", "INFO")
    Log("  aitqb:verify  - Verificar archivos", "INFO")
    PrintSeparator()
end)

-- ═══════════════════════════════════════════════════════════════
-- HEARTBEAT (OPCIONAL)
-- ═══════════════════════════════════════════════════════════════

-- Heartbeat cada 5 minutos para monitoreo
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutos

        -- Garbage collection
        collectgarbage("collect")

        -- Log de heartbeat (opcional, puede ser muy verbose)
        -- Log("Heartbeat - Sistema funcionando", "INFO")
    end
end)
