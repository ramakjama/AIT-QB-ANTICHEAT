--[[
    AIT-QB: Sistema de Chop Shop
    Trabajo ILEGAL - Desguace de vehículos robados
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.ChopShop = {}

local isChopping = false
local chopLevel = 1
local chopXP = 0
local currentVehicle = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Ubicaciones de chop shop
    locations = {
        {
            name = 'Desguace de Elysian',
            coords = vector3(482.0, -1314.0, 29.0),
            dropOff = vector3(488.0, -1320.0, 29.0),
            heading = 180.0,
            active = true,
        },
        {
            name = 'Desguace del Desierto',
            coords = vector3(2336.0, 3132.0, 48.0),
            dropOff = vector3(2342.0, 3125.0, 48.0),
            heading = 270.0,
            active = true,
        },
        {
            name = 'Desguace de Paleto',
            coords = vector3(105.0, 6625.0, 32.0),
            dropOff = vector3(110.0, 6618.0, 32.0),
            heading = 180.0,
            active = true,
        },
    },

    -- Precios base por clase de vehículo
    vehiclePrices = {
        compacts = { min = 2000, max = 4000 },
        sedans = { min = 3000, max = 6000 },
        suvs = { min = 5000, max = 10000 },
        coupes = { min = 4000, max = 8000 },
        muscle = { min = 6000, max = 12000 },
        sports = { min = 15000, max = 30000 },
        sportsclassics = { min = 20000, max = 40000 },
        super = { min = 50000, max = 100000 },
        motorcycles = { min = 2000, max = 15000 },
        offroad = { min = 4000, max = 8000 },
        industrial = { min = 8000, max = 15000 },
        vans = { min = 3000, max = 7000 },
    },

    -- Partes que se pueden extraer
    parts = {
        { name = 'engine_parts', label = 'Piezas de Motor', baseValue = 500, extractTime = 30000 },
        { name = 'transmission_parts', label = 'Transmisión', baseValue = 400, extractTime = 25000 },
        { name = 'electronics', label = 'Electrónica', baseValue = 300, extractTime = 15000 },
        { name = 'wheels', label = 'Ruedas', baseValue = 200, extractTime = 10000 },
        { name = 'exhaust', label = 'Escape', baseValue = 150, extractTime = 8000 },
        { name = 'scrap_metal', label = 'Chatarra', baseValue = 100, extractTime = 5000 },
    },

    -- Contratos especiales (vehículos solicitados)
    contracts = {
        refreshTime = 1800, -- 30 minutos
        maxActive = 3,
        bonusMultiplier = 1.5, -- 50% más si es contrato
    },

    -- VIP targets (alto valor)
    vipVehicles = {
        'adder', 'zentorno', 't20', 'osiris', 'entityxf', 'turismor',
        'reaper', 'fmj', 'penetrator', 'nero', 'italigtb2', 'tempesta',
        'vagner', 'xa21', 'autarch', 'sc1', 'cyclone', 'visione',
    },
    vipMultiplier = 2.0,

    -- Riesgo policial
    policeRisk = {
        steal = 30,    -- Al robar
        transport = 40, -- Durante transporte
        chop = 50,      -- Durante desguace
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Aprendiz', partsBonus = 0, speedBonus = 0 },
        { level = 2, xpRequired = 500, title = 'Desguazador', partsBonus = 5, speedBonus = 5 },
        { level = 3, xpRequired = 1500, title = 'Mecánico Oscuro', partsBonus = 10, speedBonus = 10 },
        { level = 4, xpRequired = 3500, title = 'Experto', partsBonus = 20, speedBonus = 15 },
        { level = 5, xpRequired = 7000, title = 'Maestro del Desguace', partsBonus = 35, speedBonus = 25 },
    },

    -- XP
    xpSteal = 25,
    xpChop = 100,
    xpContract = 150,
}

-- Contratos activos
local activeContracts = {}
local contractsLastRefresh = 0

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.ChopShop.Init()
    -- No blips públicos para actividades ilegales

    -- Crear zonas de drop-off
    for _, location in ipairs(Config.locations) do
        if location.active and lib and lib.zones then
            lib.zones.sphere({
                coords = location.dropOff,
                radius = 10.0,
                onEnter = function()
                    if currentVehicle then
                        lib.showTextUI('[E] Entregar vehículo')
                    end
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
            })
        end
    end

    print('[AIT-QB] Sistema de chop shop inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- ROBO DE VEHÍCULOS
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('robarvehiculo', function()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        AIT.Notify('Ya estás en un vehículo', 'error')
        return
    end

    local vehicle = AIT.Jobs.ChopShop.GetNearestVehicle()

    if not vehicle then
        AIT.Notify('No hay vehículo cercano', 'error')
        return
    end

    -- Verificar si tiene dueño (es de un jugador)
    local plate = GetVehicleNumberPlateText(vehicle)

    -- Verificar si está bloqueado
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 2 then
        -- Necesita forzar cerradura
        AIT.Jobs.ChopShop.HotwireVehicle(vehicle)
    else
        -- Está abierto, entrar directamente
        TaskEnterVehicle(ped, vehicle, 5000, -1, 1.0, 1, 0)
        AIT.Jobs.ChopShop.SetupStolenVehicle(vehicle)
    end
end, false)

function AIT.Jobs.ChopShop.GetNearestVehicle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    return GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
end

function AIT.Jobs.ChopShop.HotwireVehicle(vehicle)
    local ped = PlayerPedId()

    -- Animación de forzar puerta
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Forzando cerradura...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'veh@break_in@0h@p_m_one@',
                clip = 'low_force_entry_ds',
            },
        }) then
            -- Desbloquear
            SetVehicleDoorsLocked(vehicle, 1)

            -- Entrar
            TaskEnterVehicle(ped, vehicle, 5000, -1, 1.0, 1, 0)

            Wait(3000)

            -- Hacer puente
            if lib.progressBar({
                duration = 15000,
                label = 'Haciendo puente...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'veh@std@ds@base',
                    clip = 'hotwire',
                },
            }) then
                SetVehicleEngineOn(vehicle, true, true, false)
                AIT.Jobs.ChopShop.SetupStolenVehicle(vehicle)
                AIT.Notify('Vehículo robado', 'success')

                -- Alerta policial
                TriggerServerEvent('ait:server:police:vehicleTheftAlert', GetEntityCoords(ped))
            end
        end
    end
