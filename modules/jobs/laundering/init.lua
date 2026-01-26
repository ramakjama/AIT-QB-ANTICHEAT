--[[
    AIT-QB: Sistema de Lavado de Dinero
    Trabajo ILEGAL - Conversión de dinero sucio a limpio
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Laundering = {}

local isLaundering = false
local launderingLevel = 1
local launderingXP = 0

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Negocios fachada (para lavar dinero)
    businesses = {
        {
            name = 'Lavandería del Sol',
            coords = vector3(1136.0, -982.0, 46.0),
            type = 'laundromat',
            maxDaily = 50000,
            fee = 15, -- 15% de comisión
            minAmount = 1000,
            processTime = 30000,
            level = 1,
        },
        {
            name = 'Arcade Retro',
            coords = vector3(-1654.0, -1063.0, 13.0),
            type = 'arcade',
            maxDaily = 100000,
            fee = 12,
            minAmount = 5000,
            processTime = 45000,
            level = 2,
        },
        {
            name = 'Car Wash Premium',
            coords = vector3(55.0, -1391.0, 29.0),
            type = 'carwash',
            maxDaily = 75000,
            fee = 13,
            minAmount = 2500,
            processTime = 35000,
            level = 1,
        },
        {
            name = 'Nightclub Paradise',
            coords = vector3(-1604.0, -3013.0, -76.0), -- Interior del nightclub
            type = 'nightclub',
            maxDaily = 250000,
            fee = 10,
            minAmount = 10000,
            processTime = 60000,
            level = 3,
        },
        {
            name = 'Casino Fantasma',
            coords = vector3(924.0, 47.0, 81.0),
            type = 'casino',
            maxDaily = 500000,
            fee = 8,
            minAmount = 25000,
            processTime = 90000,
            level = 4,
        },
    },

    -- Otros métodos de lavado
    methods = {
        -- Compra de criptomonedas (ATM especiales)
        crypto = {
            locations = {
                vector3(-537.0, -854.0, 29.0),
                vector3(289.0, -1282.0, 29.0),
            },
            fee = 20, -- 20% comisión
            maxTransaction = 20000,
            processTime = 15000,
            level = 1,
        },

        -- Compra de arte/objetos de valor
        art = {
            location = vector3(-473.0, -59.0, 44.0), -- Galería de arte
            fee = 25,
            minAmount = 50000,
            processTime = 60000,
            level = 3,
        },

        -- Inversión inmobiliaria
        realestate = {
            location = vector3(-704.0, 271.0, 83.0),
            fee = 5, -- Mejor tasa pero requiere más
            minAmount = 100000,
            processTime = 120000,
            level = 4,
        },
    },

    -- Contactos (NPCs para misiones de lavado)
    contacts = {
        {
            name = 'El Contador',
            coords = vector3(-102.0, -1451.0, 30.0),
            missions = {
                'transport_cash',
                'fake_invoices',
                'offshore_transfer',
            },
        },
    },

    -- Misiones de lavado
    missions = {
        transport_cash = {
            label = 'Transporte de Efectivo',
            description = 'Transporta efectivo a múltiples ubicaciones',
            pay = 5000,
            xp = 50,
            minLevel = 1,
        },
        fake_invoices = {
            label = 'Facturas Falsas',
            description = 'Entrega facturas falsas a negocios',
            pay = 10000,
            xp = 100,
            minLevel = 2,
        },
        offshore_transfer = {
            label = 'Transferencia Offshore',
            description = 'Gestiona transferencias a paraísos fiscales',
            pay = 25000,
            xp = 200,
            minLevel = 3,
        },
    },

    -- Items de dinero
    dirtyMoneyItem = 'marked_bills', -- Billetes marcados
    cleanMoneyItem = 'cash',

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Novato', feeReduction = 0, dailyBonus = 0 },
        { level = 2, xpRequired = 500, title = 'Blanqueador', feeReduction = 2, dailyBonus = 10 },
        { level = 3, xpRequired = 1500, title = 'Financiero', feeReduction = 4, dailyBonus = 20 },
        { level = 4, xpRequired = 4000, title = 'Experto', feeReduction = 6, dailyBonus = 35 },
        { level = 5, xpRequired = 10000, title = 'Maestro del Lavado', feeReduction = 10, dailyBonus = 50 },
    },

    -- Riesgo
    policeRisk = {
        laundromat = 10,
        arcade = 15,
        carwash = 12,
        nightclub = 25,
        casino = 30,
        crypto = 20,
        art = 15,
        realestate = 5,
    },
}

