--[[
    AIT-QB: Server Handlers para Teléfono
    Servidor Español
]]

AIT = AIT or {}
AIT.Server = AIT.Server or {}
AIT.Server.Phone = {}

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════

local function GetPlayer(source)
    return exports['qb-core']:GetPlayer(source)
end

local function GetIdentifier(source)
    local player = GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end

local function Notify(source, msg, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Teléfono',
        description = msg,
        type = type or 'info',
    })
end

-- ═══════════════════════════════════════════════════════════════
-- DATOS DEL TELÉFONO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getData', function()
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    -- Cargar datos del teléfono
    local phoneData = MySQL.Sync.fetchAll('SELECT * FROM phone_data WHERE citizenid = ?', { identifier })

    local data = {
        contacts = {},
        messages = {},
        calls = {},
        settings = {
            wallpaper = 'default',
            ringtone = 'default',
            volume = 100,
            airplane = false,
            wifi = true,
        },
    }

    if phoneData and phoneData[1] then
        data.contacts = json.decode(phoneData[1].contacts) or {}
        data.messages = json.decode(phoneData[1].messages) or {}
        data.calls = json.decode(phoneData[1].calls) or {}
        data.settings = json.decode(phoneData[1].settings) or data.settings
    end

    TriggerClientEvent('ait:client:phone:loadData', source, data)
end)

-- ═══════════════════════════════════════════════════════════════
-- CONTACTOS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getContacts', function()
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    local result = MySQL.Sync.fetchScalar('SELECT contacts FROM phone_data WHERE citizenid = ?', { identifier })
    local contacts = result and json.decode(result) or {}

    TriggerClientEvent('ait:client:phone:showContacts', source, contacts)
end)

