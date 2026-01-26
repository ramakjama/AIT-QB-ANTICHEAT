--[[
    AIT-QB: Sistema de Interacciones
    Target system y zonas interactivas
    Servidor Español
]]

AIT = AIT or {}
AIT.Interactions = {}

local activeTargets = {}
local activeZones = {}
local interactionDistance = 2.5

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.Init()
    -- Thread de detección de interacciones
    CreateThread(function()
        while true do
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local closestEntity, closestDist = AIT.Interactions.GetClosestInteractable(coords)

            if closestEntity and closestDist <= interactionDistance then
                -- Mostrar prompt de interacción
                AIT.Interactions.ShowPrompt(closestEntity)

                -- Detectar tecla E
                if IsControlJustPressed(0, 38) then -- E
                    AIT.Interactions.Execute(closestEntity)
                end
            else
                Wait(200) -- Reducir CPU cuando no hay nada cerca
            end
        end
    end)

    -- Registrar interacciones predeterminadas
    AIT.Interactions.RegisterDefaults()

    print('[AIT-QB] Sistema de interacciones inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- REGISTRO DE TARGETS
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.AddTarget(id, options)
    activeTargets[id] = {
        id = id,
        label = options.label or 'Interactuar',
        icon = options.icon or 'hand',
        coords = options.coords,
        entity = options.entity,
        model = options.model,
        bone = options.bone,
        distance = options.distance or interactionDistance,
        canInteract = options.canInteract,
        onSelect = options.onSelect,
        options = options.options or {},
    }

    return id
end

function AIT.Interactions.RemoveTarget(id)
    activeTargets[id] = nil
end

-- ═══════════════════════════════════════════════════════════════
-- REGISTRO DE ZONAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.AddZone(id, options)
    activeZones[id] = {
        id = id,
        label = options.label or 'Zona',
        coords = options.coords,
        size = options.size or vector3(2.0, 2.0, 2.0),
        rotation = options.rotation or 0.0,
        debug = options.debug or false,
        onEnter = options.onEnter,
        onExit = options.onExit,
        inside = false,
        options = options.options or {},
    }

    -- Thread para detectar entrada/salida
    CreateThread(function()
        local zone = activeZones[id]
        if not zone then return end

        while activeZones[id] do
            Wait(500)

            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - zone.coords)

            if dist <= zone.size.x then
                if not zone.inside then
                    zone.inside = true
                    if zone.onEnter then
                        zone.onEnter(zone)
                    end
                end
            else
                if zone.inside then
                    zone.inside = false
                    if zone.onExit then
                        zone.onExit(zone)
                    end
                end
            end
        end
    end)

    return id
end

function AIT.Interactions.RemoveZone(id)
    activeZones[id] = nil
end

-- ═══════════════════════════════════════════════════════════════
-- DETECCIÓN DE INTERACCIONES
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.GetClosestInteractable(coords)
    local closest = nil
    local closestDist = math.huge

    -- Revisar targets por coordenadas
    for id, target in pairs(activeTargets) do
        if target.coords then
            local dist = #(coords - target.coords)
            if dist < closestDist and dist <= target.distance then
                if not target.canInteract or target.canInteract() then
                    closest = target
                    closestDist = dist
                end
            end
        end
    end

    -- Revisar targets por entidad
    for id, target in pairs(activeTargets) do
        if target.entity and DoesEntityExist(target.entity) then
            local entityCoords = GetEntityCoords(target.entity)
            local dist = #(coords - entityCoords)
            if dist < closestDist and dist <= target.distance then
                if not target.canInteract or target.canInteract() then
                    closest = target
                    closestDist = dist
                end
            end
        end
    end

    -- Revisar targets por modelo (NPCs, objetos)
    local handle, entity = FindFirstPed()
    local found = true
    while found do
        if entity ~= PlayerPedId() then
            local model = GetEntityModel(entity)
            for id, target in pairs(activeTargets) do
                if target.model and GetHashKey(target.model) == model then
                    local entityCoords = GetEntityCoords(entity)
                    local dist = #(coords - entityCoords)
                    if dist < closestDist and dist <= target.distance then
                        if not target.canInteract or target.canInteract(entity) then
                            target._entity = entity
                            closest = target
                            closestDist = dist
                        end
                    end
                end
            end
        end
        found, entity = FindNextPed(handle)
    end
    EndFindPed(handle)

    return closest, closestDist
end

-- ═══════════════════════════════════════════════════════════════
-- MOSTRAR PROMPT
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.ShowPrompt(target)
    -- Draw 3D text o NUI
    local coords = target.coords or (target._entity and GetEntityCoords(target._entity))

    if coords then
        DrawText3D(coords.x, coords.y, coords.z + 1.0, '[E] ' .. target.label)
    end
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)

    local factor = #text / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 100)

    ClearDrawOrigin()
