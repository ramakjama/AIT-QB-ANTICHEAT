--[[
    AIT-QB: Trabajo de EMS/Ambulancia
    Sistema médico completo
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Ambulance = {}

local onDuty = false

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    jobName = 'ambulance',
    dutyLocations = {
        { coords = vector3(311.0, -593.0, 43.3), heading = 70.0, label = 'Pillbox Hill' },
        { coords = vector3(-247.0, 6331.0, 32.4), heading = 225.0, label = 'Paleto Bay' },
        { coords = vector3(1839.0, 3672.0, 34.2), heading = 210.0, label = 'Sandy Shores' },
    },
    garages = {
        { coords = vector3(325.0, -574.0, 28.8), spawn = vector4(335.0, -580.0, 28.5, 160.0), label = 'Garaje Pillbox' },
    },
    vehicles = {
        { model = 'ambulance', label = 'Ambulancia', grade = 0 },
        { model = 'lguard', label = 'Vehículo Socorrista', grade = 0 },
    },
    items = {
        { item = 'bandage', label = 'Vendas', price = 50, effect = 'heal_small' },
        { item = 'firstaid', label = 'Kit Primeros Auxilios', price = 100, effect = 'heal_medium' },
        { item = 'medikit', label = 'Kit Médico', price = 250, effect = 'heal_full' },
        { item = 'painkillers', label = 'Analgésicos', price = 75, effect = 'pain_relief' },
    },
    revivePrice = 500,
    healPrice = 100,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Ambulance.Init()
    -- Crear blips
    for _, loc in ipairs(Config.dutyLocations) do
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, 61)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Hospital - ' .. loc.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Registrar interacciones
    AIT.Jobs.Ambulance.RegisterInteractions()

    print('[AIT-QB] Job de EMS inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- SERVICIO (DUTY)
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Ambulance.ToggleDuty()
    if not AIT.Jobs.Ambulance.IsEMS() then
        AIT.Notify('No eres paramédico', 'error')
        return
    end

    onDuty = not onDuty

    if onDuty then
        AIT.Notify('Has entrado de servicio', 'success')
        AIT.Jobs.Ambulance.SetUniform()
        TriggerServerEvent('ait:server:job:setDuty', Config.jobName, true)
    else
        AIT.Notify('Has salido de servicio', 'info')
        AIT.Jobs.Ambulance.RemoveUniform()
        TriggerServerEvent('ait:server:job:setDuty', Config.jobName, false)
    end
end

function AIT.Jobs.Ambulance.IsEMS()
    return AIT.PlayerData and AIT.PlayerData.job and AIT.PlayerData.job.name == Config.jobName
end

function AIT.Jobs.Ambulance.IsOnDuty()
    return onDuty
end

function AIT.Jobs.Ambulance.GetGrade()
    if AIT.PlayerData and AIT.PlayerData.job then
        return AIT.PlayerData.job.grade or 0
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════════
-- UNIFORME
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Ambulance.SetUniform()
    local ped = PlayerPedId()
    local gender = AIT.PlayerData and AIT.PlayerData.gender or 'male'

    if gender == 'male' then
        SetPedComponentVariation(ped, 0, 0, 0, 2)
        SetPedComponentVariation(ped, 1, 0, 0, 2)
        SetPedComponentVariation(ped, 3, 0, 0, 2)
        SetPedComponentVariation(ped, 4, 35, 0, 2)
        SetPedComponentVariation(ped, 5, 0, 0, 2)
        SetPedComponentVariation(ped, 6, 24, 0, 2)
        SetPedComponentVariation(ped, 7, 0, 0, 2)
        SetPedComponentVariation(ped, 8, 59, 0, 2)
        SetPedComponentVariation(ped, 9, 0, 0, 2)
        SetPedComponentVariation(ped, 10, 0, 0, 2)
        SetPedComponentVariation(ped, 11, 250, 0, 2)
    else
        SetPedComponentVariation(ped, 0, 0, 0, 2)
        SetPedComponentVariation(ped, 1, 0, 0, 2)
        SetPedComponentVariation(ped, 3, 0, 0, 2)
        SetPedComponentVariation(ped, 4, 34, 0, 2)
        SetPedComponentVariation(ped, 5, 0, 0, 2)
        SetPedComponentVariation(ped, 6, 24, 0, 2)
        SetPedComponentVariation(ped, 7, 0, 0, 2)
        SetPedComponentVariation(ped, 8, 44, 0, 2)
        SetPedComponentVariation(ped, 9, 0, 0, 2)
        SetPedComponentVariation(ped, 10, 0, 0, 2)
        SetPedComponentVariation(ped, 11, 258, 0, 2)
    end
end

function AIT.Jobs.Ambulance.RemoveUniform()
    if AIT.PlayerData and AIT.PlayerData.skin then
        TriggerEvent('ait:client:character:applyAppearance', AIT.PlayerData.skin)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ACCIONES MÉDICAS
-- ═══════════════════════════════════════════════════════════════

-- Revivir jugador
function AIT.Jobs.Ambulance.Revive(targetId)
    if not AIT.Jobs.Ambulance.IsOnDuty() then
        AIT.Notify('Debes estar de servicio', 'error')
        return
    end

    -- Animación de reanimación
    local ped = PlayerPedId()
    local dict = 'mini@cpr@char_a@cpr_str'

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    -- Progress bar
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 15000,
            label = 'Reanimando paciente...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = dict,
                clip = 'cpr_pumpchest'
            },
        }) then
            TriggerServerEvent('ait:server:ambulance:revive', targetId)
            AIT.Notify('Paciente reanimado', 'success')
        else
            AIT.Notify('Reanimación cancelada', 'error')
        end
    else
        -- Fallback
        TaskPlayAnim(ped, dict, 'cpr_pumpchest', 8.0, -8.0, 15000, 1, 0, false, false, false)
        Wait(15000)
        ClearPedTasks(ped)
        TriggerServerEvent('ait:server:ambulance:revive', targetId)
        AIT.Notify('Paciente reanimado', 'success')
    end
