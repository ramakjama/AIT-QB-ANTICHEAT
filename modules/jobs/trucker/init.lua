--[[
    AIT-QB: Sistema de Camionero
    Trabajo legal - Transporte de mercancías
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Trucker = {}

local isOnDuty = false
local currentDelivery = nil
local deliveriesCompleted = 0
local currentRoute = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    depot = {
        coords = vector3(151.0, -3210.0, 5.9),
        heading = 270.0,
        blip = { sprite = 477, color = 1, scale = 0.9 },
    },

    -- Vehículos según rango
    vehicles = {
        { model = 'mule', label = 'Mule (Pequeño)', grade = 0, capacity = 50 },
        { model = 'mule3', label = 'Mule Grande', grade = 1, capacity = 75 },
        { model = 'benson', label = 'Benson', grade = 2, capacity = 100 },
        { model = 'pounder', label = 'Pounder', grade = 3, capacity = 150 },
        { model = 'hauler', label = 'Hauler + Trailer', grade = 4, capacity = 300 },
        { model = 'packer', label = 'Packer', grade = 5, capacity = 400 },
    },

    -- Tipos de carga
    cargoTypes = {
        { name = 'electronica', label = 'Electrónica', payMultiplier = 1.5, fragile = true },
        { name = 'alimentos', label = 'Alimentos', payMultiplier = 1.0, perishable = true },
        { name = 'construccion', label = 'Materiales de Construcción', payMultiplier = 0.8, heavy = true },
        { name = 'textiles', label = 'Textiles', payMultiplier = 0.9 },
        { name = 'quimicos', label = 'Químicos', payMultiplier = 1.3, hazardous = true },
        { name = 'vehiculos', label = 'Vehículos', payMultiplier = 1.4, requiresTrailer = true },
        { name = 'combustible', label = 'Combustible', payMultiplier = 1.6, hazardous = true },
        { name = 'farmaceuticos', label = 'Farmacéuticos', payMultiplier = 1.8, fragile = true },
    },

    -- Destinos de entrega
    deliveryPoints = {
        -- Los Santos
        { name = 'Puerto de LS', coords = vector3(164.0, -3082.0, 5.9), region = 'ciudad' },
        { name = 'Almacén Davis', coords = vector3(84.0, -1951.0, 21.0), region = 'ciudad' },
        { name = 'Centro Comercial', coords = vector3(127.0, -1293.0, 29.0), region = 'ciudad' },
        { name = 'Fábrica Textil', coords = vector3(717.0, -962.0, 30.0), region = 'ciudad' },
        { name = 'Hospital Central', coords = vector3(340.0, -583.0, 28.0), region = 'ciudad' },
        { name = 'Aeropuerto', coords = vector3(-1037.0, -2737.0, 20.0), region = 'ciudad' },

        -- Condado
        { name = 'Harmony', coords = vector3(1205.0, 1866.0, 79.0), region = 'condado' },
        { name = 'Sandy Shores', coords = vector3(1970.0, 3820.0, 32.0), region = 'condado' },
        { name = 'Grapeseed', coords = vector3(1694.0, 4785.0, 42.0), region = 'condado' },
        { name = 'Paleto Bay', coords = vector3(-117.0, 6385.0, 31.0), region = 'condado' },

        -- Especiales
        { name = 'Base Militar', coords = vector3(-2156.0, 3226.0, 33.0), region = 'especial', restricted = true },
        { name = 'Prisión', coords = vector3(1850.0, 2604.0, 46.0), region = 'especial', restricted = true },
    },

    -- Pagos base por distancia
    payPerKm = 15,
    bonusOnTime = 500,
    penaltyDamage = 0.3, -- 30% menos si se daña la carga

    -- Tiempos
    deliveryTimePerKm = 60, -- segundos por km para bonus

    -- Sueldo base
    salary = 120,
    salaryInterval = 60000,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Trucker.Init()
    -- Blip del depósito
    local blip = AddBlipForCoord(Config.depot.coords.x, Config.depot.coords.y, Config.depot.coords.z)
    SetBlipSprite(blip, Config.depot.blip.sprite)
    SetBlipColour(blip, Config.depot.blip.color)
    SetBlipScale(blip, Config.depot.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Depósito de Camiones')
    EndTextCommandSetBlipName(blip)

    print('[AIT-QB] Sistema de camionero inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE SERVICIO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:trucker:toggleDuty', function()
    local playerData = exports['ait-qb']:GetPlayerData()

    if not playerData or playerData.job.name ~= 'trucker' then
        AIT.Notify('No eres camionero', 'error')
        return
    end

    isOnDuty = not isOnDuty

    if isOnDuty then
        AIT.Notify('Has entrado en servicio como camionero', 'success')
        TriggerServerEvent('ait:server:trucker:setDuty', true)
        AIT.Jobs.Trucker.StartSalaryThread()
        AIT.Jobs.Trucker.OpenJobMenu()
    else
        AIT.Notify('Has salido de servicio', 'info')
        TriggerServerEvent('ait:server:trucker:setDuty', false)

        if currentDelivery then
            AIT.Jobs.Trucker.CancelDelivery()
        end
    end
end)

function AIT.Jobs.Trucker.StartSalaryThread()
    CreateThread(function()
        while isOnDuty do
            Wait(Config.salaryInterval)
            if isOnDuty then
                TriggerServerEvent('ait:server:trucker:paySalary')
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MENÚ DE TRABAJO
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Trucker.OpenJobMenu()
    local playerData = exports['ait-qb']:GetPlayerData()
    local grade = playerData.job.grade.level or 0

    local options = {
        {
            title = 'Sacar Vehículo',
            description = 'Obtener camión de trabajo',
            icon = 'truck',
            onSelect = function()
                AIT.Jobs.Trucker.OpenVehicleMenu(grade)
            end,
        },
        {
            title = 'Nueva Entrega',
            description = 'Aceptar un trabajo de transporte',
            icon = 'box',
            onSelect = function()
                AIT.Jobs.Trucker.OpenDeliveryMenu()
            end,
        },
        {
            title = 'Entregas Completadas',
            description = 'Hoy: ' .. deliveriesCompleted,
            icon = 'check-circle',
        },
        {
            title = 'Guardar Vehículo',
            description = 'Devolver camión',
            icon = 'warehouse',
            onSelect = function()
                AIT.Jobs.Trucker.StoreVehicle()
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'trucker_menu',
            title = 'Trabajo de Camionero',
            options = options,
        })
        lib.showContext('trucker_menu')
    end
end

function AIT.Jobs.Trucker.OpenVehicleMenu(grade)
    local options = {}

    for _, vehicle in ipairs(Config.vehicles) do
        if grade >= vehicle.grade then
            table.insert(options, {
                title = vehicle.label,
                description = 'Capacidad: ' .. vehicle.capacity .. ' unidades',
                icon = 'truck',
                onSelect = function()
                    AIT.Jobs.Trucker.SpawnVehicle(vehicle)
                end,
            })
        end
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'trucker_vehicles',
            title = 'Seleccionar Vehículo',
            menu = 'trucker_menu',
            options = options,
        })
        lib.showContext('trucker_vehicles')
    end
end

function AIT.Jobs.Trucker.SpawnVehicle(vehicleData)
    local hash = GetHashKey(vehicleData.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local vehicle = CreateVehicle(hash, Config.depot.coords.x, Config.depot.coords.y, Config.depot.coords.z, Config.depot.heading, true, false)
    SetVehicleNumberPlateText(vehicle, 'TRUCK' .. math.random(100, 999))
    SetModelAsNoLongerNeeded(hash)

    -- Configurar vehículo
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleEngineOn(vehicle, true, true, false)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    -- Dar llaves
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent('ait:client:vehicle:giveKeys', plate)

    AIT.Notify('Has sacado: ' .. vehicleData.label, 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE ENTREGAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Trucker.OpenDeliveryMenu()
    if currentDelivery then
        AIT.Notify('Ya tienes una entrega activa', 'error')
        return
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        AIT.Notify('Necesitas un vehículo de trabajo', 'error')
        return
    end

    -- Generar entregas disponibles
    local options = {}

    for i = 1, 3 do
        local cargo = Config.cargoTypes[math.random(1, #Config.cargoTypes)]
        local destination = Config.deliveryPoints[math.random(1, #Config.deliveryPoints)]

        -- Calcular distancia y pago
        local playerCoords = GetEntityCoords(ped)
        local distance = #(playerCoords - destination.coords) / 1000 -- en km
        local basePay = distance * Config.payPerKm
        local totalPay = math.floor(basePay * cargo.payMultiplier)

        local description = 'Destino: ' .. destination.name .. '\n'
        description = description .. 'Distancia: ' .. string.format('%.1f', distance) .. ' km\n'
        description = description .. 'Pago: $' .. totalPay

        if cargo.fragile then description = description .. '\n⚠️ Carga frágil' end
        if cargo.hazardous then description = description .. '\n☢️ Material peligroso' end
        if cargo.perishable then description = description .. '\n🕐 Perecedero' end

        table.insert(options, {
            title = cargo.label,
            description = description,
            icon = 'box',
            onSelect = function()
                AIT.Jobs.Trucker.AcceptDelivery(cargo, destination, distance, totalPay)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'trucker_deliveries',
            title = 'Entregas Disponibles',
            menu = 'trucker_menu',
            options = options,
        })
        lib.showContext('trucker_deliveries')
    end
end

function AIT.Jobs.Trucker.AcceptDelivery(cargo, destination, distance, pay)
    local timeLimit = distance * Config.deliveryTimePerKm

    currentDelivery = {
        cargo = cargo,
        destination = destination,
        distance = distance,
        pay = pay,
        startTime = GetGameTimer(),
        timeLimit = timeLimit * 1000,
        damaged = false,
    }

    -- Crear blip de destino
    currentDelivery.blip = AddBlipForCoord(destination.coords.x, destination.coords.y, destination.coords.z)
    SetBlipSprite(currentDelivery.blip, 477)
    SetBlipColour(currentDelivery.blip, 5)
    SetBlipScale(currentDelivery.blip, 1.2)
    SetBlipRoute(currentDelivery.blip, true)
    SetBlipRouteColour(currentDelivery.blip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Entrega: ' .. destination.name)
    EndTextCommandSetBlipName(currentDelivery.blip)

    SetNewWaypoint(destination.coords.x, destination.coords.y)

    AIT.Notify('Entrega aceptada: ' .. cargo.label .. ' a ' .. destination.name, 'success')

    -- Iniciar threads de monitoreo
    AIT.Jobs.Trucker.StartDeliveryThread()
end

function AIT.Jobs.Trucker.StartDeliveryThread()
    -- Thread de tiempo y daño
    CreateThread(function()
        local lastHealth = 1000

        while currentDelivery do
            Wait(1000)

            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                -- Fuera del vehículo
                goto continue
            end

            local vehicle = GetVehiclePedIsIn(ped, false)
            local health = GetVehicleBodyHealth(vehicle)

            -- Detectar daño
            if health < lastHealth - 50 then
                if currentDelivery.cargo.fragile then
                    currentDelivery.damaged = true
                    AIT.Notify('¡Cuidado! La carga frágil se ha dañado', 'error')
                elseif currentDelivery.cargo.hazardous and health < 500 then
                    AIT.Notify('¡Peligro! Riesgo de derrame de material peligroso', 'error')
                end
            end
            lastHealth = health

            -- Verificar tiempo restante
            local elapsed = GetGameTimer() - currentDelivery.startTime
            local remaining = currentDelivery.timeLimit - elapsed

            if remaining < 60000 and remaining > 59000 then
                AIT.Notify('¡1 minuto para el bonus de tiempo!', 'warning')
            elseif remaining < 0 and remaining > -1000 then
                AIT.Notify('Has perdido el bonus de tiempo', 'error')
            end

            -- Verificar llegada
            local coords = GetEntityCoords(ped)
            local dist = #(coords - currentDelivery.destination.coords)

            if dist < 20.0 then
                AIT.Jobs.Trucker.CompleteDelivery()
                break
            end

            ::continue::
        end
    end)

    -- Thread de UI
    CreateThread(function()
        while currentDelivery do
            Wait(500)

            local elapsed = GetGameTimer() - currentDelivery.startTime
            local remaining = math.max(0, currentDelivery.timeLimit - elapsed)

            SendNUIMessage({
                action = 'updateDeliveryHUD',
                data = {
                    cargo = currentDelivery.cargo.label,
                    destination = currentDelivery.destination.name,
                    timeRemaining = remaining / 1000,
                    pay = currentDelivery.pay,
                    damaged = currentDelivery.damaged,
                }
            })
        end

        SendNUIMessage({ action = 'hideDeliveryHUD' })
    end)
end

function AIT.Jobs.Trucker.CompleteDelivery()
    if not currentDelivery then return end

    local ped = PlayerPedId()

    -- Animación de descarga
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 8000,
            label = 'Descargando mercancía...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'anim@heists@box_carry@',
                clip = 'idle',
            },
        }) then
            -- Calcular pago final
            local finalPay = currentDelivery.pay

            -- Bonus de tiempo
            local elapsed = GetGameTimer() - currentDelivery.startTime
            if elapsed < currentDelivery.timeLimit then
                finalPay = finalPay + Config.bonusOnTime
                AIT.Notify('¡Bonus por entrega a tiempo! +$' .. Config.bonusOnTime, 'success')
            end

            -- Penalización por daño
            if currentDelivery.damaged then
                local penalty = math.floor(finalPay * Config.penaltyDamage)
                finalPay = finalPay - penalty
                AIT.Notify('Penalización por daños: -$' .. penalty, 'error')
            end

            -- Pagar
            TriggerServerEvent('ait:server:trucker:completeDelivery', finalPay)

            deliveriesCompleted = deliveriesCompleted + 1

            AIT.Notify('Entrega completada. Ganancia: $' .. finalPay, 'success')

            -- Limpiar
            if currentDelivery.blip then
                RemoveBlip(currentDelivery.blip)
            end

            currentDelivery = nil
        end
    end
end

function AIT.Jobs.Trucker.CancelDelivery()
    if not currentDelivery then return end

    if currentDelivery.blip then
        RemoveBlip(currentDelivery.blip)
    end

    AIT.Notify('Entrega cancelada', 'error')
    currentDelivery = nil

    SendNUIMessage({ action = 'hideDeliveryHUD' })
end

function AIT.Jobs.Trucker.StoreVehicle()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        AIT.Notify('Debes estar en un vehículo', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local coords = GetEntityCoords(vehicle)
    local dist = #(coords - Config.depot.coords)

    if dist > 30.0 then
        AIT.Notify('Debes estar en el depósito', 'error')
        return
    end

    TaskLeaveVehicle(ped, vehicle, 0)
    Wait(1500)

    DeleteVehicle(vehicle)
    AIT.Notify('Vehículo guardado', 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- RUTAS ESPECIALES (Alto rango)
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:trucker:specialRoute', function()
    local playerData = exports['ait-qb']:GetPlayerData()
    local grade = playerData.job.grade.level or 0

    if grade < 4 then
        AIT.Notify('Necesitas rango 4+ para rutas especiales', 'error')
        return
    end

    -- Ruta especial con múltiples paradas
    currentRoute = {
        stops = {
            { coords = vector3(164.0, -3082.0, 5.9), name = 'Puerto', completed = false },
            { coords = vector3(1970.0, 3820.0, 32.0), name = 'Sandy Shores', completed = false },
            { coords = vector3(-117.0, 6385.0, 31.0), name = 'Paleto Bay', completed = false },
        },
        currentStop = 1,
        totalPay = 5000,
    }

    AIT.Notify('Ruta especial activada: 3 paradas', 'success')
    AIT.Jobs.Trucker.UpdateRouteBlip()
end)

function AIT.Jobs.Trucker.UpdateRouteBlip()
    if not currentRoute then return end

    local stop = currentRoute.stops[currentRoute.currentStop]
    if not stop then return end

    if currentRoute.blip then
        RemoveBlip(currentRoute.blip)
    end

    currentRoute.blip = AddBlipForCoord(stop.coords.x, stop.coords.y, stop.coords.z)
    SetBlipSprite(currentRoute.blip, 477)
    SetBlipColour(currentRoute.blip, 3)
    SetBlipRoute(currentRoute.blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Parada ' .. currentRoute.currentStop .. ': ' .. stop.name)
    EndTextCommandSetBlipName(currentRoute.blip)
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsTruckerOnDuty', function() return isOnDuty end)
exports('GetCurrentDelivery', function() return currentDelivery end)
exports('GetDeliveriesCompleted', function() return deliveriesCompleted end)

return AIT.Jobs.Trucker
