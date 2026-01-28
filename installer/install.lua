--[[
    AIT-QB: Instalador Interactivo
    Sistema de instalación y configuración inicial
    Servidor Español
]]

local VERSION = "1.0.0"
local CONFIG_FILE = "installer/config.json"

-- Colores para consola
local Colors = {
    Reset = "\27[0m",
    Red = "\27[31m",
    Green = "\27[32m",
    Yellow = "\27[33m",
    Blue = "\27[34m",
    Magenta = "\27[35m",
    Cyan = "\27[36m",
    White = "\27[37m",
    Bold = "\27[1m",
}

-- Estado de la instalación
local InstallState = {
    firstRun = true,
    databaseInstalled = false,
    coreEnabled = false,
    enginesEnabled = {},
    jobsEnabled = {},
    modulesEnabled = {},
}

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE UTILIDAD
-- ═══════════════════════════════════════════════════════════════

local function Print(text, color)
    color = color or Colors.White
    print(color .. text .. Colors.Reset)
end

local function PrintHeader(text)
    print("\n" .. Colors.Bold .. Colors.Cyan .. "═══════════════════════════════════════════════════════════" .. Colors.Reset)
    print(Colors.Bold .. Colors.Cyan .. "  " .. text .. Colors.Reset)
    print(Colors.Bold .. Colors.Cyan .. "═══════════════════════════════════════════════════════════" .. Colors.Reset .. "\n")
end

local function PrintSuccess(text)
    Print("✓ " .. text, Colors.Green)
end

local function PrintError(text)
    Print("✗ " .. text, Colors.Red)
end

local function PrintWarning(text)
    Print("⚠ " .. text, Colors.Yellow)
end

local function PrintInfo(text)
    Print("ℹ " .. text, Colors.Blue)
end

local function AskYesNo(question, default)
    local defaultText = default and "(S/n)" or "(s/N)"
    Print(question .. " " .. defaultText .. ": ", Colors.Yellow)
    local answer = io.read()

    if answer == "" then
        return default
    end

    return answer:lower() == "s" or answer:lower() == "si" or answer:lower() == "y" or answer:lower() == "yes"
end

local function AskNumber(question, min, max, default)
    while true do
        Print(question .. " [" .. min .. "-" .. max .. "] (default: " .. default .. "): ", Colors.Yellow)
        local answer = io.read()

        if answer == "" then
            return default
        end

        local num = tonumber(answer)
        if num and num >= min and num <= max then
            return num
        end

        PrintError("Por favor ingresa un número entre " .. min .. " y " .. max)
    end
end

local function AskText(question, default)
    Print(question .. (default and " (default: " .. default .. ")" or "") .. ": ", Colors.Yellow)
    local answer = io.read()

    if answer == "" and default then
        return default
    end

    return answer
end

-- ═══════════════════════════════════════════════════════════════
-- MENÚ PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local function ShowMainMenu()
    PrintHeader("AIT-QB INSTALADOR v" .. VERSION)

    Print("Bienvenido al instalador interactivo de AIT-QB", Colors.Cyan)
    Print("Este asistente te ayudará a configurar tu servidor paso a paso.\n", Colors.White)

    Print("1. Instalación Completa (Recomendado)", Colors.Green)
    Print("2. Instalación Personalizada", Colors.Yellow)
    Print("3. Solo Base de Datos", Colors.Blue)
    Print("4. Verificar Instalación", Colors.Magenta)
    Print("5. Desinstalar", Colors.Red)
    Print("0. Salir\n", Colors.White)

    local choice = AskNumber("Selecciona una opción", 0, 5, 1)
    return choice
end

-- ═══════════════════════════════════════════════════════════════
-- INSTALACIÓN DE BASE DE DATOS
-- ═══════════════════════════════════════════════════════════════

local function InstallDatabase()
    PrintHeader("INSTALACIÓN DE BASE DE DATOS")

    PrintInfo("Este paso instalará todas las tablas necesarias en la base de datos.")
    PrintWarning("Asegúrate de haber configurado oxmysql correctamente.")

    if not AskYesNo("¿Deseas continuar con la instalación de la base de datos?", true) then
        return false
    end

    Print("\nInstalando tablas...", Colors.Cyan)

    -- Ejecutar install.sql
    local success, error = pcall(function()
        MySQL.Async.execute([[
            -- Ejecutar el archivo install.sql
            SOURCE install.sql
        ]])
    end)

    if success then
        PrintSuccess("Base de datos instalada correctamente")
        InstallState.databaseInstalled = true
        return true
    else
        PrintError("Error al instalar la base de datos")
        PrintError(tostring(error))
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SELECCIÓN DE ENGINES
-- ═══════════════════════════════════════════════════════════════

