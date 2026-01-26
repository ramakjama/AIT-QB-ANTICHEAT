--[[
    AIT-QB: Server Handlers para TODOS los Jobs
    Servidor Español - Handlers unificados
]]

AIT = AIT or {}
AIT.Server = AIT.Server or {}
AIT.Server.Jobs = {}

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════

local function GetPlayer(source)
    return exports['qb-core']:GetPlayer(source)
end

local function AddMoney(source, amount, moneyType)
    local player = GetPlayer(source)
    if player then
        player.Functions.AddMoney(moneyType or 'cash', amount, 'job-payment')
        return true
    end
    return false
end

local function RemoveMoney(source, amount, moneyType)
    local player = GetPlayer(source)
    if player then
        return player.Functions.RemoveMoney(moneyType or 'cash', amount, 'job-purchase')
    end
    return false
end

local function AddItem(source, item, amount)
    local player = GetPlayer(source)
    if player then
        return player.Functions.AddItem(item, amount or 1)
    end
    return false
end

local function RemoveItem(source, item, amount)
    local player = GetPlayer(source)
    if player then
        return player.Functions.RemoveItem(item, amount or 1)
    end
    return false
end

local function HasItem(source, item, amount)
    local player = GetPlayer(source)
    if player then
        local itemData = player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= (amount or 1)
    end
    return false
end

local function Notify(source, msg, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'AIT-QB',
        description = msg,
        type = type or 'info',
    })
end

-- ═══════════════════════════════════════════════════════════════
-- MECHANIC HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:mechanic:repair', function(plate, repairType, cost)
    local source = source

    if RemoveMoney(source, cost) then
        Notify(source, 'Reparación completada: -$' .. cost, 'success')
        -- Log de transacción
        MySQL.Async.execute('INSERT INTO transactions (identifier, type, amount, description) VALUES (?, ?, ?, ?)', {
            GetPlayer(source).PlayerData.citizenid,
            'mechanic_repair',
            -cost,
            'Reparación de vehículo: ' .. repairType
        })
    else
        Notify(source, 'No tienes suficiente dinero', 'error')
    end
end)

RegisterNetEvent('ait:server:mechanic:buyPart', function(partName, price)
    local source = source

    if RemoveMoney(source, price) then
        AddItem(source, partName, 1)
        Notify(source, 'Pieza comprada', 'success')
    else
        Notify(source, 'No tienes suficiente dinero', 'error')
    end
end)

RegisterNetEvent('ait:server:mechanic:paySalary', function()
    local source = source
    local salary = 80
    AddMoney(source, salary)
end)

-- ═══════════════════════════════════════════════════════════════
-- TAXI HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:taxi:completeRide', function(fare)
    local source = source
    AddMoney(source, fare)
    Notify(source, 'Carrera completada: +$' .. fare, 'success')
end)

RegisterNetEvent('ait:server:taxi:paySalary', function()
    local source = source
    AddMoney(source, 60)
end)

-- ═══════════════════════════════════════════════════════════════
-- TRUCKER HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:trucker:completeDelivery', function(payment, xp)
    local source = source
    AddMoney(source, payment)
    Notify(source, 'Entrega completada: +$' .. payment, 'success')

    -- Guardar XP
    local player = GetPlayer(source)
    if player then
        MySQL.Async.execute('UPDATE characters SET trucker_xp = trucker_xp + ? WHERE citizenid = ?', {
            xp, player.PlayerData.citizenid
        })
    end
end)

RegisterNetEvent('ait:server:trucker:paySalary', function()
    local source = source
    AddMoney(source, 100)
end)

-- ═══════════════════════════════════════════════════════════════
-- GARBAGE HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:garbage:completeRoute', function(payment, bags)
    local source = source
    AddMoney(source, payment)
    Notify(source, 'Ruta completada: ' .. bags .. ' bolsas | +$' .. payment, 'success')
end)

RegisterNetEvent('ait:server:garbage:paySalary', function()
    local source = source
    AddMoney(source, 70)
end)

