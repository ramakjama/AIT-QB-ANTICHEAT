--[[
    AIT-QB: Sistema de Robos
    Trabajo ILEGAL - Robos a tiendas, casas, bancos, joyería
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Robbery = {}

local isRobbing = false
local robberyLevel = 1
local robberyXP = 0
local currentRobbery = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- TIENDAS 24/7
    stores = {
        cooldown = 900, -- 15 minutos entre robos a la misma tienda
        minPolice = 0,
        locations = {
            { coords = vector3(25.0, -1346.0, 29.0), name = 'Tienda 24/7 Strawberry', register = vector3(28.0, -1339.0, 29.0) },
            { coords = vector3(-47.0, -1757.0, 29.0), name = 'Tienda 24/7 Davis', register = vector3(-43.0, -1748.0, 29.0) },
            { coords = vector3(373.0, 326.0, 103.0), name = 'Tienda 24/7 Vinewood', register = vector3(378.0, 333.0, 103.0) },
            { coords = vector3(1164.0, -323.0, 69.0), name = 'Tienda 24/7 Mirror Park', register = vector3(1159.0, -314.0, 69.0) },
            { coords = vector3(2556.0, 380.0, 108.0), name = 'Tienda 24/7 Harmony', register = vector3(2549.0, 387.0, 108.0) },
            { coords = vector3(1960.0, 3740.0, 32.0), name = 'Tienda 24/7 Sandy Shores', register = vector3(1959.0, 3749.0, 32.0) },
            { coords = vector3(549.0, 2670.0, 42.0), name = 'Tienda 24/7 Harmony 2', register = vector3(547.0, 2662.0, 42.0) },
            { coords = vector3(-164.0, 6321.0, 31.0), name = 'Tienda 24/7 Paleto', register = vector3(-161.0, 6318.0, 31.0) },
        },
        loot = {
            { item = 'cash', min = 500, max = 1500 },
            { item = 'marked_bills', min = 200, max = 800 },
        },
        xp = 50,
        registerTime = 20000,
        safeTime = 45000,
        requiredItem = nil, -- No necesita herramienta
    },

    -- LICORERÍAS
    liquorStores = {
        cooldown = 1200, -- 20 minutos
        minPolice = 0,
        locations = {
            { coords = vector3(-1222.0, -906.0, 12.0), name = 'Licorería Vespucci', register = vector3(-1220.0, -908.0, 12.0) },
            { coords = vector3(-1486.0, -378.0, 40.0), name = 'Licorería Morningwood', register = vector3(-1487.0, -375.0, 40.0) },
        },
        loot = {
            { item = 'cash', min = 800, max = 2000 },
            { item = 'marked_bills', min = 400, max = 1000 },
        },
        xp = 75,
        registerTime = 25000,
        requiredItem = nil,
    },

    -- CASAS
    houses = {
        cooldown = 3600, -- 1 hora
        minPolice = 1,
        lockpickTime = 15000,
        searchTime = 10000,
        locations = {
            -- Vinewood Hills
            { coords = vector3(-853.0, 533.0, 105.0), name = 'Casa Vinewood 1', tier = 'alta' },
            { coords = vector3(-1290.0, 449.0, 97.0), name = 'Casa Vinewood 2', tier = 'alta' },
            { coords = vector3(-174.0, 497.0, 137.0), name = 'Casa Vinewood 3', tier = 'alta' },

            -- Centro
            { coords = vector3(-1154.0, -1518.0, 10.0), name = 'Casa Vespucci', tier = 'media' },
            { coords = vector3(-632.0, -234.0, 38.0), name = 'Casa Centro', tier = 'media' },

            -- Barrios bajos
            { coords = vector3(86.0, -1959.0, 21.0), name = 'Casa Davis', tier = 'baja' },
            { coords = vector3(-32.0, -1438.0, 31.0), name = 'Casa Rancho', tier = 'baja' },
        },
        loot = {
            baja = {
                { item = 'cash', min = 100, max = 500, chance = 70 },
                { item = 'phone', min = 1, max = 1, chance = 30 },
                { item = 'rolex', min = 1, max = 1, chance = 10 },
            },
            media = {
                { item = 'cash', min = 500, max = 1500, chance = 80 },
                { item = 'phone', min = 1, max = 2, chance = 50 },
                { item = 'rolex', min = 1, max = 1, chance = 25 },
                { item = 'laptop', min = 1, max = 1, chance = 20 },
                { item = 'gold_chain', min = 1, max = 1, chance = 15 },
            },
            alta = {
                { item = 'cash', min = 2000, max = 5000, chance = 90 },
                { item = 'rolex', min = 1, max = 2, chance = 60 },
                { item = 'laptop', min = 1, max = 2, chance = 50 },
                { item = 'gold_chain', min = 1, max = 2, chance = 40 },
                { item = 'diamond_ring', min = 1, max = 1, chance = 20 },
                { item = 'painting', min = 1, max = 1, chance = 10 },
            },
        },
        xp = 100,
        requiredItem = 'lockpick',
    },

    -- JOYERÍA (Vangelico)
    jewelry = {
        cooldown = 7200, -- 2 horas
        minPolice = 3,
        location = vector3(-630.0, -236.0, 38.0),
        interior = vector3(-630.0, -238.0, 38.0),
        displayCases = {
            { coords = vector3(-620.0, -230.0, 38.0), tier = 'diamantes' },
            { coords = vector3(-624.0, -231.0, 38.0), tier = 'oro' },
            { coords = vector3(-628.0, -232.0, 38.0), tier = 'plata' },
            { coords = vector3(-617.0, -234.0, 38.0), tier = 'diamantes' },
            { coords = vector3(-621.0, -235.0, 38.0), tier = 'oro' },
            { coords = vector3(-625.0, -236.0, 38.0), tier = 'plata' },
        },
        loot = {
            plata = {
                { item = 'silver_necklace', min = 1, max = 2 },
                { item = 'silver_ring', min = 1, max = 3 },
            },
            oro = {
                { item = 'gold_necklace', min = 1, max = 2 },
                { item = 'gold_ring', min = 1, max = 2 },
                { item = 'gold_watch', min = 1, max = 1 },
            },
            diamantes = {
                { item = 'diamond_necklace', min = 1, max = 1 },
                { item = 'diamond_ring', min = 1, max = 2 },
                { item = 'diamond_earrings', min = 1, max = 2 },
            },
        },
        smashTime = 8000,
        xp = 200,
        requiredItem = 'thermite', -- Para abrir
    },

    -- FLEECA BANK
    fleecaBank = {
        cooldown = 10800, -- 3 horas
        minPolice = 4,
        locations = {
            { coords = vector3(149.0, -1040.0, 29.0), name = 'Fleeca Legion Square' },
            { coords = vector3(-350.0, -49.0, 49.0), name = 'Fleeca Burton' },
            { coords = vector3(-1212.0, -330.0, 37.0), name = 'Fleeca Rockford Hills' },
            { coords = vector3(-2962.0, 482.0, 15.0), name = 'Fleeca Pacific Bluffs' },
            { coords = vector3(1175.0, 2706.0, 38.0), name = 'Fleeca Harmony' },
        },
        vault = {
            hackingTime = 30000,
            drillingTime = 60000,
            loot = {
                { item = 'cash', min = 20000, max = 50000 },
                { item = 'marked_bills', min = 15000, max = 35000 },
                { item = 'gold_bar', min = 2, max = 5 },
            },
        },
        xp = 500,
        requiredItems = { 'laptop', 'drill' },
    },

    -- PACIFIC STANDARD (Gran banco)
    pacificBank = {
        cooldown = 28800, -- 8 horas
        minPolice = 6,
        location = vector3(235.0, 216.0, 106.0),
        stages = {
            { name = 'entrada', coords = vector3(232.0, 214.0, 106.0) },
            { name = 'seguridad', coords = vector3(241.0, 225.0, 106.0) },
            { name = 'boveda', coords = vector3(255.0, 225.0, 102.0) },
        },
        vault = {
            hackingTime = 45000,
            thermiteTime = 30000,
            loot = {
                { item = 'cash', min = 100000, max = 250000 },
                { item = 'marked_bills', min = 50000, max = 100000 },
                { item = 'gold_bar', min = 10, max = 25 },
                { item = 'diamond_uncut', min = 5, max = 15 },
            },
        },
        xp = 1500,
        requiredItems = { 'laptop', 'thermite', 'drill', 'usb_hack' },
    },

    -- Fencing (venta de objetos robados)
    fence = {
        coords = vector3(308.0, -917.0, 24.0),
        prices = {
            marked_bills = 0.6, -- 60% del valor
            gold_bar = 5000,
            phone = 150,
            laptop = 800,
            rolex = 2500,
            gold_chain = 1500,
            diamond_ring = 5000,
            painting = 10000,
            silver_necklace = 200,
            silver_ring = 100,
            gold_necklace = 800,
            gold_ring = 500,
            gold_watch = 1200,
            diamond_necklace = 8000,
            diamond_earrings = 3000,
            diamond_uncut = 2000,
        },
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Ratero', hackBonus = 0 },
        { level = 2, xpRequired = 500, title = 'Ladrón', hackBonus = 5 },
        { level = 3, xpRequired = 1500, title = 'Ladrón Experto', hackBonus = 10 },
        { level = 4, xpRequired = 4000, title = 'Profesional', hackBonus = 15 },
        { level = 5, xpRequired = 10000, title = 'Maestro del Crimen', hackBonus = 25 },
    },
}

-- Tiendas en cooldown
local storeCooldowns = {}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Robbery.Init()
    -- No blips públicos para actividades ilegales
    print('[AIT-QB] Sistema de robos inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- ROBOS A TIENDAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Robbery.FindNearestStore()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Buscar en tiendas 24/7
    for i, store in ipairs(Config.stores.locations) do
        local dist = #(coords - store.register)
        if dist < 2.0 then
            return 'store', i, store
        end
    end

    -- Buscar en licorerías
    for i, store in ipairs(Config.liquorStores.locations) do
        local dist = #(coords - store.register)
        if dist < 2.0 then
            return 'liquor', i, store
        end
    end

    return nil
end

RegisterCommand('robartienda', function()
    if isRobbing then
        AIT.Notify('Ya estás robando', 'error')
        return
    end

    local storeType, storeIndex, store = AIT.Jobs.Robbery.FindNearestStore()

    if not storeType then
        AIT.Notify('No hay caja registradora cerca', 'error')
        return
    end

    local config = storeType == 'store' and Config.stores or Config.liquorStores

    -- Verificar cooldown
    local cooldownKey = storeType .. '_' .. storeIndex
    if storeCooldowns[cooldownKey] and storeCooldowns[cooldownKey] > GetGameTimer() then
        local remaining = math.ceil((storeCooldowns[cooldownKey] - GetGameTimer()) / 1000 / 60)
        AIT.Notify('Esta tienda fue robada hace poco. Espera ' .. remaining .. ' minutos.', 'error')
        return
    end

    -- Verificar policías mínimos
    TriggerServerEvent('ait:server:robbery:checkPolice', config.minPolice, function(canRob)
        if canRob then
            AIT.Jobs.Robbery.StartStoreRobbery(storeType, storeIndex, store, config)
        end
    end)
end, false)

RegisterNetEvent('ait:client:robbery:policeChecked', function(canRob, storeType, storeIndex, config)
    if canRob then
        local store = (storeType == 'store' and Config.stores or Config.liquorStores).locations[storeIndex]
        AIT.Jobs.Robbery.StartStoreRobbery(storeType, storeIndex, store, config)
    else
        AIT.Notify('No hay suficientes policías en servicio para este tipo de robo', 'error')
    end
end)

function AIT.Jobs.Robbery.StartStoreRobbery(storeType, storeIndex, store, config)
    isRobbing = true

    local ped = PlayerPedId()

    -- Alertar a la policía
    TriggerServerEvent('ait:server:police:robberyAlert', 'store', store.coords, store.name)

    AIT.Notify('¡Robo iniciado! La policía ha sido alertada.', 'warning')

    -- Animación de apuntar
    if not IsPedArmed(ped, 4) then
        AIT.Notify('Necesitas un arma para intimidar al cajero', 'error')
        isRobbing = false
        return
    end

    if lib and lib.progressBar then
        -- Fase 1: Vaciar caja registradora
        if lib.progressBar({
            duration = config.registerTime,
            label = 'Vaciando caja registradora...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, combat = true },
        }) then
            -- Dar loot de caja
            for _, lootItem in ipairs(config.loot) do
                local amount = math.random(lootItem.min, lootItem.max)
                TriggerServerEvent('ait:server:robbery:addLoot', lootItem.item, amount)
            end

            AIT.Jobs.Robbery.AddXP(config.xp)

            -- Establecer cooldown
            local cooldownKey = storeType .. '_' .. storeIndex
            storeCooldowns[cooldownKey] = GetGameTimer() + (config.cooldown * 1000)

            AIT.Notify('Caja vaciada. ¡Huye!', 'success')
        else
            AIT.Notify('Robo cancelado', 'error')
        end
    end

    isRobbing = false
    currentRobbery = nil
end

-- ═══════════════════════════════════════════════════════════════
-- ROBOS A CASAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Robbery.FindNearestHouse()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for i, house in ipairs(Config.houses.locations) do
        local dist = #(coords - house.coords)
        if dist < 3.0 then
            return i, house
        end
    end

    return nil
end

RegisterCommand('robarcasa', function()
    if isRobbing then
        AIT.Notify('Ya estás robando', 'error')
        return
    end

    local houseIndex, house = AIT.Jobs.Robbery.FindNearestHouse()

    if not houseIndex then
        AIT.Notify('No hay casa para robar cerca', 'error')
        return
    end

    -- Verificar lockpick
    TriggerServerEvent('ait:server:robbery:checkItem', 'lockpick')
end, false)

RegisterNetEvent('ait:client:robbery:itemChecked', function(hasItem, itemType)
    if not hasItem then
        AIT.Notify('Necesitas una ganzúa', 'error')
        return
    end

    local houseIndex, house = AIT.Jobs.Robbery.FindNearestHouse()
    if house then
        AIT.Jobs.Robbery.StartHouseRobbery(houseIndex, house)
    end
end)

function AIT.Jobs.Robbery.StartHouseRobbery(houseIndex, house)
    isRobbing = true

    -- Alertar a la policía
    TriggerServerEvent('ait:server:police:robberyAlert', 'house', house.coords, house.name)

    -- Fase 1: Forzar cerradura
    if lib and lib.skillCheck then
        local success = lib.skillCheck({ 'easy', 'easy', 'medium' }, { 'w', 'a', 's', 'd' })

        if success then
            AIT.Notify('Cerradura forzada', 'success')

            -- Fase 2: Registrar casa
            AIT.Jobs.Robbery.SearchHouse(house)
        else
            AIT.Notify('Fallaste al forzar la cerradura', 'error')
            -- Consumir lockpick
            TriggerServerEvent('ait:server:robbery:useItem', 'lockpick')
        end
    else
        -- Fallback sin skillCheck
        if lib and lib.progressBar then
            if lib.progressBar({
                duration = Config.houses.lockpickTime,
                label = 'Forzando cerradura...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
            }) then
                AIT.Jobs.Robbery.SearchHouse(house)
            end
        end
    end

    isRobbing = false
end

function AIT.Jobs.Robbery.SearchHouse(house)
    local lootTable = Config.houses.loot[house.tier]
    local itemsFound = {}

    -- Múltiples búsquedas
    for i = 1, 3 do
        if lib and lib.progressBar then
            if lib.progressBar({
                duration = Config.houses.searchTime,
                label = 'Registrando... (' .. i .. '/3)',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'anim@gangops@facility@servers@bodysearch@',
                    clip = 'player_search',
                },
            }) then
                -- Determinar loot
                for _, lootItem in ipairs(lootTable) do
                    if math.random(1, 100) <= lootItem.chance then
                        local amount = math.random(lootItem.min, lootItem.max)
                        TriggerServerEvent('ait:server:robbery:addLoot', lootItem.item, amount)
                        table.insert(itemsFound, lootItem.item .. ' x' .. amount)
                    end
                end
            else
                AIT.Notify('Registro cancelado', 'error')
                break
            end
        end
    end

    if #itemsFound > 0 then
        AIT.Notify('Encontraste: ' .. table.concat(itemsFound, ', '), 'success')
        AIT.Jobs.Robbery.AddXP(Config.houses.xp)
    else
        AIT.Notify('No encontraste nada de valor', 'info')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ROBO A JOYERÍA
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('robarjoyeria', function()
    if isRobbing then
        AIT.Notify('Ya estás robando', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - Config.jewelry.location)

    if dist > 30.0 then
        AIT.Notify('No estás cerca de la joyería', 'error')
        return
    end

    -- Verificar termita
    TriggerServerEvent('ait:server:robbery:checkItem', 'thermite')
end, false)

RegisterNetEvent('ait:client:robbery:jewelryStart', function()
    AIT.Jobs.Robbery.StartJewelryRobbery()
end)

function AIT.Jobs.Robbery.StartJewelryRobbery()
    isRobbing = true

    -- Alertar a la policía (nivel alto)
    TriggerServerEvent('ait:server:police:robberyAlert', 'jewelry', Config.jewelry.location, 'Joyería Vangelico')

    AIT.Notify('¡ALERTA! Robo a joyería en progreso', 'warning')

    -- Romper vitrinas
    for i, display in ipairs(Config.jewelry.displayCases) do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - display.coords)

        if dist < 2.0 then
            if lib and lib.progressBar then
                if lib.progressBar({
                    duration = Config.jewelry.smashTime,
                    label = 'Rompiendo vitrina...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                }) then
                    -- Dar loot según tier
                    local lootTable = Config.jewelry.loot[display.tier]
                    for _, lootItem in ipairs(lootTable) do
                        local amount = math.random(lootItem.min, lootItem.max)
                        TriggerServerEvent('ait:server:robbery:addLoot', lootItem.item, amount)
                    end

                    AIT.Notify('Vitrina de ' .. display.tier .. ' saqueada', 'success')
                end
            end
        end
    end

    AIT.Jobs.Robbery.AddXP(Config.jewelry.xp)
    isRobbing = false
end

-- ═══════════════════════════════════════════════════════════════
-- ROBO A BANCO FLEECA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Robbery.FindNearestFleeca()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for i, bank in ipairs(Config.fleecaBank.locations) do
        local dist = #(coords - bank.coords)
        if dist < 10.0 then
            return i, bank
        end
    end

    return nil
end

RegisterCommand('robarfleeca', function()
    if isRobbing then
        AIT.Notify('Ya estás robando', 'error')
        return
    end

    local bankIndex, bank = AIT.Jobs.Robbery.FindNearestFleeca()

    if not bankIndex then
        AIT.Notify('No estás cerca de un banco Fleeca', 'error')
        return
    end

    -- Verificar items requeridos
    TriggerServerEvent('ait:server:robbery:checkBankItems', 'fleeca')
end, false)

RegisterNetEvent('ait:client:robbery:fleecaStart', function(bankIndex)
    local bank = Config.fleecaBank.locations[bankIndex]
    AIT.Jobs.Robbery.StartFleecaRobbery(bankIndex, bank)
end)

function AIT.Jobs.Robbery.StartFleecaRobbery(bankIndex, bank)
    isRobbing = true

    -- Alertar a la policía
    TriggerServerEvent('ait:server:police:robberyAlert', 'fleeca', bank.coords, bank.name)

    AIT.Notify('¡ALERTA MÁXIMA! Robo a banco en progreso', 'error')

    -- Fase 1: Hackear sistema
    if lib and lib.skillCheck then
        AIT.Notify('Hackeando sistema de seguridad...', 'info')

        local success = lib.skillCheck({ 'medium', 'medium', 'hard', 'hard' }, { 'w', 'a', 's', 'd' })

        if not success then
            AIT.Notify('Hackeo fallido. Alarma activada.', 'error')
            isRobbing = false
            return
        end

        AIT.Notify('Sistema hackeado', 'success')
    end

    -- Fase 2: Taladrar bóveda
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.fleecaBank.vault.drillingTime,
            label = 'Taladrando bóveda...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            AIT.Notify('Bóveda abierta', 'success')

            -- Fase 3: Saquear
            for _, lootItem in ipairs(Config.fleecaBank.vault.loot) do
                local amount = math.random(lootItem.min, lootItem.max)
                TriggerServerEvent('ait:server:robbery:addLoot', lootItem.item, amount)
            end

            AIT.Jobs.Robbery.AddXP(Config.fleecaBank.xp)
            AIT.Notify('¡Banco saqueado! ¡HUYE!', 'success')
        end
    end

    isRobbing = false
end

-- ═══════════════════════════════════════════════════════════════
-- PACIFIC STANDARD (Gran golpe)
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('robarpacific', function()
    if isRobbing then
        AIT.Notify('Ya estás robando', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - Config.pacificBank.location)

    if dist > 20.0 then
        AIT.Notify('No estás cerca del Pacific Standard', 'error')
        return
    end

    -- Este robo requiere mínimo 4 jugadores
    TriggerServerEvent('ait:server:robbery:checkPacific')
end, false)

RegisterNetEvent('ait:client:robbery:pacificStart', function()
    AIT.Jobs.Robbery.StartPacificRobbery()
end)

function AIT.Jobs.Robbery.StartPacificRobbery()
    isRobbing = true

    -- Alertar máxima prioridad
    TriggerServerEvent('ait:server:police:robberyAlert', 'pacific', Config.pacificBank.location, 'Pacific Standard Bank')

    AIT.Notify('¡¡¡CÓDIGO ROJO!!! Asalto al Pacific Standard', 'error')

    -- Este es un robo multi-fase que requiere coordinación
    -- Simplificado para este ejemplo

    -- Fase 1: Entrada
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Tomando el control de la entrada...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, combat = true },
        }) then
            AIT.Notify('Entrada asegurada', 'success')
        else
            isRobbing = false
            return
        end
    end

    -- Fase 2: Seguridad
    if lib and lib.skillCheck then
        local success = lib.skillCheck({ 'hard', 'hard', 'hard', 'hard', 'hard' }, { 'w', 'a', 's', 'd' })

        if not success then
            AIT.Notify('Hackeo fallido', 'error')
            isRobbing = false
            return
        end
    end

    -- Fase 3: Bóveda
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.pacificBank.vault.thermiteTime,
            label = 'Usando termita en la bóveda...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            -- Dar loot masivo
            for _, lootItem in ipairs(Config.pacificBank.vault.loot) do
                local amount = math.random(lootItem.min, lootItem.max)
                TriggerServerEvent('ait:server:robbery:addLoot', lootItem.item, amount)
            end

            AIT.Jobs.Robbery.AddXP(Config.pacificBank.xp)
            AIT.Notify('¡¡¡GOLPE COMPLETADO!!! ¡ESCAPA!', 'success')
        end
    end

    isRobbing = false
