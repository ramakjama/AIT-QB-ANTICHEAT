--[[
    AIT-QB: Sistema de Arranque Seguro
    Previene crashes cargando módulos en orden
    Servidor Español
]]

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local STARTUP_CONFIG_FILE = "installer/startup_config.json"
local SAFE_MODE = false -- Cambiar a true si hay problemas

-- Orden de carga (CRÍTICO - NO CAMBIAR)
local LoadOrder = {
    phase1 = {
        name = "FASE 1: Core Engine",
        critical = true,
        scripts = {
            "core/bootstrap.lua",
            "core/di.lua",
            "core/eventbus.lua",
            "core/state.lua",
            "core/cache.lua",
        }
    },
    phase2 = {
        name = "FASE 2: Configuración",
        critical = true,
        scripts = {
            "shared/config/main.lua",
            "shared/config/economy.lua",
            "shared/config/security.lua",
        }
    },
    phase3 = {
        name = "FASE 3: Base de Datos",
        critical = true,
        scripts = {
            "server/db/connection.lua",
            "server/db/repositories/base.lua",
        }
    },
    phase4 = {
        name = "FASE 4: Engines Básicos",
        critical = true,
        scripts = {
            "server/engines/economy/init.lua",
            "server/engines/inventory/init.lua",
        }
    },
    phase5 = {
        name = "FASE 5: Cliente Básico",
        critical = true,
        scripts = {
            "client/main.lua",
            "client/modules/hud/init.lua",
        }
    },
    phase6 = {
        name = "FASE 6: Engines Opcionales",
        critical = false,
        scripts = {
            "server/engines/factions/init.lua",
            "server/engines/vehicles/init.lua",
            "server/engines/housing/init.lua",
        }
    },
    phase7 = {
        name = "FASE 7: Jobs",
        critical = false,
        scripts = {
            "modules/jobs/police/init.lua",
            "modules/jobs/ambulance/init.lua",
        }
    },
    phase8 = {
        name = "FASE 8: Módulos Cliente",
        critical = false,
        scripts = {
            "client/modules/phone/init.lua",
            "client/modules/inventory/init.lua",
        }
    },
}

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE CARGA SEGURA
-- ═══════════════════════════════════════════════════════════════

local LoadedScripts = {}
local FailedScripts = {}
local StartTime = os.clock()

local function LogLoad(message, level)
    level = level or "INFO"
    local colors = {
        INFO = "^5",
        SUCCESS = "^2",
        WARNING = "^3",
        ERROR = "^1",
    }

    print(string.format("%s[AIT-QB] [%s] %s^7", colors[level] or "^7", level, message))
end

local function SafeLoad(scriptPath, phaseName, isCritical)
    LogLoad(string.format("Cargando: %s", scriptPath), "INFO")

    local success, err = pcall(function()
        -- Verificar que el archivo existe
        local file = LoadResourceFile(GetCurrentResourceName(), scriptPath)
        if not file then
            error("Archivo no encontrado: " .. scriptPath)
        end

        -- Esperar un poco entre cargas para evitar race conditions
        Wait(50)
    end)

    if success then
        table.insert(LoadedScripts, scriptPath)
        LogLoad(string.format("✓ Cargado: %s", scriptPath), "SUCCESS")
        return true
    else
        table.insert(FailedScripts, { script = scriptPath, error = err, phase = phaseName, critical = isCritical })
        LogLoad(string.format("✗ Error en: %s", scriptPath), "ERROR")
        LogLoad(string.format("   Detalle: %s", tostring(err)), "ERROR")

        if isCritical then
            LogLoad("Este script es CRÍTICO. El servidor podría no funcionar correctamente.", "ERROR")
        end

        return false
    end
end

local function LoadPhase(phase, phaseData)
    LogLoad("═══════════════════════════════════════════════", "INFO")
    LogLoad(phaseData.name, "INFO")
    LogLoad("═══════════════════════════════════════════════", "INFO")

    local allSuccess = true

    for _, script in ipairs(phaseData.scripts) do
        if not SafeLoad(script, phaseData.name, phaseData.critical) then
            allSuccess = false

            if phaseData.critical then
                LogLoad("ADVERTENCIA: Fallo en script crítico. Deteniendo carga.", "ERROR")
                return false
            end
        end
    end

    if allSuccess then
        LogLoad(string.format("✓ %s completada", phaseData.name), "SUCCESS")
    else
        LogLoad(string.format("⚠ %s completada con errores", phaseData.name), "WARNING")
    end

    return allSuccess
end

-- ═══════════════════════════════════════════════════════════════
-- MODO SEGURO
-- ═══════════════════════════════════════════════════════════════

