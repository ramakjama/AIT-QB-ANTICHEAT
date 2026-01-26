--[[
    AIT-QB: Sistema de Basurero
    Trabajo legal - Recolección de basura
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Garbage = {}

local isOnDuty = false
local currentRoute = nil
local bagsCollected = 0
local routesCompleted = 0

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    depot = {
        coords = vector3(-322.0, -1545.0, 31.0),
        heading = 270.0,
        blip = { sprite = 318, color = 2, scale = 0.8 },
    },

    dumpSite = {
        coords = vector3(-353.0, -1557.0, 25.0),
        radius = 20.0,
    },

    vehicle = {
        model = 'trash',
        spawn = vector3(-330.0, -1556.0, 31.0),
        heading = 90.0,
    },

    -- Rutas de recolección
    routes = {
        {
            name = 'Ruta Centro',
            difficulty = 1,
            stops = {
                { coords = vector3(-265.0, -972.0, 31.0), bags = 3 },
                { coords = vector3(-349.0, -869.0, 31.0), bags = 2 },
                { coords = vector3(-489.0, -787.0, 30.0), bags = 4 },
                { coords = vector3(-626.0, -656.0, 31.0), bags = 2 },
                { coords = vector3(-774.0, -597.0, 30.0), bags = 3 },
                { coords = vector3(-913.0, -451.0, 39.0), bags = 2 },
            },
            basePay = 800,
        },
        {
            name = 'Ruta Vespucci',
            difficulty = 1,
            stops = {
                { coords = vector3(-1211.0, -1455.0, 4.0), bags = 3 },
                { coords = vector3(-1343.0, -1278.0, 4.0), bags = 2 },
                { coords = vector3(-1482.0, -1134.0, 2.0), bags = 4 },
                { coords = vector3(-1598.0, -1011.0, 13.0), bags = 3 },
                { coords = vector3(-1677.0, -867.0, 8.0), bags = 2 },
            },
            basePay = 750,
        },
        {
            name = 'Ruta Vinewood',
            difficulty = 2,
            stops = {
                { coords = vector3(95.0, 72.0, 71.0), bags = 2 },
                { coords = vector3(244.0, 161.0, 104.0), bags = 3 },
                { coords = vector3(351.0, 276.0, 103.0), bags = 2 },
                { coords = vector3(478.0, 392.0, 105.0), bags = 3 },
                { coords = vector3(602.0, 511.0, 108.0), bags = 4 },
                { coords = vector3(701.0, 578.0, 129.0), bags = 2 },
                { coords = vector3(801.0, 611.0, 142.0), bags = 3 },
            },
            basePay = 1200,
        },
        {
            name = 'Ruta Industrial',
            difficulty = 2,
            stops = {
                { coords = vector3(852.0, -1039.0, 32.0), bags = 5 },
                { coords = vector3(943.0, -1194.0, 25.0), bags = 4 },
                { coords = vector3(1033.0, -1396.0, 34.0), bags = 6 },
                { coords = vector3(1150.0, -1560.0, 34.0), bags = 5 },
                { coords = vector3(1205.0, -1703.0, 34.0), bags = 4 },
            },
            basePay = 1100,
        },
        {
            name = 'Ruta Norte',
            difficulty = 3,
            stops = {
                { coords = vector3(1957.0, 3740.0, 32.0), bags = 4 },
                { coords = vector3(1715.0, 4680.0, 42.0), bags = 3 },
                { coords = vector3(1686.0, 4929.0, 42.0), bags = 5 },
                { coords = vector3(168.0, 6640.0, 31.0), bags = 4 },
                { coords = vector3(-129.0, 6335.0, 31.0), bags = 3 },
            },
            basePay = 1500,
        },
    },

    -- Pago por bolsa
    payPerBag = 25,
    bonusFullRoute = 200,

    -- Capacidad del camión
    truckCapacity = 30,

    -- Sueldo base
    salary = 100,
    salaryInterval = 60000,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Garbage.Init()
    -- Blip del depósito
    local blip = AddBlipForCoord(Config.depot.coords.x, Config.depot.coords.y, Config.depot.coords.z)
    SetBlipSprite(blip, Config.depot.blip.sprite)
    SetBlipColour(blip, Config.depot.blip.color)
    SetBlipScale(blip, Config.depot.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Depósito de Basura')
    EndTextCommandSetBlipName(blip)

    print('[AIT-QB] Sistema de basurero inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE SERVICIO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:garbage:toggleDuty', function()
    local playerData = exports['ait-qb']:GetPlayerData()

    if not playerData or playerData.job.name ~= 'garbage' then
        AIT.Notify('No eres basurero', 'error')
        return
    end

    isOnDuty = not isOnDuty

    if isOnDuty then
        AIT.Notify('Has entrado en servicio como basurero', 'success')
        TriggerServerEvent('ait:server:garbage:setDuty', true)
        AIT.Jobs.Garbage.StartSalaryThread()
        AIT.Jobs.Garbage.OpenJobMenu()
    else
        AIT.Notify('Has salido de servicio', 'info')
        TriggerServerEvent('ait:server:garbage:setDuty', false)

        if currentRoute then
            AIT.Jobs.Garbage.CancelRoute()
        end
    end
end)

function AIT.Jobs.Garbage.StartSalaryThread()
    CreateThread(function()
        while isOnDuty do
            Wait(Config.salaryInterval)
            if isOnDuty then
                TriggerServerEvent('ait:server:garbage:paySalary')
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MENÚ PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Garbage.OpenJobMenu()
    local playerData = exports['ait-qb']:GetPlayerData()
    local grade = playerData.job.grade.level or 0

    local options = {
        {
            title = 'Sacar Camión',
            description = 'Obtener camión de basura',
            icon = 'truck',
            onSelect = function()
                AIT.Jobs.Garbage.SpawnTruck()
            end,
        },
        {
            title = 'Seleccionar Ruta',
            description = 'Elegir ruta de recolección',
            icon = 'route',
            onSelect = function()
                AIT.Jobs.Garbage.OpenRouteMenu(grade)
            end,
        },
        {
            title = 'Vaciar Camión',
            description = 'Descargar basura en el vertedero',
            icon = 'dumpster',
            onSelect = function()
                AIT.Jobs.Garbage.EmptyTruck()
            end,
        },
        {
            title = 'Estadísticas',
            description = 'Bolsas: ' .. bagsCollected .. ' | Rutas: ' .. routesCompleted,
            icon = 'chart-bar',
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'garbage_menu',
            title = 'Trabajo de Basurero',
            options = options,
        })
        lib.showContext('garbage_menu')
    end
end

function AIT.Jobs.Garbage.SpawnTruck()
    local hash = GetHashKey(Config.vehicle.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local vehicle = CreateVehicle(hash, Config.vehicle.spawn.x, Config.vehicle.spawn.y, Config.vehicle.spawn.z, Config.vehicle.heading, true, false)
    SetVehicleNumberPlateText(vehicle, 'BASURA' .. math.random(10, 99))
    SetVehicleColours(vehicle, 53, 53) -- Verde oscuro
    SetModelAsNoLongerNeeded(hash)

    SetVehicleFuelLevel(vehicle, 100.0)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent('ait:client:vehicle:giveKeys', plate)

    AIT.Notify('Camión de basura listo', 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE RUTAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Garbage.OpenRouteMenu(grade)
    if currentRoute then
        AIT.Notify('Ya tienes una ruta activa', 'error')
        return
    end

    local options = {}

    for i, route in ipairs(Config.routes) do
        local locked = route.difficulty > grade + 1
        local totalBags = 0
        for _, stop in ipairs(route.stops) do
            totalBags = totalBags + stop.bags
        end

        table.insert(options, {
            title = route.name,
            description = 'Paradas: ' .. #route.stops .. ' | Bolsas: ' .. totalBags .. '\nPago base: $' .. route.basePay,
            icon = locked and 'lock' or 'route',
            disabled = locked,
            onSelect = function()
                AIT.Jobs.Garbage.StartRoute(i)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'garbage_routes',
            title = 'Seleccionar Ruta',
            menu = 'garbage_menu',
            options = options,
        })
        lib.showContext('garbage_routes')
    end
end

function AIT.Jobs.Garbage.StartRoute(routeIndex)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        AIT.Notify('Necesitas el camión de basura', 'error')
        return
    end

    local route = Config.routes[routeIndex]

    currentRoute = {
        data = route,
        currentStop = 1,
        totalBags = 0,
        bagsInTruck = 0,
        stopsCompleted = 0,
    }

    -- Calcular total de bolsas
    for _, stop in ipairs(route.stops) do
        currentRoute.totalBags = currentRoute.totalBags + stop.bags
    end

    AIT.Notify('Ruta iniciada: ' .. route.name, 'success')
    AIT.Jobs.Garbage.UpdateRouteBlip()
    AIT.Jobs.Garbage.StartRouteThread()
end

function AIT.Jobs.Garbage.UpdateRouteBlip()
    if not currentRoute then return end

    -- Limpiar blip anterior
    if currentRoute.blip then
        RemoveBlip(currentRoute.blip)
    end

    local stop = currentRoute.data.stops[currentRoute.currentStop]
    if not stop then return end

    currentRoute.blip = AddBlipForCoord(stop.coords.x, stop.coords.y, stop.coords.z)
    SetBlipSprite(currentRoute.blip, 318)
    SetBlipColour(currentRoute.blip, 2)
    SetBlipScale(currentRoute.blip, 1.0)
    SetBlipRoute(currentRoute.blip, true)
    SetBlipRouteColour(currentRoute.blip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Parada ' .. currentRoute.currentStop .. ' (' .. stop.bags .. ' bolsas)')
    EndTextCommandSetBlipName(currentRoute.blip)
end

function AIT.Jobs.Garbage.StartRouteThread()
    CreateThread(function()
        while currentRoute do
            Wait(500)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local stop = currentRoute.data.stops[currentRoute.currentStop]

            if not stop then
                -- Ruta completada
                AIT.Jobs.Garbage.CompleteRoute()
                break
            end

            local dist = #(coords - stop.coords)

            if dist < 15.0 then
                -- En la parada
                if not IsPedInAnyVehicle(ped, false) then
                    lib.showTextUI('[E] Recoger basura (' .. stop.bags .. ' bolsas)')
                end
            end

            -- Actualizar HUD
            SendNUIMessage({
                action = 'updateGarbageHUD',
                data = {
                    route = currentRoute.data.name,
                    stop = currentRoute.currentStop,
                    totalStops = #currentRoute.data.stops,
                    bagsInTruck = currentRoute.bagsInTruck,
                    truckCapacity = Config.truckCapacity,
                }
            })
        end

        SendNUIMessage({ action = 'hideGarbageHUD' })
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- RECOLECCIÓN DE BASURA
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('recogerbasuragb', function()
    if not currentRoute then return end
    if not isOnDuty then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        AIT.Notify('Sal del vehículo para recoger basura', 'error')
        return
    end

    local coords = GetEntityCoords(ped)
    local stop = currentRoute.data.stops[currentRoute.currentStop]

    if not stop then return end

    local dist = #(coords - stop.coords)
    if dist > 15.0 then
        AIT.Notify('Debes estar en la zona de recogida', 'error')
        return
    end

    -- Verificar capacidad
    if currentRoute.bagsInTruck >= Config.truckCapacity then
        AIT.Notify('El camión está lleno. Ve al vertedero.', 'error')
        return
    end

    -- Recoger bolsas una a una
    for i = 1, stop.bags do
        if currentRoute.bagsInTruck >= Config.truckCapacity then
            AIT.Notify('Camión lleno. Ve a vaciar.', 'warning')
            break
        end

        if lib and lib.progressBar then
            if lib.progressBar({
                duration = 3000,
                label = 'Recogiendo bolsa ' .. i .. '/' .. stop.bags,
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'anim@mp_snowball',
                    clip = 'pickup_snowball',
                },
            }) then
                currentRoute.bagsInTruck = currentRoute.bagsInTruck + 1
                bagsCollected = bagsCollected + 1

                -- Crear prop de bolsa (visual)
                local bagProp = CreateObject(GetHashKey('prop_cs_rub_binbag_01'), coords.x, coords.y, coords.z - 1.0, true, true, true)
                Wait(500)
                DeleteObject(bagProp)
            else
                AIT.Notify('Recogida cancelada', 'error')
                break
            end
        end
    end

    -- Avanzar a siguiente parada
    currentRoute.stopsCompleted = currentRoute.stopsCompleted + 1
    currentRoute.currentStop = currentRoute.currentStop + 1

    if currentRoute.currentStop <= #currentRoute.data.stops then
        AIT.Jobs.Garbage.UpdateRouteBlip()
        AIT.Notify('Parada completada. Siguiente parada marcada.', 'success')
    else
        AIT.Notify('Todas las paradas completadas. Ve al vertedero.', 'success')
        AIT.Jobs.Garbage.ShowDumpBlip()
    end
end, false)

-- Keybind para recoger
RegisterKeyMapping('recogerbasuragb', 'Recoger basura', 'keyboard', 'E')

function AIT.Jobs.Garbage.ShowDumpBlip()
    if currentRoute and currentRoute.blip then
        RemoveBlip(currentRoute.blip)
    end

    currentRoute.blip = AddBlipForCoord(Config.dumpSite.coords.x, Config.dumpSite.coords.y, Config.dumpSite.coords.z)
    SetBlipSprite(currentRoute.blip, 365)
    SetBlipColour(currentRoute.blip, 1)
    SetBlipRoute(currentRoute.blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Vertedero')
    EndTextCommandSetBlipName(currentRoute.blip)
end

-- ═══════════════════════════════════════════════════════════════
-- VACIAR CAMIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Garbage.EmptyTruck()
    if not currentRoute then
        AIT.Notify('No tienes ruta activa', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - Config.dumpSite.coords)

    if dist > Config.dumpSite.radius then
        AIT.Notify('Debes estar en el vertedero', 'error')
        return
    end

    if currentRoute.bagsInTruck == 0 then
        AIT.Notify('El camión está vacío', 'error')
        return
    end

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Vaciando camión...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true },
        }) then
            local bags = currentRoute.bagsInTruck
            local pay = bags * Config.payPerBag

            currentRoute.bagsInTruck = 0

            TriggerServerEvent('ait:server:garbage:emptyTruck', pay)
            AIT.Notify('Camión vaciado. +$' .. pay .. ' por ' .. bags .. ' bolsas', 'success')

            -- Si la ruta está completa
            if currentRoute.currentStop > #currentRoute.data.stops then
                AIT.Jobs.Garbage.CompleteRoute()
            else
                -- Actualizar blip a siguiente parada
                AIT.Jobs.Garbage.UpdateRouteBlip()
            end
        end
    end
end

function AIT.Jobs.Garbage.CompleteRoute()
    if not currentRoute then return end

    -- Pagar bonus de ruta completa
    local bonus = currentRoute.data.basePay + Config.bonusFullRoute
    TriggerServerEvent('ait:server:garbage:completeRoute', bonus)

    routesCompleted = routesCompleted + 1

    AIT.Notify('¡Ruta completada! Bonus: $' .. bonus, 'success')

    -- Limpiar
    if currentRoute.blip then
        RemoveBlip(currentRoute.blip)
    end

    currentRoute = nil
end

function AIT.Jobs.Garbage.CancelRoute()
    if not currentRoute then return end

    if currentRoute.blip then
        RemoveBlip(currentRoute.blip)
    end

    AIT.Notify('Ruta cancelada', 'error')
    currentRoute = nil

    SendNUIMessage({ action = 'hideGarbageHUD' })
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsGarbageOnDuty', function() return isOnDuty end)
exports('GetBagsCollected', function() return bagsCollected end)
exports('GetRoutesCompleted', function() return routesCompleted end)

return AIT.Jobs.Garbage
