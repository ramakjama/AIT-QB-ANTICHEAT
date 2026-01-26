--[[
    AIT-QB: Servidor Principal
    Gestión central del servidor
    Servidor Español - 2048 slots
]]

AIT = AIT or {}
AIT.Server = AIT.Server or {}
AIT.Players = {}
AIT.Characters = {}
AIT.Ready = false

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    -- Esperar a que la base de datos esté lista
    Wait(1000)

    -- Inicializar módulos del core
    if AIT.Core and AIT.Core.Initialize then
        AIT.Core.Initialize()
    end

    -- Inicializar engines
    AIT.Server.InitializeEngines()

    -- Marcar como listo
    AIT.Ready = true

    print('^2[AIT-QB]^7 ═══════════════════════════════════════════')
    print('^2[AIT-QB]^7 Servidor iniciado correctamente')
    print('^2[AIT-QB]^7 Versión: 1.0.0')
    print('^2[AIT-QB]^7 Slots: 2048')
    print('^2[AIT-QB]^7 ═══════════════════════════════════════════')
end)

-- ═══════════════════════════════════════════════════════════════
-- GESTIÓN DE JUGADORES
-- ═══════════════════════════════════════════════════════════════

-- Conexión de jugador
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)

    deferrals.defer()
    Wait(0)

    deferrals.update('🔍 Verificando identidad...')
    Wait(500)

    -- Obtener identificadores
    local license, discord, steam, fivem = nil, nil, nil, nil
    for _, v in pairs(identifiers) do
        if string.sub(v, 1, 8) == 'license:' then
            license = v
        elseif string.sub(v, 1, 8) == 'discord:' then
            discord = v
        elseif string.sub(v, 1, 6) == 'steam:' then
            steam = v
        elseif string.sub(v, 1, 6) == 'fivem:' then
            fivem = v
        end
    end

    if not license then
        deferrals.done('❌ No se pudo verificar tu licencia de Rockstar.')
        return
    end

    deferrals.update('📊 Cargando datos del jugador...')
    Wait(500)

    -- Verificar ban
    local banned = MySQL.scalar.await('SELECT reason FROM ait_bans WHERE identifier = ? AND (expires_at IS NULL OR expires_at > NOW())', { license })
    if banned then
        deferrals.done('⛔ Estás baneado del servidor.\nRazón: ' .. banned)
        return
    end

    -- Verificar whitelist si está activa
    if Config and Config.Whitelist and Config.Whitelist.enabled then
        local whitelisted = MySQL.scalar.await('SELECT 1 FROM ait_whitelist WHERE identifier = ?', { license })
        if not whitelisted then
            deferrals.done('📋 No estás en la whitelist del servidor.\nSolicita acceso en nuestro Discord.')
            return
        end
    end

    deferrals.update('✅ ¡Bienvenido a AIT-QB!')
    Wait(500)

    deferrals.done()
end)

