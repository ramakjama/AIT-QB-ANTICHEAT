--[[
    AIT-QB: Sistema de Leñador
    Trabajo legal - Tala y procesamiento de madera
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Lumberjack = {}

local isChopping = false
local lumberjackLevel = 1
local lumberjackXP = 0
local logsCarried = 0
local maxLogs = 5

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    shop = {
        coords = vector3(-553.0, 5335.0, 74.0),
        blip = { sprite = 607, color = 69, scale = 0.8 },
    },

    sawmill = {
        coords = vector3(-548.0, 5351.0, 74.0),
        blip = { sprite = 436, color = 69, scale = 0.7 },
        processTime = 5000,
    },

    sellPoint = {
        coords = vector3(-555.0, 5325.0, 74.0),
        blip = { sprite = 52, color = 2, scale = 0.7 },
    },

    depositPoint = {
        coords = vector3(-545.0, 5345.0, 74.0),
    },

    -- Zonas de tala
    forests = {
        {
            name = 'Bosque de Paleto',
            center = vector3(-556.0, 5405.0, 70.0),
            radius = 150.0,
            trees = {
                vector3(-570.0, 5410.0, 70.0),
                vector3(-545.0, 5420.0, 71.0),
                vector3(-580.0, 5430.0, 69.0),
                vector3(-535.0, 5400.0, 72.0),
                vector3(-555.0, 5440.0, 68.0),
                vector3(-590.0, 5415.0, 70.0),
                vector3(-540.0, 5450.0, 67.0),
                vector3(-565.0, 5395.0, 73.0),
            },
            quality = 'normal',
            blip = { sprite = 607, color = 69, scale = 0.6 },
        },
        {
            name = 'Bosque de Mount Chiliad',
            center = vector3(490.0, 5535.0, 780.0),
            radius = 200.0,
            trees = {
                vector3(480.0, 5530.0, 780.0),
                vector3(500.0, 5540.0, 779.0),
                vector3(475.0, 5550.0, 781.0),
                vector3(510.0, 5520.0, 778.0),
                vector3(485.0, 5560.0, 780.0),
                vector3(520.0, 5545.0, 779.0),
            },
            quality = 'buena',
        },
        {
            name = 'Reserva Forestal',
            center = vector3(-783.0, 5530.0, 34.0),
            radius = 100.0,
            trees = {
                vector3(-790.0, 5525.0, 34.0),
                vector3(-775.0, 5535.0, 34.0),
                vector3(-800.0, 5540.0, 34.0),
                vector3(-770.0, 5520.0, 34.0),
            },
            quality = 'rara',
        },
    },

    -- Tipos de madera
    woodTypes = {
        -- Comunes (60%)
        { name = 'pino', label = 'Pino', priceLog = 20, pricePlank = 45, xp = 8, rarity = 'comun' },
        { name = 'abeto', label = 'Abeto', priceLog = 22, pricePlank = 50, xp = 9, rarity = 'comun' },

        -- Normales (28%)
        { name = 'roble', label = 'Roble', priceLog = 40, pricePlank = 90, xp = 20, rarity = 'normal' },
        { name = 'haya', label = 'Haya', priceLog = 45, pricePlank = 100, xp = 22, rarity = 'normal' },

        -- Buenos (10%)
        { name = 'cedro', label = 'Cedro', priceLog = 80, pricePlank = 180, xp = 45, rarity = 'buena' },
        { name = 'nogal', label = 'Nogal', priceLog = 100, pricePlank = 220, xp = 55, rarity = 'buena' },

        -- Raros (2%)
        { name = 'caoba', label = 'Caoba', priceLog = 200, pricePlank = 450, xp = 100, rarity = 'rara' },
        { name = 'teca', label = 'Teca', priceLog = 250, pricePlank = 550, xp = 120, rarity = 'rara' },
    },

    -- Equipamiento
    equipment = {
        basicAxe = { name = 'axe', label = 'Hacha Básica', price = 250, speedMultiplier = 1.0 },
        steelAxe = { name = 'axe_steel', label = 'Hacha de Acero', price = 1000, speedMultiplier = 0.8 },
        chainsaw = { name = 'chainsaw', label = 'Motosierra', price = 5000, speedMultiplier = 0.4 },
        gloves = { name = 'work_gloves', label = 'Guantes de Trabajo', price = 100, carryBonus = 2 },
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Ayudante' },
        { level = 2, xpRequired = 100, title = 'Aprendiz' },
        { level = 3, xpRequired = 300, title = 'Leñador' },
        { level = 4, xpRequired = 600, title = 'Leñador Experto' },
        { level = 5, xpRequired = 1000, title = 'Maestro Leñador' },
        { level = 6, xpRequired = 1800, title = 'Jefe de Cuadrilla' },
    },

    choppingTime = 12000, -- Tiempo base de tala
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Lumberjack.Init()
    -- Blips
    local shopBlip = AddBlipForCoord(Config.shop.coords.x, Config.shop.coords.y, Config.shop.coords.z)
    SetBlipSprite(shopBlip, Config.shop.blip.sprite)
    SetBlipColour(shopBlip, Config.shop.blip.color)
    SetBlipScale(shopBlip, Config.shop.blip.scale)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Aserradero - Tienda')
    EndTextCommandSetBlipName(shopBlip)

    local sawmillBlip = AddBlipForCoord(Config.sawmill.coords.x, Config.sawmill.coords.y, Config.sawmill.coords.z)
    SetBlipSprite(sawmillBlip, Config.sawmill.blip.sprite)
    SetBlipColour(sawmillBlip, Config.sawmill.blip.color)
    SetBlipScale(sawmillBlip, Config.sawmill.blip.scale)
    SetBlipAsShortRange(sawmillBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Aserradero - Procesado')
    EndTextCommandSetBlipName(sawmillBlip)

    local sellBlip = AddBlipForCoord(Config.sellPoint.coords.x, Config.sellPoint.coords.y, Config.sellPoint.coords.z)
    SetBlipSprite(sellBlip, Config.sellPoint.blip.sprite)
    SetBlipColour(sellBlip, Config.sellPoint.blip.color)
    SetBlipScale(sellBlip, Config.sellPoint.blip.scale)
    SetBlipAsShortRange(sellBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Venta de Madera')
    EndTextCommandSetBlipName(sellBlip)

    -- Blips de bosques
    for _, forest in ipairs(Config.forests) do
        local forestBlip = AddBlipForCoord(forest.center.x, forest.center.y, forest.center.z)
        SetBlipSprite(forestBlip, 607)
        SetBlipColour(forestBlip, 69)
        SetBlipScale(forestBlip, 0.6)
        SetBlipAsShortRange(forestBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(forest.name)
        EndTextCommandSetBlipName(forestBlip)
    end

    print('[AIT-QB] Sistema de leñador inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- TIENDA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:lumberjack:openShop', function()
    local options = {
        {
            title = 'Hacha Básica',
            description = 'Precio: $' .. Config.equipment.basicAxe.price,
            icon = 'axe',
            onSelect = function()
                TriggerServerEvent('ait:server:lumberjack:buyItem', 'basicAxe')
            end,
        },
        {
            title = 'Hacha de Acero',
            description = 'Precio: $' .. Config.equipment.steelAxe.price .. ' | 20% más rápida',
            icon = 'axe',
            onSelect = function()
                TriggerServerEvent('ait:server:lumberjack:buyItem', 'steelAxe')
            end,
        },
        {
            title = 'Motosierra',
            description = 'Precio: $' .. Config.equipment.chainsaw.price .. ' | 60% más rápida',
            icon = 'cogs',
            onSelect = function()
                TriggerServerEvent('ait:server:lumberjack:buyItem', 'chainsaw')
            end,
        },
        {
            title = 'Guantes de Trabajo',
            description = 'Precio: $' .. Config.equipment.gloves.price .. ' | +2 troncos',
            icon = 'hand-paper',
            onSelect = function()
                TriggerServerEvent('ait:server:lumberjack:buyItem', 'gloves')
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'lumberjack_shop',
            title = 'Tienda de Leñador',
            options = options,
        })
        lib.showContext('lumberjack_shop')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- TALA DE ÁRBOLES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Lumberjack.GetCurrentForest()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, forest in ipairs(Config.forests) do
        local dist = #(coords - forest.center)
        if dist <= forest.radius then
            return forest
        end
    end

    return nil
end

function AIT.Jobs.Lumberjack.GetNearestTree()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forest = AIT.Jobs.Lumberjack.GetCurrentForest()

    if not forest then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, treeCoords in ipairs(forest.trees) do
        local dist = #(coords - treeCoords)
        if dist < nearestDist and dist <= 5.0 then
            nearest = treeCoords
            nearestDist = dist
        end
    end

    return nearest, forest
end

RegisterCommand('talar', function()
    if isChopping then
        AIT.Notify('Ya estás talando', 'error')
        return
    end

    if logsCarried >= maxLogs then
        AIT.Notify('Llevas demasiados troncos. Ve a depositarlos.', 'error')
        return
    end

    local tree, forest = AIT.Jobs.Lumberjack.GetNearestTree()
    if not tree then
        AIT.Notify('No hay árbol cerca para talar', 'error')
        return
    end

    TriggerServerEvent('ait:server:lumberjack:checkEquipment')
end, false)

RegisterNetEvent('ait:client:lumberjack:equipmentChecked', function(hasAxe, axeType, hasGloves)
    if not hasAxe then
        AIT.Notify('Necesitas un hacha o motosierra', 'error')
        return
    end

    -- Actualizar capacidad si tiene guantes
    if hasGloves then
        maxLogs = 7
    else
        maxLogs = 5
    end

    local tree, forest = AIT.Jobs.Lumberjack.GetNearestTree()
    if tree and forest then
        AIT.Jobs.Lumberjack.StartChopping(forest, axeType)
    end
end)

function AIT.Jobs.Lumberjack.StartChopping(forest, toolType)
    isChopping = true

    local ped = PlayerPedId()

    -- Calcular tiempo
    local choppingTime = Config.choppingTime
    local speedMultiplier = 1.0

    if toolType == 'steelAxe' then
        speedMultiplier = 0.8
    elseif toolType == 'chainsaw' then
        speedMultiplier = 0.4
    end

    -- Reducir por nivel
    speedMultiplier = speedMultiplier * (1 - (lumberjackLevel * 0.03))
    choppingTime = choppingTime * speedMultiplier

    -- Animación y progress bar
    local animDict = toolType == 'chainsaw' and 'anim@heists@fleeca_bank@drilling' or 'melee@large_wpn@streamed_core'
    local animClip = toolType == 'chainsaw' and 'drill_straight_idle' or 'ground_attack_0'

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = math.floor(choppingTime),
            label = toolType == 'chainsaw' and 'Cortando con motosierra...' or 'Talando árbol...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                scenario = 'WORLD_HUMAN_HAMMERING',
            },
        }) then
            -- Determinar tipo de madera
            local wood = AIT.Jobs.Lumberjack.DetermineWood(forest.quality)

            if wood then
                logsCarried = logsCarried + 1

                local rarityEmoji = ({
                    comun = '⚪',
                    normal = '🟢',
                    buena = '🔵',
                    rara = '🟣',
                })[wood.rarity] or ''

                AIT.Notify(rarityEmoji .. ' Tronco de ' .. wood.label .. ' (' .. logsCarried .. '/' .. maxLogs .. ')', 'success')

                -- Dar item temporalmente
                TriggerServerEvent('ait:server:lumberjack:addLog', wood.name)

                -- Dar XP
                AIT.Jobs.Lumberjack.AddXP(wood.xp)

                -- Mostrar prop de tronco si lleva varios
                if logsCarried >= 3 then
                    AIT.Notify('Llevas muchos troncos. Ve a depositarlos.', 'warning')
                end
            end
        else
            AIT.Notify('Tala cancelada', 'error')
        end
    end

    isChopping = false
end

function AIT.Jobs.Lumberjack.DetermineWood(forestQuality)
    local bonus = lumberjackLevel * 3
    local roll = math.random(1, 100) + bonus

    local rarity
    if forestQuality == 'rara' then
        if roll > 95 then rarity = 'rara'
        elseif roll > 75 then rarity = 'buena'
        elseif roll > 45 then rarity = 'normal'
        else rarity = 'comun' end
    elseif forestQuality == 'buena' then
        if roll > 92 then rarity = 'buena'
        elseif roll > 55 then rarity = 'normal'
        else rarity = 'comun' end
    else
        if roll > 85 then rarity = 'normal'
        else rarity = 'comun' end
    end

    local possibleWoods = {}
    for _, wood in ipairs(Config.woodTypes) do
        if wood.rarity == rarity then
            table.insert(possibleWoods, wood)
        end
    end

    if #possibleWoods == 0 then
        return Config.woodTypes[1] -- Fallback a pino
    end

    return possibleWoods[math.random(1, #possibleWoods)]
end

-- ═══════════════════════════════════════════════════════════════
-- DEPOSITAR TRONCOS
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('depositartroncos', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - Config.depositPoint.coords)

    if dist > 5.0 then
        AIT.Notify('Debes estar en el punto de depósito del aserradero', 'error')
        return
    end

    if logsCarried == 0 then
        AIT.Notify('No llevas troncos', 'error')
        return
    end

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 3000,
            label = 'Depositando troncos...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'anim@heists@box_carry@',
                clip = 'idle',
            },
        }) then
            TriggerServerEvent('ait:server:lumberjack:depositLogs', logsCarried)
            AIT.Notify('Has depositado ' .. logsCarried .. ' troncos', 'success')
            logsCarried = 0
        end
    end
end, false)

-- ═══════════════════════════════════════════════════════════════
-- PROCESAMIENTO (ASERRADERO)
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:lumberjack:openSawmill', function(inventory)
    local options = {}

    for _, wood in ipairs(Config.woodTypes) do
        local logItem = 'log_' .. wood.name
        local amount = inventory[logItem] or 0

        if amount > 0 then
            table.insert(options, {
                title = 'Procesar ' .. wood.label,
                description = 'Tienes: ' .. amount .. ' troncos',
                icon = 'cut',
                onSelect = function()
                    AIT.Jobs.Lumberjack.ProcessLogs(wood, amount)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes troncos para procesar', 'error')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'lumberjack_sawmill',
            title = 'Aserradero',
            options = options,
        })
        lib.showContext('lumberjack_sawmill')
    end
end)

