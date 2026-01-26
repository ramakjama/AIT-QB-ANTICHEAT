--[[
    AIT-QB: Módulo de Administración
    Panel de admin y comandos
    Servidor Español
]]

AIT = AIT or {}
AIT.Admin = AIT.Admin or {}

-- Niveles de permisos
AIT.Admin.Levels = {
    user = 0,
    helper = 1,
    moderator = 2,
    admin = 3,
    superadmin = 4,
    owner = 5,
}

-- Cache de permisos
AIT.Admin.Permissions = {}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Admin.Init()
    -- Cargar permisos desde la base de datos
    MySQL.ready(function()
        local admins = MySQL.query.await('SELECT identifier, level, permissions FROM ait_admins')
        for _, admin in ipairs(admins or {}) do
            AIT.Admin.Permissions[admin.identifier] = {
                level = admin.level,
                permissions = json.decode(admin.permissions) or {},
            }
        end
        print('^2[AIT-QB]^7 Módulo Admin inicializado - ' .. #(admins or {}) .. ' admins cargados')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE PERMISOS
-- ═══════════════════════════════════════════════════════════════

-- Obtener nivel de admin
function AIT.Admin.GetLevel(source)
    local player = AIT.Server and AIT.Server.GetPlayer(source)
    if not player then return 0 end

    local adminData = AIT.Admin.Permissions[player.identifier]
    return adminData and adminData.level or 0
end

-- Verificar si tiene nivel mínimo
function AIT.Admin.HasLevel(source, minLevel)
    local level = AIT.Admin.GetLevel(source)
    if type(minLevel) == 'string' then
        minLevel = AIT.Admin.Levels[minLevel] or 0
    end
    return level >= minLevel
end

-- Verificar permiso específico
function AIT.Admin.HasPermission(source, permission)
    local player = AIT.Server and AIT.Server.GetPlayer(source)
    if not player then return false end

    local adminData = AIT.Admin.Permissions[player.identifier]
    if not adminData then return false end

    -- Owners tienen todos los permisos
    if adminData.level >= AIT.Admin.Levels.owner then
        return true
    end

    -- Verificar permiso específico
    if adminData.permissions then
        return adminData.permissions[permission] == true
    end

    return false
end

-- Establecer nivel de admin
function AIT.Admin.SetLevel(identifier, level)
    MySQL.insert([[
        INSERT INTO ait_admins (identifier, level) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level)
    ]], { identifier, level })

    if not AIT.Admin.Permissions[identifier] then
        AIT.Admin.Permissions[identifier] = { level = level, permissions = {} }
    else
        AIT.Admin.Permissions[identifier].level = level
    end
end

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DE ADMINISTRACIÓN
-- ═══════════════════════════════════════════════════════════════

-- /admin - Abrir panel de admin
RegisterCommand('admin', function(source)
    if not AIT.Admin.HasLevel(source, 'helper') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:openAdminPanel', source)
end, false)

-- /kick - Expulsar jugador
RegisterCommand('kick', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    local reason = table.concat(args, ' ', 2) or 'Sin razón especificada'

    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /kick [id] [razón]', 'error')
        return
    end

    local targetName = GetPlayerName(targetId)
    if targetName then
        DropPlayer(targetId, '⛔ Has sido expulsado\nRazón: ' .. reason .. '\nAdmin: ' .. GetPlayerName(source))
        AIT.Admin.Log(source, 'kick', 'Expulsó a ' .. targetName .. ' - Razón: ' .. reason)
        TriggerClientEvent('ait:client:notification', -1, '👢 ' .. targetName .. ' ha sido expulsado', 'warning')
    end
end, false)

-- /ban - Banear jugador
RegisterCommand('ban', function(source, args)
    if not AIT.Admin.HasLevel(source, 'admin') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    local duration = args[2] or 'permanent' -- días o 'permanent'
    local reason = table.concat(args, ' ', 3) or 'Sin razón especificada'

    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /ban [id] [días/permanent] [razón]', 'error')
        return
    end

    local player = AIT.Server and AIT.Server.GetPlayer(targetId)
    if not player then
        TriggerClientEvent('ait:client:notification', source, '❌ Jugador no encontrado', 'error')
        return
    end

    local expiresAt = nil
    if duration ~= 'permanent' then
        local days = tonumber(duration) or 1
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (days * 24 * 60 * 60))
    end

    MySQL.insert([[
        INSERT INTO ait_bans (identifier, reason, banned_by, expires_at, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { player.identifier, reason, GetPlayerName(source), expiresAt })

    DropPlayer(targetId, '⛔ Has sido baneado\nRazón: ' .. reason .. '\nDuración: ' .. (duration == 'permanent' and 'Permanente' or duration .. ' días'))
    AIT.Admin.Log(source, 'ban', 'Baneó a ' .. player.name .. ' - Duración: ' .. duration .. ' - Razón: ' .. reason)
    TriggerClientEvent('ait:client:notification', -1, '🔨 ' .. player.name .. ' ha sido baneado', 'error')
end, false)

-- /unban - Desbanear jugador
RegisterCommand('unban', function(source, args)
    if not AIT.Admin.HasLevel(source, 'admin') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local identifier = args[1]
    if not identifier then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /unban [license:xxx]', 'error')
        return
    end

    MySQL.update('DELETE FROM ait_bans WHERE identifier = ?', { identifier })
    TriggerClientEvent('ait:client:notification', source, '✅ Jugador desbaneado', 'success')
    AIT.Admin.Log(source, 'unban', 'Desbaneó a ' .. identifier)
end, false)

-- /tp - Teletransportarse a jugador
RegisterCommand('tp', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /tp [id]', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if targetPed then
        local coords = GetEntityCoords(targetPed)
        TriggerClientEvent('ait:client:teleport', source, coords)
        TriggerClientEvent('ait:client:notification', source, '✅ Teletransportado a ' .. GetPlayerName(targetId), 'success')
    end
end, false)

-- /bring - Traer jugador
RegisterCommand('bring', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /bring [id]', 'error')
        return
    end

    local myPed = GetPlayerPed(source)
    if myPed then
        local coords = GetEntityCoords(myPed)
        TriggerClientEvent('ait:client:teleport', targetId, coords)
        TriggerClientEvent('ait:client:notification', targetId, '📍 Has sido teletransportado por un admin', 'info')
        TriggerClientEvent('ait:client:notification', source, '✅ Jugador traído', 'success')
    end
end, false)

-- /goto - Ir a coordenadas
RegisterCommand('goto', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])

    if not x or not y or not z then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /goto [x] [y] [z]', 'error')
        return
    end

    TriggerClientEvent('ait:client:teleport', source, vector3(x, y, z))
    TriggerClientEvent('ait:client:notification', source, '✅ Teletransportado', 'success')
end, false)

-- /revive - Revivir jugador
RegisterCommand('revive', function(source, args)
    if not AIT.Admin.HasLevel(source, 'helper') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1]) or source
    TriggerClientEvent('ait:client:revive', targetId)
    TriggerClientEvent('ait:client:notification', targetId, '💚 Has sido revivido', 'success')

    if targetId ~= source then
        TriggerClientEvent('ait:client:notification', source, '✅ Jugador revivido', 'success')
    end

    AIT.Admin.Log(source, 'revive', 'Revivió a ID ' .. targetId)
