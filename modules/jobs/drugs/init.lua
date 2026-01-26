--[[
    AIT-QB: Sistema de Drogas
    Trabajo ILEGAL - Producción y venta de drogas
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Drugs = {}

local isProcessing = false
local drugLevel = 1
local drugXP = 0

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- MARIHUANA
    weed = {
        -- Recolección
        fields = {
            { coords = vector3(2220.0, 5577.0, 53.0), radius = 80.0, name = 'Campo Norte' },
            { coords = vector3(2428.0, 4999.0, 46.0), radius = 60.0, name = 'Campo Grapeseed' },
        },
        plants = {
            { coords = vector3(2220.0, 5577.0, 53.0) },
            { coords = vector3(2230.0, 5580.0, 53.0) },
            { coords = vector3(2210.0, 5585.0, 53.0) },
            { coords = vector3(2225.0, 5590.0, 53.0) },
            { coords = vector3(2215.0, 5570.0, 53.0) },
        },
        harvestItem = 'weed_raw',
        harvestAmount = { 1, 3 },
        harvestTime = 5000,

        -- Procesamiento
        processLocation = vector3(1065.0, -3183.0, -39.0), -- Interior de meth lab
        processItem = 'weed_raw',
        processAmount = 5,
        resultItem = 'weed_bag',
        resultAmount = 1,
        processTime = 15000,

        -- Venta
        sellPrice = { min = 80, max = 150 },
        sellLocations = {
            { coords = vector3(124.0, -1932.0, 21.0), name = 'Grove Street' },
            { coords = vector3(-1182.0, -1320.0, 4.0), name = 'Vespucci' },
            { coords = vector3(325.0, -2046.0, 20.0), name = 'Rancho' },
        },
    },

    -- COCAÍNA
    cocaine = {
        -- Recolección (hojas de coca)
        fields = {
            { coords = vector3(-391.0, 5968.0, 32.0), radius = 50.0, name = 'Plantación Oculta' },
        },
        plants = {
            { coords = vector3(-391.0, 5968.0, 32.0) },
            { coords = vector3(-385.0, 5970.0, 32.0) },
            { coords = vector3(-395.0, 5975.0, 32.0) },
        },
        harvestItem = 'coca_leaf',
        harvestAmount = { 1, 2 },
        harvestTime = 8000,

        -- Procesamiento (requiere químicos)
        processLocation = vector3(1088.0, -3187.0, -38.0),
        processItems = {
            { item = 'coca_leaf', amount = 10 },
            { item = 'acetone', amount = 2 },
            { item = 'hydrochloric_acid', amount = 1 },
        },
        resultItem = 'cocaine_bag',
        resultAmount = 1,
        processTime = 30000,

        -- Venta
        sellPrice = { min = 250, max = 400 },
        sellLocations = {
            { coords = vector3(-125.0, -1526.0, 34.0), name = 'Strawberry' },
            { coords = vector3(959.0, -117.0, 74.0), name = 'Vinewood Hills' },
        },
    },

    -- METANFETAMINA
    meth = {
        -- No hay recolección, se fabrica con químicos
        processLocation = vector3(1391.0, 3606.0, 38.0), -- Laboratorio abandonado

        -- Procesamiento (requiere múltiples químicos)
        processItems = {
            { item = 'pseudoephedrine', amount = 5 },
            { item = 'methylamine', amount = 3 },
            { item = 'phosphorus', amount = 2 },
            { item = 'acetone', amount = 2 },
        },
        resultItem = 'meth_bag',
        resultAmount = 1,
        processTime = 45000,

        -- Venta
        sellPrice = { min = 350, max = 500 },
        sellLocations = {
            { coords = vector3(1959.0, 3746.0, 32.0), name = 'Sandy Shores' },
            { coords = vector3(1329.0, 4330.0, 38.0), name = 'Grapeseed' },
        },
    },

    -- Químicos (se compran de contacto)
    chemicals = {
        dealer = vector3(1542.0, 3609.0, 35.0),
        items = {
            { name = 'acetone', label = 'Acetona', price = 50 },
            { name = 'hydrochloric_acid', label = 'Ácido Clorhídrico', price = 150 },
            { name = 'pseudoephedrine', label = 'Pseudoefedrina', price = 100 },
            { name = 'methylamine', label = 'Metilamina', price = 200 },
            { name = 'phosphorus', label = 'Fósforo Rojo', price = 120 },
        },
    },

    -- Niveles de habilidad
    levels = {
        { level = 1, xpRequired = 0, title = 'Novato', qualityBonus = 0 },
        { level = 2, xpRequired = 500, title = 'Aficionado', qualityBonus = 5 },
        { level = 3, xpRequired = 1500, title = 'Cocinero', qualityBonus = 10 },
        { level = 4, xpRequired = 3500, title = 'Experto', qualityBonus = 20 },
        { level = 5, xpRequired = 7000, title = 'Heisenberg', qualityBonus = 35 },
    },

    -- XP por acción
    xpHarvest = 10,
    xpProcess = 50,
    xpSell = 25,

    -- Riesgo policial (0-100)
    policeRisk = {
        harvest = 15,
        process = 30,
        sell = 45,
    },
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Drugs.Init()
    -- Blips discretos para campos (solo visible si conoces)
    -- NO añadir blips públicos para drogas

    -- Crear zonas de recolección
    AIT.Jobs.Drugs.CreateHarvestZones()

    print('[AIT-QB] Sistema de drogas inicializado')
end

function AIT.Jobs.Drugs.CreateHarvestZones()
    -- Weed zones
    for _, field in ipairs(Config.weed.fields) do
        if lib and lib.zones then
            lib.zones.sphere({
                coords = field.coords,
                radius = field.radius,
                debug = false,
                onEnter = function()
                    AIT.Notify('Has entrado a una zona de cultivo', 'info')
                end,
            })
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- RECOLECCIÓN DE MARIHUANA
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('recolectarweed', function()
    if isProcessing then
        AIT.Notify('Ya estás ocupado', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Verificar si está en zona de weed
    local inZone = false
    for _, field in ipairs(Config.weed.fields) do
        local dist = #(coords - field.coords)
        if dist <= field.radius then
            inZone = true
            break
        end
    end

    if not inZone then
        AIT.Notify('No hay plantas de marihuana aquí', 'error')
        return
    end

    -- Verificar riesgo policial
    if AIT.Jobs.Drugs.CheckPoliceRisk('harvest') then
        return
    end

    isProcessing = true

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.weed.harvestTime,
            label = 'Recolectando marihuana...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'amb@medic@standing@kneel@base',
                clip = 'base',
            },
        }) then
            local amount = math.random(Config.weed.harvestAmount[1], Config.weed.harvestAmount[2])

            TriggerServerEvent('ait:server:drugs:addItem', Config.weed.harvestItem, amount)
            AIT.Jobs.Drugs.AddXP(Config.xpHarvest)

            AIT.Notify('Has recolectado ' .. amount .. ' plantas de marihuana', 'success')

            -- Chance de llamar a la policía
            AIT.Jobs.Drugs.TriggerPoliceAlert('harvest', coords)
        else
            AIT.Notify('Recolección cancelada', 'error')
        end
    end

    isProcessing = false
end, false)