RegisterNetEvent('ait:server:phone:addContact', function(name, number)
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    local result = MySQL.Sync.fetchScalar('SELECT contacts FROM phone_data WHERE citizenid = ?', { identifier })
    local contacts = result and json.decode(result) or {}

    table.insert(contacts, {
        name = name,
        number = number,
        favorite = false,
    })

    MySQL.Async.execute('INSERT INTO phone_data (citizenid, contacts) VALUES (?, ?) ON DUPLICATE KEY UPDATE contacts = ?', {
        identifier, json.encode(contacts), json.encode(contacts)
    })

    Notify(source, 'Contacto añadido: ' .. name, 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- MENSAJES
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getMessages', function()
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    local result = MySQL.Sync.fetchScalar('SELECT messages FROM phone_data WHERE citizenid = ?', { identifier })
    local messages = result and json.decode(result) or {}

    TriggerClientEvent('ait:client:phone:showMessages', source, messages)
end)

RegisterNetEvent('ait:server:phone:sendMessage', function(toNumber, message)
    local source = source
    local identifier = GetIdentifier(source)
    local player = GetPlayer(source)
    if not identifier or not player then return end

    local senderNumber = player.PlayerData.charinfo.phone or identifier

    -- Guardar mensaje para el remitente
    local senderMessages = MySQL.Sync.fetchScalar('SELECT messages FROM phone_data WHERE citizenid = ?', { identifier })
    senderMessages = senderMessages and json.decode(senderMessages) or {}

    -- Buscar o crear conversación
    local convoFound = false
    for i, convo in ipairs(senderMessages) do
        if convo.number == toNumber then
            table.insert(convo.messages, {
                content = message,
                sender = 'me',
                time = os.time(),
            })
            convoFound = true
            break
        end
    end

    if not convoFound then
        table.insert(senderMessages, {
            number = toNumber,
            name = toNumber,
            messages = {
                { content = message, sender = 'me', time = os.time() }
            }
        })
    end

    MySQL.Async.execute('INSERT INTO phone_data (citizenid, messages) VALUES (?, ?) ON DUPLICATE KEY UPDATE messages = ?', {
        identifier, json.encode(senderMessages), json.encode(senderMessages)
    })

    -- Buscar destinatario por número de teléfono
    local targetPlayer = nil
    for _, playerId in ipairs(GetPlayers()) do
        local p = GetPlayer(playerId)
        if p and p.PlayerData.charinfo.phone == toNumber then
            targetPlayer = playerId
            break
        end
    end

    if targetPlayer then
        -- Guardar mensaje para el destinatario
        local targetIdentifier = GetIdentifier(targetPlayer)
        local targetMessages = MySQL.Sync.fetchScalar('SELECT messages FROM phone_data WHERE citizenid = ?', { targetIdentifier })
        targetMessages = targetMessages and json.decode(targetMessages) or {}

        local convoFound2 = false
        for i, convo in ipairs(targetMessages) do
            if convo.number == senderNumber then
                table.insert(convo.messages, {
                    content = message,
                    sender = senderNumber,
                    time = os.time(),
                })
                convoFound2 = true
                break
            end
        end

        if not convoFound2 then
            table.insert(targetMessages, {
                number = senderNumber,
                name = senderNumber,
                messages = {
                    { content = message, sender = senderNumber, time = os.time() }
                }
            })
        end

        MySQL.Async.execute('UPDATE phone_data SET messages = ? WHERE citizenid = ?', {
            json.encode(targetMessages), targetIdentifier
        })

        -- Notificar al destinatario
        TriggerClientEvent('ait:client:phone:newMessage', targetPlayer, player.PlayerData.charinfo.firstname, message)
    end

    Notify(source, 'Mensaje enviado', 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- LLAMADAS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:makeCall', function(number)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local callerNumber = player.PlayerData.charinfo.phone or 'Desconocido'

    -- Buscar destinatario
    for _, playerId in ipairs(GetPlayers()) do
        local p = GetPlayer(playerId)
        if p and p.PlayerData.charinfo.phone == number then
            TriggerClientEvent('ait:client:phone:incomingCall', playerId, callerName, callerNumber)
            Notify(source, 'Llamando...', 'info')
            return
        end
    end

    Notify(source, 'Número no disponible', 'error')
end)

RegisterNetEvent('ait:server:phone:emergencyCall', function(service)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local coords = GetEntityCoords(GetPlayerPed(source))
    local callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    local jobName = service == 'police' and 'police' or service == 'ambulance' and 'ambulance' or 'mechanic'
    local serviceName = service == 'police' and 'Policía' or service == 'ambulance' and 'EMS' or 'Mecánico'

    -- Notificar a todos los de ese servicio
    local notified = 0
    for _, playerId in ipairs(GetPlayers()) do
        local p = GetPlayer(playerId)
        if p and p.PlayerData.job.name == jobName and p.PlayerData.job.onduty then
            TriggerClientEvent('ait:client:phone:notification', playerId, {
                title = 'Llamada de Emergencia',
                message = 'De: ' .. callerName,
                app = '911',
            })
            TriggerClientEvent('ait:client:police:alert', playerId, 'emergency', coords)
            notified = notified + 1
        end
    end

    if notified > 0 then
        Notify(source, serviceName .. ' notificado (' .. notified .. ' unidades)', 'success')
    else
        Notify(source, 'No hay unidades de ' .. serviceName .. ' disponibles', 'error')
    end
end)

RegisterNetEvent('ait:server:phone:call911', function(service, message)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local coords = GetEntityCoords(GetPlayerPed(source))
    local callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local street = 'Los Santos' -- Simplificado

    local jobName = service

    for _, playerId in ipairs(GetPlayers()) do
        local p = GetPlayer(playerId)
        if p and p.PlayerData.job.name == jobName and p.PlayerData.job.onduty then
            TriggerClientEvent('ait:client:phone:notification', playerId, {
                title = '📞 911 - ' .. string.upper(service),
                message = callerName .. ': ' .. (message or 'Sin mensaje'),
                app = '911',
            })
            TriggerClientEvent('ait:client:police:alert', playerId, '911', coords)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- BANCO
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getBankData', function()
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local identifier = GetIdentifier(source)

    -- Obtener transacciones recientes
    local transactions = MySQL.Sync.fetchAll(
        'SELECT * FROM transactions WHERE identifier = ? ORDER BY created_at DESC LIMIT 20',
        { identifier }
    ) or {}

    local bankData = {
        balance = player.PlayerData.money.bank or 0,
        cash = player.PlayerData.money.cash or 0,
        transactions = transactions,
    }

    TriggerClientEvent('ait:client:phone:showBank', source, bankData)
end)

RegisterNetEvent('ait:server:phone:bankTransfer', function(toAccount, amount)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        Notify(source, 'Cantidad inválida', 'error')
        return
    end

    if player.PlayerData.money.bank < amount then
        Notify(source, 'Fondos insuficientes', 'error')
        return
    end

    -- Buscar destinatario por número de cuenta (citizenid)
    local targetPlayer = nil
    for _, playerId in ipairs(GetPlayers()) do
        local p = GetPlayer(playerId)
        if p and p.PlayerData.citizenid == toAccount then
            targetPlayer = playerId
            break
        end
    end

    -- Quitar dinero al remitente
    player.Functions.RemoveMoney('bank', amount, 'transfer-out')

    -- Añadir dinero al destinatario (online u offline)
    if targetPlayer then
        local tp = GetPlayer(targetPlayer)
        tp.Functions.AddMoney('bank', amount, 'transfer-in')
        TriggerClientEvent('ait:client:phone:notification', targetPlayer, {
            title = 'Transferencia recibida',
            message = '+$' .. amount .. ' de ' .. player.PlayerData.charinfo.firstname,
            app = 'bank',
        })
    else
        -- Actualizar en DB para jugador offline
        MySQL.Async.execute('UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', {
            amount, toAccount
        })
    end

    -- Registrar transacciones
    MySQL.Async.execute('INSERT INTO transactions (identifier, type, amount, description) VALUES (?, ?, ?, ?)', {
        GetIdentifier(source), 'transfer_out', -amount, 'Transferencia a ' .. toAccount
    })

    MySQL.Async.execute('INSERT INTO transactions (identifier, type, amount, description) VALUES (?, ?, ?, ?)', {
        toAccount, 'transfer_in', amount, 'Transferencia de ' .. GetIdentifier(source)
    })

    Notify(source, 'Transferencia de $' .. amount .. ' completada', 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- GARAJE
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getGarage', function()
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    local vehicles = MySQL.Sync.fetchAll(
        'SELECT * FROM player_vehicles WHERE citizenid = ?',
        { identifier }
    ) or {}

    TriggerClientEvent('ait:client:phone:showGarage', source, vehicles)
end)

-- ═══════════════════════════════════════════════════════════════
-- TWITTER
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getTweets', function()
    local source = source

    local tweets = MySQL.Sync.fetchAll(
        'SELECT t.*, c.firstname, c.lastname FROM twitter_tweets t LEFT JOIN characters c ON t.citizenid = c.citizenid ORDER BY t.created_at DESC LIMIT 50'
    ) or {}

    TriggerClientEvent('ait:client:phone:showTweets', source, tweets)
end)

RegisterNetEvent('ait:server:phone:postTweet', function(message)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local identifier = GetIdentifier(source)
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    MySQL.Async.execute('INSERT INTO twitter_tweets (citizenid, message, created_at) VALUES (?, ?, NOW())', {
        identifier, message
    })

    -- Notificar a todos (simplificado)
    for _, playerId in ipairs(GetPlayers()) do
        if playerId ~= source then
            TriggerClientEvent('ait:client:phone:notification', playerId, {
                title = 'Twitter',
                message = name .. ': ' .. string.sub(message, 1, 50),
                app = 'twitter',
            })
        end
    end

    Notify(source, 'Tweet publicado', 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- MARKETPLACE
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:getMarketplace', function()
    local source = source

    local listings = MySQL.Sync.fetchAll(
        'SELECT m.*, c.firstname, c.lastname FROM marketplace_listings m LEFT JOIN characters c ON m.citizenid = c.citizenid WHERE m.sold = 0 ORDER BY m.created_at DESC LIMIT 50'
    ) or {}

    TriggerClientEvent('ait:client:phone:showMarketplace', source, listings)
end)

-- ═══════════════════════════════════════════════════════════════
-- DARKWEB
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:checkDarkwebAccess', function()
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local hasUSB = player.Functions.GetItemByName('darkweb_usb')
    local hasAccess = hasUSB and hasUSB.amount > 0

    local listings = {}
    if hasAccess then
        listings = {
            { id = 1, name = 'Pistola Sin Registro', price = 5000, category = 'armas' },
            { id = 2, name = 'Droga (10g)', price = 2000, category = 'drogas' },
            { id = 3, name = 'Lockpick Avanzado', price = 500, category = 'herramientas' },
            { id = 4, name = 'Documento Falso', price = 10000, category = 'documentos' },
            { id = 5, name = 'Laptop Hackeada', price = 15000, category = 'tech' },
            { id = 6, name = 'Info de Banco', price = 50000, category = 'info' },
        }
    end

    TriggerClientEvent('ait:client:phone:showDarkweb', source, hasAccess, listings)
end)

-- ═══════════════════════════════════════════════════════════════
-- CRYPTO
-- ═══════════════════════════════════════════════════════════════

local cryptoPrices = {
    bitcoin = { price = 45000, change = 0 },
    ethereum = { price = 3200, change = 0 },
    litecoin = { price = 180, change = 0 },
    dogecoin = { price = 0.15, change = 0 },
}

-- Actualizar precios cada minuto
CreateThread(function()
    while true do
        Wait(60000)
        for coin, data in pairs(cryptoPrices) do
            local change = math.random(-500, 500) / 100 -- -5% a +5%
            data.price = data.price * (1 + change / 100)
            data.change = change
        end
    end
end)

RegisterNetEvent('ait:server:phone:getCrypto', function()
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    local wallet = MySQL.Sync.fetchScalar('SELECT crypto_wallet FROM characters WHERE citizenid = ?', { identifier })
    wallet = wallet and json.decode(wallet) or { bitcoin = 0, ethereum = 0, litecoin = 0, dogecoin = 0 }

    local data = {
        wallet = wallet,
        prices = cryptoPrices,
    }

    TriggerClientEvent('ait:client:phone:showCrypto', source, data)
end)

RegisterNetEvent('ait:server:phone:buyCrypto', function(coin, amount)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local price = cryptoPrices[coin]
    if not price then return end

    local cost = price.price * amount

    if player.PlayerData.money.bank < cost then
        Notify(source, 'Fondos insuficientes', 'error')
        return
    end

    player.Functions.RemoveMoney('bank', cost, 'crypto-buy')

    local identifier = GetIdentifier(source)
    local wallet = MySQL.Sync.fetchScalar('SELECT crypto_wallet FROM characters WHERE citizenid = ?', { identifier })
    wallet = wallet and json.decode(wallet) or {}

    wallet[coin] = (wallet[coin] or 0) + amount

    MySQL.Async.execute('UPDATE characters SET crypto_wallet = ? WHERE citizenid = ?', {
        json.encode(wallet), identifier
    })

    Notify(source, 'Compraste ' .. amount .. ' ' .. coin .. ' por $' .. math.floor(cost), 'success')
end)

RegisterNetEvent('ait:server:phone:sellCrypto', function(coin, amount)
    local source = source
    local player = GetPlayer(source)
    if not player then return end

    local identifier = GetIdentifier(source)
    local wallet = MySQL.Sync.fetchScalar('SELECT crypto_wallet FROM characters WHERE citizenid = ?', { identifier })
    wallet = wallet and json.decode(wallet) or {}

    if not wallet[coin] or wallet[coin] < amount then
        Notify(source, 'No tienes suficiente ' .. coin, 'error')
        return
    end

    local price = cryptoPrices[coin]
    local earnings = price.price * amount

    wallet[coin] = wallet[coin] - amount

    MySQL.Async.execute('UPDATE characters SET crypto_wallet = ? WHERE citizenid = ?', {
        json.encode(wallet), identifier
    })

    player.Functions.AddMoney('bank', math.floor(earnings), 'crypto-sell')

    Notify(source, 'Vendiste ' .. amount .. ' ' .. coin .. ' por $' .. math.floor(earnings), 'success')
end)

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:phone:updateSetting', function(setting, value)
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end

    local result = MySQL.Sync.fetchScalar('SELECT settings FROM phone_data WHERE citizenid = ?', { identifier })
    local settings = result and json.decode(result) or {}

    settings[setting] = value

    MySQL.Async.execute('INSERT INTO phone_data (citizenid, settings) VALUES (?, ?) ON DUPLICATE KEY UPDATE settings = ?', {
        identifier, json.encode(settings), json.encode(settings)
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    -- Crear tabla si no existe
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS phone_data (
            citizenid VARCHAR(50) PRIMARY KEY,
            contacts LONGTEXT DEFAULT '[]',
            messages LONGTEXT DEFAULT '[]',
            calls LONGTEXT DEFAULT '[]',
            settings LONGTEXT DEFAULT '{}'
        )
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS twitter_tweets (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            message TEXT,
            likes INT DEFAULT 0,
            retweets INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS marketplace_listings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            title VARCHAR(255),
            description TEXT,
            price INT,
            category VARCHAR(50),
            sold TINYINT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    print('[AIT-QB] Server handlers de teléfono cargados')
end)

return AIT.Server.Phone