local AvailableEngines = {
    { id = "economy", name = "Economy", description = "Sistema de economía y transacciones", required = true },
    { id = "inventory", name = "Inventory", description = "Sistema de inventario", required = true },
    { id = "factions", name = "Factions", description = "Sistema de facciones y trabajos", required = false },
    { id = "missions", name = "Missions", description = "Sistema de misiones dinámicas", required = false },
    { id = "events", name = "Events", description = "Eventos del servidor", required = false },
    { id = "vehicles", name = "Vehicles", description = "Sistema de vehículos", required = false },
    { id = "housing", name = "Housing", description = "Sistema de propiedades", required = false },
    { id = "combat", name = "Combat", description = "Sistema de combate", required = false },
    { id = "ai", name = "AI", description = "NPCs inteligentes", required = false },
    { id = "justice", name = "Justice", description = "Sistema de justicia", required = false },
}

local function SelectEngines()
    PrintHeader("SELECCIÓN DE ENGINES")

    PrintInfo("Los engines son los sistemas principales del servidor.")
    PrintInfo("Los marcados como REQUERIDOS son necesarios para el funcionamiento básico.\n")

    for i, engine in ipairs(AvailableEngines) do
        local status = engine.required and " [REQUERIDO]" or ""
        Print(string.format("%d. %s%s", i, engine.name, status), Colors.Cyan)
        Print("   " .. engine.description, Colors.White)

        if engine.required then
            InstallState.enginesEnabled[engine.id] = true
            PrintSuccess("   Activado automáticamente\n")
        else
            local enable = AskYesNo("   ¿Activar este engine?", true)
            InstallState.enginesEnabled[engine.id] = enable

            if enable then
                PrintSuccess("   Activado\n")
            else
                PrintWarning("   Desactivado\n")
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SELECCIÓN DE JOBS
-- ═══════════════════════════════════════════════════════════════

local AvailableJobs = {
    -- Emergencias (recomendados)
    { id = "police", name = "Policía", category = "emergency", recommended = true },
    { id = "ambulance", name = "EMS/Ambulancia", category = "emergency", recommended = true },

    -- Legales
    { id = "mechanic", name = "Mecánico", category = "legal", recommended = true },
    { id = "taxi", name = "Taxi", category = "legal", recommended = false },
    { id = "trucker", name = "Camionero", category = "legal", recommended = false },
    { id = "garbage", name = "Basurero", category = "legal", recommended = false },
    { id = "fishing", name = "Pescador", category = "legal", recommended = false },
    { id = "mining", name = "Minero", category = "legal", recommended = false },
    { id = "lumberjack", name = "Leñador", category = "legal", recommended = false },
    { id = "hunting", name = "Cazador", category = "legal", recommended = false },
    { id = "delivery", name = "Repartidor", category = "legal", recommended = false },

    -- Ilegales
    { id = "drugs", name = "Drogas", category = "illegal", recommended = false },
    { id = "robbery", name = "Robos", category = "illegal", recommended = false },
    { id = "chopshop", name = "Desguace", category = "illegal", recommended = false },
    { id = "weapons", name = "Armas", category = "illegal", recommended = false },
    { id = "laundering", name = "Lavado de Dinero", category = "illegal", recommended = false },
    { id = "gangs", name = "Bandas", category = "illegal", recommended = false },
}

local function SelectJobs()
    PrintHeader("SELECCIÓN DE JOBS")

    PrintInfo("Selecciona qué trabajos quieres activar en tu servidor.")
    PrintInfo("Puedes activarlos/desactivarlos después editando la configuración.\n")

    -- Preguntar si quiere todos
    if AskYesNo("¿Deseas activar TODOS los jobs? (No recomendado para primera instalación)", false) then
        for _, job in ipairs(AvailableJobs) do
            InstallState.jobsEnabled[job.id] = true
        end
        PrintSuccess("Todos los jobs activados")
        return
    end

    -- Preguntar si quiere solo recomendados
    if AskYesNo("¿Deseas activar solo los jobs RECOMENDADOS?", true) then
        for _, job in ipairs(AvailableJobs) do
            InstallState.jobsEnabled[job.id] = job.recommended
        end
        PrintSuccess("Jobs recomendados activados")
        return
    end

    -- Selección manual
    PrintInfo("\nSelección manual de jobs:\n")

    -- Por categoría
    local categories = {
        { id = "emergency", name = "EMERGENCIAS", color = Colors.Red },
        { id = "legal", name = "LEGALES", color = Colors.Green },
        { id = "illegal", name = "ILEGALES", color = Colors.Yellow },
    }

    for _, category in ipairs(categories) do
        Print("\n" .. category.name .. ":", category.color)

        for _, job in ipairs(AvailableJobs) do
            if job.category == category.id then
                local rec = job.recommended and " [RECOMENDADO]" or ""
                local enable = AskYesNo("  " .. job.name .. rec, job.recommended)
                InstallState.jobsEnabled[job.id] = enable
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SELECCIÓN DE MÓDULOS
-- ═══════════════════════════════════════════════════════════════