end

function AIT.Jobs.ChopShop.SetupStolenVehicle(vehicle)
    currentVehicle = {
        entity = vehicle,
        plate = GetVehicleNumberPlateText(vehicle),
        model = GetEntityModel(vehicle),
        class = GetVehicleClass(vehicle),
        health = GetVehicleBodyHealth(vehicle),
        stolenTime = GetGameTimer(),
    }

    -- Verificar si es contrato activo
    for i, contract in ipairs(activeContracts) do
        if GetHashKey(contract.model) == currentVehicle.model then
            currentVehicle.isContract = true
            currentVehicle.contractIndex = i
            AIT.Notify('¡Este vehículo es un contrato activo! Bonus x1.5', 'success')
            break
        end
    end

    -- Verificar si es VIP
    local modelName = GetDisplayNameFromVehicleModel(currentVehicle.model):lower()
    for _, vipModel in ipairs(Config.vipVehicles) do
        if modelName == vipModel then
            currentVehicle.isVIP = true
            AIT.Notify('¡Vehículo de alto valor! Bonus x2', 'success')
            break
        end
    end

    AIT.Jobs.ChopShop.AddXP(Config.xpSteal)

    -- Marcar chop shop más cercano
    local nearest = AIT.Jobs.ChopShop.GetNearestLocation()
    if nearest then
        SetNewWaypoint(nearest.dropOff.x, nearest.dropOff.y)
        AIT.Notify('Lleva el vehículo al desguace marcado', 'info')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ENTREGA Y DESGUACE
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.ChopShop.GetNearestLocation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearest = nil
    local nearestDist = math.huge

    for _, location in ipairs(Config.locations) do
        if location.active then
            local dist = #(coords - location.coords)
            if dist < nearestDist then
                nearest = location
                nearestDist = dist
            end
        end
    end

    return nearest
end