-- ═══════════════════════════════════════════════════════════════
-- RECOLECCIÓN DE COCA
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('recolectarcoca', function()
    if isProcessing then
        AIT.Notify('Ya estás ocupado', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Verificar si está en zona de coca
    local inZone = false
    for _, field in ipairs(Config.cocaine.fields) do
        local dist = #(coords - field.coords)
        if dist <= field.radius then
            inZone = true
            break
        end
    end

    if not inZone then
        AIT.Notify('No hay plantas de coca aquí', 'error')
        return
    end

    if AIT.Jobs.Drugs.CheckPoliceRisk('harvest') then
        return
    end

    isProcessing = true

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.cocaine.harvestTime,
            label = 'Recolectando hojas de coca...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'amb@medic@standing@kneel@base',
                clip = 'base',
            },
        }) then
            local amount = math.random(Config.cocaine.harvestAmount[1], Config.cocaine.harvestAmount[2])

            TriggerServerEvent('ait:server:drugs:addItem', Config.cocaine.harvestItem, amount)
            AIT.Jobs.Drugs.AddXP(Config.xpHarvest)

            AIT.Notify('Has recolectado ' .. amount .. ' hojas de coca', 'success')
            AIT.Jobs.Drugs.TriggerPoliceAlert('harvest', coords)
        else
            AIT.Notify('Recolección cancelada', 'error')
        end
    end

    isProcessing = false
