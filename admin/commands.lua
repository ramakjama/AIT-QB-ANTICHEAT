--[[
    AIT-QB: Sistema de Administración - Comandos
    Servidor Español - Comandos de admin completos
]]

AIT = AIT or {}
AIT.Admin = AIT.Admin or {}
AIT.Admin.Commands = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE PERMISOS
-- ═══════════════════════════════════════════════════════════════

local Permissions = {
    god = 5,           -- Dueño del servidor
    admin = 4,         -- Administrador
    mod = 3,           -- Moderador
    helper = 2,        -- Helper/Support
    vip = 1,           -- VIP
    user = 0,          -- Usuario normal
}

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════

local function GetPlayer(source)
    return exports['qb-core']:GetPlayer(source)
end

local function GetPermissionLevel(source)
    local player = GetPlayer(source)
    if not player then return 0 end

    local permission = player.PlayerData.permission or 'user'
    return Permissions[permission] or 0
end

local function HasPermission(source, requiredLevel)
    return GetPermissionLevel(source) >= requiredLevel
end

local function Notify(source, msg, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Admin',
        description = msg,
        type = type or 'info',
    })
end

local function LogAdmin(admin, action, target, details)
    local adminPlayer = GetPlayer(admin)
    local adminName = adminPlayer and (adminPlayer.PlayerData.charinfo.firstname .. ' ' .. adminPlayer.PlayerData.charinfo.lastname) or 'Console'

    MySQL.Async.execute('INSERT INTO admin_logs (admin_id, admin_name, action, target_id, details, timestamp) VALUES (?, ?, ?, ?, ?, NOW())', {
        admin, adminName, action, target, json.encode(details)
    })

    print('[ADMIN] ' .. adminName .. ' ejecutó: ' .. action .. ' en ' .. (target or 'N/A'))
end

local function GetPlayerByIdOrName(identifier)
    -- Intentar por ID de servidor
    local id = tonumber(identifier)
    if id then
        local player = GetPlayer(id)
        if player then return id end
    end

    -- Intentar por nombre
    for _, playerId in ipairs(GetPlayers()) do
        local player = GetPlayer(playerId)
        if player then
            local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            if string.lower(name):find(string.lower(identifier)) then
                return tonumber(playerId)
            end
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE MODERACIÓN
-- ═══════════════════════════════════════════════════════════════

-- /kick [id] [razón]
RegisterCommand('kick', function(source, args)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local reason = table.concat(args, ' ', 2) or 'Sin razón especificada'

    DropPlayer(targetId, '🚫 Has sido expulsado\nRazón: ' .. reason .. '\n\nContacta con un admin si crees que es un error.')

    LogAdmin(source, 'kick', targetId, { reason = reason })
    Notify(source, 'Jugador expulsado', 'success')

    -- Notificar a todos los admins
    for _, playerId in ipairs(GetPlayers()) do
        if HasPermission(playerId, Permissions.mod) then
            Notify(playerId, 'Jugador ID:' .. targetId .. ' expulsado por: ' .. reason, 'warning')
        end
    end
end, false)

-- /ban [id] [duración] [razón]
RegisterCommand('ban', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local duration = args[2] or 'permanente'
    local reason = table.concat(args, ' ', 3) or 'Sin razón especificada'

    local targetPlayer = GetPlayer(targetId)
    local identifier = targetPlayer.PlayerData.citizenid
    local license = targetPlayer.PlayerData.license

    -- Calcular fecha de expiración
    local expireDate = nil
    if duration ~= 'permanente' then
        local num = tonumber(duration:match('%d+'))
        local unit = duration:match('%a+')

        if num and unit then
            local seconds = 0
            if unit == 'd' or unit == 'dias' then seconds = num * 86400
            elseif unit == 'h' or unit == 'horas' then seconds = num * 3600
            elseif unit == 'w' or unit == 'semanas' then seconds = num * 604800
            elseif unit == 'm' or unit == 'meses' then seconds = num * 2592000
            end
            expireDate = os.time() + seconds
        end
    end

    -- Guardar ban
    MySQL.Async.execute('INSERT INTO bans (identifier, license, reason, expire, banned_by) VALUES (?, ?, ?, ?, ?)', {
        identifier, license, reason, expireDate, source
    })

    DropPlayer(targetId, '🚫 Has sido BANEADO\nRazón: ' .. reason .. '\nDuración: ' .. duration .. '\n\nApela en: discord.gg/tuservidor')

    LogAdmin(source, 'ban', targetId, { reason = reason, duration = duration })
    Notify(source, 'Jugador baneado: ' .. duration, 'success')
end, false)