RegisterCommand('entregarvehiculo', function()
    if not currentVehicle then
        AIT.Notify('No tienes vehículo robado', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Verificar si está en zona de entrega
    local inZone = false
    local currentLocation = nil

    for _, location in ipairs(Config.locations) do
        local dist = #(coords - location.dropOff)
        if dist < 15.0 then
            inZone = true
            currentLocation = location
            break
        end
    end

    if not inZone then
        AIT.Notify('No estás en un desguace', 'error')
        return
    end

    -- Salir del vehículo
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, currentVehicle.entity, 0)
        Wait(2000)
    end

    -- Menú de opciones
    local options = {
        {
            title = 'Vender Completo',
            description = 'Vender el vehículo entero',
            icon = 'car',
            onSelect = function()
                AIT.Jobs.ChopShop.SellWhole(currentLocation)
            end,
        },
        {
            title = 'Desguazar por Piezas',
            description = 'Extraer piezas individualmente (más dinero)',
            icon = 'cogs',
            onSelect = function()
                AIT.Jobs.ChopShop.ChopForParts(currentLocation)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'chopshop_deliver',
            title = 'Desguace',
            options = options,
        })
        lib.showContext('chopshop_deliver')
    end
end, false)

function AIT.Jobs.ChopShop.SellWhole(location)
    if isChopping then return end
    isChopping = true

    -- Calcular precio
    local classNames = {
        [0] = 'compacts', [1] = 'sedans', [2] = 'suvs', [3] = 'coupes',
        [4] = 'muscle', [5] = 'sportsclassics', [6] = 'sports', [7] = 'super',
        [8] = 'motorcycles', [9] = 'offroad', [10] = 'industrial', [11] = 'vans',
    }

    local className = classNames[currentVehicle.class] or 'sedans'
    local priceRange = Config.vehiclePrices[className] or Config.vehiclePrices.sedans

    local basePrice = math.random(priceRange.min, priceRange.max)

    -- Aplicar multiplicadores
    if currentVehicle.isVIP then
        basePrice = basePrice * Config.vipMultiplier
    end

    if currentVehicle.isContract then
        basePrice = basePrice * Config.contracts.bonusMultiplier
    end

    -- Penalización por daño
    local healthPercent = currentVehicle.health / 1000
    basePrice = math.floor(basePrice * healthPercent)

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Procesando vehículo...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true },
        }) then
            -- Eliminar vehículo
            DeleteVehicle(currentVehicle.entity)

            -- Pagar
            TriggerServerEvent('ait:server:chopshop:payment', basePrice)

            -- XP
            AIT.Jobs.ChopShop.AddXP(Config.xpChop)

            -- Completar contrato si aplica
            if currentVehicle.isContract then
                table.remove(activeContracts, currentVehicle.contractIndex)
                AIT.Jobs.ChopShop.AddXP(Config.xpContract)
            end

            AIT.Notify('Vehículo vendido por $' .. basePrice, 'success')

            currentVehicle = nil
        end
    end

    isChopping = false
end

