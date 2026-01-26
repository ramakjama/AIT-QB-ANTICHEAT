--[[
    AIT-QB: Trabajo de Policía
    Sistema completo de LSPD
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Police = {}

local onDuty = false
local currentLoadout = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    jobName = 'police',
    dutyLocations = {
        { coords = vector3(441.7, -982.0, 30.7), heading = 180.0, label = 'MRPD' },
        { coords = vector3(1853.0, 3686.0, 34.2), heading = 210.0, label = 'Sandy Shores' },
        { coords = vector3(-449.0, 6012.0, 31.7), heading = 45.0, label = 'Paleto Bay' },
    },
    armories = {
        { coords = vector3(452.0, -980.0, 30.7), label = 'Armería MRPD' },
    },
    garages = {
        { coords = vector3(454.5, -1017.5, 28.5), spawn = vector4(440.0, -1025.0, 28.5, 180.0), label = 'Garaje MRPD' },
    },
    vehicles = {
        { model = 'police', label = 'Patrulla', grade = 0 },
        { model = 'police2', label = 'Buffalo', grade = 1 },
        { model = 'police3', label = 'Interceptor', grade = 2 },
        { model = 'police4', label = 'Sin marcas', grade = 3 },
        { model = 'policeb', label = 'Moto', grade = 1 },
        { model = 'riot', label = 'Antidisturbios', grade = 4 },
    },
    loadouts = {
        [0] = { -- Cadete
            { weapon = 'WEAPON_STUNGUN', ammo = 0 },
            { weapon = 'WEAPON_NIGHTSTICK', ammo = 0 },
            { weapon = 'WEAPON_FLASHLIGHT', ammo = 0 },
        },
        [1] = { -- Oficial
            { weapon = 'WEAPON_COMBATPISTOL', ammo = 60 },
            { weapon = 'WEAPON_STUNGUN', ammo = 0 },
            { weapon = 'WEAPON_NIGHTSTICK', ammo = 0 },
            { weapon = 'WEAPON_FLASHLIGHT', ammo = 0 },
        },
        [2] = { -- Sargento
            { weapon = 'WEAPON_COMBATPISTOL', ammo = 90 },
            { weapon = 'WEAPON_PUMPSHOTGUN', ammo = 30 },
            { weapon = 'WEAPON_STUNGUN', ammo = 0 },
            { weapon = 'WEAPON_NIGHTSTICK', ammo = 0 },
        },
        [3] = { -- Teniente+
            { weapon = 'WEAPON_COMBATPISTOL', ammo = 120 },
            { weapon = 'WEAPON_CARBINERIFLE', ammo = 120 },
            { weapon = 'WEAPON_PUMPSHOTGUN', ammo = 40 },
            { weapon = 'WEAPON_STUNGUN', ammo = 0 },
        },
    }
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.Init()
    -- Crear blips
    for _, loc in ipairs(Config.dutyLocations) do
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, 60)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 29)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Comisaría - ' .. loc.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Registrar interacciones
    AIT.Jobs.Police.RegisterInteractions()

    print('[AIT-QB] Job de policía inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SERVICIO (DUTY)
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.ToggleDuty()
    if not AIT.Jobs.Police.IsPolice() then
        AIT.Notify('No eres policía', 'error')
        return
    end

    onDuty = not onDuty

    if onDuty then
        AIT.Notify('Has entrado de servicio', 'success')
        AIT.Jobs.Police.SetUniform()
        TriggerServerEvent('ait:server:job:setDuty', Config.jobName, true)
    else
        AIT.Notify('Has salido de servicio', 'info')
        AIT.Jobs.Police.RemoveUniform()
        AIT.Jobs.Police.RemoveLoadout()
        TriggerServerEvent('ait:server:job:setDuty', Config.jobName, false)
    end
end

function AIT.Jobs.Police.IsPolice()
    return AIT.PlayerData and AIT.PlayerData.job and AIT.PlayerData.job.name == Config.jobName
end

function AIT.Jobs.Police.IsOnDuty()
    return onDuty
end

function AIT.Jobs.Police.GetGrade()
    if AIT.PlayerData and AIT.PlayerData.job then
        return AIT.PlayerData.job.grade or 0
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════════
-- UNIFORME
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.SetUniform()
    local ped = PlayerPedId()
    local gender = AIT.PlayerData and AIT.PlayerData.gender or 'male'

    if gender == 'male' then
        SetPedComponentVariation(ped, 0, 0, 0, 2)    -- Cara
        SetPedComponentVariation(ped, 1, 0, 0, 2)    -- Máscara
        SetPedComponentVariation(ped, 2, 0, 0, 2)    -- Pelo
        SetPedComponentVariation(ped, 3, 0, 0, 2)    -- Torso
        SetPedComponentVariation(ped, 4, 35, 0, 2)   -- Piernas
        SetPedComponentVariation(ped, 5, 0, 0, 2)    -- Bolsas
        SetPedComponentVariation(ped, 6, 24, 0, 2)   -- Zapatos
        SetPedComponentVariation(ped, 7, 0, 0, 2)    -- Accesorios
        SetPedComponentVariation(ped, 8, 58, 0, 2)   -- Camiseta
        SetPedComponentVariation(ped, 9, 0, 0, 2)    -- Chaleco
        SetPedComponentVariation(ped, 10, 0, 0, 2)   -- Calcomanías
        SetPedComponentVariation(ped, 11, 55, 0, 2)  -- Chaqueta
    else
        SetPedComponentVariation(ped, 0, 0, 0, 2)
        SetPedComponentVariation(ped, 1, 0, 0, 2)
        SetPedComponentVariation(ped, 2, 0, 0, 2)
        SetPedComponentVariation(ped, 3, 0, 0, 2)
        SetPedComponentVariation(ped, 4, 34, 0, 2)
        SetPedComponentVariation(ped, 5, 0, 0, 2)
        SetPedComponentVariation(ped, 6, 24, 0, 2)
        SetPedComponentVariation(ped, 7, 0, 0, 2)
        SetPedComponentVariation(ped, 8, 35, 0, 2)
        SetPedComponentVariation(ped, 9, 0, 0, 2)
        SetPedComponentVariation(ped, 10, 0, 0, 2)
        SetPedComponentVariation(ped, 11, 48, 0, 2)
    end
end

function AIT.Jobs.Police.RemoveUniform()
    -- Restaurar ropa guardada
    if AIT.PlayerData and AIT.PlayerData.skin then
        -- Aplicar skin guardado
        TriggerEvent('ait:client:character:applyAppearance', AIT.PlayerData.skin)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ARMERÍA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.OpenArmory()
    if not AIT.Jobs.Police.IsOnDuty() then
        AIT.Notify('Debes estar de servicio', 'error')
        return
    end

    local grade = AIT.Jobs.Police.GetGrade()
    local loadoutIndex = math.min(grade, 3)
    local loadout = Config.loadouts[loadoutIndex]

    local options = {
        {
            title = 'Recoger equipamiento',
            icon = 'gun',
            onSelect = function()
                AIT.Jobs.Police.GiveLoadout(loadout)
            end
        },
        {
            title = 'Devolver equipamiento',
            icon = 'box',
            onSelect = function()
                AIT.Jobs.Police.RemoveLoadout()
            end
        },
        {
            title = 'Chaleco antibalas',
            icon = 'shield',
            onSelect = function()
                SetPedArmour(PlayerPedId(), 100)
                AIT.Notify('Chaleco equipado', 'success')
            end
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'police_armory',
            title = 'Armería Policial',
            options = options
        })
        lib.showContext('police_armory')
    end
end

function AIT.Jobs.Police.GiveLoadout(loadout)
    local ped = PlayerPedId()

    for _, item in ipairs(loadout) do
        local hash = GetHashKey(item.weapon)
        GiveWeaponToPed(ped, hash, item.ammo, false, false)
    end

    currentLoadout = loadout
    AIT.Notify('Equipamiento recogido', 'success')
end

function AIT.Jobs.Police.RemoveLoadout()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    currentLoadout = {}
    AIT.Notify('Equipamiento devuelto', 'info')
end

-- ═══════════════════════════════════════════════════════════════
-- ACCIONES POLICIALES
-- ═══════════════════════════════════════════════════════════════

-- Esposar
function AIT.Jobs.Police.Cuff(targetId)
    if not AIT.Jobs.Police.IsOnDuty() then
        AIT.Notify('Debes estar de servicio', 'error')
        return
    end

    TriggerServerEvent('ait:server:police:cuff', targetId)
end

RegisterNetEvent('ait:client:police:getCuffed', function(cufferId)
    local ped = PlayerPedId()

    -- Animación de esposas
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do Wait(10) end

    TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    SetEnableHandcuffs(ped, true)
    DisablePlayerFiring(PlayerId(), true)

    AIT.Notify('Has sido esposado', 'info')

    if AIT.PlayerData then
        AIT.PlayerData.metadata.isHandcuffed = true
    end
end)

RegisterNetEvent('ait:client:police:getUncuffed', function()
    local ped = PlayerPedId()

    ClearPedTasks(ped)
    SetEnableHandcuffs(ped, false)
    DisablePlayerFiring(PlayerId(), false)

    AIT.Notify('Te han quitado las esposas', 'success')

    if AIT.PlayerData then
        AIT.PlayerData.metadata.isHandcuffed = false
    end
end)

-- Cachear
function AIT.Jobs.Police.Search(targetId)
    if not AIT.Jobs.Police.IsOnDuty() then return end

    TriggerServerEvent('ait:server:police:search', targetId)
end

-- Escoltar
function AIT.Jobs.Police.Escort(targetId)
    if not AIT.Jobs.Police.IsOnDuty() then return end

    TriggerServerEvent('ait:server:police:escort', targetId)
end

RegisterNetEvent('ait:client:police:getEscorted', function(officerId)
    local ped = PlayerPedId()
    local officerPed = GetPlayerPed(GetPlayerFromServerId(officerId))

    AttachEntityToEntity(ped, officerPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    AIT.Notify('Estás siendo escoltado', 'info')
end)

RegisterNetEvent('ait:client:police:stopEscort', function()
    local ped = PlayerPedId()
    DetachEntity(ped, true, false)
    AIT.Notify('Ya no estás siendo escoltado', 'info')
end)

-- Meter en vehículo
function AIT.Jobs.Police.PutInVehicle(targetId)
    if not AIT.Jobs.Police.IsOnDuty() then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        vehicle = AIT.Vehicles.GetClosestVehicle(5.0)
    end

    if vehicle then
        TriggerServerEvent('ait:server:police:putInVehicle', targetId, VehToNet(vehicle))
    else
        AIT.Notify('No hay vehículo cerca', 'error')
    end
end

RegisterNetEvent('ait:client:police:putInVehicle', function(netId)
    local vehicle = NetToVeh(netId)
    local ped = PlayerPedId()

    if DoesEntityExist(vehicle) then
        local seat = GetVehicleMaxNumberOfPassengers(vehicle) - 1
        TaskWarpPedIntoVehicle(ped, vehicle, seat)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MULTAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.Fine(targetId, amount, reason)
    if not AIT.Jobs.Police.IsOnDuty() then return end

    TriggerServerEvent('ait:server:police:fine', targetId, amount, reason)
end

-- ═══════════════════════════════════════════════════════════════
-- MDT (Terminal de Datos)
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.OpenMDT()
    if not AIT.Jobs.Police.IsOnDuty() then
        AIT.Notify('Debes estar de servicio', 'error')
        return
    end

    SendNUIMessage({
        action = 'openMDT',
    })
    SetNuiFocus(true, true)
end

-- ═══════════════════════════════════════════════════════════════
-- INTERACCIONES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Police.RegisterInteractions()
    -- Puntos de servicio
    for i, loc in ipairs(Config.dutyLocations) do
        if AIT.Interactions then
            AIT.Interactions.AddTarget('police_duty_' .. i, {
                coords = loc.coords,
                label = 'Fichar',
                icon = 'clipboard-check',
                distance = 2.0,
                canInteract = function()
                    return AIT.Jobs.Police.IsPolice()
                end,
                onSelect = function()
                    AIT.Jobs.Police.ToggleDuty()
                end
            })
        end
    end

    -- Armerías
    for i, loc in ipairs(Config.armories) do
        if AIT.Interactions then
            AIT.Interactions.AddTarget('police_armory_' .. i, {
                coords = loc.coords,
                label = 'Armería',
                icon = 'gun',
                distance = 2.0,
                canInteract = function()
                    return AIT.Jobs.Police.IsPolice() and AIT.Jobs.Police.IsOnDuty()
                end,
                onSelect = function()
                    AIT.Jobs.Police.OpenArmory()
                end
            })
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('cuff', function(source, args)
    if not AIT.Jobs.Police.IsOnDuty() then return end

    local targetId = tonumber(args[1])
    if targetId then
        AIT.Jobs.Police.Cuff(targetId)
    else
        -- Buscar jugador más cercano
        local closestPlayer = AIT.GetClosestPlayer(3.0)
        if closestPlayer then
            AIT.Jobs.Police.Cuff(GetPlayerServerId(closestPlayer))
        end
    end
end, false)

RegisterCommand('escort', function(source, args)
    if not AIT.Jobs.Police.IsOnDuty() then return end

    local targetId = tonumber(args[1])
    if targetId then
        AIT.Jobs.Police.Escort(targetId)
    else
        local closestPlayer = AIT.GetClosestPlayer(3.0)
        if closestPlayer then
            AIT.Jobs.Police.Escort(GetPlayerServerId(closestPlayer))
        end
    end
end, false)

RegisterCommand('mdt', function()
    AIT.Jobs.Police.OpenMDT()
end, false)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsPolice', AIT.Jobs.Police.IsPolice)
exports('IsPoliceOnDuty', AIT.Jobs.Police.IsOnDuty)

return AIT.Jobs.Police