end

-- ═══════════════════════════════════════════════════════════════
-- EJECUTAR INTERACCIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.Execute(target)
    if #target.options > 1 then
        -- Mostrar menú de opciones
        AIT.Interactions.ShowMenu(target)
    elseif #target.options == 1 then
        -- Ejecutar única opción
        target.options[1].onSelect(target._entity or target.entity)
    elseif target.onSelect then
        -- Ejecutar callback directo
        target.onSelect(target._entity or target.entity)
    end
end

function AIT.Interactions.ShowMenu(target)
    local menuOptions = {}

    for _, opt in ipairs(target.options) do
        table.insert(menuOptions, {
            title = opt.label or opt.title,
            icon = opt.icon,
            onSelect = function()
                opt.onSelect(target._entity or target.entity)
            end
        })
    end

    -- Usar ox_lib si está disponible
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'interaction_menu',
            title = target.label,
            options = menuOptions
        })
        lib.showContext('interaction_menu')
    else
        -- Fallback a NUI propio
        SendNUIMessage({
            action = 'showInteractionMenu',
            title = target.label,
            options = menuOptions
        })
        SetNuiFocus(true, true)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INTERACCIONES PREDETERMINADAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Interactions.RegisterDefaults()
    -- ATMs
    local atmModels = {
        'prop_atm_01', 'prop_atm_02', 'prop_atm_03', 'prop_fleeca_atm'
    }

    for _, model in ipairs(atmModels) do
        AIT.Interactions.AddTarget('atm_' .. model, {
            model = model,
            label = 'Cajero Automático',
            icon = 'money-bill',
            distance = 1.5,
            options = {
                {
                    label = 'Retirar dinero',
                    icon = 'arrow-down',
                    onSelect = function()
                        TriggerEvent('ait:client:atm:withdraw')
                    end
                },
                {
                    label = 'Depositar dinero',
                    icon = 'arrow-up',
                    onSelect = function()
                        TriggerEvent('ait:client:atm:deposit')
                    end
                },
                {
                    label = 'Ver saldo',
                    icon = 'eye',
                    onSelect = function()
                        TriggerEvent('ait:client:atm:balance')
                    end
                },
            }
        })
    end

    -- Vehículos
    AIT.Interactions.AddVehicleInteractions()

    -- NPCs de tiendas
    AIT.Interactions.AddShopNPCs()
end

function AIT.Interactions.AddVehicleInteractions()
    CreateThread(function()
        while true do
            Wait(500)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)

            if vehicle and vehicle ~= 0 and not IsPedInAnyVehicle(ped, false) then
                local vehCoords = GetEntityCoords(vehicle)
                local dist = #(coords - vehCoords)

                if dist <= 3.0 then
                    -- Mostrar opciones de vehículo
                    Wait(0)
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.0, '[E] Vehículo')

                    if IsControlJustPressed(0, 38) then
                        AIT.Interactions.ShowVehicleMenu(vehicle)
                    end
                end
            end
        end
    end)
end

function AIT.Interactions.ShowVehicleMenu(vehicle)
    local options = {
        {
            title = 'Abrir/Cerrar',
            icon = 'lock',
            onSelect = function()
                TriggerEvent('ait:client:vehicle:toggleLock', vehicle)
            end
        },
        {
            title = 'Motor',
            icon = 'car',
            onSelect = function()
                TriggerEvent('ait:client:vehicle:toggleEngine', vehicle)
            end
        },
        {
            title = 'Maletero',
            icon = 'box',
            onSelect = function()
                TriggerEvent('ait:client:vehicle:trunk', vehicle)
            end
        },
        {
            title = 'Guantera',
            icon = 'briefcase',
            onSelect = function()
                TriggerEvent('ait:client:vehicle:glovebox', vehicle)
            end
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'vehicle_menu',
            title = 'Vehículo',
            options = options
        })
        lib.showContext('vehicle_menu')
    end
end

function AIT.Interactions.AddShopNPCs()
    -- Los NPCs de tiendas se añaden dinámicamente según la configuración
    -- Esto es un placeholder
end

-- ═══════════════════════════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback('interactionSelect', function(data, cb)
    SetNuiFocus(false, false)

    if data.index and activeMenuOptions and activeMenuOptions[data.index] then
        activeMenuOptions[data.index].onSelect()
    end

    cb('ok')
end)

RegisterNUICallback('closeInteraction', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('AddTarget', AIT.Interactions.AddTarget)
exports('RemoveTarget', AIT.Interactions.RemoveTarget)
exports('AddZone', AIT.Interactions.AddZone)
exports('RemoveZone', AIT.Interactions.RemoveZone)

return AIT.Interactions