end

-- Curar jugador
function AIT.Jobs.Ambulance.Heal(targetId)
    if not AIT.Jobs.Ambulance.IsOnDuty() then
        AIT.Notify('Debes estar de servicio', 'error')
        return
    end

    local dict = 'mini@cpr@char_a@cpr_str'

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 8000,
            label = 'Tratando paciente...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = dict,
                clip = 'cpr_pumpchest'
            },
        }) then
            TriggerServerEvent('ait:server:ambulance:heal', targetId)
            AIT.Notify('Paciente curado', 'success')
        end
    end
end

-- Camilla
function AIT.Jobs.Ambulance.ToggleStretcher(targetId)
    if not AIT.Jobs.Ambulance.IsOnDuty() then return end

    TriggerServerEvent('ait:server:ambulance:stretcher', targetId)
end

RegisterNetEvent('ait:client:ambulance:putOnStretcher', function()
    local ped = PlayerPedId()

    -- Animación de estar en camilla
    local dict = 'anim@gangops@morgue@table@'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    TaskPlayAnim(ped, dict, 'body_search', 8.0, -8.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(ped, true)

    AIT.Notify('Estás en una camilla', 'info')
end)

RegisterNetEvent('ait:client:ambulance:removeFromStretcher', function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    AIT.Notify('Te han bajado de la camilla', 'info')
end)

-- ═══════════════════════════════════════════════════════════════
-- FARMACIA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Ambulance.OpenPharmacy()
    local options = {}

    for _, item in ipairs(Config.items) do
        table.insert(options, {
            title = item.label,
            description = '$' .. item.price,
            icon = 'pills',
            onSelect = function()
                TriggerServerEvent('ait:server:ambulance:buyItem', item.item, item.price)
            end
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'ems_pharmacy',
            title = 'Farmacia Hospital',
            options = options
        })
        lib.showContext('ems_pharmacy')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FACTURACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Ambulance.BillPatient(targetId, amount, reason)
    if not AIT.Jobs.Ambulance.IsOnDuty() then return end

    TriggerServerEvent('ait:server:ambulance:bill', targetId, amount, reason)
end

-- ═══════════════════════════════════════════════════════════════
-- REGISTRO DE INTERACCIONES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Ambulance.RegisterInteractions()
    -- Puntos de servicio
    for i, loc in ipairs(Config.dutyLocations) do
        if AIT.Interactions then
            AIT.Interactions.AddTarget('ems_duty_' .. i, {
                coords = loc.coords,
                label = 'Fichar',
                icon = 'clipboard-check',
                distance = 2.0,
                canInteract = function()
                    return AIT.Jobs.Ambulance.IsEMS()
                end,
                onSelect = function()
                    AIT.Jobs.Ambulance.ToggleDuty()
                end
            })
        end
    end

    -- Farmacia
    if AIT.Interactions then
        AIT.Interactions.AddTarget('hospital_pharmacy', {
            coords = vector3(308.0, -595.0, 43.3),
            label = 'Farmacia',
            icon = 'prescription-bottle',
            distance = 2.0,
            onSelect = function()
                AIT.Jobs.Ambulance.OpenPharmacy()
            end
        })
    end

    -- Cama de hospital (NPC o zona)
    if AIT.Interactions then
        AIT.Interactions.AddTarget('hospital_bed', {
            coords = vector3(311.0, -582.0, 43.3),
            label = 'Cama Hospital',
            icon = 'bed',
            distance = 2.0,
            canInteract = function()
                return AIT.PlayerData and AIT.PlayerData.metadata and AIT.PlayerData.metadata.isDead
            end,
            onSelect = function()
                -- Respawn en hospital (con coste)
                TriggerServerEvent('ait:server:ambulance:respawn', Config.revivePrice)
            end
        })
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:ambulance:revived', function()
    local ped = PlayerPedId()

    -- Restaurar estado
    SetEntityHealth(ped, 200)
    SetEntityInvincible(ped, false)
    ClearPedTasks(ped)

    if AIT.PlayerData and AIT.PlayerData.metadata then
        AIT.PlayerData.metadata.isDead = false
    end

    AIT.Notify('Has sido reanimado', 'success')

    -- Efectos post-reanimación (debilidad temporal)
    SetRunSprintMultiplierForPlayer(PlayerId(), 0.5)
    Wait(30000)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)