-- ═══════════════════════════════════════════════════════════════
-- FISHING HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:fishing:buyItem', function(itemType, amount)
    local source = source
    amount = amount or 1

    local prices = {
        basicRod = 500,
        proRod = 2500,
        legendaryRod = 10000,
        bait = 20,
        premiumBait = 100,
    }

    local items = {
        basicRod = 'fishing_rod',
        proRod = 'fishing_rod_pro',
        legendaryRod = 'fishing_rod_legendary',
        bait = 'fishing_bait',
        premiumBait = 'premium_bait',
    }

    local price = prices[itemType] * amount

    if RemoveMoney(source, price) then
        AddItem(source, items[itemType], amount)
        Notify(source, 'Compra realizada', 'success')
    else
        Notify(source, 'No tienes suficiente dinero', 'error')
    end
end)

RegisterNetEvent('ait:server:fishing:checkEquipment', function()
    local source = source
    local hasRod = HasItem(source, 'fishing_rod') or HasItem(source, 'fishing_rod_pro') or HasItem(source, 'fishing_rod_legendary')
    local hasBait = HasItem(source, 'fishing_bait') or HasItem(source, 'premium_bait')

    local rodType = 'basicRod'
    if HasItem(source, 'fishing_rod_legendary') then
        rodType = 'legendaryRod'
    elseif HasItem(source, 'fishing_rod_pro') then
        rodType = 'proRod'
    end

    TriggerClientEvent('ait:client:fishing:equipmentChecked', source, hasRod, hasBait, rodType)
end)

RegisterNetEvent('ait:server:fishing:addCatch', function(fishName, amount)
    local source = source
    AddItem(source, fishName, amount)
end)

RegisterNetEvent('ait:server:fishing:useBait', function()
    local source = source
    if HasItem(source, 'premium_bait') then
        RemoveItem(source, 'premium_bait', 1)
    else
        RemoveItem(source, 'fishing_bait', 1)
    end
end)

RegisterNetEvent('ait:server:fishing:sellFish', function(fishName, amount)
    local source = source

    local fishPrices = {
        sardina = 15, anchoa = 12, caballa = 20, jurel = 25,
        dorada = 45, lubina = 55, merluza = 50, besugo = 60,
        salmon = 120, trucha = 85, rodaballo = 150, rape = 130,
        atun = 350, pez_espada = 400, emperador = 380,
        tiburon = 1500, marlin = 2000, atun_gigante = 2500,
    }

    if HasItem(source, fishName, amount) then
        RemoveItem(source, fishName, amount)
        local payment = (fishPrices[fishName] or 10) * amount
        AddMoney(source, payment)
        Notify(source, 'Vendiste pescado: +$' .. payment, 'success')
    end
end)

RegisterNetEvent('ait:server:fishing:sellAll', function()
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local fishPrices = {
        sardina = 15, anchoa = 12, caballa = 20, jurel = 25,
        dorada = 45, lubina = 55, merluza = 50, besugo = 60,
        salmon = 120, trucha = 85, rodaballo = 150, rape = 130,
        atun = 350, pez_espada = 400, emperador = 380,
        tiburon = 1500, marlin = 2000, atun_gigante = 2500,
    }

    local totalPayment = 0

    for fishName, price in pairs(fishPrices) do
        local item = player.Functions.GetItemByName(fishName)
        if item and item.amount > 0 then
            local amount = item.amount
            RemoveItem(source, fishName, amount)
            totalPayment = totalPayment + (price * amount)
        end
    end

    if totalPayment > 0 then
        AddMoney(source, totalPayment)
        Notify(source, 'Vendiste todo el pescado: +$' .. totalPayment, 'success')
    else
        Notify(source, 'No tienes pescado para vender', 'error')
    end
end)