-- Jugador conectado
AddEventHandler('playerJoining', function()
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    local license = nil

    for _, v in pairs(identifiers) do
        if string.sub(v, 1, 8) == 'license:' then
            license = v
            break
        end
    end

    -- Registrar o actualizar jugador en DB
    MySQL.insert.await([[
        INSERT INTO ait_players (identifier, name, first_join, last_join)
        VALUES (?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE name = VALUES(name), last_join = NOW()
    ]], { license, GetPlayerName(source) })

    -- Crear entrada en cache
    AIT.Players[source] = {
        source = source,
        identifier = license,
        name = GetPlayerName(source),
        character = nil,
        loaded = false,
    }

    print('^3[AIT-QB]^7 Jugador conectando: ' .. GetPlayerName(source) .. ' (ID: ' .. source .. ')')
end)

-- Solicitar datos del jugador
RegisterNetEvent('ait:server:requestPlayerData', function()
    local source = source
    local player = AIT.Players[source]

    if not player then
        return
    end

    -- Cargar personaje activo o crear selección
    local characters = MySQL.query.await([[
        SELECT * FROM ait_characters
        WHERE player_identifier = ?
        ORDER BY last_played DESC
    ]], { player.identifier })

    if #characters == 0 then
        -- No tiene personajes, enviar a creación
        TriggerClientEvent('ait:client:characterCreation', source)
    elseif #characters == 1 then
        -- Solo un personaje, cargar automáticamente
        AIT.Server.LoadCharacter(source, characters[1].id)
    else
        -- Múltiples personajes, mostrar selección
        TriggerClientEvent('ait:client:characterSelection', source, characters)
    end
end)

-- Cargar personaje
function AIT.Server.LoadCharacter(source, characterId)
    local player = AIT.Players[source]
    if not player then return false end

    local character = MySQL.single.await('SELECT * FROM ait_characters WHERE id = ?', { characterId })
    if not character then return false end

    -- Actualizar última vez jugado
    MySQL.update.await('UPDATE ait_characters SET last_played = NOW() WHERE id = ?', { characterId })

    -- Parsear datos JSON
    local charData = {
        id = character.id,
        identifier = player.identifier,
        name = character.first_name .. ' ' .. character.last_name,
        firstName = character.first_name,
        lastName = character.last_name,
        dateOfBirth = character.date_of_birth,
        gender = character.gender,
        nationality = character.nationality,

        -- Dinero
        money = {
            cash = character.cash or 0,
            bank = character.bank or 0,
            crypto = character.crypto or 0,
        },

        -- Trabajo
        job = json.decode(character.job) or { name = 'unemployed', label = 'Desempleado', grade = 0, gradeName = 'Desempleado' },

        -- Gang
        gang = json.decode(character.gang) or { name = 'none', label = 'Sin Banda', grade = 0 },

        -- Posición
        position = json.decode(character.position) or vector4(-269.4, -955.3, 31.2, 205.8),

        -- Metadata
        metadata = json.decode(character.metadata) or {
            hunger = 100,
            thirst = 100,
            stress = 0,
            health = 200,
            armor = 0,
            isHandcuffed = false,
            isDead = false,
            jailtimer = 0,
            licenses = {},
            phone = nil,
        },

        -- Skin
        skin = json.decode(character.skin) or {},

        -- Estadísticas
        stats = json.decode(character.stats) or {
            playTime = 0,
            deaths = 0,
            kills = 0,
        },
    }

    -- Guardar en cache
    player.character = charData
    player.loaded = true
    AIT.Characters[characterId] = source

    -- Enviar datos al cliente
    TriggerClientEvent('ait:client:setPlayerData', source, charData)

    -- Evento de personaje cargado
    TriggerEvent('ait:server:playerLoaded', source, charData)

    print('^2[AIT-QB]^7 Personaje cargado: ' .. charData.name .. ' (ID: ' .. characterId .. ') para ' .. GetPlayerName(source))

    return true
end

-- Jugador desconectado
AddEventHandler('playerDropped', function(reason)
    local source = source
    local player = AIT.Players[source]

    if player and player.character then
        -- Guardar datos del personaje
        AIT.Server.SaveCharacter(source)

        -- Limpiar cache
        if player.character.id then
            AIT.Characters[player.character.id] = nil
        end

        print('^3[AIT-QB]^7 Jugador desconectado: ' .. player.name .. ' - ' .. reason)
    end

    AIT.Players[source] = nil
end)

-- Guardar personaje
function AIT.Server.SaveCharacter(source)
    local player = AIT.Players[source]
    if not player or not player.character then return false end

    local char = player.character
    local ped = GetPlayerPed(source)

    -- Actualizar posición si está vivo
    if ped and DoesEntityExist(ped) and not char.metadata.isDead then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        char.position = vector4(coords.x, coords.y, coords.z, heading)
    end

    MySQL.update.await([[
        UPDATE ait_characters SET
            cash = ?,
            bank = ?,
            crypto = ?,
            job = ?,
            gang = ?,
            position = ?,
            metadata = ?,
            skin = ?,
            stats = ?,
            last_played = NOW()
        WHERE id = ?
    ]], {
        char.money.cash,
        char.money.bank,
        char.money.crypto,
        json.encode(char.job),
        json.encode(char.gang),
        json.encode(char.position),
        json.encode(char.metadata),
        json.encode(char.skin),
        json.encode(char.stats),
        char.id,
    })

    return true
end

-- Auto-guardado periódico
CreateThread(function()
    while true do
        Wait(5 * 60 * 1000) -- Cada 5 minutos

        local count = 0
        for source, player in pairs(AIT.Players) do
            if player.loaded then
                AIT.Server.SaveCharacter(source)
                count = count + 1
            end
        end

        if count > 0 then
            print('^2[AIT-QB]^7 Auto-guardado: ' .. count .. ' personajes guardados')
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE ENGINES
-- ═══════════════════════════════════════════════════════════════

AIT.Server.Engines = {}

function AIT.Server.RegisterEngine(name, engine)
    AIT.Server.Engines[name] = engine
    print('^3[AIT-QB]^7 Engine registrado: ' .. name)
end

function AIT.Server.InitializeEngines()
    for name, engine in pairs(AIT.Server.Engines) do
        if engine.Init then
            local success, err = pcall(engine.Init)
            if success then
                print('^2[AIT-QB]^7 Engine inicializado: ' .. name)
            else
                print('^1[AIT-QB]^7 Error inicializando engine ' .. name .. ': ' .. tostring(err))
            end
        end
    end
end

function AIT.Server.GetEngine(name)
    return AIT.Server.Engines[name]
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE CALLBACKS
-- ═══════════════════════════════════════════════════════════════

AIT.Server.Callbacks = {}

function AIT.Server.RegisterCallback(name, cb)
    AIT.Server.Callbacks[name] = cb
end

RegisterNetEvent('ait:server:triggerCallback', function(name, callbackId, ...)
    local source = source
    if AIT.Server.Callbacks[name] then
        local result = { AIT.Server.Callbacks[name](source, ...) }
        TriggerClientEvent('ait:client:callbackResponse', source, callbackId, table.unpack(result))
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE UTILIDAD
-- ═══════════════════════════════════════════════════════════════

-- Obtener jugador
function AIT.Server.GetPlayer(source)
    return AIT.Players[source]
end

-- Obtener jugador por identifier
function AIT.Server.GetPlayerByIdentifier(identifier)
    for source, player in pairs(AIT.Players) do
        if player.identifier == identifier then
            return player, source
        end
    end
    return nil
end

-- Obtener jugador por character ID
function AIT.Server.GetPlayerByCharacterId(characterId)
    local source = AIT.Characters[characterId]
    if source then
        return AIT.Players[source], source
    end
    return nil
end

-- Obtener todos los jugadores
function AIT.Server.GetPlayers()
    local players = {}
    for source, player in pairs(AIT.Players) do
        if player.loaded then
            table.insert(players, {
                source = source,
                player = player,
            })
        end
    end
    return players
end

-- Notificar a jugador
function AIT.Server.Notify(source, message, type, duration)
    TriggerClientEvent('ait:client:notification', source, message, type or 'info', duration or 5000)
end

-- Notificar a todos
function AIT.Server.NotifyAll(message, type, duration)
    TriggerClientEvent('ait:client:notification', -1, message, type or 'info', duration or 5000)
end

-- ═══════════════════════════════════════════════════════════════
-- EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:server:playerDied', function(killerId)
    local source = source
    local player = AIT.Players[source]

    if player and player.character then
        player.character.metadata.isDead = true
        player.character.stats.deaths = (player.character.stats.deaths or 0) + 1

        TriggerClientEvent('ait:client:updatePlayerData', source, 'metadata', player.character.metadata)

        -- Registrar muerte
        TriggerEvent('ait:server:playerDeath', source, killerId)
    end
end)

RegisterNetEvent('ait:server:playerRevived', function()
    local source = source
    local player = AIT.Players[source]

    if player and player.character then
        player.character.metadata.isDead = false
        TriggerClientEvent('ait:client:updatePlayerData', source, 'metadata', player.character.metadata)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE ADMIN
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('givemoney', function(source, args)
    if source > 0 then
        -- Verificar permisos
        local player = AIT.Players[source]
        -- TODO: Verificar si es admin
    end

    local targetId = tonumber(args[1])
    local type = args[2] or 'cash'
    local amount = tonumber(args[3]) or 0

    if not targetId or amount <= 0 then
        print('Uso: givemoney [id] [cash/bank/crypto] [cantidad]')
        return
    end

    local target = AIT.Players[targetId]
    if target and target.character then
        if target.character.money[type] then
            target.character.money[type] = target.character.money[type] + amount
            TriggerClientEvent('ait:client:updatePlayerData', targetId, 'money', target.character.money)
            AIT.Server.Notify(targetId, 'Has recibido $' .. amount .. ' (' .. type .. ')', 'success')
            print('[AIT-QB] Dinero dado a ' .. target.name .. ': ' .. amount .. ' ' .. type)
        end
    end
end, true)

RegisterCommand('setjob', function(source, args)
    local targetId = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0

    if not targetId or not jobName then
        print('Uso: setjob [id] [trabajo] [grado]')
        return
    end

    local target = AIT.Players[targetId]
    if target and target.character then
        -- TODO: Validar trabajo desde catálogo
        target.character.job = {
            name = jobName,
            label = jobName,
            grade = grade,
            gradeName = 'Grado ' .. grade,
        }
        TriggerClientEvent('ait:client:updatePlayerData', targetId, 'job', target.character.job)
        AIT.Server.Notify(targetId, 'Tu trabajo ha sido cambiado a: ' .. jobName, 'info')
        print('[AIT-QB] Trabajo establecido para ' .. target.name .. ': ' .. jobName)
    end
end, true)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('GetPlayer', function(source)
    return AIT.Server.GetPlayer(source)
end)

exports('GetPlayerByIdentifier', function(identifier)
    return AIT.Server.GetPlayerByIdentifier(identifier)
end)

exports('GetPlayers', function()
    return AIT.Server.GetPlayers()
end)

exports('Notify', function(source, message, type, duration)
    AIT.Server.Notify(source, message, type, duration)
end)

exports('RegisterCallback', function(name, cb)
    AIT.Server.RegisterCallback(name, cb)
end)

exports('SaveCharacter', function(source)
    return AIT.Server.SaveCharacter(source)
end)
