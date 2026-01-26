--[[
    AIT-QB: Sistema HUD
    Heads-Up Display completo
    Servidor Español
]]

AIT = AIT or {}
AIT.HUD = {}

-- Estado del HUD
local hudEnabled = true
local hudData = {
    health = 200,
    armor = 0,
    hunger = 100,
    thirst = 100,
    stress = 0,
    oxygen = 100,
    stamina = 100,
    cash = 0,
    bank = 0,
    job = 'Desempleado',
    jobGrade = '',
    isInVehicle = false,
    speed = 0,
    fuel = 100,
    seatbelt = false,
    gear = 0,
    rpm = 0,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.HUD.Init()
    -- Thread principal del HUD
    CreateThread(function()
        while true do
            Wait(200) -- Actualizar cada 200ms

            if hudEnabled and AIT.PlayerData then
                AIT.HUD.Update()
            end
        end
    end)

    -- Thread de vehículo (más frecuente)
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)

            if inVehicle then
                Wait(50)
                AIT.HUD.UpdateVehicle()
            else
                Wait(500)
                if hudData.isInVehicle then
                    hudData.isInVehicle = false
                    AIT.HUD.SendUpdate()
                end
            end
        end
    end)

    -- Thread de necesidades (hambre, sed)
    CreateThread(function()
        while true do
            Wait(60000) -- Cada minuto

            if AIT.PlayerData and AIT.PlayerData.metadata then
                -- Decrementar hambre y sed
                local hunger = (AIT.PlayerData.metadata.hunger or 100) - 0.5
                local thirst = (AIT.PlayerData.metadata.thirst or 100) - 0.7

                hunger = math.max(0, hunger)
                thirst = math.max(0, thirst)

                AIT.PlayerData.metadata.hunger = hunger
                AIT.PlayerData.metadata.thirst = thirst

                -- Sincronizar con servidor
                TriggerServerEvent('ait:server:updateMetadata', 'hunger', hunger)
                TriggerServerEvent('ait:server:updateMetadata', 'thirst', thirst)

                -- Efectos de hambre/sed baja
                if hunger <= 0 then
                    local health = GetEntityHealth(PlayerPedId())
                    SetEntityHealth(PlayerPedId(), math.max(100, health - 5))
                    AIT.Notify('Estás muriendo de hambre...', 'error')
                elseif hunger <= 20 then
                    AIT.Notify('Tienes mucha hambre', 'warning')
                end

                if thirst <= 0 then
                    local health = GetEntityHealth(PlayerPedId())
                    SetEntityHealth(PlayerPedId(), math.max(100, health - 5))
                    AIT.Notify('Estás muriendo de sed...', 'error')
                elseif thirst <= 20 then
                    AIT.Notify('Tienes mucha sed', 'warning')
                end
            end
        end
    end)

    print('[AIT-QB] HUD inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- ACTUALIZACIÓN DE DATOS
-- ═══════════════════════════════════════════════════════════════

function AIT.HUD.Update()
    local ped = PlayerPedId()

    -- Salud y armadura
    hudData.health = GetEntityHealth(ped) - 100
    hudData.armor = GetPedArmour(ped)

    -- Oxígeno
    hudData.oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10

    -- Stamina
    hudData.stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())

    -- Datos del jugador
    if AIT.PlayerData then
        if AIT.PlayerData.money then
            hudData.cash = AIT.PlayerData.money.cash or 0
            hudData.bank = AIT.PlayerData.money.bank or 0
        end

        if AIT.PlayerData.job then
            hudData.job = AIT.PlayerData.job.label or 'Desempleado'
            hudData.jobGrade = AIT.PlayerData.job.gradeName or ''
        end

        if AIT.PlayerData.metadata then
            hudData.hunger = AIT.PlayerData.metadata.hunger or 100
            hudData.thirst = AIT.PlayerData.metadata.thirst or 100
            hudData.stress = AIT.PlayerData.metadata.stress or 0
        end
    end

    AIT.HUD.SendUpdate()
end