end, false)

-- ═══════════════════════════════════════════════════════════════
-- PROCESAMIENTO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:drugs:openProcessMenu', function(drugType)
    local drug = Config[drugType]
    if not drug then return end

    local options = {}

    if drugType == 'weed' then
        table.insert(options, {
            title = 'Procesar Marihuana',
            description = drug.processAmount .. 'x Marihuana Cruda → 1x Bolsa de Marihuana',
            icon = 'cannabis',
            onSelect = function()
                TriggerServerEvent('ait:server:drugs:checkProcess', drugType)
            end,
        })
    elseif drugType == 'cocaine' then
        local desc = ''
        for _, item in ipairs(drug.processItems) do
            desc = desc .. item.amount .. 'x ' .. item.item .. ', '
        end
        desc = desc .. ' → 1x Bolsa de Cocaína'

        table.insert(options, {
            title = 'Procesar Cocaína',
            description = desc,
            icon = 'snowflake',
            onSelect = function()
                TriggerServerEvent('ait:server:drugs:checkProcess', drugType)
            end,
        })
    elseif drugType == 'meth' then
        local desc = ''
        for _, item in ipairs(drug.processItems) do
            desc = desc .. item.amount .. 'x ' .. item.item .. ', '
        end
        desc = desc .. ' → 1x Meta Cristalina'

        table.insert(options, {
            title = 'Cocinar Metanfetamina',
            description = desc,
            icon = 'flask',
            onSelect = function()
                TriggerServerEvent('ait:server:drugs:checkProcess', drugType)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'drugs_process_' .. drugType,
            title = 'Laboratorio',
            options = options,
        })
        lib.showContext('drugs_process_' .. drugType)
    end
end)

RegisterNetEvent('ait:client:drugs:startProcess', function(drugType)
    local drug = Config[drugType]
    if not drug then return end

    if isProcessing then
        AIT.Notify('Ya estás procesando', 'error')
        return
    end

    if AIT.Jobs.Drugs.CheckPoliceRisk('process') then
        return
    end

    isProcessing = true
    local coords = GetEntityCoords(PlayerPedId())

    local label = ({
        weed = 'Procesando marihuana...',
        cocaine = 'Refinando cocaína...',
        meth = 'Cocinando metanfetamina...',
    })[drugType] or 'Procesando...'

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = drug.processTime,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'anim@amb@business@coc@coc_unpack_cut@',
                clip = 'fullcut_cycle_v1_cokecutter',
            },
        }) then
            -- Calcular calidad basada en nivel
            local levelData = Config.levels[drugLevel] or Config.levels[1]
            local quality = 50 + levelData.qualityBonus + math.random(0, 20)
            quality = math.min(100, quality)

            TriggerServerEvent('ait:server:drugs:completeProcess', drugType, quality)
            AIT.Jobs.Drugs.AddXP(Config.xpProcess)

            local qualityText = quality >= 90 and 'Excelente' or quality >= 70 and 'Buena' or quality >= 50 and 'Normal' or 'Baja'
            AIT.Notify('Producto procesado. Calidad: ' .. qualityText .. ' (' .. quality .. '%)', 'success')

            AIT.Jobs.Drugs.TriggerPoliceAlert('process', coords)
        else
            AIT.Notify('Procesamiento cancelado', 'error')
        end
    end

    isProcessing = false
end)