local AvailableModules = {
    { id = "phone", name = "Teléfono (22 apps)", recommended = true },
    { id = "housing", name = "Sistema de Propiedades", recommended = true },
    { id = "admin", name = "Panel de Admin", recommended = true },
    { id = "scoreboard", name = "Scoreboard (TAB)", recommended = true },
    { id = "inventory_ui", name = "Inventario UI", recommended = true },
    { id = "hud", name = "HUD Personalizado", recommended = true },
    { id = "anticheat", name = "Anticheat", recommended = true },
}

local function SelectModules()
    PrintHeader("SELECCIÓN DE MÓDULOS")

    PrintInfo("Los módulos son funcionalidades adicionales del cliente.\n")

    if AskYesNo("¿Activar TODOS los módulos?", true) then
        for _, module in ipairs(AvailableModules) do
            InstallState.modulesEnabled[module.id] = true
        end
        PrintSuccess("Todos los módulos activados")
        return
    end

    for _, module in ipairs(AvailableModules) do
        local rec = module.recommended and " [RECOMENDADO]" or ""
        local enable = AskYesNo(module.name .. rec, module.recommended)
        InstallState.modulesEnabled[module.id] = enable
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════

local function ConfigureServer()
    PrintHeader("CONFIGURACIÓN DEL SERVIDOR")

    PrintInfo("Configuración básica del servidor:\n")

    local config = {}

    config.serverName = AskText("Nombre del servidor", "AIT-QB Roleplay")
    config.maxPlayers = AskNumber("Máximo de jugadores", 32, 2048, 128)
    config.language = AskText("Idioma (es/en)", "es")

    PrintInfo("\nConfiguración de economía inicial:")
    config.startingCash = AskNumber("Dinero en efectivo inicial", 0, 100000, 5000)
    config.startingBank = AskNumber("Dinero en banco inicial", 0, 100000, 10000)

    PrintInfo("\nPunto de spawn:")
    if not AskYesNo("¿Usar spawn por defecto (Hospital Central)?", true) then
        config.spawnX = tonumber(AskText("Coordenada X", "-269.4"))
        config.spawnY = tonumber(AskText("Coordenada Y", "-955.3"))
        config.spawnZ = tonumber(AskText("Coordenada Z", "31.2"))
        config.spawnHeading = tonumber(AskText("Heading", "205.0"))
    end

    return config
end

-- ═══════════════════════════════════════════════════════════════
-- GENERACIÓN DE ARCHIVOS DE CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local function GenerateConfigFiles(config)
    PrintHeader("GENERANDO ARCHIVOS DE CONFIGURACIÓN")

    -- Generar fxmanifest.lua personalizado
    local fxmanifest = [[
-- ═══════════════════════════════════════════════════════════════
-- AIT-QB - Generado por el instalador
-- ═══════════════════════════════════════════════════════════════

fx_version 'cerulean'
game 'gta5'

name 'ait-qb'
version '1.0.0'

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config/main.lua',
]]

    -- Añadir engines habilitados
    if InstallState.enginesEnabled.economy then
        fxmanifest = fxmanifest .. "    'shared/config/economy.lua',\n"
    end

    -- ... (continuar con el resto)

    fxmanifest = fxmanifest .. [[
}

lua54 'yes'
]]

    -- Escribir archivo
    local file = io.open("fxmanifest_generated.lua", "w")
    if file then
        file:write(fxmanifest)
        file:close()
        PrintSuccess("fxmanifest.lua generado")
    else
        PrintError("No se pudo generar fxmanifest.lua")
    end

    -- Generar config/main.lua
    local mainConfig = string.format([[
Config = {}

Config.ServerName = "%s"
Config.MaxPlayers = %d
Config.DefaultLanguage = "%s"

Config.StartingMoney = {
    cash = %d,
    bank = %d,
}
]], config.serverName, config.maxPlayers, config.language, config.startingCash, config.startingBank)

    file = io.open("shared/config/main_generated.lua", "w")
    if file then
        file:write(mainConfig)
        file:close()
        PrintSuccess("config/main.lua generado")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INSTALACIÓN COMPLETA
-- ═══════════════════════════════════════════════════════════════