function AIT.Jobs.Lumberjack.ProcessLogs(wood, amount)
    -- Procesar de uno en uno
    for i = 1, amount do
        if lib and lib.progressBar then
            if lib.progressBar({
                duration = Config.sawmill.processTime,
                label = 'Procesando tronco ' .. i .. '/' .. amount .. '...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
            }) then
                TriggerServerEvent('ait:server:lumberjack:processLog', wood.name)
            else
                AIT.Notify('Procesamiento cancelado', 'error')
                break
            end
        end
    end

    AIT.Notify('Procesamiento completado', 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- VENTA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:lumberjack:openSellMenu', function(inventory)
    local options = {}
    local totalValue = 0

    for _, wood in ipairs(Config.woodTypes) do
        -- Troncos
        local logItem = 'log_' .. wood.name
        local logAmount = inventory[logItem] or 0
        if logAmount > 0 then
            local value = wood.priceLog * logAmount
            totalValue = totalValue + value
            table.insert(options, {
                title = 'Tronco ' .. wood.label .. ' x' .. logAmount,
                description = 'Valor: $' .. value,
                icon = 'tree',
                onSelect = function()
                    TriggerServerEvent('ait:server:lumberjack:sell', logItem, logAmount)
                end,
            })
        end

        -- Tablones
        local plankItem = 'plank_' .. wood.name
        local plankAmount = inventory[plankItem] or 0
        if plankAmount > 0 then
            local value = wood.pricePlank * plankAmount
            totalValue = totalValue + value
            table.insert(options, {
                title = 'Tablón ' .. wood.label .. ' x' .. plankAmount,
                description = 'Valor: $' .. value,
                icon = 'box',
                onSelect = function()
                    TriggerServerEvent('ait:server:lumberjack:sell', plankItem, plankAmount)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes madera para vender', 'error')
        return
    end

    table.insert(options, 1, {
        title = 'Vender Todo',
        description = 'Valor total: $' .. totalValue,
        icon = 'dollar-sign',
        onSelect = function()
            TriggerServerEvent('ait:server:lumberjack:sellAll')
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'lumberjack_sell',
            title = 'Venta de Madera',
            options = options,
        })
        lib.showContext('lumberjack_sell')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Lumberjack.AddXP(amount)
    lumberjackXP = lumberjackXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if lumberjackXP >= levelData.xpRequired and lumberjackLevel < levelData.level then
            lumberjackLevel = levelData.level
            AIT.Notify('¡Nivel de leñador ' .. lumberjackLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:lumberjack:saveLevel', lumberjackLevel, lumberjackXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:lumberjack:loadLevel', function(level, xp)
    lumberjackLevel = level or 1
    lumberjackXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsChopping', function() return isChopping end)
exports('GetLumberjackLevel', function() return lumberjackLevel end)
exports('GetLogsCarried', function() return logsCarried end)

return AIT.Jobs.Lumberjack
