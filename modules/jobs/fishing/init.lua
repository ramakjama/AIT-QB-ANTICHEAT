--[[
    AIT-QB: Sistema de Pesca
    Trabajo legal - Pesca y venta de pescado
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Fishing = {}

local isFishing = false
local hasFishingRod = false
local currentCatch = {}
local fishingLevel = 1
local fishingXP = 0

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    shop = {
        coords = vector3(-1853.0, -1231.0, 13.0),
        blip = { sprite = 356, color = 3, scale = 0.8 },
    },

    sellPoint = {
        coords = vector3(-1828.0, -1193.0, 14.0),
        blip = { sprite = 52, color = 2, scale = 0.7 },
    },

    -- Zonas de pesca
    fishingZones = {
        { name = 'Muelle Del Perro', coords = vector3(-1850.0, -1245.0, 8.0), radius = 100.0, quality = 'normal' },
        { name = 'Playa Vespucci', coords = vector3(-1600.0, -1100.0, 2.0), radius = 150.0, quality = 'normal' },
        { name = 'Puerto de LS', coords = vector3(-280.0, -2750.0, 1.0), radius = 200.0, quality = 'buena' },
        { name = 'Lago Alamo', coords = vector3(1355.0, 4385.0, 44.0), radius = 150.0, quality = 'buena' },
        { name = 'Lago Zancudo', coords = vector3(-2193.0, 2310.0, 3.0), radius = 200.0, quality = 'rara' },
        { name = 'Mar Abierto Norte', coords = vector3(3280.0, 5185.0, 0.0), radius = 300.0, quality = 'legendaria' },
    },

    -- Tipos de peces
    fish = {
        -- Comunes (60%)
        { name = 'sardina', label = 'Sardina', price = 15, xp = 5, rarity = 'comun', weight = 0.2 },
        { name = 'anchoa', label = 'Anchoa', price = 12, xp = 4, rarity = 'comun', weight = 0.1 },
        { name = 'caballa', label = 'Caballa', price = 20, xp = 6, rarity = 'comun', weight = 0.5 },
        { name = 'jurel', label = 'Jurel', price = 25, xp = 7, rarity = 'comun', weight = 0.6 },

        -- Normales (25%)
        { name = 'dorada', label = 'Dorada', price = 45, xp = 15, rarity = 'normal', weight = 1.2 },
        { name = 'lubina', label = 'Lubina', price = 55, xp = 18, rarity = 'normal', weight = 1.5 },
        { name = 'merluza', label = 'Merluza', price = 50, xp = 16, rarity = 'normal', weight = 2.0 },
        { name = 'besugo', label = 'Besugo', price = 60, xp = 20, rarity = 'normal', weight = 1.8 },

        -- Buenos (10%)
        { name = 'salmon', label = 'Salmón', price = 120, xp = 35, rarity = 'buena', weight = 3.5 },
        { name = 'trucha', label = 'Trucha', price = 85, xp = 28, rarity = 'buena', weight = 2.0 },
        { name = 'rodaballo', label = 'Rodaballo', price = 150, xp = 45, rarity = 'buena', weight = 4.0 },
        { name = 'rape', label = 'Rape', price = 130, xp = 40, rarity = 'buena', weight = 5.0 },

        -- Raros (4%)
        { name = 'atun', label = 'Atún Rojo', price = 350, xp = 100, rarity = 'rara', weight = 15.0 },
        { name = 'pez_espada', label = 'Pez Espada', price = 400, xp = 120, rarity = 'rara', weight = 20.0 },
        { name = 'emperador', label = 'Emperador', price = 380, xp = 110, rarity = 'rara', weight = 8.0 },

        -- Legendarios (1%)
        { name = 'tiburon', label = 'Tiburón', price = 1500, xp = 500, rarity = 'legendaria', weight = 100.0 },
        { name = 'marlin', label = 'Marlín Azul', price = 2000, xp = 600, rarity = 'legendaria', weight = 80.0 },
        { name = 'atun_gigante', label = 'Atún Gigante', price = 2500, xp = 750, rarity = 'legendaria', weight = 150.0 },
    },

    -- Objetos basura (chance)
    junk = {
        { name = 'boot', label = 'Bota Vieja', price = 0 },
        { name = 'tire', label = 'Neumático', price = 5 },
        { name = 'can', label = 'Lata Oxidada', price = 2 },
        { name = 'bottle', label = 'Botella de Plástico', price = 1 },
    },

    -- Equipamiento
    equipment = {
        basicRod = { name = 'fishing_rod', label = 'Caña Básica', price = 500, catchBonus = 0 },
        proRod = { name = 'fishing_rod_pro', label = 'Caña Profesional', price = 2500, catchBonus = 15 },
        legendaryRod = { name = 'fishing_rod_legendary', label = 'Caña Legendaria', price = 10000, catchBonus = 30 },
        bait = { name = 'fishing_bait', label = 'Cebo', price = 20, required = true },
        premiumBait = { name = 'premium_bait', label = 'Cebo Premium', price = 100, rareBonus = 10 },
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Novato' },
        { level = 2, xpRequired = 100, title = 'Aprendiz' },
        { level = 3, xpRequired = 300, title = 'Aficionado' },
        { level = 4, xpRequired = 600, title = 'Pescador' },
        { level = 5, xpRequired = 1000, title = 'Pescador Experto' },
        { level = 6, xpRequired = 1500, title = 'Maestro Pescador' },
        { level = 7, xpRequired = 2500, title = 'Gran Maestro' },
        { level = 8, xpRequired = 4000, title = 'Leyenda del Mar' },
    },

    -- Tiempos
    minCatchTime = 5000,
    maxCatchTime = 20000,

    -- Chances base
    junkChance = 15, -- 15% basura
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Fishing.Init()
    -- Blip tienda
    local shopBlip = AddBlipForCoord(Config.shop.coords.x, Config.shop.coords.y, Config.shop.coords.z)
    SetBlipSprite(shopBlip, Config.shop.blip.sprite)
    SetBlipColour(shopBlip, Config.shop.blip.color)
    SetBlipScale(shopBlip, Config.shop.blip.scale)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Tienda de Pesca')
    EndTextCommandSetBlipName(shopBlip)

    -- Blip venta
    local sellBlip = AddBlipForCoord(Config.sellPoint.coords.x, Config.sellPoint.coords.y, Config.sellPoint.coords.z)
    SetBlipSprite(sellBlip, Config.sellPoint.blip.sprite)
    SetBlipColour(sellBlip, Config.sellPoint.blip.color)
    SetBlipScale(sellBlip, Config.sellPoint.blip.scale)
    SetBlipAsShortRange(sellBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Pescadería')
    EndTextCommandSetBlipName(sellBlip)

    -- Blips de zonas de pesca
    for _, zone in ipairs(Config.fishingZones) do
        local zoneBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(zoneBlip, 317)
        SetBlipColour(zoneBlip, 3)
        SetBlipScale(zoneBlip, 0.6)
        SetBlipAsShortRange(zoneBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Zona de Pesca: ' .. zone.name)
        EndTextCommandSetBlipName(zoneBlip)
    end

    print('[AIT-QB] Sistema de pesca inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- TIENDA DE PESCA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:fishing:openShop', function()
    local options = {
        {
            title = 'Caña Básica',
            description = 'Precio: $' .. Config.equipment.basicRod.price,
            icon = 'fish',
            onSelect = function()
                TriggerServerEvent('ait:server:fishing:buyItem', 'basicRod')
            end,
        },
        {
            title = 'Caña Profesional',
            description = 'Precio: $' .. Config.equipment.proRod.price .. ' | +15% captura',
            icon = 'fish',
            onSelect = function()
                TriggerServerEvent('ait:server:fishing:buyItem', 'proRod')
            end,
        },
        {
            title = 'Caña Legendaria',
            description = 'Precio: $' .. Config.equipment.legendaryRod.price .. ' | +30% captura',
            icon = 'fish',
            onSelect = function()
                TriggerServerEvent('ait:server:fishing:buyItem', 'legendaryRod')
            end,
        },
        {
            title = 'Cebo (x10)',
            description = 'Precio: $' .. (Config.equipment.bait.price * 10),
            icon = 'worm',
            onSelect = function()
                TriggerServerEvent('ait:server:fishing:buyItem', 'bait', 10)
            end,
        },
        {
            title = 'Cebo Premium (x10)',
            description = 'Precio: $' .. (Config.equipment.premiumBait.price * 10) .. ' | +10% raros',
            icon = 'worm',
            onSelect = function()
                TriggerServerEvent('ait:server:fishing:buyItem', 'premiumBait', 10)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'fishing_shop',
            title = 'Tienda de Pesca',
            options = options,
        })
        lib.showContext('fishing_shop')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE PESCA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Fishing.GetCurrentZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, zone in ipairs(Config.fishingZones) do
        local dist = #(coords - zone.coords)
        if dist <= zone.radius then
            return zone
        end
    end

    return nil
end

RegisterCommand('pescar', function()
    if isFishing then
        AIT.Notify('Ya estás pescando', 'error')
        return
    end

    local zone = AIT.Jobs.Fishing.GetCurrentZone()
    if not zone then
        AIT.Notify('No estás en una zona de pesca', 'error')
        return
    end

    -- Verificar caña
    -- TriggerServerEvent para verificar items
    TriggerServerEvent('ait:server:fishing:checkEquipment', function(hasRod, hasBait, rodType)
        if not hasRod then
            AIT.Notify('Necesitas una caña de pescar', 'error')
            return
        end

        if not hasBait then
            AIT.Notify('Necesitas cebo para pescar', 'error')
            return
        end

        AIT.Jobs.Fishing.StartFishing(zone, rodType)
    end)
end, false)

RegisterNetEvent('ait:client:fishing:equipmentChecked', function(hasRod, hasBait, rodType)
    if not hasRod then
        AIT.Notify('Necesitas una caña de pescar', 'error')
        return
    end

    if not hasBait then
        AIT.Notify('Necesitas cebo para pescar', 'error')
        return
    end

    local zone = AIT.Jobs.Fishing.GetCurrentZone()
    if zone then
        AIT.Jobs.Fishing.StartFishing(zone, rodType)
    end
end)

function AIT.Jobs.Fishing.StartFishing(zone, rodType)
    isFishing = true

    local ped = PlayerPedId()

    -- Animación de pesca
    local dict = 'amb@world_human_stand_fishing@idle_a'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    -- Prop de caña
    local rodProp = CreateObject(GetHashKey('prop_fishing_rod_01'), 0, 0, 0, true, true, true)
    AttachEntityToEntity(rodProp, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.05, 0.0, -80.0, 120.0, 160.0, true, true, false, true, 1, true)

    TaskPlayAnim(ped, dict, 'idle_c', 8.0, -8.0, -1, 1, 0, false, false, false)

    AIT.Notify('Pescando en ' .. zone.name .. '...', 'info')

    -- Tiempo aleatorio de espera
    local waitTime = math.random(Config.minCatchTime, Config.maxCatchTime)

    -- Reducir tiempo según nivel
    waitTime = waitTime * (1 - (fishingLevel * 0.05))

    -- Thread de pesca
    CreateThread(function()
        Wait(waitTime)

        if not isFishing then
            DeleteObject(rodProp)
            return
        end

        -- Determinar captura
        local catch = AIT.Jobs.Fishing.DetermineCatch(zone, rodType)

        -- Animación de tirar
        TaskPlayAnim(ped, dict, 'fish_catch', 8.0, -8.0, 2000, 0, 0, false, false, false)
        Wait(2000)

        if catch then
            if catch.isJunk then
                AIT.Notify('Has pescado: ' .. catch.label .. ' (basura)', 'info')
            else
                local rarityText = ({
                    comun = '⚪',
                    normal = '🟢',
                    buena = '🔵',
                    rara = '🟣',
                    legendaria = '🟡',
                })[catch.rarity] or ''

                AIT.Notify(rarityText .. ' Has pescado: ' .. catch.label .. ' (' .. catch.weight .. 'kg)', 'success')

                -- Dar XP
                AIT.Jobs.Fishing.AddXP(catch.xp)
            end

            -- Añadir al inventario
            TriggerServerEvent('ait:server:fishing:addCatch', catch.name, 1)
        else
            AIT.Notify('El pez escapó...', 'error')
        end

        -- Consumir cebo
        TriggerServerEvent('ait:server:fishing:useBait')

        -- Limpiar
        DeleteObject(rodProp)
        ClearPedTasks(ped)
        isFishing = false
    end)
end

function AIT.Jobs.Fishing.DetermineCatch(zone, rodType)
    -- Chance de basura
    if math.random(1, 100) <= Config.junkChance then
        local junk = Config.junk[math.random(1, #Config.junk)]
        return { name = junk.name, label = junk.label, price = junk.price, isJunk = true }
    end

    -- Bonus por caña
    local catchBonus = 0
    if rodType == 'proRod' then
        catchBonus = 15
    elseif rodType == 'legendaryRod' then
        catchBonus = 30
    end

    -- Bonus por nivel
    catchBonus = catchBonus + (fishingLevel * 2)

    -- Determinar rareza según zona
    local rarity = AIT.Jobs.Fishing.DetermineRarity(zone.quality, catchBonus)

    -- Filtrar peces por rareza
    local possibleFish = {}
    for _, fish in ipairs(Config.fish) do
        if fish.rarity == rarity then
            table.insert(possibleFish, fish)
        end
    end

    if #possibleFish == 0 then
        -- Fallback a común
        for _, fish in ipairs(Config.fish) do
            if fish.rarity == 'comun' then
                table.insert(possibleFish, fish)
            end
        end
    end

    -- Seleccionar pez aleatorio
    local selectedFish = possibleFish[math.random(1, #possibleFish)]

    -- Variar peso
    local weightVariation = math.random(80, 120) / 100
    selectedFish.weight = math.floor(selectedFish.weight * weightVariation * 10) / 10

    return selectedFish
end

function AIT.Jobs.Fishing.DetermineRarity(zoneQuality, bonus)
    local roll = math.random(1, 100) + bonus

    if zoneQuality == 'legendaria' then
        if roll > 99 then return 'legendaria' end
        if roll > 90 then return 'rara' end
        if roll > 70 then return 'buena' end
        if roll > 40 then return 'normal' end
        return 'comun'
    elseif zoneQuality == 'rara' then
        if roll > 99 then return 'rara' end
        if roll > 85 then return 'buena' end
        if roll > 55 then return 'normal' end
        return 'comun'
    elseif zoneQuality == 'buena' then
        if roll > 95 then return 'buena' end
        if roll > 65 then return 'normal' end
        return 'comun'
    else
        if roll > 90 then return 'normal' end
        return 'comun'
    end
end

-- Cancelar pesca
RegisterCommand('cancelarpesca', function()
    if isFishing then
        isFishing = false
        ClearPedTasks(PlayerPedId())
        AIT.Notify('Pesca cancelada', 'info')
    end
end, false)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Fishing.AddXP(amount)
    fishingXP = fishingXP + amount

    -- Verificar subida de nivel
    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if fishingXP >= levelData.xpRequired and fishingLevel < levelData.level then
            fishingLevel = levelData.level
            AIT.Notify('¡Subiste a nivel ' .. fishingLevel .. ': ' .. levelData.title .. '!', 'success')

            -- Guardar en servidor
            TriggerServerEvent('ait:server:fishing:saveLevel', fishingLevel, fishingXP)
            break
        end
    end
end

-- Cargar nivel al conectar
RegisterNetEvent('ait:client:fishing:loadLevel', function(level, xp)
    fishingLevel = level or 1
    fishingXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- VENTA DE PESCADO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:fishing:openSellMenu', function(inventory)
    local options = {}
    local totalValue = 0

    for _, fish in ipairs(Config.fish) do
        local amount = inventory[fish.name] or 0
        if amount > 0 then
            local value = fish.price * amount
            totalValue = totalValue + value

            table.insert(options, {
                title = fish.label .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'fish',
                onSelect = function()
                    TriggerServerEvent('ait:server:fishing:sellFish', fish.name, amount)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes pescado para vender', 'error')
        return
    end

    table.insert(options, 1, {
        title = 'Vender Todo',
        description = 'Valor total: $' .. totalValue,
        icon = 'dollar-sign',
        onSelect = function()
            TriggerServerEvent('ait:server:fishing:sellAll')
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'fishing_sell',
            title = 'Pescadería',
            options = options,
        })
        lib.showContext('fishing_sell')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsFishing', function() return isFishing end)
exports('GetFishingLevel', function() return fishingLevel end)
exports('GetFishingXP', function() return fishingXP end)

return AIT.Jobs.Fishing
