--[[
    AIT-QB: Sistema de Vehículos Cliente
    Garajes, llaves, combustible, daños
    Servidor Español
]]

AIT = AIT or {}
AIT.Vehicles = AIT.Vehicles or {}

local currentVehicle = nil
local vehicleKeys = {}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Vehicles.Init()
    -- Thread de vehículo actual
    CreateThread(function()
        while true do
            Wait(500)

            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= currentVehicle then
                    currentVehicle = vehicle
                    TriggerEvent('ait:client:vehicle:entered', vehicle)
                end
            else
                if currentVehicle then
                    TriggerEvent('ait:client:vehicle:exited', currentVehicle)
                    currentVehicle = nil
                end
            end
        end
    end)

    print('[AIT-QB] Sistema de vehículos cliente inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE LLAVES
-- ═══════════════════════════════════════════════════════════════

function AIT.Vehicles.HasKeys(plate)
    return vehicleKeys[plate] ~= nil
end

function AIT.Vehicles.GiveKeys(plate)
    vehicleKeys[plate] = true
    AIT.Notify('Has recibido las llaves del vehículo', 'success')
end

function AIT.Vehicles.RemoveKeys(plate)
    vehicleKeys[plate] = nil
    AIT.Notify('Has entregado las llaves del vehículo', 'info')
end

RegisterNetEvent('ait:client:vehicle:giveKeys', function(plate)
    AIT.Vehicles.GiveKeys(plate)
end)

RegisterNetEvent('ait:client:vehicle:removeKeys', function(plate)
    AIT.Vehicles.RemoveKeys(plate)
end)

-- ═══════════════════════════════════════════════════════════════
-- BLOQUEAR/DESBLOQUEAR
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:vehicle:toggleLock', function(vehicle)
    if not vehicle then
        vehicle = AIT.Vehicles.GetClosestVehicle()
    end

    if not vehicle then
        AIT.Notify('No hay vehículo cerca', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)

    if not AIT.Vehicles.HasKeys(plate) then
        AIT.Notify('No tienes las llaves de este vehículo', 'error')
        return
    end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)

    if lockStatus == 1 then
        -- Bloquear
        SetVehicleDoorsLocked(vehicle, 2)
        AIT.Notify('Vehículo bloqueado', 'info')

        -- Animación de mando
        AIT.Vehicles.PlayKeyFobAnimation()

        -- Sonido y luces
        SetVehicleLights(vehicle, 2)
        Wait(200)
        SetVehicleLights(vehicle, 0)
        Wait(100)
        SetVehicleLights(vehicle, 2)
        Wait(200)
        SetVehicleLights(vehicle, 0)
    else
        -- Desbloquear
        SetVehicleDoorsLocked(vehicle, 1)
        AIT.Notify('Vehículo desbloqueado', 'success')

        -- Animación de mando
        AIT.Vehicles.PlayKeyFobAnimation()

        -- Sonido y luces
        SetVehicleLights(vehicle, 2)
        Wait(150)
        SetVehicleLights(vehicle, 0)
    end

    TriggerServerEvent('ait:server:vehicle:syncLock', VehToNet(vehicle), lockStatus == 1 and 2 or 1)
end)

function AIT.Vehicles.PlayKeyFobAnimation()
    local ped = PlayerPedId()
    local dict = 'anim@mp_player_intmenu@key_fob@'

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskPlayAnim(ped, dict, 'fob_click', 8.0, 8.0, -1, 48, 0, false, false, false)
    Wait(500)
    ClearPedTasks(ped)
end

-- ═══════════════════════════════════════════════════════════════
-- MOTOR
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:vehicle:toggleEngine', function(vehicle)
    if not vehicle then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            vehicle = GetVehiclePedIsIn(ped, false)
        end
    end

    if not vehicle then
        AIT.Notify('Debes estar en un vehículo', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)

    if not AIT.Vehicles.HasKeys(plate) then
        AIT.Notify('No tienes las llaves de este vehículo', 'error')
        return
    end

    local engineOn = GetIsVehicleEngineRunning(vehicle)

    if engineOn then
        SetVehicleEngineOn(vehicle, false, false, true)
        AIT.Notify('Motor apagado', 'info')
    else
        -- Verificar combustible
        local fuel = GetVehicleFuelLevel(vehicle)
        if fuel <= 0 then
            AIT.Notify('El vehículo no tiene combustible', 'error')
            return
        end

        SetVehicleEngineOn(vehicle, true, false, true)
        AIT.Notify('Motor encendido', 'success')
    end
end)