-- ═══════════════════════════════════════════════════════════════
-- VENTA DE DROGAS
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('venderdrogas', function()
    if isProcessing then
        AIT.Notify('Ya estás ocupado', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Buscar punto de venta cercano
    local nearestPoint = nil
    local drugType = nil

    -- Verificar weed
    for _, point in ipairs(Config.weed.sellLocations) do
        local dist = #(coords - point.coords)
        if dist < 30.0 then
            nearestPoint = point
            drugType = 'weed'
            break
        end
    end

    -- Verificar cocaine
    if not nearestPoint then
        for _, point in ipairs(Config.cocaine.sellLocations) do
            local dist = #(coords - point.coords)
            if dist < 30.0 then
                nearestPoint = point
                drugType = 'cocaine'
                break
            end
        end
    end

    -- Verificar meth
    if not nearestPoint then
        for _, point in ipairs(Config.meth.sellLocations) do
            local dist = #(coords - point.coords)
            if dist < 30.0 then
                nearestPoint = point
                drugType = 'meth'
                break
            end
        end
    end

    if not nearestPoint then
        AIT.Notify('No hay compradores cerca', 'error')
        return
    end

    TriggerServerEvent('ait:server:drugs:checkSell', drugType)
end, false)

RegisterNetEvent('ait:client:drugs:startSell', function(drugType, amount, quality)
    local drug = Config[drugType]
    if not drug then return end

    if AIT.Jobs.Drugs.CheckPoliceRisk('sell') then
        return
    end

    isProcessing = true
    local coords = GetEntityCoords(PlayerPedId())

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 5000,
            label = 'Vendiendo...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'mp_common',
                clip = 'givetake2_a',
            },
        }) then
            -- Calcular precio basado en calidad
            local basePrice = math.random(drug.sellPrice.min, drug.sellPrice.max)
            local qualityMultiplier = 0.5 + (quality / 100) * 0.8 -- 0.5x a 1.3x
            local finalPrice = math.floor(basePrice * qualityMultiplier * amount)

            TriggerServerEvent('ait:server:drugs:completeSell', drugType, amount, finalPrice)
            AIT.Jobs.Drugs.AddXP(Config.xpSell * amount)

            AIT.Notify('Vendiste ' .. amount .. ' por $' .. finalPrice, 'success')

            AIT.Jobs.Drugs.TriggerPoliceAlert('sell', coords)
        else
            AIT.Notify('Venta cancelada', 'error')
        end
    end

    isProcessing = false
end)

-- ═══════════════════════════════════════════════════════════════
-- COMPRA DE QUÍMICOS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:drugs:openChemicalShop', function()
    local options = {}

    for _, chemical in ipairs(Config.chemicals.items) do
        table.insert(options, {
            title = chemical.label,
            description = 'Precio: $' .. chemical.price,
            icon = 'flask',
            onSelect = function()
                -- Input para cantidad
                if lib and lib.inputDialog then
                    local input = lib.inputDialog('Comprar ' .. chemical.label, {
                        { type = 'number', label = 'Cantidad', min = 1, max = 50 },
                    })

                    if input and input[1] then
                        TriggerServerEvent('ait:server:drugs:buyChemical', chemical.name, input[1])
                    end
                end
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'drugs_chemicals',
            title = 'Contacto de Químicos',
            options = options,
        })
        lib.showContext('drugs_chemicals')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE RIESGO POLICIAL
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Drugs.CheckPoliceRisk(action)
    -- Verificar si hay policías en servicio
    -- Si hay muchos policías, mayor riesgo

    local risk = Config.policeRisk[action] or 20
    local roll = math.random(1, 100)

    if roll <= risk then
        AIT.Notify('Sientes que alguien te observa...', 'warning')
        -- No bloquear, solo advertir
    end

    return false -- No bloquear la acción
end

function AIT.Jobs.Drugs.TriggerPoliceAlert(action, coords)
    local risk = Config.policeRisk[action] or 20
    local roll = math.random(1, 100)

    if roll <= risk / 2 then -- 50% del riesgo para alerta real
        -- Enviar alerta a policías
        TriggerServerEvent('ait:server:police:drugAlert', action, coords)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Drugs.AddXP(amount)
    drugXP = drugXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if drugXP >= levelData.xpRequired and drugLevel < levelData.level then
            drugLevel = levelData.level
            AIT.Notify('¡Nivel de drogas ' .. drugLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:drugs:saveLevel', drugLevel, drugXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:drugs:loadLevel', function(level, xp)
    drugLevel = level or 1
    drugXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsProcessingDrugs', function() return isProcessing end)
exports('GetDrugLevel', function() return drugLevel end)
exports('GetDrugXP', function() return drugXP end)

return AIT.Jobs.Drugs
