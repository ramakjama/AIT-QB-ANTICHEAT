--[[
    AIT-QB: Sistema de Mecánico
    Trabajo legal - Reparación y tuning de vehículos
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Mechanic = {}

local isOnDuty = false
local currentWorkshop = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    workshops = {
        {
            name = 'LSCustoms',
            label = 'Los Santos Customs',
            coords = vector3(-337.0, -136.0, 39.0),
            blip = { sprite = 72, color = 5, scale = 0.8 },
            repairZone = vector3(-339.0, -138.0, 39.0),
            repairRadius = 15.0,
        },
        {
            name = 'BennysMotoworks',
            label = "Benny's Original Motorworks",
            coords = vector3(-205.0, -1310.0, 31.0),
            blip = { sprite = 72, color = 5, scale = 0.8 },
            repairZone = vector3(-211.0, -1320.0, 31.0),
            repairRadius = 20.0,
        },
        {
            name = 'HarmonyMechanic',
            label = 'Harmony Mechanic',
            coords = vector3(1175.0, 2640.0, 38.0),
            blip = { sprite = 72, color = 5, scale = 0.8 },
            repairZone = vector3(1180.0, 2645.0, 38.0),
            repairRadius = 15.0,
        },
    },

    prices = {
        repair = {
            minor = 500,      -- Daños menores
            moderate = 1500,  -- Daños moderados
            major = 3500,     -- Daños graves
            full = 5000,      -- Reparación completa
        },
        wash = 100,
        tuning = {
            engine = { 5000, 10000, 15000, 25000 },     -- Niveles 1-4
            brakes = { 2500, 5000, 7500, 10000 },
            transmission = { 3500, 7000, 12000, 18000 },
            suspension = { 2000, 4000, 6000, 8000 },
            turbo = 15000,
            armor = { 5000, 10000, 20000, 35000, 50000 },
        },
        cosmetic = {
            respray = 1500,
            wheels = 2500,
            neon = 5000,
            window_tint = 3000,
            livery = 2000,
            plate = 1000,
        },
    },

    -- Herramientas necesarias
    tools = {
        'wrench',
        'screwdriver',
        'hammer',
        'drill',
    },

    -- Materiales para reparación
    materials = {
        repair = {
            { item = 'metalscrap', amount = 2 },
            { item = 'plastic', amount = 1 },
        },
        tuning = {
            { item = 'metalscrap', amount = 5 },
            { item = 'steel', amount = 3 },
            { item = 'electronics', amount = 2 },
        },
    },

    -- Sueldo por hora en servicio
    salary = 150,
    salaryInterval = 60000, -- 1 minuto
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mechanic.Init()
    -- Crear blips
    for _, workshop in ipairs(Config.workshops) do
        local blip = AddBlipForCoord(workshop.coords.x, workshop.coords.y, workshop.coords.z)
        SetBlipSprite(blip, workshop.blip.sprite)
        SetBlipColour(blip, workshop.blip.color)
        SetBlipScale(blip, workshop.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(workshop.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Registrar targets para cada taller
    for _, workshop in ipairs(Config.workshops) do
        -- Zona de entrada/servicio
        if lib and lib.zones then
            lib.zones.sphere({
                coords = workshop.coords,
                radius = 3.0,
                onEnter = function()
                    currentWorkshop = workshop
                end,
                onExit = function()
                    if currentWorkshop == workshop then
                        currentWorkshop = nil
                    end
                end,
            })
        end
    end

    print('[AIT-QB] Sistema de mecánico inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE SERVICIO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:mechanic:toggleDuty', function()
    local playerData = exports['ait-qb']:GetPlayerData()

    if not playerData or playerData.job.name ~= 'mechanic' then
        AIT.Notify('No eres mecánico', 'error')
        return
    end

    isOnDuty = not isOnDuty

    if isOnDuty then
        AIT.Notify('Has entrado en servicio como mecánico', 'success')
        TriggerServerEvent('ait:server:mechanic:setDuty', true)
        AIT.Jobs.Mechanic.StartSalaryThread()
    else
        AIT.Notify('Has salido de servicio', 'info')
        TriggerServerEvent('ait:server:mechanic:setDuty', false)
    end
end)

function AIT.Jobs.Mechanic.StartSalaryThread()
    CreateThread(function()
        while isOnDuty do
            Wait(Config.salaryInterval)
            if isOnDuty then
                TriggerServerEvent('ait:server:mechanic:paySalary')
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MENÚ DE TALLER
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:mechanic:openMenu', function()
    if not currentWorkshop then
        AIT.Notify('Debes estar en un taller', 'error')
        return
    end

    local ped = PlayerPedId()
    local vehicle = nil

    -- Buscar vehículo cercano
    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        vehicle = AIT.Vehicles.GetClosestVehicle(10.0)
    end

    if not vehicle then
        AIT.Notify('No hay vehículo cerca para reparar', 'error')
        return
    end

    -- Obtener estado del vehículo
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local dirtLevel = GetVehicleDirtLevel(vehicle)

    local options = {}

    -- Opciones de reparación
    if bodyHealth < 1000 or engineHealth < 1000 then
        local repairPrice = AIT.Jobs.Mechanic.CalculateRepairPrice(vehicle)
        table.insert(options, {
            title = 'Reparar Vehículo',
            description = 'Precio: $' .. repairPrice,
            icon = 'wrench',
            onSelect = function()
                AIT.Jobs.Mechanic.RepairVehicle(vehicle, repairPrice)
            end,
        })
    end

    -- Lavado
    if dirtLevel > 0 then
        table.insert(options, {
            title = 'Lavar Vehículo',
            description = 'Precio: $' .. Config.prices.wash,
            icon = 'soap',
            onSelect = function()
                AIT.Jobs.Mechanic.WashVehicle(vehicle)
            end,
        })
    end

    -- Tuning (solo mecánicos de servicio)
    if isOnDuty then
        table.insert(options, {
            title = 'Tuning de Motor',
            description = 'Mejoras de rendimiento',
            icon = 'gear',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenTuningMenu(vehicle, 'engine')
            end,
        })

        table.insert(options, {
            title = 'Tuning de Frenos',
            icon = 'brake',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenTuningMenu(vehicle, 'brakes')
            end,
        })

        table.insert(options, {
            title = 'Tuning de Transmisión',
            icon = 'gears',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenTuningMenu(vehicle, 'transmission')
            end,
        })

        table.insert(options, {
            title = 'Tuning de Suspensión',
            icon = 'car',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenTuningMenu(vehicle, 'suspension')
            end,
        })

        table.insert(options, {
            title = 'Instalar Turbo',
            description = 'Precio: $' .. Config.prices.tuning.turbo,
            icon = 'bolt',
            onSelect = function()
                AIT.Jobs.Mechanic.InstallTurbo(vehicle)
            end,
        })
    end

    -- Cosméticos
    table.insert(options, {
        title = 'Personalización',
        description = 'Pintura, ruedas, neones...',
        icon = 'palette',
        onSelect = function()
            AIT.Jobs.Mechanic.OpenCosmeticMenu(vehicle)
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'mechanic_menu',
            title = currentWorkshop.label,
            options = options,
        })
        lib.showContext('mechanic_menu')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE REPARACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mechanic.CalculateRepairPrice(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local avgHealth = (bodyHealth + engineHealth) / 2

    if avgHealth >= 800 then
        return Config.prices.repair.minor
    elseif avgHealth >= 500 then
        return Config.prices.repair.moderate
    elseif avgHealth >= 200 then
        return Config.prices.repair.major
    else
        return Config.prices.repair.full
    end
end

function AIT.Jobs.Mechanic.RepairVehicle(vehicle, price)
    -- Verificar pago
    TriggerServerEvent('ait:server:mechanic:checkPayment', price, function(canPay)
        if not canPay then
            AIT.Notify('No tienes suficiente dinero', 'error')
            return
        end

        -- Animación de reparación
        local ped = PlayerPedId()

        if lib and lib.progressBar then
            TaskTurnPedToFaceEntity(ped, vehicle, 1000)
            Wait(1000)

            if lib.progressBar({
                duration = 15000,
                label = 'Reparando vehículo...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_player',
                },
                prop = {
                    model = 'prop_tool_wrench',
                    bone = 28422,
                    pos = vector3(0.0, 0.0, 0.0),
                    rot = vector3(0.0, 0.0, 0.0),
                },
            }) then
                -- Reparar
                SetVehicleFixed(vehicle)
                SetVehicleEngineHealth(vehicle, 1000.0)
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehiclePetrolTankHealth(vehicle, 1000.0)

                TriggerServerEvent('ait:server:mechanic:chargeRepair', price)
                AIT.Notify('Vehículo reparado correctamente', 'success')
            else
                AIT.Notify('Reparación cancelada', 'error')
            end
        end
    end)
end

function AIT.Jobs.Mechanic.WashVehicle(vehicle)
    local ped = PlayerPedId()

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 5000,
            label = 'Lavando vehículo...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'timetable@gardener@filling_can',
                clip = 'gar_ig_5_filling_can',
            },
        }) then
            SetVehicleDirtLevel(vehicle, 0.0)
            TriggerServerEvent('ait:server:mechanic:chargeWash')
            AIT.Notify('Vehículo lavado', 'success')
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TUNING
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mechanic.OpenTuningMenu(vehicle, tuningType)
    local modType = ({
        engine = 11,
        brakes = 12,
        transmission = 13,
        suspension = 15,
    })[tuningType]

    local currentLevel = GetVehicleMod(vehicle, modType)
    local maxLevel = GetNumVehicleMods(vehicle, modType)

    local options = {}

    for level = 0, math.min(maxLevel - 1, 3) do
        local price = Config.prices.tuning[tuningType][level + 1]
        local installed = currentLevel >= level

        table.insert(options, {
            title = 'Nivel ' .. (level + 1),
            description = installed and '✓ Instalado' or ('Precio: $' .. price),
            icon = installed and 'check' or 'plus',
            disabled = installed,
            onSelect = function()
                AIT.Jobs.Mechanic.InstallTuning(vehicle, modType, level, price)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'tuning_' .. tuningType,
            title = 'Tuning - ' .. tuningType:gsub('^%l', string.upper),
            menu = 'mechanic_menu',
            options = options,
        })
        lib.showContext('tuning_' .. tuningType)
    end
end

function AIT.Jobs.Mechanic.InstallTuning(vehicle, modType, level, price)
    TriggerServerEvent('ait:server:mechanic:checkPayment', price, function(canPay)
        if not canPay then
            AIT.Notify('No tienes suficiente dinero', 'error')
            return
        end

        if lib and lib.progressBar then
            if lib.progressBar({
                duration = 20000,
                label = 'Instalando mejora...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_player',
                },
            }) then
                SetVehicleModKit(vehicle, 0)
                SetVehicleMod(vehicle, modType, level, false)

                TriggerServerEvent('ait:server:mechanic:chargeTuning', price)
                AIT.Notify('Mejora instalada correctamente', 'success')
            end
        end
    end)
end

function AIT.Jobs.Mechanic.InstallTurbo(vehicle)
    local hasTurbo = IsToggleModOn(vehicle, 18)

    if hasTurbo then
        AIT.Notify('Este vehículo ya tiene turbo', 'error')
        return
    end

    TriggerServerEvent('ait:server:mechanic:checkPayment', Config.prices.tuning.turbo, function(canPay)
        if not canPay then
            AIT.Notify('No tienes suficiente dinero', 'error')
            return
        end

        if lib and lib.progressBar then
            if lib.progressBar({
                duration = 30000,
                label = 'Instalando turbo...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_player',
                },
            }) then
                SetVehicleModKit(vehicle, 0)
                ToggleVehicleMod(vehicle, 18, true)

                TriggerServerEvent('ait:server:mechanic:chargeTuning', Config.prices.tuning.turbo)
                AIT.Notify('Turbo instalado', 'success')
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- PERSONALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mechanic.OpenCosmeticMenu(vehicle)
    local options = {
        {
            title = 'Pintura',
            description = 'Precio: $' .. Config.prices.cosmetic.respray,
            icon = 'fill-drip',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenPaintMenu(vehicle)
            end,
        },
        {
            title = 'Ruedas',
            description = 'Precio: $' .. Config.prices.cosmetic.wheels,
            icon = 'circle',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenWheelsMenu(vehicle)
            end,
        },
        {
            title = 'Neones',
            description = 'Precio: $' .. Config.prices.cosmetic.neon,
            icon = 'lightbulb',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenNeonMenu(vehicle)
            end,
        },
        {
            title = 'Tintado de Lunas',
            description = 'Precio: $' .. Config.prices.cosmetic.window_tint,
            icon = 'square',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenTintMenu(vehicle)
            end,
        },
        {
            title = 'Matrícula',
            description = 'Precio: $' .. Config.prices.cosmetic.plate,
            icon = 'id-card',
            onSelect = function()
                AIT.Jobs.Mechanic.OpenPlateMenu(vehicle)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'cosmetic_menu',
            title = 'Personalización',
            menu = 'mechanic_menu',
            options = options,
        })
        lib.showContext('cosmetic_menu')
    end
end

function AIT.Jobs.Mechanic.OpenPaintMenu(vehicle)
    local colors = {
        { label = 'Negro', primary = 0 },
        { label = 'Blanco', primary = 1 },
        { label = 'Rojo', primary = 27 },
        { label = 'Azul', primary = 64 },
        { label = 'Verde', primary = 55 },
        { label = 'Amarillo', primary = 88 },
        { label = 'Naranja', primary = 38 },
        { label = 'Morado', primary = 71 },
        { label = 'Rosa', primary = 135 },
        { label = 'Dorado', primary = 37 },
        { label = 'Plateado', primary = 4 },
        { label = 'Cromado', primary = 120 },
    }

    local options = {}

    for _, color in ipairs(colors) do
        table.insert(options, {
            title = color.label,
            onSelect = function()
                AIT.Jobs.Mechanic.ApplyPaint(vehicle, color.primary)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'paint_menu',
            title = 'Seleccionar Color',
            menu = 'cosmetic_menu',
            options = options,
        })
        lib.showContext('paint_menu')
    end
end

function AIT.Jobs.Mechanic.ApplyPaint(vehicle, colorIndex)
    TriggerServerEvent('ait:server:mechanic:checkPayment', Config.prices.cosmetic.respray, function(canPay)
        if not canPay then
            AIT.Notify('No tienes suficiente dinero', 'error')
            return
        end

        if lib and lib.progressBar then
            if lib.progressBar({
                duration = 10000,
                label = 'Pintando vehículo...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
            }) then
                SetVehicleColours(vehicle, colorIndex, colorIndex)
                TriggerServerEvent('ait:server:mechanic:chargeCosmetic', Config.prices.cosmetic.respray)
                AIT.Notify('Vehículo pintado', 'success')
            end
        end
    end)
end

function AIT.Jobs.Mechanic.OpenNeonMenu(vehicle)
    local colors = {
        { label = 'Blanco', r = 255, g = 255, b = 255 },
        { label = 'Rojo', r = 255, g = 0, b = 0 },
        { label = 'Azul', r = 0, g = 0, b = 255 },
        { label = 'Verde', r = 0, g = 255, b = 0 },
        { label = 'Amarillo', r = 255, g = 255, b = 0 },
        { label = 'Rosa', r = 255, g = 0, b = 255 },
        { label = 'Cian', r = 0, g = 255, b = 255 },
        { label = 'Naranja', r = 255, g = 128, b = 0 },
        { label = 'Morado', r = 128, g = 0, b = 255 },
        { label = 'Quitar Neones', r = -1, g = -1, b = -1 },
    }

    local options = {}

    for _, color in ipairs(colors) do
        table.insert(options, {
            title = color.label,
            onSelect = function()
                AIT.Jobs.Mechanic.ApplyNeon(vehicle, color.r, color.g, color.b)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'neon_menu',
            title = 'Neones',
            menu = 'cosmetic_menu',
            options = options,
        })
        lib.showContext('neon_menu')
    end
end

function AIT.Jobs.Mechanic.ApplyNeon(vehicle, r, g, b)
    TriggerServerEvent('ait:server:mechanic:checkPayment', Config.prices.cosmetic.neon, function(canPay)
        if not canPay then
            AIT.Notify('No tienes suficiente dinero', 'error')
            return
        end

        if r == -1 then
            -- Quitar neones
            SetVehicleNeonLightEnabled(vehicle, 0, false)
            SetVehicleNeonLightEnabled(vehicle, 1, false)
            SetVehicleNeonLightEnabled(vehicle, 2, false)
            SetVehicleNeonLightEnabled(vehicle, 3, false)
        else
            -- Aplicar neones
            SetVehicleNeonLightEnabled(vehicle, 0, true)
            SetVehicleNeonLightEnabled(vehicle, 1, true)
            SetVehicleNeonLightEnabled(vehicle, 2, true)
            SetVehicleNeonLightEnabled(vehicle, 3, true)
            SetVehicleNeonLightsColour(vehicle, r, g, b)
        end

        TriggerServerEvent('ait:server:mechanic:chargeCosmetic', Config.prices.cosmetic.neon)
        AIT.Notify('Neones aplicados', 'success')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- SERVICIO MÓVIL (GRÚA)
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:mechanic:towRequest', function(requestData)
    if not isOnDuty then return end

    AIT.Notify('Nuevo servicio de grúa solicitado', 'info')

    -- Marcar ubicación en mapa
    SetNewWaypoint(requestData.coords.x, requestData.coords.y)

    -- Blip temporal
    local blip = AddBlipForCoord(requestData.coords.x, requestData.coords.y, requestData.coords.z)
    SetBlipSprite(blip, 68)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Servicio de Grúa')
    EndTextCommandSetBlipName(blip)

    -- Eliminar blip después de 5 minutos
    SetTimeout(300000, function()
        RemoveBlip(blip)
    end)
end)

-- Comando para solicitar grúa
RegisterCommand('gruamecanico', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TriggerServerEvent('ait:server:mechanic:requestTow', coords)
    AIT.Notify('Grúa solicitada. Un mecánico llegará pronto.', 'info')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsMechanicOnDuty', function() return isOnDuty end)
exports('GetCurrentWorkshop', function() return currentWorkshop end)

return AIT.Jobs.Mechanic
