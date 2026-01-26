--[[
    AIT-QB: Sistema de Minería
    Trabajo legal - Extracción de minerales
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Mining = {}

local isMining = false
local miningLevel = 1
local miningXP = 0
local currentOre = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    shop = {
        coords = vector3(2947.0, 2776.0, 39.0),
        blip = { sprite = 618, color = 46, scale = 0.8 },
    },

    sellPoint = {
        coords = vector3(1101.0, -2005.0, 30.0),
        blip = { sprite = 52, color = 2, scale = 0.7 },
    },

    refinery = {
        coords = vector3(1099.0, -1988.0, 30.0),
        blip = { sprite = 436, color = 46, scale = 0.7 },
    },

    -- Minas
    mines = {
        {
            name = 'Mina del Desierto',
            coords = vector3(2947.0, 2785.0, 42.0),
            nodes = {
                vector3(2935.0, 2780.0, 42.0),
                vector3(2950.0, 2790.0, 42.0),
                vector3(2960.0, 2775.0, 42.0),
                vector3(2940.0, 2800.0, 42.0),
                vector3(2955.0, 2765.0, 42.0),
            },
            quality = 'normal',
            blip = { sprite = 618, color = 46, scale = 0.6 },
        },
        {
            name = 'Cantera de Harmony',
            coords = vector3(1206.0, 1877.0, 85.0),
            nodes = {
                vector3(1195.0, 1870.0, 85.0),
                vector3(1210.0, 1885.0, 85.0),
                vector3(1220.0, 1865.0, 85.0),
                vector3(1200.0, 1890.0, 85.0),
            },
            quality = 'buena',
        },
        {
            name = 'Mina Abandonada',
            coords = vector3(-597.0, 2089.0, 131.0),
            nodes = {
                vector3(-590.0, 2080.0, 131.0),
                vector3(-605.0, 2095.0, 131.0),
                vector3(-585.0, 2100.0, 131.0),
            },
            quality = 'rara',
        },
    },

    -- Minerales
    ores = {
        -- Comunes (55%)
        { name = 'piedra', label = 'Piedra', price = 5, xp = 2, rarity = 'comun' },
        { name = 'carbon', label = 'Carbón', price = 15, xp = 5, rarity = 'comun' },
        { name = 'cobre', label = 'Cobre', price = 25, xp = 8, rarity = 'comun' },

        -- Normales (28%)
        { name = 'hierro', label = 'Hierro', price = 45, xp = 15, rarity = 'normal' },
        { name = 'plomo', label = 'Plomo', price = 40, xp = 12, rarity = 'normal' },
        { name = 'zinc', label = 'Zinc', price = 50, xp = 18, rarity = 'normal' },

        -- Buenos (12%)
        { name = 'plata', label = 'Plata', price = 150, xp = 50, rarity = 'buena' },
        { name = 'titanio', label = 'Titanio', price = 200, xp = 65, rarity = 'buena' },

        -- Raros (4%)
        { name = 'oro', label = 'Oro', price = 500, xp = 150, rarity = 'rara' },
        { name = 'platino', label = 'Platino', price = 750, xp = 200, rarity = 'rara' },

        -- Legendarios (1%)
        { name = 'diamante', label = 'Diamante', price = 2500, xp = 500, rarity = 'legendaria' },
        { name = 'esmeralda', label = 'Esmeralda', price = 2000, xp = 450, rarity = 'legendaria' },
        { name = 'rubi', label = 'Rubí', price = 2200, xp = 480, rarity = 'legendaria' },
    },

    -- Refinería - Recetas
    refining = {
        { input = 'hierro', inputAmount = 5, output = 'steel', outputAmount = 2, time = 10000 },
        { input = 'cobre', inputAmount = 3, output = 'copper_wire', outputAmount = 5, time = 8000 },
        { input = 'oro', inputAmount = 2, output = 'gold_bar', outputAmount = 1, time = 15000 },
        { input = 'plata', inputAmount = 3, output = 'silver_bar', outputAmount = 1, time = 12000 },
        { input = 'platino', inputAmount = 2, output = 'platinum_bar', outputAmount = 1, time = 20000 },
    },

    -- Productos refinados
    refinedProducts = {
        { name = 'steel', label = 'Acero', price = 120 },
        { name = 'copper_wire', label = 'Cable de Cobre', price = 50 },
        { name = 'gold_bar', label = 'Lingote de Oro', price = 1200 },
        { name = 'silver_bar', label = 'Lingote de Plata', price = 400 },
        { name = 'platinum_bar', label = 'Lingote de Platino', price = 1800 },
    },

    -- Equipamiento
    equipment = {
        basicPickaxe = { name = 'pickaxe', label = 'Pico Básico', price = 300, miningSpeed = 1.0 },
        steelPickaxe = { name = 'pickaxe_steel', label = 'Pico de Acero', price = 1500, miningSpeed = 0.8 },
        diamondPickaxe = { name = 'pickaxe_diamond', label = 'Pico de Diamante', price = 8000, miningSpeed = 0.5 },
        helmet = { name = 'mining_helmet', label = 'Casco de Minero', price = 200 },
        lantern = { name = 'mining_lantern', label = 'Linterna', price = 100 },
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Aprendiz de Minero' },
        { level = 2, xpRequired = 150, title = 'Minero Novato' },
        { level = 3, xpRequired = 400, title = 'Minero' },
        { level = 4, xpRequired = 800, title = 'Minero Experto' },
        { level = 5, xpRequired = 1500, title = 'Maestro Minero' },
        { level = 6, xpRequired = 2500, title = 'Gran Maestro' },
        { level = 7, xpRequired = 4000, title = 'Leyenda Minera' },
    },

    miningTime = 8000, -- Tiempo base de minado
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mining.Init()
    -- Blip tienda
    local shopBlip = AddBlipForCoord(Config.shop.coords.x, Config.shop.coords.y, Config.shop.coords.z)
    SetBlipSprite(shopBlip, Config.shop.blip.sprite)
    SetBlipColour(shopBlip, Config.shop.blip.color)
    SetBlipScale(shopBlip, Config.shop.blip.scale)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Tienda de Minería')
    EndTextCommandSetBlipName(shopBlip)

    -- Blip venta
    local sellBlip = AddBlipForCoord(Config.sellPoint.coords.x, Config.sellPoint.coords.y, Config.sellPoint.coords.z)
    SetBlipSprite(sellBlip, Config.sellPoint.blip.sprite)
    SetBlipColour(sellBlip, Config.sellPoint.blip.color)
    SetBlipScale(sellBlip, Config.sellPoint.blip.scale)
    SetBlipAsShortRange(sellBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Comprador de Minerales')
    EndTextCommandSetBlipName(sellBlip)

    -- Blip refinería
    local refBlip = AddBlipForCoord(Config.refinery.coords.x, Config.refinery.coords.y, Config.refinery.coords.z)
    SetBlipSprite(refBlip, Config.refinery.blip.sprite)
    SetBlipColour(refBlip, Config.refinery.blip.color)
    SetBlipScale(refBlip, Config.refinery.blip.scale)
    SetBlipAsShortRange(refBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Refinería')
    EndTextCommandSetBlipName(refBlip)

    -- Blips de minas
    for _, mine in ipairs(Config.mines) do
        local mineBlip = AddBlipForCoord(mine.coords.x, mine.coords.y, mine.coords.z)
        SetBlipSprite(mineBlip, 618)
        SetBlipColour(mineBlip, 46)
        SetBlipScale(mineBlip, 0.6)
        SetBlipAsShortRange(mineBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(mine.name)
        EndTextCommandSetBlipName(mineBlip)
    end

    -- Crear nodos de minería como objetos interactuables
    AIT.Jobs.Mining.CreateMiningNodes()

    print('[AIT-QB] Sistema de minería inicializado')
end

function AIT.Jobs.Mining.CreateMiningNodes()
    for _, mine in ipairs(Config.mines) do
        for i, nodeCoords in ipairs(mine.nodes) do
            -- Crear zona interactuable
            if lib and lib.zones then
                lib.zones.sphere({
                    coords = nodeCoords,
                    radius = 2.0,
                    debug = false,
                    onEnter = function()
                        lib.showTextUI('[E] Minar')
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                })
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TIENDA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:mining:openShop', function()
    local options = {
        {
            title = 'Pico Básico',
            description = 'Precio: $' .. Config.equipment.basicPickaxe.price,
            icon = 'hammer',
            onSelect = function()
                TriggerServerEvent('ait:server:mining:buyItem', 'basicPickaxe')
            end,
        },
        {
            title = 'Pico de Acero',
            description = 'Precio: $' .. Config.equipment.steelPickaxe.price .. ' | 20% más rápido',
            icon = 'hammer',
            onSelect = function()
                TriggerServerEvent('ait:server:mining:buyItem', 'steelPickaxe')
            end,
        },
        {
            title = 'Pico de Diamante',
            description = 'Precio: $' .. Config.equipment.diamondPickaxe.price .. ' | 50% más rápido',
            icon = 'hammer',
            onSelect = function()
                TriggerServerEvent('ait:server:mining:buyItem', 'diamondPickaxe')
            end,
        },
        {
            title = 'Casco de Minero',
            description = 'Precio: $' .. Config.equipment.helmet.price,
            icon = 'hard-hat',
            onSelect = function()
                TriggerServerEvent('ait:server:mining:buyItem', 'helmet')
            end,
        },
        {
            title = 'Linterna',
            description = 'Precio: $' .. Config.equipment.lantern.price,
            icon = 'lightbulb',
            onSelect = function()
                TriggerServerEvent('ait:server:mining:buyItem', 'lantern')
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'mining_shop',
            title = 'Tienda de Minería',
            options = options,
        })
        lib.showContext('mining_shop')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE MINADO
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mining.GetCurrentMine()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, mine in ipairs(Config.mines) do
        local dist = #(coords - mine.coords)
        if dist <= 100.0 then
            return mine
        end
    end

    return nil
end

function AIT.Jobs.Mining.GetNearestNode()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local mine = AIT.Jobs.Mining.GetCurrentMine()

    if not mine then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, nodeCoords in ipairs(mine.nodes) do
        local dist = #(coords - nodeCoords)
        if dist < nearestDist and dist <= 3.0 then
            nearest = nodeCoords
            nearestDist = dist
        end
    end

    return nearest, mine
end

RegisterCommand('minar', function()
    if isMining then
        AIT.Notify('Ya estás minando', 'error')
        return
    end

    local node, mine = AIT.Jobs.Mining.GetNearestNode()
    if not node then
        AIT.Notify('No hay veta de mineral cerca', 'error')
        return
    end

    -- Verificar pico
    TriggerServerEvent('ait:server:mining:checkEquipment')
end, false)

RegisterNetEvent('ait:client:mining:equipmentChecked', function(hasPickaxe, pickaxeType)
    if not hasPickaxe then
        AIT.Notify('Necesitas un pico para minar', 'error')
        return
    end

    local node, mine = AIT.Jobs.Mining.GetNearestNode()
    if node and mine then
        AIT.Jobs.Mining.StartMining(mine, pickaxeType)
    end
end)

function AIT.Jobs.Mining.StartMining(mine, pickaxeType)
    isMining = true

    local ped = PlayerPedId()

    -- Calcular tiempo de minado
    local miningTime = Config.miningTime
    if pickaxeType == 'steelPickaxe' then
        miningTime = miningTime * 0.8
    elseif pickaxeType == 'diamondPickaxe' then
        miningTime = miningTime * 0.5
    end

    -- Reducir por nivel
    miningTime = miningTime * (1 - (miningLevel * 0.03))

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = math.floor(miningTime),
            label = 'Minando...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                scenario = 'WORLD_HUMAN_HAMMERING',
            },
        }) then
            -- Determinar mineral
            local ore = AIT.Jobs.Mining.DetermineOre(mine.quality, pickaxeType)

            if ore then
                local rarityEmoji = ({
                    comun = '⚪',
                    normal = '🟢',
                    buena = '🔵',
                    rara = '🟣',
                    legendaria = '🟡',
                })[ore.rarity] or ''

                AIT.Notify(rarityEmoji .. ' Has extraído: ' .. ore.label, 'success')

                -- Añadir al inventario
                TriggerServerEvent('ait:server:mining:addOre', ore.name, 1)

                -- Dar XP
                AIT.Jobs.Mining.AddXP(ore.xp)
            else
                AIT.Notify('No encontraste nada útil', 'info')
            end
        else
            AIT.Notify('Minado cancelado', 'error')
        end
    end

    isMining = false
end

function AIT.Jobs.Mining.DetermineOre(mineQuality, pickaxeType)
    local bonus = 0

    -- Bonus por pico
    if pickaxeType == 'steelPickaxe' then
        bonus = 10
    elseif pickaxeType == 'diamondPickaxe' then
        bonus = 25
    end

    -- Bonus por nivel
    bonus = bonus + (miningLevel * 3)

    local roll = math.random(1, 100) + bonus

    local rarity
    if mineQuality == 'rara' then
        if roll > 99 then rarity = 'legendaria'
        elseif roll > 90 then rarity = 'rara'
        elseif roll > 70 then rarity = 'buena'
        elseif roll > 40 then rarity = 'normal'
        else rarity = 'comun' end
    elseif mineQuality == 'buena' then
        if roll > 98 then rarity = 'rara'
        elseif roll > 80 then rarity = 'buena'
        elseif roll > 50 then rarity = 'normal'
        else rarity = 'comun' end
    else
        if roll > 95 then rarity = 'buena'
        elseif roll > 65 then rarity = 'normal'
        else rarity = 'comun' end
    end

    -- Filtrar minerales por rareza
    local possibleOres = {}
    for _, ore in ipairs(Config.ores) do
        if ore.rarity == rarity then
            table.insert(possibleOres, ore)
        end
    end

    if #possibleOres == 0 then
        return nil
    end

    return possibleOres[math.random(1, #possibleOres)]
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Mining.AddXP(amount)
    miningXP = miningXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if miningXP >= levelData.xpRequired and miningLevel < levelData.level then
            miningLevel = levelData.level
            AIT.Notify('¡Nivel de minería ' .. miningLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:mining:saveLevel', miningLevel, miningXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:mining:loadLevel', function(level, xp)
    miningLevel = level or 1
    miningXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- REFINERÍA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:mining:openRefinery', function(inventory)
    local options = {}

    for _, recipe in ipairs(Config.refining) do
        local hasEnough = (inventory[recipe.input] or 0) >= recipe.inputAmount

        local inputOre = nil
        for _, ore in ipairs(Config.ores) do
            if ore.name == recipe.input then
                inputOre = ore
                break
            end
        end

        local outputProduct = nil
        for _, product in ipairs(Config.refinedProducts) do
            if product.name == recipe.output then
                outputProduct = product
                break
            end
        end

        if inputOre and outputProduct then
            table.insert(options, {
                title = inputOre.label .. ' → ' .. outputProduct.label,
                description = recipe.inputAmount .. 'x ' .. inputOre.label .. ' = ' .. recipe.outputAmount .. 'x ' .. outputProduct.label,
                icon = 'fire',
                disabled = not hasEnough,
                onSelect = function()
                    AIT.Jobs.Mining.RefineOre(recipe)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes minerales para refinar', 'error')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'mining_refinery',
            title = 'Refinería',
            options = options,
        })
        lib.showContext('mining_refinery')
    end
end)

function AIT.Jobs.Mining.RefineOre(recipe)
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = recipe.time,
            label = 'Refinando...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            TriggerServerEvent('ait:server:mining:refine', recipe.input, recipe.inputAmount, recipe.output, recipe.outputAmount)
            AIT.Notify('Material refinado correctamente', 'success')
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- VENTA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:mining:openSellMenu', function(inventory)
    local options = {}
    local totalValue = 0

    -- Minerales
    for _, ore in ipairs(Config.ores) do
        local amount = inventory[ore.name] or 0
        if amount > 0 then
            local value = ore.price * amount
            totalValue = totalValue + value

            table.insert(options, {
                title = ore.label .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'gem',
                onSelect = function()
                    TriggerServerEvent('ait:server:mining:sellOre', ore.name, amount)
                end,
            })
        end
    end

    -- Productos refinados
    for _, product in ipairs(Config.refinedProducts) do
        local amount = inventory[product.name] or 0
        if amount > 0 then
            local value = product.price * amount
            totalValue = totalValue + value

            table.insert(options, {
                title = product.label .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'cube',
                onSelect = function()
                    TriggerServerEvent('ait:server:mining:sellOre', product.name, amount)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes nada para vender', 'error')
        return
    end

    table.insert(options, 1, {
        title = 'Vender Todo',
        description = 'Valor total: $' .. totalValue,
        icon = 'dollar-sign',
        onSelect = function()
            TriggerServerEvent('ait:server:mining:sellAll')
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'mining_sell',
            title = 'Comprador de Minerales',
            options = options,
        })
        lib.showContext('mining_sell')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsMining', function() return isMining end)
exports('GetMiningLevel', function() return miningLevel end)
exports('GetMiningXP', function() return miningXP end)

return AIT.Jobs.Mining