-- /unban [citizenid]
RegisterCommand('unban', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local identifier = args[1]
    if not identifier then
        Notify(source, 'Uso: /unban [citizenid]', 'error')
        return
    end

    MySQL.Async.execute('DELETE FROM bans WHERE identifier = ?', { identifier })

    LogAdmin(source, 'unban', nil, { identifier = identifier })
    Notify(source, 'Ban eliminado', 'success')
end, false)

-- /warn [id] [razón]
RegisterCommand('warn', function(source, args)
    if not HasPermission(source, Permissions.helper) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local reason = table.concat(args, ' ', 2) or 'Sin razón especificada'

    local targetPlayer = GetPlayer(targetId)
    local identifier = targetPlayer.PlayerData.citizenid

    -- Guardar warning
    MySQL.Async.execute('INSERT INTO warnings (identifier, reason, warned_by, timestamp) VALUES (?, ?, ?, NOW())', {
        identifier, reason, source
    })

    -- Contar warnings
    local warnings = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM warnings WHERE identifier = ?', { identifier })

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = '⚠️ ADVERTENCIA',
        description = reason .. '\n\nTotal de advertencias: ' .. warnings,
        type = 'warning',
        duration = 10000,
    })

    LogAdmin(source, 'warn', targetId, { reason = reason, totalWarnings = warnings })
    Notify(source, 'Advertencia enviada (Total: ' .. warnings .. ')', 'success')

    -- Auto-ban si tiene muchas advertencias
    if warnings >= 5 then
        Notify(source, 'El jugador tiene 5+ advertencias. Considera banearlo.', 'warning')
    end
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE TELEPORTE
-- ═══════════════════════════════════════════════════════════════

-- /tp [id]
RegisterCommand('tp', function(source, args)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    local coords = GetEntityCoords(targetPed)

    TriggerClientEvent('ait:client:admin:teleport', source, coords)

    LogAdmin(source, 'tp', targetId, { coords = coords })
    Notify(source, 'Teleportado al jugador', 'success')
end, false)

-- /bring [id]
RegisterCommand('bring', function(source, args)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local adminPed = GetPlayerPed(source)
    local coords = GetEntityCoords(adminPed)

    TriggerClientEvent('ait:client:admin:teleport', targetId, coords)

    LogAdmin(source, 'bring', targetId, { coords = coords })
    Notify(source, 'Jugador traído', 'success')
    Notify(targetId, 'Has sido teleportado por un admin', 'info')
end, false)

-- /tpcoords [x] [y] [z]
RegisterCommand('tpcoords', function(source, args)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])

    if not x or not y or not z then
        Notify(source, 'Uso: /tpcoords [x] [y] [z]', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:teleport', source, vector3(x, y, z))

    LogAdmin(source, 'tpcoords', nil, { x = x, y = y, z = z })
    Notify(source, 'Teleportado a coordenadas', 'success')
end, false)