local function LoadSafeMode()
    LogLoad("═══════════════════════════════════════════════", "WARNING")
    LogLoad("MODO SEGURO ACTIVADO", "WARNING")
    LogLoad("Solo se cargarán los componentes esenciales", "WARNING")
    LogLoad("═══════════════════════════════════════════════", "WARNING")

    -- Solo cargar fases críticas
    local phasesToLoad = { "phase1", "phase2", "phase3", "phase4", "phase5" }

    for _, phaseKey in ipairs(phasesToLoad) do
        local phase = LoadOrder[phaseKey]
        if not LoadPhase(phaseKey, phase) then
            LogLoad("Error crítico en modo seguro. Abortando.", "ERROR")
            return false
        end
        Wait(500) -- Más tiempo entre fases en modo seguro
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════
-- CARGA NORMAL
-- ═══════════════════════════════════════════════════════════════

local function LoadNormal()
    LogLoad("═══════════════════════════════════════════════", "INFO")
    LogLoad("Iniciando carga normal de AIT-QB", "INFO")
    LogLoad("═══════════════════════════════════════════════", "INFO")

    local allSuccess = true

    -- Cargar todas las fases en orden
    for phaseNum = 1, 8 do
        local phaseKey = "phase" .. phaseNum
        local phase = LoadOrder[phaseKey]

        if phase then
            if not LoadPhase(phaseKey, phase) then
                if phase.critical then
                    LogLoad("Error en fase crítica. Cambiando a modo seguro...", "ERROR")
                    return LoadSafeMode()
                else
                    allSuccess = false
                end
            end

            -- Esperar entre fases para evitar sobrecarga
            Wait(200)
        end
    end

    return allSuccess
end

-- ═══════════════════════════════════════════════════════════════
-- REPORTE FINAL
-- ═══════════════════════════════════════════════════════════════

local function GenerateReport()
    local endTime = os.clock()
    local loadTime = endTime - StartTime

    LogLoad("═══════════════════════════════════════════════", "INFO")
    LogLoad("REPORTE DE CARGA", "INFO")
    LogLoad("═══════════════════════════════════════════════", "INFO")

    LogLoad(string.format("Tiempo de carga: %.2f segundos", loadTime), "INFO")
    LogLoad(string.format("Scripts cargados: %d", #LoadedScripts), "SUCCESS")
    LogLoad(string.format("Scripts fallidos: %d", #FailedScripts), #FailedScripts > 0 and "WARNING" or "SUCCESS")

    if #FailedScripts > 0 then
        LogLoad("", "INFO")
        LogLoad("SCRIPTS FALLIDOS:", "ERROR")
        for i, fail in ipairs(FailedScripts) do
            LogLoad(string.format("%d. %s (Fase: %s)", i, fail.script, fail.phase), "ERROR")
            if fail.critical then
                LogLoad("   ¡CRÍTICO!", "ERROR")
            end
        end

        LogLoad("", "INFO")
        LogLoad("RECOMENDACIONES:", "WARNING")
        LogLoad("1. Verifica que todos los archivos existen", "WARNING")
        LogLoad("2. Revisa los errores en la consola", "WARNING")
        LogLoad("3. Considera usar el modo seguro si el problema persiste", "WARNING")
        LogLoad("4. Ejecuta el instalador: installer/install.lua", "WARNING")
    else
        LogLoad("", "INFO")
        LogLoad("✓ TODOS LOS SCRIPTS CARGADOS CORRECTAMENTE", "SUCCESS")
        LogLoad("", "INFO")
        LogLoad("Servidor AIT-QB iniciado exitosamente", "SUCCESS")
    end

    LogLoad("═══════════════════════════════════════════════", "INFO")
end

-- ═══════════════════════════════════════════════════════════════
-- INICIO
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    LogLoad("", "INFO")
    LogLoad("═══════════════════════════════════════════════", "INFO")
    LogLoad("AIT-QB - Advanced Intelligence Technology", "INFO")
    LogLoad("Sistema de Arranque Seguro v1.0.0", "INFO")
    LogLoad("═══════════════════════════════════════════════", "INFO")
    LogLoad("", "INFO")

    -- Esperar un segundo antes de empezar
    Wait(1000)

    local success
    if SAFE_MODE then
        success = LoadSafeMode()
    else
        success = LoadNormal()
    end

    -- Generar reporte
    Wait(500)
    GenerateReport()

    if not success then
        LogLoad("", "ERROR")
        LogLoad("ADVERTENCIA: El servidor inició con errores", "ERROR")
        LogLoad("Revisa el reporte anterior para más detalles", "ERROR")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE UTILIDAD
-- ═══════════════════════════════════════════════════════════════

RegisterCommand("aitqb:report", function()
    GenerateReport()
end, true)

RegisterCommand("aitqb:reload", function()
    LogLoad("Recargando AIT-QB...", "WARNING")
    ExecuteCommand("refresh")
    ExecuteCommand("ensure ait-qb")
end, true)

RegisterCommand("aitqb:safemode", function()
    LogLoad("Activando modo seguro...", "WARNING")
    SAFE_MODE = true
    ExecuteCommand("aitqb:reload")
end, true)