local function FullInstall()
    PrintHeader("INSTALACIÓN COMPLETA")

    PrintInfo("Esta opción instalará:")
    PrintInfo("✓ Base de datos completa")
    PrintInfo("✓ Todos los engines recomendados")
    PrintInfo("✓ Jobs de emergencia (Police, EMS, Mechanic)")
    PrintInfo("✓ Todos los módulos del cliente")
    PrintInfo("✓ Configuración por defecto\n")

    if not AskYesNo("¿Deseas continuar?", true) then
        return
    end

    -- 1. Base de datos
    Print("\n[1/5] Instalando base de datos...", Colors.Cyan)
    if not InstallDatabase() then
        PrintError("Instalación cancelada")
        return
    end

    -- 2. Activar engines recomendados
    Print("\n[2/5] Configurando engines...", Colors.Cyan)
    for _, engine in ipairs(AvailableEngines) do
        InstallState.enginesEnabled[engine.id] = engine.required or engine.id == "vehicles" or engine.id == "housing"
    end
    PrintSuccess("Engines configurados")

    -- 3. Activar jobs recomendados
    Print("\n[3/5] Configurando jobs...", Colors.Cyan)
    for _, job in ipairs(AvailableJobs) do
        InstallState.jobsEnabled[job.id] = job.recommended
    end
    PrintSuccess("Jobs configurados")

    -- 4. Activar todos los módulos
    Print("\n[4/5] Configurando módulos...", Colors.Cyan)
    for _, module in ipairs(AvailableModules) do
        InstallState.modulesEnabled[module.id] = true
    end
    PrintSuccess("Módulos configurados")

    -- 5. Generar configuración
    Print("\n[5/5] Generando configuración...", Colors.Cyan)
    local config = {
        serverName = "AIT-QB Roleplay",
        maxPlayers = 128,
        language = "es",
        startingCash = 5000,
        startingBank = 10000,
    }
    GenerateConfigFiles(config)

    PrintHeader("¡INSTALACIÓN COMPLETADA!")
    PrintSuccess("Tu servidor AIT-QB está listo para usar")
    PrintInfo("\nPróximos pasos:")
    PrintInfo("1. Reinicia tu servidor FiveM")
    PrintInfo("2. Verifica que no haya errores en la consola")
    PrintInfo("3. ¡Disfruta de tu servidor!\n")
end

-- ═══════════════════════════════════════════════════════════════
-- INSTALACIÓN PERSONALIZADA
-- ═══════════════════════════════════════════════════════════════

local function CustomInstall()
    PrintHeader("INSTALACIÓN PERSONALIZADA")

    -- 1. Base de datos
    if AskYesNo("¿Instalar base de datos?", true) then
        InstallDatabase()
    end

    -- 2. Engines
    SelectEngines()

    -- 3. Jobs
    SelectJobs()

    -- 4. Módulos
    SelectModules()

    -- 5. Configuración
    local config = ConfigureServer()

    -- 6. Generar archivos
    GenerateConfigFiles(config)

    PrintHeader("¡INSTALACIÓN PERSONALIZADA COMPLETADA!")
    PrintSuccess("Configuración guardada")
end

-- ═══════════════════════════════════════════════════════════════
-- VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════

local function VerifyInstallation()
    PrintHeader("VERIFICACIÓN DE INSTALACIÓN")

    PrintInfo("Verificando componentes...\n")

    -- Verificar archivos críticos
    local criticalFiles = {
        "fxmanifest.lua",
        "server/main.lua",
        "client/main.lua",
        "install.sql",
    }

    local allGood = true

    for _, file in ipairs(criticalFiles) do
        local f = io.open(file, "r")
        if f then
            f:close()
            PrintSuccess(file .. " encontrado")
        else
            PrintError(file .. " NO ENCONTRADO")
            allGood = false
        end
    end

    if allGood then
        PrintHeader("✓ VERIFICACIÓN EXITOSA")
    else
        PrintHeader("✗ ERRORES ENCONTRADOS")
        PrintWarning("Reinstala los componentes faltantes")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- BUCLE PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local function Main()
    while true do
        local choice = ShowMainMenu()

        if choice == 0 then
            Print("\n¡Hasta luego!", Colors.Green)
            break
        elseif choice == 1 then
            FullInstall()
        elseif choice == 2 then
            CustomInstall()
        elseif choice == 3 then
            InstallDatabase()
        elseif choice == 4 then
            VerifyInstallation()
        elseif choice == 5 then
            PrintWarning("Funcionalidad de desinstalación no implementada")
        end

        Print("\nPresiona ENTER para continuar...", Colors.White)
        io.read()
    end
end

-- Ejecutar
Main()