RegisterNetEvent('ait:client:ambulance:healed', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)

    if AIT.PlayerData and AIT.PlayerData.metadata then
        AIT.PlayerData.metadata.health = 200
    end

    AIT.Notify('Te han curado completamente', 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('revive', function(source, args)
    if not AIT.Jobs.Ambulance.IsOnDuty() then return end

    local targetId = tonumber(args[1])
    if targetId then
        AIT.Jobs.Ambulance.Revive(targetId)
    else
        local closestPlayer = AIT.GetClosestPlayer(3.0)
        if closestPlayer then
            AIT.Jobs.Ambulance.Revive(GetPlayerServerId(closestPlayer))
        end
    end
end, false)

RegisterCommand('heal', function(source, args)
    if not AIT.Jobs.Ambulance.IsOnDuty() then return end

    local targetId = tonumber(args[1])
    if targetId then
        AIT.Jobs.Ambulance.Heal(targetId)
    else
        local closestPlayer = AIT.GetClosestPlayer(3.0)
        if closestPlayer then
            AIT.Jobs.Ambulance.Heal(GetPlayerServerId(closestPlayer))
        end
    end
end, false)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsEMS', AIT.Jobs.Ambulance.IsEMS)
exports('IsEMSOnDuty', AIT.Jobs.Ambulance.IsOnDuty)

return AIT.Jobs.Ambulance