RegisterNetEvent('ait:server:fishing:saveLevel', function(level, xp)
    local source = source
    local player = GetPlayer(source)
    if player then
        MySQL.Async.execute('UPDATE characters SET fishing_level = ?, fishing_xp = ? WHERE citizenid = ?', {
            level, xp, player.PlayerData.citizenid
        })
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MINING HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:mining:addOre', function(oreName, amount)
    local source = source
    AddItem(source, oreName, amount)
end)

RegisterNetEvent('ait:server:mining:refine', function(oreName, resultName, oreAmount)
    local source = source

    if HasItem(source, oreName, oreAmount) then
        RemoveItem(source, oreName, oreAmount)
        AddItem(source, resultName, 1)
        Notify(source, 'Refinado completado', 'success')
    else
        Notify(source, 'No tienes suficiente mineral', 'error')
    end
end)

RegisterNetEvent('ait:server:mining:sell', function(itemName, amount, price)
    local source = source

    if HasItem(source, itemName, amount) then
        RemoveItem(source, itemName, amount)
        AddMoney(source, price)
        Notify(source, 'Venta realizada: +$' .. price, 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- LUMBERJACK HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:lumberjack:addWood', function(woodType, amount)
    local source = source
    AddItem(source, woodType, amount)
end)

RegisterNetEvent('ait:server:lumberjack:process', function(inputItem, outputItem, inputAmount, outputAmount)
    local source = source

    if HasItem(source, inputItem, inputAmount) then
        RemoveItem(source, inputItem, inputAmount)
        AddItem(source, outputItem, outputAmount)
        Notify(source, 'Procesado completado', 'success')
    else
        Notify(source, 'No tienes suficiente material', 'error')
    end
end)

RegisterNetEvent('ait:server:lumberjack:sell', function(itemName, amount, price)
    local source = source

    if HasItem(source, itemName, amount) then
        RemoveItem(source, itemName, amount)
        AddMoney(source, price)
        Notify(source, 'Venta realizada: +$' .. price, 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- HUNTING HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:hunting:addItem', function(itemName, amount)
    local source = source
    AddItem(source, itemName, amount)
end)

RegisterNetEvent('ait:server:hunting:sell', function(itemName, amount, price)
    local source = source

    if HasItem(source, itemName, amount) then
        RemoveItem(source, itemName, amount)
        AddMoney(source, price)
        Notify(source, 'Venta realizada: +$' .. price, 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- DELIVERY HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:delivery:setDuty', function(onDuty)
    local source = source
    local player = GetPlayer(source)
    if player then
        player.Functions.SetJobDuty(onDuty)
    end
end)

RegisterNetEvent('ait:server:delivery:complete', function(payment)
    local source = source
    AddMoney(source, payment)
end)

RegisterNetEvent('ait:server:delivery:paySalary', function()
    local source = source
    AddMoney(source, 80)
end)

-- ═══════════════════════════════════════════════════════════════
-- DRUGS HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:drugs:harvest', function(drugType, amount)
    local source = source
    AddItem(source, drugType .. '_raw', amount)
end)

RegisterNetEvent('ait:server:drugs:process', function(rawItem, processedItem, rawAmount, processedAmount)
    local source = source

    if HasItem(source, rawItem, rawAmount) then
        RemoveItem(source, rawItem, rawAmount)
        AddItem(source, processedItem, processedAmount)
        Notify(source, 'Procesado completado', 'success')
    else
        Notify(source, 'No tienes suficiente material', 'error')
    end
end)

RegisterNetEvent('ait:server:drugs:sell', function(drugItem, amount, payment)
    local source = source

    if HasItem(source, drugItem, amount) then
        RemoveItem(source, drugItem, amount)
        AddMoney(source, payment, 'cash')
        Notify(source, 'Venta realizada: +$' .. payment .. ' (efectivo sucio)', 'success')

        -- Chance de alerta policial
        if math.random(1, 100) <= 15 then
            TriggerEvent('ait:server:police:drugAlert', source)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ROBBERY HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:robbery:complete', function(robberyType, loot)
    local source = source

    -- Dar items del robo
    for _, item in ipairs(loot) do
        AddItem(source, item.name, item.amount)
    end

    -- Log
    local player = GetPlayer(source)
    if player then
        MySQL.Async.execute('INSERT INTO audit_logs (identifier, action, details) VALUES (?, ?, ?)', {
            player.PlayerData.citizenid,
            'robbery_' .. robberyType,
            json.encode(loot)
        })
    end

    -- Alerta policial
    TriggerEvent('ait:server:police:robberyAlert', robberyType, source)
end)

RegisterNetEvent('ait:server:robbery:sellLoot', function(itemName, amount, price)
    local source = source

    if HasItem(source, itemName, amount) then
        RemoveItem(source, itemName, amount)
        AddMoney(source, price, 'cash')
        Notify(source, 'Vendido: +$' .. price, 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- CHOP SHOP HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:chopshop:addPart', function(partName, amount)
    local source = source
    AddItem(source, partName, amount)
end)

RegisterNetEvent('ait:server:chopshop:sell', function(partName, amount, price)
    local source = source

    if HasItem(source, partName, amount) then
        RemoveItem(source, partName, amount)
        AddMoney(source, price, 'cash')
        Notify(source, 'Pieza vendida: +$' .. price, 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- WEAPONS HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:weapons:buyWeapon', function(weaponName, price, includeAmmo)
    local source = source

    if RemoveMoney(source, price, 'cash') then
        local player = GetPlayer(source)
        if player then
            player.Functions.AddItem(weaponName, 1)
            if includeAmmo then
                -- Dar munición según el tipo de arma
                if string.find(weaponName, 'pistol') then
                    player.Functions.AddItem('pistol_ammo', 48)
                elseif string.find(weaponName, 'smg') then
                    player.Functions.AddItem('smg_ammo', 120)
                elseif string.find(weaponName, 'rifle') then
                    player.Functions.AddItem('rifle_ammo', 120)
                elseif string.find(weaponName, 'shotgun') then
                    player.Functions.AddItem('shotgun_ammo', 24)
                end
            end
            Notify(source, 'Arma comprada', 'success')
        end
    else
        Notify(source, 'No tienes suficiente dinero', 'error')
    end
end)

RegisterNetEvent('ait:server:weapons:buyAmmo', function(ammoName, amount, price)
    local source = source

    if RemoveMoney(source, price, 'cash') then
        AddItem(source, ammoName, amount)
        Notify(source, 'Munición comprada', 'success')
    else
        Notify(source, 'No tienes suficiente dinero', 'error')
    end
end)

RegisterNetEvent('ait:server:weapons:completeCraft', function(resultItem, materials)
    local source = source

    -- Verificar y quitar materiales
    for _, mat in ipairs(materials) do
        if not HasItem(source, mat.item, mat.amount) then
            Notify(source, 'Faltan materiales', 'error')
            return
        end
    end

    for _, mat in ipairs(materials) do
        RemoveItem(source, mat.item, mat.amount)
    end

    AddItem(source, resultItem, 1)
    Notify(source, 'Fabricación completada', 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- LAUNDERING HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:laundering:launder', function(dirtyAmount, cleanAmount, method)
    local source = source
    local player = GetPlayer(source)

    if not player then return end

    -- El dinero sucio está en 'cash', el limpio va a 'bank'
    if player.Functions.RemoveMoney('cash', dirtyAmount, 'laundering') then
        player.Functions.AddMoney('bank', cleanAmount, 'laundered-funds')
        Notify(source, 'Dinero lavado: $' .. dirtyAmount .. ' → $' .. cleanAmount, 'success')

        -- Log
        MySQL.Async.execute('INSERT INTO audit_logs (identifier, action, details) VALUES (?, ?, ?)', {
            player.PlayerData.citizenid,
            'money_laundering',
            json.encode({ dirty = dirtyAmount, clean = cleanAmount, method = method })
        })
    else
        Notify(source, 'No tienes suficiente dinero sucio', 'error')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- GANGS HANDLERS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:gangs:completeDrugDeal', function(money, rep)
    local source = source
    AddMoney(source, money, 'cash')

    -- Actualizar rep en DB
    local player = GetPlayer(source)
    if player then
        MySQL.Async.execute('UPDATE characters SET gang_rep = gang_rep + ? WHERE citizenid = ?', {
            rep, player.PlayerData.citizenid
        })
    end
end)

RegisterNetEvent('ait:server:gangs:checkSpray', function()
    local source = source

    if HasItem(source, 'spray_can') then
        RemoveItem(source, 'spray_can', 1)
        TriggerClientEvent('ait:client:gangs:doSpray', source)
    else
        Notify(source, 'Necesitas un spray', 'error')
    end
end)

RegisterNetEvent('ait:server:gangs:completeSpray', function(territoryIndex)
    local source = source
    local player = GetPlayer(source)

    if player then
        MySQL.Async.execute('UPDATE characters SET gang_rep = gang_rep + 25 WHERE citizenid = ?', {
            player.PlayerData.citizenid
        })
    end
end)

RegisterNetEvent('ait:server:gangs:addRep', function(amount)
    local source = source
    local player = GetPlayer(source)

    if player then
        MySQL.Async.execute('UPDATE characters SET gang_rep = gang_rep + ? WHERE citizenid = ?', {
            amount, player.PlayerData.citizenid
        })
    end
end)

RegisterNetEvent('ait:server:gangs:buyItem', function(itemName, repCost)
    local source = source
    local player = GetPlayer(source)

    if not player then return end

    -- Verificar rep (simplificado, debería consultar DB)
    AddItem(source, itemName, 1)

    MySQL.Async.execute('UPDATE characters SET gang_rep = gang_rep - ? WHERE citizenid = ?', {
        repCost, player.PlayerData.citizenid
    })

    Notify(source, 'Item comprado', 'success')
end)

RegisterNetEvent('ait:server:gangs:sendInvite', function(targetId, gangName)
    local source = source
    local player = GetPlayer(source)

    if player then
        local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        TriggerClientEvent('ait:client:gangs:receiveInvite', targetId, gangName, playerName)
    end
end)

RegisterNetEvent('ait:server:gangs:acceptInvite', function(gangName)
    local source = source
    local player = GetPlayer(source)

    if player then
        MySQL.Async.execute('UPDATE characters SET gang = ?, gang_rank = 0, gang_rep = 0 WHERE citizenid = ?', {
            gangName, player.PlayerData.citizenid
        })

        TriggerClientEvent('ait:client:gangs:setGang', source, gangName, 0, 0)
        Notify(source, 'Te has unido a la banda', 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- POLICE ALERTS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:police:drugAlert', function(source)
    local coords = GetEntityCoords(GetPlayerPed(source))

    -- Notificar a todos los policías
    for _, playerId in ipairs(GetPlayers()) do
        local player = GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = 'Central',
                description = 'Posible venta de drogas reportada',
                type = 'warning',
            })
            TriggerClientEvent('ait:client:police:alert', playerId, 'drugs', coords)
        end
    end
end)

RegisterNetEvent('ait:server:police:robberyAlert', function(robberyType, source)
    local coords = GetEntityCoords(GetPlayerPed(source))

    local alertMessages = {
        store = 'Robo en tienda en progreso',
        house = 'Allanamiento de morada reportado',
        jewelry = '¡Robo a joyería! Código 3',
        fleeca = '¡Atraco a Fleeca Bank! Código 2',
        pacific = '¡ATRACO AL PACIFIC STANDARD! Todas las unidades',
    }

    for _, playerId in ipairs(GetPlayers()) do
        local player = GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = 'Central - URGENTE',
                description = alertMessages[robberyType] or 'Actividad criminal reportada',
                type = 'error',
            })
            TriggerClientEvent('ait:client:police:alert', playerId, robberyType, coords)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    print('[AIT-QB] Server handlers de jobs cargados')
end)

return AIT.Server.Jobs
