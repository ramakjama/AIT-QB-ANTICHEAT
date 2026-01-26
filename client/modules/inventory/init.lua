--[[
    AIT-QB: Sistema de Inventario UI
    Cliente - Inventario con drag & drop
    Servidor Español
]]

AIT = AIT or {}
AIT.Inventory = {}

local isOpen = false
local playerInventory = {}
local otherInventory = {}
local currentSlot = nil
local isDragging = false

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    maxSlots = 41,
    maxWeight = 120000, -- 120kg
    openKey = 'TAB',
    useKey = 'RETURN',
    dropKey = 'DELETE',

    -- Hotbar
    hotbarSlots = 5,

    -- Tipos de inventario secundario
    inventoryTypes = {
        player = { maxSlots = 41, maxWeight = 120000 },
        trunk = { maxSlots = 50, maxWeight = 200000 },
        glovebox = { maxSlots = 10, maxWeight = 10000 },
        stash = { maxSlots = 100, maxWeight = 500000 },
        drop = { maxSlots = 30, maxWeight = 100000 },
        shop = { maxSlots = 50, maxWeight = 0 },
    },

    -- Categorías de items
    categories = {
        weapons = { label = 'Armas', icon = 'gun' },
        ammo = { label = 'Munición', icon = 'box' },
        food = { label = 'Comida', icon = 'utensils' },
        drinks = { label = 'Bebidas', icon = 'wine-glass' },
        drugs = { label = 'Drogas', icon = 'cannabis' },
        materials = { label = 'Materiales', icon = 'cube' },
        tools = { label = 'Herramientas', icon = 'wrench' },
        misc = { label = 'Otros', icon = 'ellipsis-h' },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Inventory.Init()
    -- Keybinds
    RegisterKeyMapping('inventory', 'Abrir Inventario', 'keyboard', Config.openKey)

    RegisterCommand('inventory', function()
        AIT.Inventory.Toggle()
    end, false)

    -- Hotbar keys
    for i = 1, Config.hotbarSlots do
        RegisterCommand('hotbar' .. i, function()
            AIT.Inventory.UseHotbarSlot(i)
        end, false)
        RegisterKeyMapping('hotbar' .. i, 'Usar Slot ' .. i, 'keyboard', tostring(i))
    end

    print('[AIT-QB] Sistema de inventario inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- TOGGLE INVENTARIO
-- ═══════════════════════════════════════════════════════════════

function AIT.Inventory.Toggle()
    if isOpen then
        AIT.Inventory.Close()
    else
        AIT.Inventory.Open()
    end
end

function AIT.Inventory.Open(otherType, otherId)
    if isOpen then return end
    isOpen = true

    -- Obtener inventario del jugador
    TriggerServerEvent('ait:server:inventory:getPlayerInventory')

    -- Si hay otro inventario
    if otherType and otherId then
        TriggerServerEvent('ait:server:inventory:getOtherInventory', otherType, otherId)
    end

    -- Abrir NUI
    SendNUIMessage({
        action = 'openInventory',
        data = {
            playerInventory = playerInventory,
            otherInventory = otherInventory,
            otherType = otherType,
            maxSlots = Config.maxSlots,
            maxWeight = Config.maxWeight,
            categories = Config.categories,
        }
    })

    SetNuiFocus(true, true)
end

function AIT.Inventory.Close()
    if not isOpen then return end
    isOpen = false

    SendNUIMessage({ action = 'closeInventory' })
    SetNuiFocus(false, false)

    -- Guardar inventario
    TriggerServerEvent('ait:server:inventory:saveInventory', playerInventory)
end

-- ═══════════════════════════════════════════════════════════════
-- RECIBIR INVENTARIO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:inventory:setPlayerInventory', function(inventory, weight)
    playerInventory = inventory

    SendNUIMessage({
        action = 'updatePlayerInventory',
        data = {
            inventory = inventory,
            weight = weight,
            maxWeight = Config.maxWeight,
        }
    })
end)

RegisterNetEvent('ait:client:inventory:setOtherInventory', function(inventory, invType, invId, maxSlots, maxWeight)
    otherInventory = {
        items = inventory,
        type = invType,
        id = invId,
        maxSlots = maxSlots,
        maxWeight = maxWeight,
    }

    SendNUIMessage({
        action = 'updateOtherInventory',
        data = otherInventory,
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback('closeInventory', function(_, cb)
    AIT.Inventory.Close()
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    local fromSlot = data.fromSlot
    local toSlot = data.toSlot
    local fromInventory = data.fromInventory -- 'player' o 'other'
    local toInventory = data.toInventory
    local amount = data.amount or 1

    TriggerServerEvent('ait:server:inventory:moveItem', fromSlot, toSlot, fromInventory, toInventory, amount)
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    local slot = data.slot
    TriggerServerEvent('ait:server:inventory:useItem', slot)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    local slot = data.slot
    local amount = data.amount or 1
    TriggerServerEvent('ait:server:inventory:dropItem', slot, amount)
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    local slot = data.slot
    local amount = data.amount or 1
    local targetId = data.targetId

    if not targetId then
        -- Buscar jugador cercano
        local closestPlayer = AIT.GetClosestPlayer()
        if closestPlayer then
            targetId = GetPlayerServerId(closestPlayer)
        end
    end

    if targetId then
        TriggerServerEvent('ait:server:inventory:giveItem', slot, amount, targetId)
        cb('ok')
    else
        cb('no_player')
    end
end)

RegisterNUICallback('splitItem', function(data, cb)
    local slot = data.slot
    local amount = data.amount

    if amount > 0 then
        TriggerServerEvent('ait:server:inventory:splitItem', slot, amount)
        cb('ok')
    else
        cb('invalid_amount')
    end
end)

RegisterNUICallback('combineItems', function(data, cb)
    local slot1 = data.slot1
    local slot2 = data.slot2

    TriggerServerEvent('ait:server:inventory:combineItems', slot1, slot2)
    cb('ok')
end)

RegisterNUICallback('getItemInfo', function(data, cb)
    local itemName = data.item
    -- Obtener info del item
    local itemInfo = exports['qb-core']:GetItem(itemName)
    cb(itemInfo or {})
end)

-- ═══════════════════════════════════════════════════════════════
-- HOTBAR
-- ═══════════════════════════════════════════════════════════════

function AIT.Inventory.UseHotbarSlot(slot)
    if isOpen then return end -- No usar hotbar con inventario abierto

    local item = playerInventory[slot]
    if item then
        TriggerServerEvent('ait:server:inventory:useItem', slot)
    end
end

-- Actualizar hotbar en pantalla
RegisterNetEvent('ait:client:inventory:updateHotbar', function(hotbarItems)
    SendNUIMessage({
        action = 'updateHotbar',
        data = {
            items = hotbarItems,
        }
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICACIONES DE ITEMS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:inventory:itemAdded', function(item, amount)
    SendNUIMessage({
        action = 'itemNotification',
        data = {
            item = item,
            amount = amount,
            type = 'add',
        }
    })

    -- Sonido
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

RegisterNetEvent('ait:client:inventory:itemRemoved', function(item, amount)
    SendNUIMessage({
        action = 'itemNotification',
        data = {
            item = item,
            amount = amount,
            type = 'remove',
        }
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- ANIMACIONES
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:inventory:playUseAnimation', function(animType)
    local ped = PlayerPedId()
    local dict, anim, duration

    if animType == 'eat' then
        dict = 'mp_player_inteat@burger'
        anim = 'mp_player_int_eat_burger'
        duration = 5000
    elseif animType == 'drink' then
        dict = 'mp_player_intdrink'
        anim = 'loop_bottle'
        duration = 3000
    elseif animType == 'bandage' then
        dict = 'anim@heists@narcotics@funding@gang_idle'
        anim = 'gang_chatting_01'
        duration = 5000
    elseif animType == 'phone' then
        dict = 'cellphone@'
        anim = 'cellphone_call_listen_base'
        duration = 2000
    end

    if dict and anim then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end

        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration, 49, 0, false, false, false)

        Wait(duration)
        ClearPedTasks(ped)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ABRIR INVENTARIOS EXTERNOS
-- ═══════════════════════════════════════════════════════════════

-- Maletero
RegisterNetEvent('ait:client:inventory:openTrunk', function(plate)
    AIT.Inventory.Open('trunk', plate)
end)

-- Guantera
RegisterNetEvent('ait:client:inventory:openGlovebox', function(plate)
    AIT.Inventory.Open('glovebox', plate)
end)

-- Stash
RegisterNetEvent('ait:client:inventory:openStash', function(stashId)
    AIT.Inventory.Open('stash', stashId)
end)

-- Tienda
RegisterNetEvent('ait:client:inventory:openShop', function(shopId, shopItems)
    otherInventory = {
        items = shopItems,
        type = 'shop',
        id = shopId,
        maxSlots = #shopItems,
        maxWeight = 0,
    }

    AIT.Inventory.Open('shop', shopId)
end)

-- Drop
RegisterNetEvent('ait:client:inventory:openDrop', function(dropId)
    AIT.Inventory.Open('drop', dropId)
end)

-- ═══════════════════════════════════════════════════════════════
-- DROPS EN EL SUELO
-- ═══════════════════════════════════════════════════════════════

local drops = {}

RegisterNetEvent('ait:client:inventory:createDrop', function(dropId, coords)
    -- Crear objeto visible
    local model = GetHashKey('prop_cs_box_clothes')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local obj = CreateObject(model, coords.x, coords.y, coords.z - 0.9, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    drops[dropId] = {
        object = obj,
        coords = coords,
    }

    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent('ait:client:inventory:removeDrop', function(dropId)
    if drops[dropId] then
        if drops[dropId].object then
            DeleteObject(drops[dropId].object)
        end
        drops[dropId] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PROGRESBAR PARA ITEMS
-- ═══════════════════════════════════════════════════════════════

function AIT.Inventory.UseItemWithProgress(item, duration, label, anim)
    if lib and lib.progressBar then
        return lib.progressBar({
            duration = duration,
            label = label or 'Usando ' .. item.label .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = anim,
        })
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsInventoryOpen', function() return isOpen end)
exports('GetPlayerInventory', function() return playerInventory end)
exports('OpenInventory', function(invType, invId) AIT.Inventory.Open(invType, invId) end)
exports('CloseInventory', AIT.Inventory.Close)

-- Inicializar
CreateThread(function()
    Wait(1000)
    AIT.Inventory.Init()
end)

return AIT.Inventory