end, false)

-- /heal - Curar jugador
RegisterCommand('heal', function(source, args)
    if not AIT.Admin.HasLevel(source, 'helper') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1]) or source
    TriggerClientEvent('ait:client:heal', targetId)
    TriggerClientEvent('ait:client:notification', targetId, '💚 Has sido curado', 'success')

    if targetId ~= source then
        TriggerClientEvent('ait:client:notification', source, '✅ Jugador curado', 'success')
    end
end, false)

-- /noclip - Modo noclip
RegisterCommand('noclip', function(source)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:toggleNoclip', source)
end, false)

-- /freeze - Congelar jugador
RegisterCommand('freeze', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /freeze [id]', 'error')
        return
    end

    TriggerClientEvent('ait:client:freeze', targetId, true)
    TriggerClientEvent('ait:client:notification', targetId, '🥶 Has sido congelado por un admin', 'warning')
    TriggerClientEvent('ait:client:notification', source, '✅ Jugador congelado', 'success')
end, false)

-- /unfreeze - Descongelar jugador
RegisterCommand('unfreeze', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /unfreeze [id]', 'error')
        return
    end

    TriggerClientEvent('ait:client:freeze', targetId, false)
    TriggerClientEvent('ait:client:notification', targetId, '✅ Has sido descongelado', 'success')
    TriggerClientEvent('ait:client:notification', source, '✅ Jugador descongelado', 'success')
end, false)