-- /tpwaypoint
RegisterCommand('tpwaypoint', function(source)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:tpwaypoint', source)
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE JUGADOR
-- ═══════════════════════════════════════════════════════════════

-- /heal [id]
RegisterCommand('heal', function(source, args)
    if not HasPermission(source, Permissions.helper) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = args[1] and GetPlayerByIdOrName(args[1]) or source

    TriggerClientEvent('ait:client:admin:heal', targetId)

    LogAdmin(source, 'heal', targetId, {})
    Notify(source, 'Jugador curado', 'success')
end, false)

-- /revive [id]
RegisterCommand('revive', function(source, args)
    if not HasPermission(source, Permissions.helper) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = args[1] and GetPlayerByIdOrName(args[1]) or source

    TriggerClientEvent('ait:client:admin:revive', targetId)

    LogAdmin(source, 'revive', targetId, {})
    Notify(source, 'Jugador revivido', 'success')
end, false)

-- /armor [id]
RegisterCommand('armor', function(source, args)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = args[1] and GetPlayerByIdOrName(args[1]) or source

    TriggerClientEvent('ait:client:admin:armor', targetId)

    LogAdmin(source, 'armor', targetId, {})
    Notify(source, 'Armadura dada', 'success')
end, false)

-- /noclip
RegisterCommand('noclip', function(source)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:noclip', source)

    LogAdmin(source, 'noclip', nil, {})
end, false)

-- /god
RegisterCommand('god', function(source)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:godmode', source)

    LogAdmin(source, 'godmode', nil, {})
end, false)

-- /invisible
RegisterCommand('invisible', function(source)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:invisible', source)

    LogAdmin(source, 'invisible', nil, {})
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE ECONOMÍA
-- ═══════════════════════════════════════════════════════════════

-- /givemoney [id] [tipo] [cantidad]
RegisterCommand('givemoney', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local moneyType = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not amount or amount <= 0 then
        Notify(source, 'Cantidad inválida', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.AddMoney(moneyType, amount, 'admin-give')

    LogAdmin(source, 'givemoney', targetId, { type = moneyType, amount = amount })
    Notify(source, 'Dinero dado: $' .. amount .. ' (' .. moneyType .. ')', 'success')
    Notify(targetId, 'Recibiste $' .. amount .. ' de un admin', 'success')
end, false)

-- /removemoney [id] [tipo] [cantidad]
RegisterCommand('removemoney', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local moneyType = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not amount or amount <= 0 then
        Notify(source, 'Cantidad inválida', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.RemoveMoney(moneyType, amount, 'admin-remove')

    LogAdmin(source, 'removemoney', targetId, { type = moneyType, amount = amount })
    Notify(source, 'Dinero quitado: $' .. amount, 'success')
end, false)

-- /setmoney [id] [tipo] [cantidad]
RegisterCommand('setmoney', function(source, args)
    if not HasPermission(source, Permissions.god) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local moneyType = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not amount then
        Notify(source, 'Cantidad inválida', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.SetMoney(moneyType, amount, 'admin-set')

    LogAdmin(source, 'setmoney', targetId, { type = moneyType, amount = amount })
    Notify(source, 'Dinero establecido: $' .. amount, 'success')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE ITEMS
-- ═══════════════════════════════════════════════════════════════

-- /giveitem [id] [item] [cantidad]
RegisterCommand('giveitem', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local itemName = args[2]
    local amount = tonumber(args[3]) or 1

    if not itemName then
        Notify(source, 'Uso: /giveitem [id] [item] [cantidad]', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    local success = targetPlayer.Functions.AddItem(itemName, amount)

    if success then
        TriggerClientEvent('inventory:client:ItemBox', targetId, exports['qb-core']:GetItem(itemName), 'add', amount)
        LogAdmin(source, 'giveitem', targetId, { item = itemName, amount = amount })
        Notify(source, 'Item dado: ' .. itemName .. ' x' .. amount, 'success')
    else
        Notify(source, 'No se pudo dar el item', 'error')
    end
end, false)

-- /removeitem [id] [item] [cantidad]
RegisterCommand('removeitem', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local itemName = args[2]
    local amount = tonumber(args[3]) or 1

    if not itemName then
        Notify(source, 'Uso: /removeitem [id] [item] [cantidad]', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.RemoveItem(itemName, amount)

    LogAdmin(source, 'removeitem', targetId, { item = itemName, amount = amount })
    Notify(source, 'Item quitado: ' .. itemName .. ' x' .. amount, 'success')
end, false)

-- /clearinventory [id]
RegisterCommand('clearinventory', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.ClearInventory()

    LogAdmin(source, 'clearinventory', targetId, {})
    Notify(source, 'Inventario limpiado', 'success')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE TRABAJO
-- ═══════════════════════════════════════════════════════════════

-- /setjob [id] [job] [grade]
RegisterCommand('setjob', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local jobName = args[2]
    local grade = tonumber(args[3]) or 0

    if not jobName then
        Notify(source, 'Uso: /setjob [id] [job] [grade]', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.SetJob(jobName, grade)

    LogAdmin(source, 'setjob', targetId, { job = jobName, grade = grade })
    Notify(source, 'Trabajo establecido: ' .. jobName .. ' (grado ' .. grade .. ')', 'success')
    Notify(targetId, 'Tu trabajo ha sido cambiado a: ' .. jobName, 'info')
end, false)

-- /setgang [id] [gang] [grade]
RegisterCommand('setgang', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local targetId = GetPlayerByIdOrName(args[1])
    if not targetId then
        Notify(source, 'Jugador no encontrado', 'error')
        return
    end

    local gangName = args[2]
    local grade = tonumber(args[3]) or 0

    if not gangName then
        Notify(source, 'Uso: /setgang [id] [gang] [grade]', 'error')
        return
    end

    local targetPlayer = GetPlayer(targetId)
    targetPlayer.Functions.SetGang(gangName, grade)

    LogAdmin(source, 'setgang', targetId, { gang = gangName, grade = grade })
    Notify(source, 'Banda establecida: ' .. gangName, 'success')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE VEHÍCULOS
-- ═══════════════════════════════════════════════════════════════

-- /car [modelo]
RegisterCommand('car', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local model = args[1]
    if not model then
        Notify(source, 'Uso: /car [modelo]', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:spawncar', source, model)

    LogAdmin(source, 'spawncar', nil, { model = model })
end, false)

-- /dv (delete vehicle)
RegisterCommand('dv', function(source)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:deletevehicle', source)

    LogAdmin(source, 'deletevehicle', nil, {})
end, false)

-- /fix
RegisterCommand('fix', function(source)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:fixvehicle', source)
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE SERVIDOR
-- ═══════════════════════════════════════════════════════════════

-- /announce [mensaje]
RegisterCommand('announce', function(source, args)
    if not HasPermission(source, Permissions.mod) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local message = table.concat(args, ' ')
    if not message or message == '' then
        Notify(source, 'Uso: /announce [mensaje]', 'error')
        return
    end

    TriggerClientEvent('ox_lib:notify', -1, {
        title = '📢 ANUNCIO DEL SERVIDOR',
        description = message,
        type = 'info',
        duration = 15000,
    })

    LogAdmin(source, 'announce', nil, { message = message })
end, false)

-- /players
RegisterCommand('players', function(source)
    if not HasPermission(source, Permissions.helper) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local playerList = {}
    for _, playerId in ipairs(GetPlayers()) do
        local player = GetPlayer(playerId)
        if player then
            table.insert(playerList, {
                id = playerId,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                citizenid = player.PlayerData.citizenid,
                job = player.PlayerData.job.name,
            })
        end
    end

    TriggerClientEvent('ait:client:admin:showPlayers', source, playerList)
end, false)

-- /coords
RegisterCommand('coords', function(source)
    if not HasPermission(source, Permissions.helper) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:showCoords', source)
end, false)

-- /tiempo [hora]
RegisterCommand('tiempo', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local hour = tonumber(args[1])
    if not hour or hour < 0 or hour > 23 then
        Notify(source, 'Uso: /tiempo [0-23]', 'error')
        return
    end

    TriggerClientEvent('ait:client:admin:setTime', -1, hour)

    LogAdmin(source, 'settime', nil, { hour = hour })
    Notify(source, 'Hora establecida: ' .. hour .. ':00', 'success')
end, false)

-- /clima [tipo]
RegisterCommand('clima', function(source, args)
    if not HasPermission(source, Permissions.admin) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local weather = args[1]
    local validWeather = {
        'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN', 'CLEARING',
        'THUNDER', 'SMOG', 'FOGGY', 'XMAS', 'SNOWLIGHT', 'BLIZZARD'
    }

    if not weather then
        Notify(source, 'Climas: ' .. table.concat(validWeather, ', '), 'info')
        return
    end

    weather = string.upper(weather)

    TriggerClientEvent('ait:client:admin:setWeather', -1, weather)

    LogAdmin(source, 'setweather', nil, { weather = weather })
    Notify(source, 'Clima establecido: ' .. weather, 'success')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- COMANDO ADMIN MENU
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('admin', function(source)
    if not HasPermission(source, Permissions.helper) then
        Notify(source, 'No tienes permisos', 'error')
        return
    end

    local permLevel = GetPermissionLevel(source)

    TriggerClientEvent('ait:client:admin:openMenu', source, permLevel)
end, false)

RegisterKeyMapping('admin', 'Abrir Menú Admin', 'keyboard', 'F10')

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    -- Crear tabla de logs si no existe
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS admin_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_id INT,
            admin_name VARCHAR(100),
            action VARCHAR(50),
            target_id INT,
            details TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS warnings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50),
            reason TEXT,
            warned_by INT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    print('[AIT-QB] Sistema de comandos admin cargado')
end)

return AIT.Admin.Commands