-- Historial diario de lavado
local dailyLaundered = {}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Laundering.Init()
    -- Reset diario a medianoche
    CreateThread(function()
        while true do
            Wait(60000) -- Cada minuto

            local hour = GetClockHours()
            local minute = GetClockMinutes()

            if hour == 0 and minute == 0 then
                dailyLaundered = {}
                AIT.Notify('Límites diarios de lavado reiniciados', 'info')
            end
        end
    end)

    print('[AIT-QB] Sistema de lavado de dinero inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- NEGOCIOS FACHADA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Laundering.GetNearestBusiness()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for i, business in ipairs(Config.businesses) do
        local dist = #(coords - business.coords)
        if dist < 10.0 then
            return i, business
        end
    end

    return nil
end

RegisterNetEvent('ait:client:laundering:openBusiness', function()
    local businessIndex, business = AIT.Jobs.Laundering.GetNearestBusiness()

    if not business then
        AIT.Notify('No estás cerca de un negocio de lavado', 'error')
        return
    end

    if launderingLevel < business.level then
        AIT.Notify('Requieres nivel ' .. business.level .. ' para usar este negocio', 'error')
        return
    end

    -- Calcular límite restante
    local todayKey = business.name
    local launderedToday = dailyLaundered[todayKey] or 0

    local levelData = Config.levels[launderingLevel] or Config.levels[1]
    local maxDaily = business.maxDaily * (1 + levelData.dailyBonus / 100)
    local remaining = maxDaily - launderedToday

    if remaining <= 0 then
        AIT.Notify('Has alcanzado el límite diario en este negocio', 'error')
        return
    end

    local fee = business.fee - levelData.feeReduction

    local options = {
        {
            title = 'Lavar Dinero',
            description = 'Comisión: ' .. fee .. '% | Límite restante: $' .. math.floor(remaining),
            icon = 'money-bill-wave',
            onSelect = function()
                AIT.Jobs.Laundering.OpenLaunderingDialog(business, remaining, fee)
            end,
        },
        {
            title = 'Información',
            description = 'Límite diario: $' .. math.floor(maxDaily) .. ' | Mínimo: $' .. business.minAmount,
            icon = 'info-circle',
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'laundering_business',
            title = business.name,
            options = options,
        })
        lib.showContext('laundering_business')
    end
end)

function AIT.Jobs.Laundering.OpenLaunderingDialog(business, maxAmount, fee)
    if lib and lib.inputDialog then
        local input = lib.inputDialog('Lavar Dinero - ' .. business.name, {
            { type = 'number', label = 'Cantidad a lavar ($)', min = business.minAmount, max = math.floor(maxAmount) },
        })

        if input and input[1] then
            local amount = tonumber(input[1])
            if amount and amount >= business.minAmount then
                TriggerServerEvent('ait:server:laundering:checkDirtyMoney', amount, business.name, fee, business.processTime)
            else
                AIT.Notify('Cantidad mínima: $' .. business.minAmount, 'error')
            end
        end
    end
end

RegisterNetEvent('ait:client:laundering:startProcess', function(amount, businessName, fee, processTime)
    if isLaundering then
        AIT.Notify('Ya estás lavando dinero', 'error')
        return
    end

    isLaundering = true

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = processTime,
            label = 'Procesando transacción...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            local cleanAmount = math.floor(amount * (1 - fee / 100))

            TriggerServerEvent('ait:server:laundering:complete', amount, cleanAmount, businessName)

            -- Actualizar límite diario local
            dailyLaundered[businessName] = (dailyLaundered[businessName] or 0) + amount

            -- XP
            local xpGained = math.floor(amount / 100)
            AIT.Jobs.Laundering.AddXP(xpGained)

            AIT.Notify('Lavado completado. Recibiste: $' .. cleanAmount .. ' (limpios)', 'success')

            -- Riesgo policial
            local businessData = nil
            for _, b in ipairs(Config.businesses) do
                if b.name == businessName then
                    businessData = b
                    break
                end
            end

            if businessData then
                AIT.Jobs.Laundering.CheckPoliceRisk(businessData.type, amount)
            end
        else
            AIT.Notify('Transacción cancelada', 'error')
        end
    end

    isLaundering = false
end)

-- ═══════════════════════════════════════════════════════════════
-- CRIPTOMONEDAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Laundering.GetNearestCryptoATM()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, atmCoords in ipairs(Config.methods.crypto.locations) do
        local dist = #(coords - atmCoords)
        if dist < 2.0 then
            return true
        end
    end

    return false
end

RegisterNetEvent('ait:client:laundering:openCryptoATM', function()
    if not AIT.Jobs.Laundering.GetNearestCryptoATM() then
        AIT.Notify('No hay cajero de cripto cerca', 'error')
        return
    end

    local crypto = Config.methods.crypto

    local options = {
        {
            title = 'Comprar Crypto',
            description = 'Convierte efectivo sucio en criptomonedas',
            icon = 'bitcoin',
            onSelect = function()
                if lib and lib.inputDialog then
                    local input = lib.inputDialog('Comprar Criptomonedas', {
                        { type = 'number', label = 'Cantidad ($)', min = 100, max = crypto.maxTransaction },
                    })

                    if input and input[1] then
                        TriggerServerEvent('ait:server:laundering:buyCrypto', tonumber(input[1]), crypto.fee)
                    end
                end
            end,
        },
        {
            title = 'Vender Crypto',
            description = 'Convierte criptomonedas en efectivo limpio',
            icon = 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('ait:server:laundering:getCryptoBalance')
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'crypto_atm',
            title = 'Cajero de Criptomonedas',
            options = options,
        })
        lib.showContext('crypto_atm')
    end
end)

RegisterNetEvent('ait:client:laundering:buyCryptoProcess', function(amount, fee)
    if isLaundering then return end
    isLaundering = true

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = Config.methods.crypto.processTime,
            label = 'Procesando compra de criptomonedas...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            local cryptoAmount = math.floor(amount * (1 - fee / 100))
            TriggerServerEvent('ait:server:laundering:completeCryptoBuy', amount, cryptoAmount)

            AIT.Jobs.Laundering.AddXP(math.floor(amount / 50))
            AIT.Notify('Compraste crypto por valor de $' .. cryptoAmount, 'success')

            AIT.Jobs.Laundering.CheckPoliceRisk('crypto', amount)
        end
    end

    isLaundering = false
end)

RegisterNetEvent('ait:client:laundering:openSellCrypto', function(cryptoBalance)
    if cryptoBalance <= 0 then
        AIT.Notify('No tienes criptomonedas', 'error')
        return
    end

    if lib and lib.inputDialog then
        local input = lib.inputDialog('Vender Criptomonedas (Balance: $' .. cryptoBalance .. ')', {
            { type = 'number', label = 'Cantidad a vender ($)', min = 100, max = cryptoBalance },
        })

        if input and input[1] then
            TriggerServerEvent('ait:server:laundering:sellCrypto', tonumber(input[1]))
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MISIONES DE LAVADO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:laundering:openContactMenu', function()
    local contact = Config.contacts[1] -- El Contador

    local options = {}

    for _, missionKey in ipairs(contact.missions) do
        local mission = Config.missions[missionKey]

        if mission then
            local canAccept = launderingLevel >= mission.minLevel

            table.insert(options, {
                title = mission.label,
                description = canAccept and (mission.description .. ' | Pago: $' .. mission.pay) or ('Requiere nivel ' .. mission.minLevel),
                icon = 'briefcase',
                disabled = not canAccept,
                onSelect = function()
                    TriggerServerEvent('ait:server:laundering:startMission', missionKey)
                end,
            })
        end
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'laundering_contact',
            title = contact.name,
            options = options,
        })
        lib.showContext('laundering_contact')
    end
