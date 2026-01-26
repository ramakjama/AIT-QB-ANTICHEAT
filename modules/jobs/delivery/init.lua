--[[
    AIT-QB: Sistema de Repartidor
    Trabajo legal - Entrega de paquetes
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Delivery = {}

local isOnDuty = false
local currentDeliveries = {}
local deliveriesCompleted = 0
local currentVehicle = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    depot = {
        coords = vector3(53.0, 6336.0, 31.0),
        heading = 230.0,
        blip = { sprite = 478, color = 28, scale = 0.8 },
    },

    -- Vehículos de reparto
    vehicles = {
        { model = 'faggio', label = 'Moto de Reparto', grade = 0, capacity = 3, type = 'bike' },
        { model = 'speedo', label = 'Furgoneta Pequeña', grade = 1, capacity = 8, type = 'van' },
        { model = 'rumpo', label = 'Furgoneta', grade = 2, capacity = 12, type = 'van' },
        { model = 'boxville', label = 'Camión de Reparto', grade = 3, capacity = 20, type = 'truck' },
    },

    -- Tipos de paquetes
    packageTypes = {
        { type = 'standard', label = 'Paquete Estándar', basePay = 50, fragile = false, urgent = false },
        { type = 'fragile', label = 'Paquete Frágil', basePay = 80, fragile = true, urgent = false },
        { type = 'express', label = 'Paquete Express', basePay = 100, fragile = false, urgent = true, timeLimit = 300 },
        { type = 'vip', label = 'Paquete VIP', basePay = 150, fragile = true, urgent = true, timeLimit = 240 },
    },

    -- Puntos de entrega
    deliveryPoints = {
        -- Los Santos
        { name = 'Residencia Vinewood', coords = vector3(520.0, 560.0, 115.0), region = 'vinewood' },
        { name = 'Apartamentos Alta', coords = vector3(-274.0, -948.0, 31.0), region = 'centro' },
        { name = 'Eclipse Towers', coords = vector3(-773.0, 312.0, 85.0), region = 'vinewood' },
        { name = 'Oficinas IAA', coords = vector3(117.0, -620.0, 44.0), region = 'centro' },
        { name = 'Hospital Central', coords = vector3(340.0, -583.0, 28.0), region = 'centro' },
        { name = 'Comisaría LSPD', coords = vector3(428.0, -984.0, 30.0), region = 'centro' },
        { name = 'Tienda 24/7 Vinewood', coords = vector3(373.0, 326.0, 103.0), region = 'vinewood' },
        { name = 'Gasolinera Davis', coords = vector3(-47.0, -1756.0, 29.0), region = 'davis' },
        { name = 'Almacén del Puerto', coords = vector3(164.0, -3082.0, 5.9), region = 'puerto' },

        -- Condado
        { name = 'Harmony', coords = vector3(542.0, 2663.0, 42.0), region = 'harmony' },
        { name = 'Sandy Shores', coords = vector3(1957.0, 3740.0, 32.0), region = 'sandy' },
        { name = 'Grapeseed', coords = vector3(1697.0, 4780.0, 42.0), region = 'grapeseed' },
        { name = 'Paleto Bay', coords = vector3(-163.0, 6323.0, 31.0), region = 'paleto' },
    },

    -- Bonuses
    bonusOnTime = 50,      -- Bonus por entrega a tiempo
    bonusPerfect = 100,    -- Bonus por ruta perfecta (sin daños)
    penaltyDamage = 0.25,  -- 25% menos si se daña paquete frágil

    -- Tiempos
    loadTime = 3000,
    deliveryTime = 5000,

    -- Sueldo base
    salary = 80,
    salaryInterval = 60000,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Delivery.Init()
    -- Blip del depósito
    local blip = AddBlipForCoord(Config.depot.coords.x, Config.depot.coords.y, Config.depot.coords.z)
    SetBlipSprite(blip, Config.depot.blip.sprite)
    SetBlipColour(blip, Config.depot.blip.color)
    SetBlipScale(blip, Config.depot.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Depósito de Reparto')
    EndTextCommandSetBlipName(blip)

    print('[AIT-QB] Sistema de repartidor inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE SERVICIO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:delivery:toggleDuty', function()
    local playerData = exports['ait-qb']:GetPlayerData()

    if not playerData or playerData.job.name ~= 'delivery' then
        AIT.Notify('No eres repartidor', 'error')
        return
    end

    isOnDuty = not isOnDuty

    if isOnDuty then
        AIT.Notify('Has entrado en servicio como repartidor', 'success')
        TriggerServerEvent('ait:server:delivery:setDuty', true)
        AIT.Jobs.Delivery.StartSalaryThread()
        AIT.Jobs.Delivery.OpenJobMenu()
    else
        AIT.Notify('Has salido de servicio', 'info')
        TriggerServerEvent('ait:server:delivery:setDuty', false)
    end
end)

function AIT.Jobs.Delivery.StartSalaryThread()
    CreateThread(function()
        while isOnDuty do
            Wait(Config.salaryInterval)
            if isOnDuty then
                TriggerServerEvent('ait:server:delivery:paySalary')
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MENÚ PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Delivery.OpenJobMenu()
    local playerData = exports['ait-qb']:GetPlayerData()
    local grade = playerData.job.grade.level or 0

    local options = {
        {
            title = 'Sacar Vehículo',
            description = 'Obtener vehículo de reparto',
            icon = 'truck',
            onSelect = function()
                AIT.Jobs.Delivery.OpenVehicleMenu(grade)
            end,
        },
        {
            title = 'Recoger Paquetes',
            description = 'Cargar paquetes para entrega',
            icon = 'box',
            onSelect = function()
                AIT.Jobs.Delivery.LoadPackages()
            end,
        },
        {
            title = 'Mis Entregas',
            description = 'Ver entregas pendientes',
            icon = 'list',
            onSelect = function()
                AIT.Jobs.Delivery.ShowPendingDeliveries()
            end,
        },
        {
            title = 'Estadísticas',
            description = 'Entregas completadas: ' .. deliveriesCompleted,
            icon = 'chart-bar',
        },
        {
            title = 'Guardar Vehículo',
            description = 'Devolver vehículo de trabajo',
            icon = 'warehouse',
            onSelect = function()
                AIT.Jobs.Delivery.StoreVehicle()
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'delivery_menu',
            title = 'Trabajo de Repartidor',
            options = options,
        })
        lib.showContext('delivery_menu')
    end
end

function AIT.Jobs.Delivery.OpenVehicleMenu(grade)
    local options = {}

    for _, vehicle in ipairs(Config.vehicles) do
        if grade >= vehicle.grade then
            table.insert(options, {
                title = vehicle.label,
                description = 'Capacidad: ' .. vehicle.capacity .. ' paquetes',
                icon = vehicle.type == 'bike' and 'motorcycle' or 'truck',
                onSelect = function()
                    AIT.Jobs.Delivery.SpawnVehicle(vehicle)
                end,
            })
        end
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'delivery_vehicles',
            title = 'Seleccionar Vehículo',
            menu = 'delivery_menu',
            options = options,
        })
        lib.showContext('delivery_vehicles')
    end
end

function AIT.Jobs.Delivery.SpawnVehicle(vehicleData)
    local hash = GetHashKey(vehicleData.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local vehicle = CreateVehicle(hash, Config.depot.coords.x + 5, Config.depot.coords.y, Config.depot.coords.z, Config.depot.heading, true, false)
    SetVehicleNumberPlateText(vehicle, 'DLVR' .. math.random(100, 999))

    -- Color corporativo
    SetVehicleColours(vehicle, 111, 111) -- Naranja

    SetModelAsNoLongerNeeded(hash)
    SetVehicleFuelLevel(vehicle, 100.0)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent('ait:client:vehicle:giveKeys', plate)

    currentVehicle = {
        entity = vehicle,
        data = vehicleData,
        packages = 0,
    }

    AIT.Notify('Has sacado: ' .. vehicleData.label, 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- CARGA DE PAQUETES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Delivery.LoadPackages()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - Config.depot.coords)

    if dist > 15.0 then
        AIT.Notify('Debes estar en el depósito', 'error')
        return
    end

    if not currentVehicle then
        AIT.Notify('Necesitas un vehículo de reparto', 'error')
        return
    end

    if currentVehicle.packages >= currentVehicle.data.capacity then
        AIT.Notify('El vehículo está lleno', 'error')
        return
    end

    -- Generar paquetes
    local availableSpace = currentVehicle.data.capacity - currentVehicle.packages
    local packagesToLoad = math.min(availableSpace, math.random(3, 6))

    local options = {}

    for i = 1, packagesToLoad do
        local packageType = Config.packageTypes[math.random(1, #Config.packageTypes)]
        local destination = Config.deliveryPoints[math.random(1, #Config.deliveryPoints)]

        local package = {
            id = 'PKG' .. math.random(10000, 99999),
            type = packageType,
            destination = destination,
            loaded = false,
            delivered = false,
            startTime = nil,
        }

        table.insert(options, {
            title = packageType.label .. ' → ' .. destination.name,
            description = 'ID: ' .. package.id .. ' | Pago: $' .. packageType.basePay,
            icon = packageType.fragile and 'box-open' or 'box',
            onSelect = function()
                AIT.Jobs.Delivery.LoadSinglePackage(package)
            end,
            metadata = {
                { label = 'Frágil', value = packageType.fragile and 'Sí' or 'No' },
                { label = 'Express', value = packageType.urgent and 'Sí' or 'No' },
            }
        })
    end

    table.insert(options, {
        title = 'Cargar Todos',
        description = 'Cargar todos los paquetes disponibles',
        icon = 'boxes',
        onSelect = function()
            for _, opt in ipairs(options) do
                if opt.metadata then -- Es un paquete, no el botón
                    -- Se cargará desde el loop
                end
            end
            AIT.Jobs.Delivery.LoadAllPackages(packagesToLoad)
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'delivery_load',
            title = 'Cargar Paquetes',
            menu = 'delivery_menu',
            options = options,
        })
        lib.showContext('delivery_load')
    end
end

function AIT.Jobs.Delivery.LoadAllPackages(count)
    for i = 1, count do
        local packageType = Config.packageTypes[math.random(1, #Config.packageTypes)]
        local destination = Config.deliveryPoints[math.random(1, #Config.deliveryPoints)]

        local package = {
            id = 'PKG' .. math.random(10000, 99999),
            type = packageType,
            destination = destination,
            loaded = false,
            delivered = false,
            startTime = nil,
        }

        if lib and lib.progressBar then
            if lib.progressBar({
                duration = Config.loadTime,
                label = 'Cargando paquete ' .. i .. '/' .. count,
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'anim@heists@box_carry@',
                    clip = 'idle',
                },
            }) then
                package.loaded = true
                package.startTime = GetGameTimer()
                table.insert(currentDeliveries, package)
                currentVehicle.packages = currentVehicle.packages + 1

                -- Crear blip
                package.blip = AddBlipForCoord(destination.coords.x, destination.coords.y, destination.coords.z)
                SetBlipSprite(package.blip, 478)
                SetBlipColour(package.blip, packageType.urgent and 1 or 5)
                SetBlipScale(package.blip, 0.8)
                SetBlipAsShortRange(package.blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(package.id)
                EndTextCommandSetBlipName(package.blip)
            else
                AIT.Notify('Carga cancelada', 'error')
                break
            end
        end
    end

    AIT.Notify('Has cargado ' .. #currentDeliveries .. ' paquetes', 'success')

    -- Iniciar monitoreo de tiempos
    AIT.Jobs.Delivery.StartDeliveryMonitor()
end

function AIT.Jobs.Delivery.LoadSinglePackage(package)
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.loadTime,
            label = 'Cargando paquete...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'anim@heists@box_carry@',
                clip = 'idle',
            },
        }) then
            package.loaded = true
            package.startTime = GetGameTimer()
            table.insert(currentDeliveries, package)
            currentVehicle.packages = currentVehicle.packages + 1

            -- Crear blip
            package.blip = AddBlipForCoord(package.destination.coords.x, package.destination.coords.y, package.destination.coords.z)
            SetBlipSprite(package.blip, 478)
            SetBlipColour(package.blip, package.type.urgent and 1 or 5)
            SetBlipScale(package.blip, 0.8)
            SetBlipAsShortRange(package.blip, true)

            AIT.Notify('Paquete ' .. package.id .. ' cargado', 'success')
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MONITOREO DE ENTREGAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Delivery.StartDeliveryMonitor()
    CreateThread(function()
        while #currentDeliveries > 0 do
            Wait(1000)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Verificar entregas expiradas
            for i = #currentDeliveries, 1, -1 do
                local package = currentDeliveries[i]

                if package.type.urgent and package.type.timeLimit then
                    local elapsed = (GetGameTimer() - package.startTime) / 1000

                    if elapsed >= package.type.timeLimit then
                        -- Entrega expirada
                        AIT.Notify('Paquete ' .. package.id .. ' expirado', 'error')

                        if package.blip then
                            RemoveBlip(package.blip)
                        end

                        table.remove(currentDeliveries, i)
                        currentVehicle.packages = currentVehicle.packages - 1
                    elseif elapsed >= package.type.timeLimit - 60 and not package.warned then
                        -- Aviso de 1 minuto
                        AIT.Notify('¡Paquete ' .. package.id .. ' expira en 1 minuto!', 'warning')
                        package.warned = true
                    end
                end

                -- Verificar cercanía a destino
                if not package.delivered then
                    local dist = #(coords - package.destination.coords)
                    if dist < 10.0 then
                        lib.showTextUI('[E] Entregar ' .. package.id)
                    end
                end
            end

            -- Actualizar HUD
            AIT.Jobs.Delivery.UpdateHUD()
        end

        SendNUIMessage({ action = 'hideDeliveryHUD' })
    end)
end

function AIT.Jobs.Delivery.UpdateHUD()
    local pendingCount = 0
    local urgentCount = 0

    for _, package in ipairs(currentDeliveries) do
        if not package.delivered then
            pendingCount = pendingCount + 1
            if package.type.urgent then
                urgentCount = urgentCount + 1
            end
        end
    end

    SendNUIMessage({
        action = 'updateDeliveryHUD',
        data = {
            pending = pendingCount,
            urgent = urgentCount,
            completed = deliveriesCompleted,
        }
    })
end

-- ═══════════════════════════════════════════════════════════════
-- ENTREGAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Delivery.ShowPendingDeliveries()
    local options = {}

    for i, package in ipairs(currentDeliveries) do
        if not package.delivered then
            local timeInfo = ''
            if package.type.urgent and package.type.timeLimit then
                local elapsed = (GetGameTimer() - package.startTime) / 1000
                local remaining = package.type.timeLimit - elapsed
                timeInfo = ' | ⏱️ ' .. math.floor(remaining) .. 's'
            end

            table.insert(options, {
                title = package.id .. ' - ' .. package.type.label,
                description = package.destination.name .. timeInfo,
                icon = package.type.fragile and 'box-open' or 'box',
                onSelect = function()
                    SetNewWaypoint(package.destination.coords.x, package.destination.coords.y)
                    AIT.Notify('GPS marcado: ' .. package.destination.name, 'info')
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes entregas pendientes', 'info')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'delivery_pending',
            title = 'Entregas Pendientes',
            menu = 'delivery_menu',
            options = options,
        })
        lib.showContext('delivery_pending')
    end
end

RegisterCommand('entregarpaquete', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Buscar paquete cercano
    local nearestPackage = nil
    local nearestIndex = nil

    for i, package in ipairs(currentDeliveries) do
        if not package.delivered then
            local dist = #(coords - package.destination.coords)
            if dist < 10.0 then
                nearestPackage = package
                nearestIndex = i
                break
            end
        end
    end

    if not nearestPackage then
        AIT.Notify('No hay punto de entrega cercano', 'error')
        return
    end

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.deliveryTime,
            label = 'Entregando paquete...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'anim@heists@box_carry@',
                clip = 'idle',
            },
        }) then
            -- Calcular pago
            local basePay = nearestPackage.type.basePay
            local finalPay = basePay

            -- Bonus por tiempo
            if nearestPackage.type.urgent and nearestPackage.type.timeLimit then
                local elapsed = (GetGameTimer() - nearestPackage.startTime) / 1000
                if elapsed < nearestPackage.type.timeLimit then
                    finalPay = finalPay + Config.bonusOnTime
                    AIT.Notify('Bonus por tiempo: +$' .. Config.bonusOnTime, 'success')
                end
            end

            -- Verificar daño al vehículo (para frágiles)
            if nearestPackage.type.fragile and currentVehicle then
                local vehicleHealth = GetVehicleBodyHealth(currentVehicle.entity)
                if vehicleHealth < 800 then
                    local penalty = math.floor(finalPay * Config.penaltyDamage)
                    finalPay = finalPay - penalty
                    AIT.Notify('Penalización por daños: -$' .. penalty, 'error')
                end
            end

            -- Pagar
            TriggerServerEvent('ait:server:delivery:complete', finalPay)

            -- Actualizar estado
            nearestPackage.delivered = true
            deliveriesCompleted = deliveriesCompleted + 1
            currentVehicle.packages = currentVehicle.packages - 1

            -- Eliminar blip
            if nearestPackage.blip then
                RemoveBlip(nearestPackage.blip)
            end

            -- Eliminar de la lista
            table.remove(currentDeliveries, nearestIndex)

            AIT.Notify('Entrega completada: +$' .. finalPay, 'success')

            -- Verificar si terminó todas las entregas
            if #currentDeliveries == 0 then
                AIT.Notify('¡Todas las entregas completadas! Vuelve al depósito.', 'success')
            end
        end
    end
end, false)

-- Keybind
RegisterKeyMapping('entregarpaquete', 'Entregar Paquete', 'keyboard', 'E')

-- ═══════════════════════════════════════════════════════════════
-- GUARDAR VEHÍCULO
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Delivery.StoreVehicle()
    if not currentVehicle then
        AIT.Notify('No tienes vehículo de trabajo', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - Config.depot.coords)

    if dist > 20.0 then
        AIT.Notify('Debes estar en el depósito', 'error')
        return
    end

    if #currentDeliveries > 0 then
        AIT.Notify('Tienes entregas pendientes', 'error')
        return
    end

    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, currentVehicle.entity, 0)
        Wait(1500)
    end

    DeleteVehicle(currentVehicle.entity)
    currentVehicle = nil

    AIT.Notify('Vehículo guardado', 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsDeliveryOnDuty', function() return isOnDuty end)
exports('GetDeliveriesCompleted', function() return deliveriesCompleted end)
exports('GetPendingDeliveries', function() return #currentDeliveries end)

return AIT.Jobs.Delivery
