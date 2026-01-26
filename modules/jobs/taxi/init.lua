--[[
    AIT-QB: Sistema de Taxi
    Trabajo legal - Transporte de pasajeros
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Taxi = {}

local isOnDuty = false
local currentFare = nil
local fareStartCoords = nil
local meterRunning = false
local currentEarnings = 0

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    depot = {
        coords = vector3(903.0, -170.0, 74.0),
        heading = 270.0,
        blip = { sprite = 198, color = 5, scale = 0.8 },
    },

    -- Tarifas
    pricing = {
        baseFare = 50,          -- Tarifa inicial
        perKm = 15,             -- Por kilómetro
        perMinute = 5,          -- Por minuto de espera
        nightMultiplier = 1.5,  -- Multiplicador nocturno (22:00 - 06:00)
        airportMultiplier = 1.3, -- Multiplicador aeropuerto
    },

    -- Vehículos de taxi
    vehicles = {
        { model = 'taxi', label = 'Taxi Clásico', grade = 0 },
        { model = 'tourbus', label = 'Autobús Turístico', grade = 2 },
        { model = 'stretch', label = 'Limusina', grade = 3 },
    },

    -- Puntos de interés para NPCs
    destinations = {
        { name = 'Aeropuerto', coords = vector3(-1037.0, -2737.0, 20.0), multiplier = 1.3 },
        { name = 'Hospital Central', coords = vector3(295.0, -584.0, 43.0) },
        { name = 'Comisaría LSPD', coords = vector3(428.0, -984.0, 30.0) },
        { name = 'Ayuntamiento', coords = vector3(-544.0, -204.0, 38.0) },
        { name = 'Plaza del Puerto', coords = vector3(-283.0, -939.0, 31.0) },
        { name = 'Vinewood Hills', coords = vector3(609.0, 560.0, 130.0) },
        { name = 'Del Perro Pier', coords = vector3(-1649.0, -1115.0, 13.0) },
        { name = 'Vespucci Beach', coords = vector3(-1323.0, -1535.0, 4.0) },
        { name = 'Paleto Bay', coords = vector3(-182.0, 6168.0, 31.0) },
        { name = 'Sandy Shores', coords = vector3(1891.0, 3713.0, 33.0) },
        { name = 'Casino Diamond', coords = vector3(924.0, 47.0, 81.0) },
        { name = 'Eclipse Towers', coords = vector3(-773.0, 312.0, 85.0) },
    },

    -- Sueldo base
    salary = 100,
    salaryInterval = 60000,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Taxi.Init()
    -- Blip del depósito
    local blip = AddBlipForCoord(Config.depot.coords.x, Config.depot.coords.y, Config.depot.coords.z)
    SetBlipSprite(blip, Config.depot.blip.sprite)
    SetBlipColour(blip, Config.depot.blip.color)
    SetBlipScale(blip, Config.depot.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Depósito de Taxis')
    EndTextCommandSetBlipName(blip)

    -- Target para el depósito
    if lib and lib.zones then
        lib.zones.sphere({
            coords = Config.depot.coords,
            radius = 5.0,
            onEnter = function()
                if not isOnDuty then
                    lib.showTextUI('[E] Entrar en servicio')
                else
                    lib.showTextUI('[E] Salir de servicio | [G] Guardar vehículo')
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end

    print('[AIT-QB] Sistema de taxi inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE SERVICIO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:taxi:toggleDuty', function()
    local playerData = exports['ait-qb']:GetPlayerData()

    if not playerData or playerData.job.name ~= 'taxi' then
        AIT.Notify('No eres taxista', 'error')
        return
    end

    isOnDuty = not isOnDuty

    if isOnDuty then
        AIT.Notify('Has entrado en servicio como taxista', 'success')
        TriggerServerEvent('ait:server:taxi:setDuty', true)
        AIT.Jobs.Taxi.StartSalaryThread()
        AIT.Jobs.Taxi.SpawnTaxiVehicle()
    else
        AIT.Notify('Has salido de servicio', 'info')
        TriggerServerEvent('ait:server:taxi:setDuty', false)

        -- Terminar carrera activa
        if currentFare then
            AIT.Jobs.Taxi.EndFare(true)
        end
    end
end)

function AIT.Jobs.Taxi.StartSalaryThread()
    CreateThread(function()
        while isOnDuty do
            Wait(Config.salaryInterval)
            if isOnDuty then
                TriggerServerEvent('ait:server:taxi:paySalary')
            end
        end
    end)
end

function AIT.Jobs.Taxi.SpawnTaxiVehicle()
    local playerData = exports['ait-qb']:GetPlayerData()
    local grade = playerData.job.grade.level or 0

    -- Obtener vehículo según rango
    local vehicleData = Config.vehicles[1]
    for _, v in ipairs(Config.vehicles) do
        if grade >= v.grade then
            vehicleData = v
        end
    end

    -- Spawner vehículo
    local hash = GetHashKey(vehicleData.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local vehicle = CreateVehicle(hash, Config.depot.coords.x, Config.depot.coords.y, Config.depot.coords.z, Config.depot.heading, true, false)
    SetVehicleNumberPlateText(vehicle, 'TAXI' .. math.random(100, 999))
    SetVehicleColours(vehicle, 88, 88) -- Amarillo taxi
    SetVehicleLivery(vehicle, 0)
    SetModelAsNoLongerNeeded(hash)

    -- Meter al jugador
    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    -- Dar llaves
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent('ait:client:vehicle:giveKeys', plate)

    AIT.Notify('Vehículo de taxi listo: ' .. vehicleData.label, 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE CARRERAS (NPC)
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:taxi:npcRequest', function()
    if not isOnDuty then return end
    if currentFare then
        AIT.Notify('Ya tienes una carrera activa', 'error')
        return
    end

    -- Generar destino aleatorio
    local destination = Config.destinations[math.random(1, #Config.destinations)]

    currentFare = {
        type = 'npc',
        destination = destination,
        startTime = GetGameTimer(),
        distance = 0,
    }

    fareStartCoords = GetEntityCoords(PlayerPedId())
    meterRunning = true

    -- Marcar destino
    SetNewWaypoint(destination.coords.x, destination.coords.y)

    -- Blip de destino
    currentFare.blip = AddBlipForCoord(destination.coords.x, destination.coords.y, destination.coords.z)
    SetBlipSprite(currentFare.blip, 1)
    SetBlipColour(currentFare.blip, 5)
    SetBlipScale(currentFare.blip, 1.2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(destination.name)
    EndTextCommandSetBlipName(currentFare.blip)

    AIT.Notify('Nueva carrera: ' .. destination.name, 'info')

    -- Thread para detectar llegada
    AIT.Jobs.Taxi.StartFareThread()
end)

function AIT.Jobs.Taxi.StartFareThread()
    CreateThread(function()
        local lastCoords = GetEntityCoords(PlayerPedId())

        while currentFare and meterRunning do
            Wait(1000)

            local ped = PlayerPedId()
            local currentCoords = GetEntityCoords(ped)

            -- Calcular distancia recorrida
            local distance = #(currentCoords - lastCoords)
            currentFare.distance = currentFare.distance + distance
            lastCoords = currentCoords

            -- Verificar llegada
            local destDist = #(currentCoords - currentFare.destination.coords)
            if destDist < 15.0 then
                AIT.Jobs.Taxi.EndFare(false)
                break
            end

            -- Mostrar taxímetro
            AIT.Jobs.Taxi.UpdateMeter()
        end
    end)
end

function AIT.Jobs.Taxi.UpdateMeter()
    if not currentFare then return end

    local fare = AIT.Jobs.Taxi.CalculateFare()

    -- Enviar a NUI para mostrar taxímetro
    SendNUIMessage({
        action = 'updateTaximeter',
        data = {
            fare = fare,
            distance = currentFare.distance / 1000, -- En km
            time = (GetGameTimer() - currentFare.startTime) / 1000, -- En segundos
            destination = currentFare.destination.name,
        }
    })
end

function AIT.Jobs.Taxi.CalculateFare()
    if not currentFare then return 0 end

    local baseFare = Config.pricing.baseFare
    local distanceKm = currentFare.distance / 1000
    local timeMinutes = (GetGameTimer() - currentFare.startTime) / 60000

    local fare = baseFare + (distanceKm * Config.pricing.perKm) + (timeMinutes * Config.pricing.perMinute)

    -- Multiplicador nocturno
    local hour = GetClockHours()
    if hour >= 22 or hour < 6 then
        fare = fare * Config.pricing.nightMultiplier
    end

    -- Multiplicador de destino
    if currentFare.destination.multiplier then
        fare = fare * currentFare.destination.multiplier
    end

    return math.floor(fare)
end

function AIT.Jobs.Taxi.EndFare(cancelled)
    if not currentFare then return end

    meterRunning = false

    if currentFare.blip then
        RemoveBlip(currentFare.blip)
    end

    if cancelled then
        AIT.Notify('Carrera cancelada', 'error')
    else
        local fare = AIT.Jobs.Taxi.CalculateFare()
        currentEarnings = currentEarnings + fare

        TriggerServerEvent('ait:server:taxi:completeFare', fare)
        AIT.Notify('Carrera completada: $' .. fare, 'success')
    end

    -- Ocultar taxímetro
    SendNUIMessage({
        action = 'hideTaximeter',
    })

    currentFare = nil
    fareStartCoords = nil
end

-- ═══════════════════════════════════════════════════════════════
-- CARRERAS DE JUGADORES
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('pedirtaxi', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TriggerServerEvent('ait:server:taxi:requestRide', coords)
    AIT.Notify('Taxi solicitado. Espera a que llegue.', 'info')
end, false)

RegisterNetEvent('ait:client:taxi:playerRequest', function(requestData)
    if not isOnDuty then return end
    if currentFare then return end

    AIT.Notify('Nuevo pasajero solicita taxi', 'info')

    -- Marcar ubicación
    SetNewWaypoint(requestData.coords.x, requestData.coords.y)

    -- Blip de recogida
    local blip = AddBlipForCoord(requestData.coords.x, requestData.coords.y, requestData.coords.z)
    SetBlipSprite(blip, 280)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Pasajero')
    EndTextCommandSetBlipName(blip)

    -- Menú para aceptar
    if lib and lib.alertDialog then
        local alert = lib.alertDialog({
            header = 'Solicitud de Taxi',
            content = '¿Aceptar carrera?',
            centered = true,
            cancel = true,
        })

        if alert == 'confirm' then
            TriggerServerEvent('ait:server:taxi:acceptRide', requestData.playerId)

            currentFare = {
                type = 'player',
                playerId = requestData.playerId,
                pickupCoords = requestData.coords,
                pickupBlip = blip,
                startTime = nil,
                distance = 0,
                pickedUp = false,
            }

            AIT.Notify('Carrera aceptada. Dirígete al pasajero.', 'success')
        else
            RemoveBlip(blip)
        end
    end
end)

RegisterNetEvent('ait:client:taxi:passengerEntered', function(passengerId)
    if not currentFare then return end
    if currentFare.type ~= 'player' then return end
    if currentFare.playerId ~= passengerId then return end

    currentFare.pickedUp = true
    currentFare.startTime = GetGameTimer()
    fareStartCoords = GetEntityCoords(PlayerPedId())
    meterRunning = true

    if currentFare.pickupBlip then
        RemoveBlip(currentFare.pickupBlip)
        currentFare.pickupBlip = nil
    end

    AIT.Notify('Pasajero recogido. Pregunta el destino.', 'info')

    -- Iniciar thread de taxímetro
    AIT.Jobs.Taxi.StartPlayerFareThread()
end)

function AIT.Jobs.Taxi.StartPlayerFareThread()
    CreateThread(function()
        local lastCoords = GetEntityCoords(PlayerPedId())

        while currentFare and meterRunning do
            Wait(1000)

            local ped = PlayerPedId()
            local currentCoords = GetEntityCoords(ped)

            -- Calcular distancia
            local distance = #(currentCoords - lastCoords)
            currentFare.distance = currentFare.distance + distance
            lastCoords = currentCoords

            -- Mostrar taxímetro
            AIT.Jobs.Taxi.UpdateMeter()
        end
    end)
end

-- Comando para terminar carrera de jugador
RegisterCommand('fincarrera', function()
    if not currentFare then
        AIT.Notify('No tienes carrera activa', 'error')
        return
    end

    if currentFare.type ~= 'player' then
        AIT.Notify('Este comando es solo para carreras de jugadores', 'error')
        return
    end

    local fare = AIT.Jobs.Taxi.CalculateFare()

    -- Cobrar al pasajero
    TriggerServerEvent('ait:server:taxi:chargePassenger', currentFare.playerId, fare)

    AIT.Jobs.Taxi.EndFare(false)
end, false)

-- ═══════════════════════════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════════════════════════

RegisterKeyMapping('taximeter', 'Taxímetro', 'keyboard', 'F5')
RegisterCommand('taximeter', function()
    if not isOnDuty then return end

    if not currentFare then
        -- Iniciar nueva carrera NPC
        TriggerEvent('ait:client:taxi:npcRequest')
    else
        -- Cancelar carrera actual
        AIT.Jobs.Taxi.EndFare(true)
    end
end, false)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsTaxiOnDuty', function() return isOnDuty end)
exports('GetCurrentFare', function() return currentFare end)
exports('GetTaxiEarnings', function() return currentEarnings end)

return AIT.Jobs.Taxi