end

-- ═══════════════════════════════════════════════════════════════
-- PERISTA (Venta de objetos robados)
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:robbery:openFence', function(inventory)
    local options = {}
    local totalValue = 0

    for item, baseValue in pairs(Config.fence.prices) do
        local amount = inventory[item] or 0
        if amount > 0 then
            local value
            if baseValue < 1 then
                -- Es un porcentaje (para billetes marcados)
                value = math.floor(amount * baseValue)
            else
                value = baseValue * amount
            end
            totalValue = totalValue + value

            table.insert(options, {
                title = item:gsub('_', ' '):gsub('^%l', string.upper) .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'sack-dollar',
                onSelect = function()
                    TriggerServerEvent('ait:server:robbery:sellToFence', item, amount, value)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes objetos robados para vender', 'error')
        return
    end

    table.insert(options, 1, {
        title = 'Vender Todo',
        description = 'Valor total: $' .. totalValue,
        icon = 'dollar-sign',
        onSelect = function()
            TriggerServerEvent('ait:server:robbery:sellAllToFence')
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'robbery_fence',
            title = 'Perista',
            options = options,
        })
        lib.showContext('robbery_fence')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Robbery.AddXP(amount)
    robberyXP = robberyXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if robberyXP >= levelData.xpRequired and robberyLevel < levelData.level then
            robberyLevel = levelData.level
            AIT.Notify('¡Nivel de robo ' .. robberyLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:robbery:saveLevel', robberyLevel, robberyXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:robbery:loadLevel', function(level, xp)
    robberyLevel = level or 1
    robberyXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsRobbing', function() return isRobbing end)
exports('GetRobberyLevel', function() return robberyLevel end)

return AIT.Jobs.Robbery