end)

RegisterNetEvent('ait:client:laundering:startMission', function(missionKey, missionData)
    local mission = Config.missions[missionKey]

    if not mission then return end

    if missionKey == 'transport_cash' then
        AIT.Jobs.Laundering.StartTransportMission(missionData)
    elseif missionKey == 'fake_invoices' then
        AIT.Jobs.Laundering.StartInvoiceMission(missionData)
    elseif missionKey == 'offshore_transfer' then
        AIT.Jobs.Laundering.StartOffshoreMission(missionData)
    end
end)

function AIT.Jobs.Laundering.StartTransportMission(data)
    local deliveryPoints = {
        vector3(-1487.0, -378.0, 40.0),
        vector3(1136.0, -982.0, 46.0),
        vector3(55.0, -1391.0, 29.0),
    }

    AIT.Notify('Recoge la bolsa de dinero y llévala a los puntos marcados', 'info')

    for i, point in ipairs(deliveryPoints) do
        -- Crear blip
        local blip = AddBlipForCoord(point.x, point.y, point.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 2)
        SetBlipRoute(blip, i == 1)

        -- Esperar llegada
        while true do
            Wait(1000)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - point)

            if dist < 5.0 then
                if lib and lib.progressBar then
                    if lib.progressBar({
                        duration = 5000,
                        label = 'Entregando... (' .. i .. '/' .. #deliveryPoints .. ')',
                        useWhileDead = false,
                        canCancel = false,
                        disable = { car = true, move = true, combat = true },
                    }) then
                        AIT.Notify('Entrega ' .. i .. ' completada', 'success')
                    end
                end

                RemoveBlip(blip)
                break
            end
        end
    end

    -- Misión completada
    TriggerServerEvent('ait:server:laundering:completeMission', 'transport_cash')
    AIT.Notify('Misión completada', 'success')