function AIT.HUD.UpdateVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle and vehicle ~= 0 then
        hudData.isInVehicle = true

        -- Velocidad (km/h)
        local speed = GetEntitySpeed(vehicle) * 3.6
        hudData.speed = math.floor(speed)

        -- Combustible (si ox_fuel o similar)
        hudData.fuel = GetVehicleFuelLevel(vehicle) or 100

        -- Marcha
        hudData.gear = GetVehicleCurrentGear(vehicle)

        -- RPM
        hudData.rpm = GetVehicleCurrentRpm(vehicle) * 100

        AIT.HUD.SendUpdate()
    end
end

function AIT.HUD.SendUpdate()
    SendNUIMessage({
        action = 'updateHUD',
        data = hudData
    })
end

-- ═══════════════════════════════════════════════════════════════
-- CONTROL DEL HUD
-- ═══════════════════════════════════════════════════════════════

function AIT.HUD.Show()
    hudEnabled = true
    SendNUIMessage({ action = 'showHUD' })
end

function AIT.HUD.Hide()
    hudEnabled = false
    SendNUIMessage({ action = 'hideHUD' })
end

function AIT.HUD.Toggle()
    hudEnabled = not hudEnabled
    if hudEnabled then
        AIT.HUD.Show()
    else
        AIT.HUD.Hide()
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CINTURÓN DE SEGURIDAD
-- ═══════════════════════════════════════════════════════════════

local seatbeltOn = false

function AIT.HUD.ToggleSeatbelt()
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        return
    end

    seatbeltOn = not seatbeltOn
    hudData.seatbelt = seatbeltOn

    if seatbeltOn then
        AIT.Notify('Te has puesto el cinturón de seguridad', 'success')
        PlaySound(-1, 'Put_On_Seatbelt', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', false, 0, true)
    else
        AIT.Notify('Te has quitado el cinturón de seguridad', 'info')
    end

    AIT.HUD.SendUpdate()
end

function AIT.HUD.IsSeatbeltOn()
    return seatbeltOn
end

-- Daño por no llevar cinturón
CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and not seatbeltOn then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(vehicle) * 3.6

            -- Si hay colisión fuerte sin cinturón
            if HasEntityCollidedWithAnything(vehicle) and speed > 60 then
                local damage = math.floor((speed - 60) / 2)
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, math.max(100, health - damage))

                -- Eyectar del vehículo si la velocidad es muy alta
                if speed > 100 and math.random(1, 100) <= 50 then
                    SetEntityCoords(ped, GetEntityCoords(vehicle) + vector3(math.random(-3, 3), math.random(-3, 3), 1.0))
                    SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)
                    AIT.Notify('Has salido despedido del vehículo', 'error')
                end
            end
        else
            Wait(500)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INDICADORES DE ZONA
-- ═══════════════════════════════════════════════════════════════

function AIT.HUD.ShowAreaName(name, subtitle)
    SendNUIMessage({
        action = 'showArea',
        name = name,
        subtitle = subtitle or ''
    })
end

-- ═══════════════════════════════════════════════════════════════
-- BRÚJULA
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(100)

        if hudEnabled and hudData.isInVehicle then
            local heading = GetEntityHeading(PlayerPedId())
            SendNUIMessage({
                action = 'updateCompass',
                heading = heading
            })
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════════════════════════

RegisterKeyMapping('togglehud', 'Mostrar/Ocultar HUD', 'keyboard', 'F7')
RegisterKeyMapping('seatbelt', 'Cinturón de seguridad', 'keyboard', 'B')

RegisterCommand('togglehud', function()
    AIT.HUD.Toggle()
end, false)

RegisterCommand('seatbelt', function()
    AIT.HUD.ToggleSeatbelt()
end, false)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('ShowHUD', AIT.HUD.Show)
exports('HideHUD', AIT.HUD.Hide)
exports('ToggleHUD', AIT.HUD.Toggle)
exports('IsSeatbeltOn', AIT.HUD.IsSeatbeltOn)

return AIT.HUD