function AIT.Jobs.ChopShop.ChopForParts(location)
    if isChopping then return end
    isChopping = true

    local totalValue = 0
    local levelData = Config.levels[chopLevel] or Config.levels[1]

    for _, part in ipairs(Config.parts) do
        -- Calcular tiempo con bonus de velocidad
        local extractTime = part.extractTime * (1 - levelData.speedBonus / 100)

        if lib and lib.progressBar then
            if lib.progressBar({
                duration = math.floor(extractTime),
                label = 'Extrayendo ' .. part.label .. '...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_player',
                },
            }) then
                -- Calcular valor de la pieza
                local partValue = part.baseValue * (1 + levelData.partsBonus / 100)

                -- Multiplicadores
                if currentVehicle.isVIP then
                    partValue = partValue * Config.vipMultiplier
                end

                if currentVehicle.isContract then
                    partValue = partValue * Config.contracts.bonusMultiplier
                end

                partValue = math.floor(partValue)
                totalValue = totalValue + partValue

                -- Dar item
                TriggerServerEvent('ait:server:chopshop:addPart', part.name, 1)

                AIT.Notify(part.label .. ' extraída ($' .. partValue .. ')', 'success')
            else
                AIT.Notify('Desguace cancelado', 'error')
                break
            end
        end
    end

    -- Eliminar vehículo (carcasa)
    if DoesEntityExist(currentVehicle.entity) then
        DeleteVehicle(currentVehicle.entity)
    end

    -- XP
    AIT.Jobs.ChopShop.AddXP(Config.xpChop * 1.5) -- Más XP por desguace completo

    if currentVehicle.isContract then
        table.remove(activeContracts, currentVehicle.contractIndex)
        AIT.Jobs.ChopShop.AddXP(Config.xpContract)
    end

    AIT.Notify('Desguace completo. Valor total de piezas: $' .. totalValue, 'success')

    currentVehicle = nil
    isChopping = false
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE CONTRATOS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.ChopShop.RefreshContracts()
    if GetGameTimer() - contractsLastRefresh < Config.contracts.refreshTime * 1000 then
        return
    end

    activeContracts = {}

    -- Generar contratos aleatorios
    local allVehicles = {
        'sultan', 'elegy', 'jester', 'massacro', 'banshee', 'carbonizzare',
        'comet2', 'feltzer2', 'fusilade', 'ninef', 'rapidgt', 'schwarzer',
        'buffalo', 'buffalo2', 'dominator', 'gauntlet', 'ruiner', 'vigero',
        'zentorno', 'entityxf', 'turismor', 'adder', 't20', -- Super ocasional
    }

    for i = 1, Config.contracts.maxActive do
        local randomVehicle = allVehicles[math.random(1, #allVehicles)]
        local isVIP = false

        for _, vip in ipairs(Config.vipVehicles) do
            if randomVehicle == vip then
                isVIP = true
                break
            end
        end

        table.insert(activeContracts, {
            model = randomVehicle,
            isVIP = isVIP,
            bonus = isVIP and Config.vipMultiplier or Config.contracts.bonusMultiplier,
        })
    end

    contractsLastRefresh = GetGameTimer()
end

RegisterNetEvent('ait:client:chopshop:openContracts', function()
    AIT.Jobs.ChopShop.RefreshContracts()

    local options = {}

    for i, contract in ipairs(activeContracts) do
        local label = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(contract.model)))
        if label == 'NULL' then
            label = contract.model:upper()
        end

        table.insert(options, {
            title = label,
            description = contract.isVIP and '⭐ VIP - Bonus x2' or 'Bonus x1.5',
            icon = contract.isVIP and 'star' or 'car',
        })
    end

    if #options == 0 then
        AIT.Notify('No hay contratos disponibles', 'info')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'chopshop_contracts',
            title = 'Contratos Activos',
            options = options,
        })
        lib.showContext('chopshop_contracts')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- VENTA DE PIEZAS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:chopshop:openPartsSale', function(inventory)
    local options = {}
    local totalValue = 0

    for _, part in ipairs(Config.parts) do
        local amount = inventory[part.name] or 0
        if amount > 0 then
            local value = part.baseValue * amount
            totalValue = totalValue + value

            table.insert(options, {
                title = part.label .. ' x' .. amount,
                description = 'Valor: $' .. value,
                icon = 'cog',
                onSelect = function()
                    TriggerServerEvent('ait:server:chopshop:sellPart', part.name, amount)
                end,
            })
        end
    end

    if #options == 0 then
        AIT.Notify('No tienes piezas para vender', 'error')
        return
    end

    table.insert(options, 1, {
        title = 'Vender Todo',
        description = 'Valor total: $' .. totalValue,
        icon = 'dollar-sign',
        onSelect = function()
            TriggerServerEvent('ait:server:chopshop:sellAllParts')
        end,
    })

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'chopshop_sell',
            title = 'Vender Piezas',
            options = options,
        })
        lib.showContext('chopshop_sell')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.ChopShop.AddXP(amount)
    chopXP = chopXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if chopXP >= levelData.xpRequired and chopLevel < levelData.level then
            chopLevel = levelData.level
            AIT.Notify('¡Nivel de chop shop ' .. chopLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:chopshop:saveLevel', chopLevel, chopXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:chopshop:loadLevel', function(level, xp)
    chopLevel = level or 1
    chopXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsChopping', function() return isChopping end)
exports('GetChopLevel', function() return chopLevel end)
exports('HasStolenVehicle', function() return currentVehicle ~= nil end)

return AIT.Jobs.ChopShop