end

function AIT.Jobs.Laundering.StartInvoiceMission(data)
    -- Simplificado - entregar facturas a negocios
    local businesses = {
        { coords = vector3(-47.0, -1757.0, 29.0), name = 'Tienda Davis' },
        { coords = vector3(373.0, 326.0, 103.0), name = 'Tienda Vinewood' },
    }

    AIT.Notify('Entrega las facturas falsas a los negocios', 'info')

    for i, business in ipairs(businesses) do
        local blip = AddBlipForCoord(business.coords.x, business.coords.y, business.coords.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 5)
        SetBlipRoute(blip, i == 1)

        while true do
            Wait(1000)
            local dist = #(GetEntityCoords(PlayerPedId()) - business.coords)

            if dist < 5.0 then
                if lib and lib.progressBar then
                    if lib.progressBar({
                        duration = 8000,
                        label = 'Entregando facturas a ' .. business.name,
                        useWhileDead = false,
                        canCancel = false,
                        disable = { car = true, move = true, combat = true },
                    }) then
                        AIT.Notify('Facturas entregadas a ' .. business.name, 'success')
                    end
                end

                RemoveBlip(blip)
                break
            end
        end
    end

    TriggerServerEvent('ait:server:laundering:completeMission', 'fake_invoices')
end

function AIT.Jobs.Laundering.StartOffshoreMission(data)
    -- Ir al banco y realizar transferencia
    local bankCoords = vector3(149.0, -1040.0, 29.0)

    AIT.Notify('Ve al banco y realiza la transferencia offshore', 'info')

    local blip = AddBlipForCoord(bankCoords.x, bankCoords.y, bankCoords.z)
    SetBlipSprite(blip, 108)
    SetBlipColour(blip, 2)
    SetBlipRoute(blip, true)

    while true do
        Wait(1000)
        local dist = #(GetEntityCoords(PlayerPedId()) - bankCoords)

        if dist < 5.0 then
            if lib and lib.progressBar then
                if lib.progressBar({
                    duration = 30000,
                    label = 'Procesando transferencia offshore...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                }) then
                    AIT.Notify('Transferencia completada', 'success')
                    TriggerServerEvent('ait:server:laundering:completeMission', 'offshore_transfer')
                end
            end

            RemoveBlip(blip)
            break
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- RIESGO POLICIAL
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Laundering.CheckPoliceRisk(businessType, amount)
    local risk = Config.policeRisk[businessType] or 10

    -- Mayor riesgo con cantidades grandes
    if amount > 50000 then
        risk = risk + 10
    elseif amount > 100000 then
        risk = risk + 25
    end

    local roll = math.random(1, 100)

    if roll <= risk then
        -- Alerta a la policía
        TriggerServerEvent('ait:server:police:launderingAlert', GetEntityCoords(PlayerPedId()))
        AIT.Notify('Algo salió mal... Parece que alguien está investigando.', 'warning')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Laundering.AddXP(amount)
    launderingXP = launderingXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if launderingXP >= levelData.xpRequired and launderingLevel < levelData.level then
            launderingLevel = levelData.level
            AIT.Notify('¡Nivel de lavado ' .. launderingLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:laundering:saveLevel', launderingLevel, launderingXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:laundering:loadLevel', function(level, xp)
    launderingLevel = level or 1
    launderingXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsLaundering', function() return isLaundering end)
exports('GetLaunderingLevel', function() return launderingLevel end)

return AIT.Jobs.Laundering
