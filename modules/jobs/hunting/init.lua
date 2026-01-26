--[[
    AIT-QB: Sistema de Caza
    Trabajo legal - Caza de animales
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Hunting = {}

local isHunting = false
local huntingLevel = 1
local huntingXP = 0
local currentPrey = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    shop = {
        coords = vector3(-685.0, 5839.0, 17.0),
        blip = { sprite = 141, color = 69, scale = 0.8 },
    },

    butcher = {
        coords = vector3(-69.0, 6270.0, 31.0),
        blip = { sprite = 52, color = 1, scale = 0.7 },
        processTime = 8000,
    },

    -- Zonas de caza
    huntingZones = {
        {
            name = 'Bosque de Paleto',
            coords = vector3(-556.0, 5505.0, 70.0),
            radius = 300.0,
            animals = { 'boar', 'deer', 'rabbit', 'coyote' },
            quality = 'normal',
            blip = { sprite = 141, color = 69, scale = 0.6 },
        },
        {
            name = 'Montañas Chiliad',
            coords = vector3(450.0, 5600.0, 750.0),
            radius = 400.0,
            animals = { 'deer', 'mountain_lion', 'boar', 'coyote' },
            quality = 'buena',
        },
        {
            name = 'Desierto de Sandy',
            coords = vector3(2200.0, 5000.0, 55.0),
            radius = 350.0,
            animals = { 'coyote', 'rabbit', 'boar' },
            quality = 'normal',
        },
        {
            name = 'Reserva Natural',
            coords = vector3(-2100.0, 2500.0, 10.0),
            radius = 250.0,
            animals = { 'deer', 'elk', 'boar', 'mountain_lion' },
            quality = 'rara',
        },
    },

    -- Animales
    animals = {
        -- Comunes
        rabbit = {
            name = 'rabbit',
            label = 'Conejo',
            model = 'a_c_rabbit_01',
            health = 50,
            difficulty = 1,
            xp = 10,
            drops = {
                { item = 'raw_rabbit', amount = { 1, 2 }, chance = 100 },
                { item = 'animal_pelt_small', amount = { 1, 1 }, chance = 80 },
            },
            rarity = 'comun',
        },
        coyote = {
            name = 'coyote',
            label = 'Coyote',
            model = 'a_c_coyote',
            health = 100,
            difficulty = 2,
            xp = 20,
            drops = {
                { item = 'raw_coyote', amount = { 2, 4 }, chance = 100 },
                { item = 'animal_pelt_medium', amount = { 1, 1 }, chance = 70 },
                { item = 'animal_fat', amount = { 1, 2 }, chance = 50 },
            },
            rarity = 'comun',
            aggressive = true,
        },

        -- Normales
        boar = {
            name = 'boar',
            label = 'Jabalí',
            model = 'a_c_boar',
            health = 200,
            difficulty = 3,
            xp = 35,
            drops = {
                { item = 'raw_boar', amount = { 3, 6 }, chance = 100 },
                { item = 'animal_pelt_medium', amount = { 1, 2 }, chance = 75 },
                { item = 'animal_fat', amount = { 2, 4 }, chance = 60 },
                { item = 'boar_tusk', amount = { 0, 2 }, chance = 30 },
            },
            rarity = 'normal',
            aggressive = true,
        },
        deer = {
            name = 'deer',
            label = 'Ciervo',
            model = 'a_c_deer',
            health = 150,
            difficulty = 3,
            xp = 40,
            drops = {
                { item = 'raw_venison', amount = { 4, 8 }, chance = 100 },
                { item = 'animal_pelt_large', amount = { 1, 1 }, chance = 85 },
                { item = 'deer_antlers', amount = { 0, 1 }, chance = 40 },
            },
            rarity = 'normal',
            flees = true,
        },

        -- Buenos
        elk = {
            name = 'elk',
            label = 'Alce',
            model = 'a_c_mtlion', -- No hay modelo de alce, usar alternativo
            health = 300,
            difficulty = 4,
            xp = 60,
            drops = {
                { item = 'raw_elk', amount = { 6, 10 }, chance = 100 },
                { item = 'animal_pelt_large', amount = { 1, 2 }, chance = 90 },
                { item = 'elk_antlers', amount = { 0, 1 }, chance = 50 },
                { item = 'animal_fat', amount = { 3, 5 }, chance = 70 },
            },
            rarity = 'buena',
        },

        -- Raros (Peligrosos)
        mountain_lion = {
            name = 'mountain_lion',
            label = 'Puma',
            model = 'a_c_mtlion',
            health = 400,
            difficulty = 5,
            xp = 100,
            drops = {
                { item = 'raw_mountain_lion', amount = { 5, 8 }, chance = 100 },
                { item = 'animal_pelt_exotic', amount = { 1, 1 }, chance = 95 },
                { item = 'mountain_lion_claw', amount = { 1, 4 }, chance = 60 },
                { item = 'mountain_lion_fang', amount = { 1, 2 }, chance = 40 },
            },
            rarity = 'rara',
            aggressive = true,
            dangerous = true,
        },
    },

    -- Precios de carne
    meatPrices = {
        raw_rabbit = 25,
        raw_coyote = 35,
        raw_boar = 50,
        raw_venison = 65,
        raw_elk = 90,
        raw_mountain_lion = 150,
        -- Cocinada vale más
        cooked_rabbit = 60,
        cooked_coyote = 80,
        cooked_boar = 120,
        cooked_venison = 150,
        cooked_elk = 200,
        cooked_mountain_lion = 350,
    },

    -- Precios de pieles y otros
    otherPrices = {
        animal_pelt_small = 50,
        animal_pelt_medium = 120,
        animal_pelt_large = 250,
        animal_pelt_exotic = 800,
        animal_fat = 20,
        boar_tusk = 150,
        deer_antlers = 200,
        elk_antlers = 400,
        mountain_lion_claw = 300,
        mountain_lion_fang = 500,
    },

    -- Equipamiento
    equipment = {
        huntingRifle = { name = 'weapon_musket', label = 'Rifle de Caza', price = 5000 },
        huntingBow = { name = 'weapon_compactlauncher', label = 'Arco de Caza', price = 2500 },
        huntingKnife = { name = 'weapon_knife', label = 'Cuchillo de Caza', price = 500 },
        binoculars = { name = 'binoculars', label = 'Prismáticos', price = 300 },
        bait = { name = 'hunting_bait', label = 'Cebo para Caza', price = 50 },
        scent_blocker = { name = 'scent_blocker', label = 'Bloqueador de Olor', price = 100 },
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Cazador Novato' },
        { level = 2, xpRequired = 100, title = 'Cazador Aprendiz' },
        { level = 3, xpRequired = 300, title = 'Cazador' },
        { level = 4, xpRequired = 600, title = 'Cazador Experto' },
        { level = 5, xpRequired = 1200, title = 'Maestro Cazador' },
        { level = 6, xpRequired = 2000, title = 'Cazador Legendario' },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Hunting.Init()
    -- Blip tienda
    local shopBlip = AddBlipForCoord(Config.shop.coords.x, Config.shop.coords.y, Config.shop.coords.z)
    SetBlipSprite(shopBlip, Config.shop.blip.sprite)
    SetBlipColour(shopBlip, Config.shop.blip.color)
    SetBlipScale(shopBlip, Config.shop.blip.scale)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Tienda de Caza')
    EndTextCommandSetBlipName(shopBlip)

    -- Blip carnicero
    local butcherBlip = AddBlipForCoord(Config.butcher.coords.x, Config.butcher.coords.y, Config.butcher.coords.z)
    SetBlipSprite(butcherBlip, Config.butcher.blip.sprite)
    SetBlipColour(butcherBlip, Config.butcher.blip.color)
    SetBlipScale(butcherBlip, Config.butcher.blip.scale)
    SetBlipAsShortRange(butcherBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Carnicero')
    EndTextCommandSetBlipName(butcherBlip)

    -- Blips de zonas
    for _, zone in ipairs(Config.huntingZones) do
        local zoneBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(zoneBlip, 141)
        SetBlipColour(zoneBlip, 69)
        SetBlipScale(zoneBlip, 0.6)
        SetBlipAsShortRange(zoneBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Zona de Caza: ' .. zone.name)
        EndTextCommandSetBlipName(zoneBlip)
    end

    print('[AIT-QB] Sistema de caza inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- TIENDA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:hunting:openShop', function()
    local options = {
        {
            title = 'Rifle de Caza',
            description = 'Precio: $' .. Config.equipment.huntingRifle.price,
            icon = 'crosshairs',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:buyItem', 'huntingRifle')
            end,
        },
        {
            title = 'Arco de Caza',
            description = 'Precio: $' .. Config.equipment.huntingBow.price .. ' | Silencioso',
            icon = 'bow-arrow',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:buyItem', 'huntingBow')
            end,
        },
        {
            title = 'Cuchillo de Caza',
            description = 'Precio: $' .. Config.equipment.huntingKnife.price .. ' | Para despiezar',
            icon = 'knife',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:buyItem', 'huntingKnife')
            end,
        },
        {
            title = 'Prismáticos',
            description = 'Precio: $' .. Config.equipment.binoculars.price,
            icon = 'binoculars',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:buyItem', 'binoculars')
            end,
        },
        {
            title = 'Cebo de Caza (x5)',
            description = 'Precio: $' .. (Config.equipment.bait.price * 5) .. ' | Atrae animales',
            icon = 'bone',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:buyItem', 'bait', 5)
            end,
        },
        {
            title = 'Bloqueador de Olor (x3)',
            description = 'Precio: $' .. (Config.equipment.scent_blocker.price * 3) .. ' | Evita que te detecten',
            icon = 'spray-can',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:buyItem', 'scent_blocker', 3)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'hunting_shop',
            title = 'Tienda de Caza',
            options = options,
        })
        lib.showContext('hunting_shop')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE CAZA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Hunting.GetCurrentZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, zone in ipairs(Config.huntingZones) do
        local dist = #(coords - zone.coords)
        if dist <= zone.radius then
            return zone
        end
    end

    return nil
end

-- Colocar cebo
RegisterCommand('colocarcebo', function()
    local zone = AIT.Jobs.Hunting.GetCurrentZone()
    if not zone then
        AIT.Notify('No estás en una zona de caza', 'error')
        return
    end

    TriggerServerEvent('ait:server:hunting:checkBait')
end, false)

RegisterNetEvent('ait:client:hunting:baitChecked', function(hasBait)
    if not hasBait then
        AIT.Notify('No tienes cebo', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 5000,
            label = 'Colocando cebo...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'anim@mp_snowball',
                clip = 'pickup_snowball',
            },
        }) then
            TriggerServerEvent('ait:server:hunting:useBait')

            -- Crear prop de cebo
            local baitProp = CreateObject(GetHashKey('prop_cs_steak'), coords.x, coords.y, coords.z - 1.0, true, true, true)
            PlaceObjectOnGroundProperly(baitProp)

            AIT.Notify('Cebo colocado. Espera escondido.', 'success')

            -- Spawn animal atraído después de un tiempo
            SetTimeout(math.random(15000, 30000), function()
                if DoesEntityExist(baitProp) then
                    AIT.Jobs.Hunting.SpawnAnimalNearBait(coords)
                    DeleteObject(baitProp)
                end
            end)

            -- El cebo desaparece después de 2 minutos
            SetTimeout(120000, function()
                if DoesEntityExist(baitProp) then
                    DeleteObject(baitProp)
                end
            end)
        end
    end
end)

function AIT.Jobs.Hunting.SpawnAnimalNearBait(baitCoords)
    local zone = AIT.Jobs.Hunting.GetCurrentZone()
    if not zone then return end

    -- Seleccionar animal aleatorio de la zona
    local animalName = zone.animals[math.random(1, #zone.animals)]
    local animalData = Config.animals[animalName]

    if not animalData then return end

    -- Spawn a cierta distancia
    local spawnOffset = vector3(math.random(-20, 20), math.random(-20, 20), 0)
    local spawnCoords = baitCoords + spawnOffset

    local hash = GetHashKey(animalData.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local animal = CreatePed(28, hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, math.random(0, 360), true, true)
    SetModelAsNoLongerNeeded(hash)

    -- Configurar comportamiento
    SetBlockingOfNonTemporaryEvents(animal, true)
    TaskGoToCoordAnyMeans(animal, baitCoords.x, baitCoords.y, baitCoords.z, 1.0, 0, false, 786603, 0)

    -- Guardar referencia
    currentPrey = {
        entity = animal,
        data = animalData,
        zone = zone,
    }

    AIT.Notify('Un ' .. animalData.label .. ' se acerca al cebo', 'info')

    -- Thread para monitorear muerte
    AIT.Jobs.Hunting.MonitorPrey()
end

function AIT.Jobs.Hunting.MonitorPrey()
    if not currentPrey then return end

    CreateThread(function()
        while currentPrey and DoesEntityExist(currentPrey.entity) do
            Wait(500)

            if IsEntityDead(currentPrey.entity) then
                AIT.Jobs.Hunting.OnPreyKilled()
                break
            end
        end
    end)
end

function AIT.Jobs.Hunting.OnPreyKilled()
    if not currentPrey then return end

    local animal = currentPrey.entity
    local data = currentPrey.data

    AIT.Notify('Has cazado un ' .. data.label .. '. Despiezalo con [E]', 'success')

    -- Dar XP
    AIT.Jobs.Hunting.AddXP(data.xp)

    -- Crear zona de despiece
    local coords = GetEntityCoords(animal)

    if lib and lib.zones then
        local harvestZone = lib.zones.sphere({
            coords = coords,
            radius = 3.0,
            onEnter = function()
                lib.showTextUI('[E] Despiezar ' .. data.label)
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })

        -- Guardar para interacción
        currentPrey.harvestZone = harvestZone
        currentPrey.coords = coords
    end
end

RegisterCommand('despiezar', function()
    if not currentPrey then
        AIT.Notify('No hay animal para despiezar', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - currentPrey.coords)

    if dist > 3.0 then
        AIT.Notify('Acércate más al animal', 'error')
        return
    end

    -- Verificar cuchillo
    TriggerServerEvent('ait:server:hunting:checkKnife')
end, false)

RegisterNetEvent('ait:client:hunting:knifeChecked', function(hasKnife)
    if not hasKnife then
        AIT.Notify('Necesitas un cuchillo de caza', 'error')
        return
    end

    if not currentPrey then return end

    local data = currentPrey.data

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Despiezando ' .. data.label .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'amb@medic@standing@kneel@base',
                clip = 'base',
            },
        }) then
            -- Dar drops
            for _, drop in ipairs(data.drops) do
                if math.random(1, 100) <= drop.chance then
                    local amount = math.random(drop.amount[1], drop.amount[2])
                    if amount > 0 then
                        TriggerServerEvent('ait:server:hunting:addItem', drop.item, amount)
                        AIT.Notify('+' .. amount .. ' ' .. drop.item, 'success')
                    end
                end
            end

            -- Eliminar animal
            if DoesEntityExist(currentPrey.entity) then
                DeleteEntity(currentPrey.entity)
            end

            -- Limpiar zona
            if currentPrey.harvestZone then
                currentPrey.harvestZone:remove()
            end

            currentPrey = nil
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SPAWN NATURAL DE ANIMALES
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(30000) -- Cada 30 segundos

        local zone = AIT.Jobs.Hunting.GetCurrentZone()
        if zone and not currentPrey then
            -- 20% de chance de spawn natural
            if math.random(1, 100) <= 20 then
                local ped = PlayerPedId()
                local playerCoords = GetEntityCoords(ped)

                -- Spawn lejos del jugador
                local angle = math.rad(math.random(0, 360))
                local distance = math.random(50, 100)
                local spawnCoords = vector3(
                    playerCoords.x + math.cos(angle) * distance,
                    playerCoords.y + math.sin(angle) * distance,
                    playerCoords.z
                )

                -- Ajustar altura
                local _, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 50.0, false)
                if groundZ then
                    spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
                end

                -- Seleccionar animal
                local animalName = zone.animals[math.random(1, #zone.animals)]
                local animalData = Config.animals[animalName]

                if animalData then
                    local hash = GetHashKey(animalData.model)
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do Wait(10) end

                    local animal = CreatePed(28, hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, math.random(0, 360), true, true)
                    SetModelAsNoLongerNeeded(hash)

                    -- Comportamiento natural
                    TaskWanderStandard(animal, 10.0, 10)

                    currentPrey = {
                        entity = animal,
                        data = animalData,
                        zone = zone,
                    }

                    AIT.Jobs.Hunting.MonitorPrey()
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- CARNICERO - PROCESAR Y VENDER
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:hunting:openButcher', function(inventory)
    local options = {
        {
            title = '🥩 Procesar Carne',
            description = 'Cocinar carne cruda',
            icon = 'fire',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:getInventoryForCooking')
            end,
        },
        {
            title = '💰 Vender Productos',
            description = 'Vender carne, pieles y otros',
            icon = 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('ait:server:hunting:getInventoryForSelling')
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'hunting_butcher',
            title = 'Carnicero',
            options = options,
        })
        lib.showContext('hunting_butcher')
    end
end)

RegisterNetEvent('ait:client:hunting:openCookingMenu', function(inventory)
    local options = {}

    local cookableItems = {
        { raw = 'raw_rabbit', cooked = 'cooked_rabbit', label = 'Conejo' },
        { raw = 'raw_coyote', cooked = 'cooked_coyote', label = 'Coyote' },
        { raw = 'raw_boar', cooked = 'cooked_boar', label = 'Jabalí' },
        { raw = 'raw_venison', cooked = 'cooked_venison', label = 'Venado' },
        { raw = 'raw_elk', cooked = 'cooked_elk', label = 'Alce' },
        { raw = 'raw_mountain_lion', cooked = 'cooked_mountain_lion', label = 'Puma' },
    }

    for _, item in ipairs(cookableItems) do
        local amount = inventory[item.raw] or 0
        if amount > 0 then
            table.insert(options, {
                title = 'Cocinar ' .. item.label,
                description = 'Tienes: ' .. amount .. ' crudos',
                icon = 'fire',
                onSelect = function()
                    AIT.Jobs.Hunting.CookMeat(item.raw, item.cooked, amount)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes carne cruda', 'error')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'hunting_cooking',
            title = 'Cocinar Carne',
            menu = 'hunting_butcher',
            options = options,
        })
        lib.showContext('hunting_cooking')
    end
end)

function AIT.Jobs.Hunting.CookMeat(rawItem, cookedItem, amount)
    for i = 1, amount do
        if lib and lib.progressBar then
            if lib.progressBar({
                duration = Config.butcher.processTime,
                label = 'Cocinando ' .. i .. '/' .. amount,
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
            }) then
                TriggerServerEvent('ait:server:hunting:cookMeat', rawItem, cookedItem)
            else
                AIT.Notify('Cocción cancelada', 'error')
                break
            end
        end
    end
end

RegisterNetEvent('ait:client:hunting:openSellMenu', function(inventory)
    local options = {}
    local totalValue = 0

    -- Carnes
    for item, price in pairs(Config.meatPrices) do
        local amount = inventory[item] or 0
        if amount > 0 then
            local value = price * amount
            totalValue = totalValue + value
            table.insert(options, {
                title = item:gsub('_', ' '):gsub('^%l', string.upper) .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'drumstick-bite',
                onSelect = function()
                    TriggerServerEvent('ait:server:hunting:sell', item, amount)
                end,
            })
        end
    end

    -- Otros (pieles, etc)
    for item, price in pairs(Config.otherPrices) do
        local amount = inventory[item] or 0
        if amount > 0 then
            local value = price * amount
            totalValue = totalValue + value
            table.insert(options, {
                title = item:gsub('_', ' '):gsub('^%l', string.upper) .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'scroll',
                onSelect = function()
                    TriggerServerEvent('ait:server:hunting:sell', item, amount)
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
            TriggerServerEvent('ait:server:hunting:sellAll')
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'hunting_sell',
            title = 'Vender Productos',
            menu = 'hunting_butcher',
            options = options,
        })
        lib.showContext('hunting_sell')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Hunting.AddXP(amount)
    huntingXP = huntingXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if huntingXP >= levelData.xpRequired and huntingLevel < levelData.level then
            huntingLevel = levelData.level
            AIT.Notify('¡Nivel de caza ' .. huntingLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:hunting:saveLevel', huntingLevel, huntingXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:hunting:loadLevel', function(level, xp)
    huntingLevel = level or 1
    huntingXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsHunting', function() return isHunting end)
exports('GetHuntingLevel', function() return huntingLevel end)
exports('GetHuntingXP', function() return huntingXP end)

return AIT.Jobs.Hunting