-- /setadmin - Establecer nivel de admin
RegisterCommand('setadmin', function(source, args)
    if not AIT.Admin.HasLevel(source, 'owner') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local targetId = tonumber(args[1])
    local level = tonumber(args[2]) or 0

    if not targetId then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /setadmin [id] [nivel 0-5]', 'error')
        return
    end

    local player = AIT.Server and AIT.Server.GetPlayer(targetId)
    if player then
        AIT.Admin.SetLevel(player.identifier, level)
        TriggerClientEvent('ait:client:notification', source, '✅ Nivel de admin establecido: ' .. level, 'success')
        TriggerClientEvent('ait:client:notification', targetId, '⭐ Tu nivel de admin ha sido cambiado a: ' .. level, 'info')
        AIT.Admin.Log(source, 'setadmin', 'Estableció nivel ' .. level .. ' a ' .. player.name)
    end
end, false)

-- /announce - Anuncio global
RegisterCommand('announce', function(source, args)
    if not AIT.Admin.HasLevel(source, 'moderator') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local message = table.concat(args, ' ')
    if message == '' then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /announce [mensaje]', 'error')
        return
    end

    TriggerClientEvent('ait:client:announcement', -1, message, GetPlayerName(source))
    AIT.Admin.Log(source, 'announce', 'Anunció: ' .. message)
end, false)

-- /car - Spawnear vehículo
RegisterCommand('car', function(source, args)
    if not AIT.Admin.HasLevel(source, 'admin') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local model = args[1]
    if not model then
        TriggerClientEvent('ait:client:notification', source, '❌ Uso: /car [modelo]', 'error')
        return
    end

    TriggerClientEvent('ait:client:spawnVehicle', source, model)
end, false)

-- /dv - Eliminar vehículo
RegisterCommand('dv', function(source)
    if not AIT.Admin.HasLevel(source, 'admin') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    TriggerClientEvent('ait:client:deleteVehicle', source)
end, false)

-- /players - Lista de jugadores
RegisterCommand('players', function(source)
    if not AIT.Admin.HasLevel(source, 'helper') then
        TriggerClientEvent('ait:client:notification', source, '❌ No tienes permisos', 'error')
        return
    end

    local players = {}
    for id, player in pairs(AIT.Players or {}) do
        table.insert(players, {
            id = id,
            name = player.name,
            character = player.character and player.character.name or 'Sin personaje',
            ping = GetPlayerPing(id),
        })
    end

    TriggerClientEvent('ait:client:showPlayerList', source, players)
end, false)

-- ═══════════════════════════════════════════════════════════════
-- LOGGING
-- ═══════════════════════════════════════════════════════════════

function AIT.Admin.Log(source, action, details)
    local adminName = source > 0 and GetPlayerName(source) or 'Console'
    local identifier = 'console'

    if source > 0 then
        local player = AIT.Server and AIT.Server.GetPlayer(source)
        if player then
            identifier = player.identifier
        end
    end

    MySQL.insert([[
        INSERT INTO ait_admin_logs (admin_identifier, admin_name, action, details, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { identifier, adminName, action, details })

    print('^3[AIT-ADMIN]^7 ' .. adminName .. ' -> ' .. action .. ': ' .. details)

    -- Enviar a Discord si está configurado
    if Config and Config.DiscordWebhook and Config.DiscordWebhook.adminLogs then
        -- TODO: Implementar webhook de Discord
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EVENTOS DEL CLIENTE
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:admin:requestData', function()
    local source = source
    if not AIT.Admin.HasLevel(source, 'helper') then return end

    local data = {
        level = AIT.Admin.GetLevel(source),
        players = {},
        stats = {
            totalPlayers = 0,
            onlinePlayers = GetNumPlayerIndices(),
        },
    }

    for id, player in pairs(AIT.Players or {}) do
        table.insert(data.players, {
            id = id,
            name = player.name,
            character = player.character and player.character.name,
            job = player.character and player.character.job and player.character.job.label,
            ping = GetPlayerPing(id),
        })
        data.stats.totalPlayers = data.stats.totalPlayers + 1
    end

    TriggerClientEvent('ait:admin:receiveData', source, data)
end)

-- Inicializar
CreateThread(function()
    Wait(2000)
    AIT.Admin.Init()
end)

-- Registrar como engine
if AIT.Server and AIT.Server.RegisterEngine then
    AIT.Server.RegisterEngine('admin', AIT.Admin)
end