-- Keybind para motor
RegisterKeyMapping('toggleengine', 'Encender/Apagar motor', 'keyboard', 'M')
RegisterCommand('toggleengine', function()
    TriggerEvent('ait:client:vehicle:toggleEngine')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- MALETERO Y GUANTERA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:vehicle:trunk', function(vehicle)
    if not vehicle then
        vehicle = AIT.Vehicles.GetClosestVehicle()
    end

    if not vehicle then
        AIT.Notify('No hay vehículo cerca', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)

    -- Verificar si está bloqueado
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 2 and not AIT.Vehicles.HasKeys(plate) then
        AIT.Notify('El vehículo está bloqueado', 'error')
        return
    end

    -- Abrir maletero
    local trunkOpen = GetVehicleDoorAngleRatio(vehicle, 5) > 0.0

    if trunkOpen then
        SetVehicleDoorShut(vehicle, 5, false)
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
    end

    -- Abrir inventario del maletero
    TriggerServerEvent('ait:server:inventory:openStash', 'trunk_' .. plate, 'vehicle')
end)

RegisterNetEvent('ait:client:vehicle:glovebox', function(vehicle)
    if not vehicle then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            vehicle = GetVehiclePedIsIn(ped, false)
        end
    end

    if not vehicle then return end

    local plate = GetVehicleNumberPlateText(vehicle)

    -- Abrir inventario de guantera
    TriggerServerEvent('ait:server:inventory:openStash', 'glovebox_' .. plate, 'vehicle')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMBUSTIBLE
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(10000) -- Cada 10 segundos

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local engineOn = GetIsVehicleEngineRunning(vehicle)

            if engineOn then
                local fuel = GetVehicleFuelLevel(vehicle)
                local speed = GetEntitySpeed(vehicle) * 3.6 -- km/h

                -- Consumo base + extra por velocidad
                local consumption = 0.1 + (speed / 500)

                local newFuel = math.max(0, fuel - consumption)
                SetVehicleFuelLevel(vehicle, newFuel)

                -- Avisos de combustible bajo
                if newFuel <= 20 and newFuel > 10 then
                    AIT.Notify('Combustible bajo', 'warning')
                elseif newFuel <= 10 and newFuel > 0 then
                    AIT.Notify('¡Combustible muy bajo!', 'error')
                elseif newFuel <= 0 then
                    SetVehicleEngineOn(vehicle, false, false, true)
                    AIT.Notify('Te has quedado sin combustible', 'error')
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- REPOSTAR
-- ═══════════════════════════════════════════════════════════════

function AIT.Vehicles.Refuel(vehicle, amount)
    local fuel = GetVehicleFuelLevel(vehicle)
    local newFuel = math.min(100, fuel + amount)

    -- Animación de repostaje
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TaskTurnPedToFaceCoord(ped, coords.x, coords.y, coords.z, 1000)
    Wait(1000)

    -- Progress bar
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = amount * 100,
            label = 'Repostando...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'timetable@gardener@filling_can',
                clip = 'gar_ig_5_filling_can'
            },
        }) then
            SetVehicleFuelLevel(vehicle, newFuel)
            AIT.Notify('Vehículo repostado: ' .. math.floor(newFuel) .. '%', 'success')
            return true
        else
            AIT.Notify('Repostaje cancelado', 'error')
            return false
        end
    else
        -- Fallback sin ox_lib
        AIT.ProgressBar('Repostando...', amount * 100, function()
            SetVehicleFuelLevel(vehicle, newFuel)
            AIT.Notify('Vehículo repostado: ' .. math.floor(newFuel) .. '%', 'success')
        end)
        return true
    end
end

-- ═══════════════════════════════════════════════════════════════
-- REPARAR
-- ═══════════════════════════════════════════════════════════════

function AIT.Vehicles.Repair(vehicle)
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Reparando vehículo...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'mini@repair',
                clip = 'fixing_a_ped'
            },
        }) then
            SetVehicleFixed(vehicle)
            SetVehicleEngineHealth(vehicle, 1000.0)
            SetVehicleBodyHealth(vehicle, 1000.0)
            SetVehiclePetrolTankHealth(vehicle, 1000.0)
            SetVehicleDirtLevel(vehicle, 0.0)
            AIT.Notify('Vehículo reparado', 'success')
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════

function AIT.Vehicles.GetClosestVehicle(radius)
    radius = radius or 5.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    return GetClosestVehicle(coords.x, coords.y, coords.z, radius, 0, 71)
end

function AIT.Vehicles.SpawnVehicle(model, coords, heading, callback)
    local hash = type(model) == 'number' and model or GetHashKey(model)

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            AIT.Notify('Error al cargar el modelo del vehículo', 'error')
            return
        end
    end

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

    SetModelAsNoLongerNeeded(hash)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleFuelLevel(vehicle, 100.0)

    if callback then
        callback(vehicle)
    end

    return vehicle
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('HasVehicleKeys', AIT.Vehicles.HasKeys)
exports('GiveVehicleKeys', AIT.Vehicles.GiveKeys)
exports('SpawnVehicle', AIT.Vehicles.SpawnVehicle)
exports('GetClosestVehicle', AIT.Vehicles.GetClosestVehicle)
exports('RefuelVehicle', AIT.Vehicles.Refuel)
exports('RepairVehicle', AIT.Vehicles.Repair)

return AIT.Vehicles
