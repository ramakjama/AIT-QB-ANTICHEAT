--[[
    AIT-QB: Sistema de Administración - Cliente
    Servidor Español - Menú admin y funciones cliente
]]

AIT = AIT or {}
AIT.Admin = {}

local isNoclip = false
local isGodmode = false
local isInvisible = false
local showCoords = false

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE ADMIN
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:admin:teleport', function(coords)
    local ped = PlayerPedId()

    DoScreenFadeOut(250)
    Wait(250)

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)

    DoScreenFadeIn(250)
end)

RegisterNetEvent('ait:client:admin:tpwaypoint', function()
    local waypoint = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypoint) then
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'No hay waypoint', type = 'error' })
        return
    end

    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()

    DoScreenFadeOut(250)
    Wait(250)

    -- Encontrar Z
    local found = false
    local z = 0.0
    for height = 1.0, 1000.0, 25.0 do
        SetEntityCoords(ped, coords.x, coords.y, height)
        Wait(50)
        local groundZ = 0
        local found2, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, height, groundZ, false)
        if found2 then
            z = groundZ
            found = true
            break
        end
    end

    if found then
        SetEntityCoords(ped, coords.x, coords.y, z + 1.0)
    else
        SetEntityCoords(ped, coords.x, coords.y, 200.0)
    end

    DoScreenFadeIn(250)
end)

RegisterNetEvent('ait:client:admin:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Curado', type = 'success' })
end)

RegisterNetEvent('ait:client:admin:revive', function()
    local ped = PlayerPedId()

    -- Revivir
    NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    SetPlayerInvincible(PlayerId(), false)

    TriggerEvent('ait:client:death:revived')
    TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Revivido', type = 'success' })
end)

RegisterNetEvent('ait:client:admin:armor', function()
    local ped = PlayerPedId()
    SetPedArmour(ped, 100)
    TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Armadura al máximo', type = 'success' })
end)

RegisterNetEvent('ait:client:admin:noclip', function()
    isNoclip = not isNoclip
    local ped = PlayerPedId()

    if isNoclip then
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Noclip ACTIVADO', type = 'success' })

        CreateThread(function()
            while isNoclip do
                Wait(0)
                ped = PlayerPedId()

                SetEntityCollision(ped, false, false)
                FreezeEntityPosition(ped, true)
                SetEntityVisible(ped, false, false)

                local speed = 1.0
                if IsControlPressed(0, 21) then -- Shift
                    speed = 5.0
                elseif IsControlPressed(0, 36) then -- Ctrl
                    speed = 0.2
                end

                local heading = GetEntityHeading(ped)
                local coords = GetEntityCoords(ped)

                -- Movimiento
                if IsControlPressed(0, 32) then -- W
                    local newX = coords.x + (-math.sin(math.rad(heading)) * speed)
                    local newY = coords.y + (math.cos(math.rad(heading)) * speed)
                    SetEntityCoords(ped, newX, newY, coords.z)
                end
                if IsControlPressed(0, 33) then -- S
                    local newX = coords.x - (-math.sin(math.rad(heading)) * speed)
                    local newY = coords.y - (math.cos(math.rad(heading)) * speed)
                    SetEntityCoords(ped, newX, newY, coords.z)
                end
                if IsControlPressed(0, 34) then -- A
                    SetEntityHeading(ped, heading + 2.0)
                end
                if IsControlPressed(0, 35) then -- D
                    SetEntityHeading(ped, heading - 2.0)
                end
                if IsControlPressed(0, 44) then -- Q
                    SetEntityCoords(ped, coords.x, coords.y, coords.z + speed)
                end
                if IsControlPressed(0, 38) then -- E
                    SetEntityCoords(ped, coords.x, coords.y, coords.z - speed)
                end
            end

            -- Restaurar
            SetEntityCollision(ped, true, true)
            FreezeEntityPosition(ped, false)
            SetEntityVisible(ped, true, false)
        end)
    else
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Noclip DESACTIVADO', type = 'info' })
    end
end)

RegisterNetEvent('ait:client:admin:godmode', function()
    isGodmode = not isGodmode
    local ped = PlayerPedId()

    SetPlayerInvincible(PlayerId(), isGodmode)

    if isGodmode then
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Modo Dios ACTIVADO', type = 'success' })
    else
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Modo Dios DESACTIVADO', type = 'info' })
    end
end)

RegisterNetEvent('ait:client:admin:invisible', function()
    isInvisible = not isInvisible
    local ped = PlayerPedId()

    SetEntityVisible(ped, not isInvisible, false)

    if isInvisible then
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Invisible ACTIVADO', type = 'success' })
    else
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Invisible DESACTIVADO', type = 'info' })
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- VEHÍCULOS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:admin:spawncar', function(model)
    local hash = GetHashKey(model)

    if not IsModelInCdimage(hash) then
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Modelo no válido', type = 'error' })
        return
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleNumberPlateText(vehicle, 'ADMIN')
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleEngineOn(vehicle, true, true, false)

    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    SetModelAsNoLongerNeeded(hash)

    TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Vehículo spawneado: ' .. model, type = 'success' })
end)

RegisterNetEvent('ait:client:admin:deletevehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        -- Buscar vehículo cercano
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 71)
    end

    if vehicle ~= 0 then
        DeleteVehicle(vehicle)
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Vehículo eliminado', type = 'success' })
    else
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'No hay vehículo cerca', type = 'error' })
    end
end)

RegisterNetEvent('ait:client:admin:fixvehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleFuelLevel(vehicle, 100.0)

        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'Vehículo reparado', type = 'success' })
    else
        TriggerEvent('ox_lib:notify', { title = 'Admin', description = 'No estás en un vehículo', type = 'error' })
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:admin:showPlayers', function(players)
    local options = {}

    for _, player in ipairs(players) do
        table.insert(options, {
            title = '[' .. player.id .. '] ' .. player.name,
            description = 'CID: ' .. player.citizenid .. ' | Job: ' .. player.job,
            icon = 'user',
            onSelect = function()
                -- Opciones del jugador
                local playerOptions = {
                    {
                        title = 'Teleportarse a',
                        icon = 'location-arrow',
                        onSelect = function()
                            ExecuteCommand('tp ' .. player.id)
                        end,
                    },
                    {
                        title = 'Traer',
                        icon = 'user-plus',
                        onSelect = function()
                            ExecuteCommand('bring ' .. player.id)
                        end,
                    },
                    {
                        title = 'Curar',
                        icon = 'heart',
                        onSelect = function()
                            ExecuteCommand('heal ' .. player.id)
                        end,
                    },
                    {
                        title = 'Kick',
                        icon = 'user-slash',
                        onSelect = function()
                            local input = lib.inputDialog('Kick ' .. player.name, {
                                { type = 'input', label = 'Razón' },
                            })
                            if input then
                                ExecuteCommand('kick ' .. player.id .. ' ' .. (input[1] or 'Sin razón'))
                            end
                        end,
                    },
                }

                lib.registerContext({
                    id = 'admin_player_' .. player.id,
                    title = player.name,
                    menu = 'admin_players',
                    options = playerOptions,
                })
                lib.showContext('admin_player_' .. player.id)
            end,
        })
    end

    lib.registerContext({
        id = 'admin_players',
        title = 'Jugadores Online (' .. #players .. ')',
        options = options,
    })
    lib.showContext('admin_players')
end)

RegisterNetEvent('ait:client:admin:showCoords', function()
    showCoords = not showCoords

    if showCoords then
        CreateThread(function()
            while showCoords do
                Wait(0)
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)

                DrawText2D(0.5, 0.02, '~w~X: ~b~' .. string.format('%.2f', coords.x))
                DrawText2D(0.5, 0.05, '~w~Y: ~b~' .. string.format('%.2f', coords.y))
                DrawText2D(0.5, 0.08, '~w~Z: ~b~' .. string.format('%.2f', coords.z))
                DrawText2D(0.5, 0.11, '~w~H: ~b~' .. string.format('%.2f', heading))
            end
        end)
    end
end)

function DrawText2D(x, y, text)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

RegisterNetEvent('ait:client:admin:setTime', function(hour)
    NetworkOverrideClockTime(hour, 0, 0)
end)

RegisterNetEvent('ait:client:admin:setWeather', function(weather)
    SetWeatherTypeNowPersist(weather)
end)

-- ═══════════════════════════════════════════════════════════════
-- MENÚ ADMIN
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:admin:openMenu', function(permLevel)
    local options = {
        {
            title = '👥 Jugadores',
            description = 'Ver lista de jugadores',
            icon = 'users',
            onSelect = function()
                ExecuteCommand('players')
            end,
        },
        {
            title = '🚀 Teleporte',
            description = 'Opciones de teleporte',
            icon = 'location-arrow',
            onSelect = function()
                OpenTeleportMenu()
            end,
        },
        {
            title = '👤 Jugador',
            description = 'Opciones de jugador',
            icon = 'user',
            onSelect = function()
                OpenPlayerMenu()
            end,
        },
        {
            title = '🚗 Vehículos',
            description = 'Spawn y gestión',
            icon = 'car',
            onSelect = function()
                OpenVehicleMenu()
            end,
        },
    }

    if permLevel >= 4 then -- Admin+
        table.insert(options, {
            title = '💰 Economía',
            description = 'Dar dinero/items',
            icon = 'dollar-sign',
            onSelect = function()
                OpenEconomyMenu()
            end,
        })
    end

    if permLevel >= 3 then -- Mod+
        table.insert(options, {
            title = '🌍 Servidor',
            description = 'Clima, tiempo, anuncios',
            icon = 'globe',
            onSelect = function()
                OpenServerMenu()
            end,
        })
    end

    table.insert(options, {
        title = '📍 Coordenadas',
        description = 'Mostrar/ocultar coords',
        icon = 'map-marker',
        onSelect = function()
            ExecuteCommand('coords')
        end,
    })

    lib.registerContext({
        id = 'admin_menu',
        title = '🛡️ Panel de Administración',
        options = options,
    })
    lib.showContext('admin_menu')
end)

function OpenTeleportMenu()
    local options = {
        {
            title = 'TP a Waypoint',
            icon = 'map-pin',
            onSelect = function()
                ExecuteCommand('tpwaypoint')
            end,
        },
        {
            title = 'TP a Jugador',
            icon = 'user',
            onSelect = function()
                local input = lib.inputDialog('Teleportarse', {
                    { type = 'number', label = 'ID del jugador' },
                })
                if input then
                    ExecuteCommand('tp ' .. input[1])
                end
            end,
        },
        {
            title = 'Traer Jugador',
            icon = 'user-plus',
            onSelect = function()
                local input = lib.inputDialog('Traer', {
                    { type = 'number', label = 'ID del jugador' },
                })
                if input then
                    ExecuteCommand('bring ' .. input[1])
                end
            end,
        },
        {
            title = 'TP a Coordenadas',
            icon = 'crosshairs',
            onSelect = function()
                local input = lib.inputDialog('Coordenadas', {
                    { type = 'number', label = 'X' },
                    { type = 'number', label = 'Y' },
                    { type = 'number', label = 'Z' },
                })
                if input then
                    ExecuteCommand('tpcoords ' .. input[1] .. ' ' .. input[2] .. ' ' .. input[3])
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_teleport',
        title = '🚀 Teleporte',
        menu = 'admin_menu',
        options = options,
    })
    lib.showContext('admin_teleport')
end

function OpenPlayerMenu()
    local options = {
        {
            title = 'Noclip',
            description = isNoclip and '🟢 Activado' or '🔴 Desactivado',
            icon = 'ghost',
            onSelect = function()
                ExecuteCommand('noclip')
            end,
        },
        {
            title = 'Modo Dios',
            description = isGodmode and '🟢 Activado' or '🔴 Desactivado',
            icon = 'shield-alt',
            onSelect = function()
                ExecuteCommand('god')
            end,
        },
        {
            title = 'Invisible',
            description = isInvisible and '🟢 Activado' or '🔴 Desactivado',
            icon = 'eye-slash',
            onSelect = function()
                ExecuteCommand('invisible')
            end,
        },
        {
            title = 'Curar',
            icon = 'heart',
            onSelect = function()
                ExecuteCommand('heal')
            end,
        },
        {
            title = 'Armadura',
            icon = 'shield',
            onSelect = function()
                ExecuteCommand('armor')
            end,
        },
    }

    lib.registerContext({
        id = 'admin_player',
        title = '👤 Jugador',
        menu = 'admin_menu',
        options = options,
    })
    lib.showContext('admin_player')
end

function OpenVehicleMenu()
    local options = {
        {
            title = 'Spawnear Vehículo',
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog('Spawn Vehículo', {
                    { type = 'input', label = 'Modelo (ej: adder, zentorno)', placeholder = 'adder' },
                })
                if input and input[1] then
                    ExecuteCommand('car ' .. input[1])
                end
            end,
        },
        {
            title = 'Eliminar Vehículo',
            icon = 'trash',
            onSelect = function()
                ExecuteCommand('dv')
            end,
        },
        {
            title = 'Reparar Vehículo',
            icon = 'wrench',
            onSelect = function()
                ExecuteCommand('fix')
            end,
        },
    }

    lib.registerContext({
        id = 'admin_vehicle',
        title = '🚗 Vehículos',
        menu = 'admin_menu',
        options = options,
    })
    lib.showContext('admin_vehicle')
end

function OpenEconomyMenu()
    local options = {
        {
            title = 'Dar Dinero',
            icon = 'dollar-sign',
            onSelect = function()
                local input = lib.inputDialog('Dar Dinero', {
                    { type = 'number', label = 'ID del jugador' },
                    { type = 'select', label = 'Tipo', options = {
                        { value = 'cash', label = 'Efectivo' },
                        { value = 'bank', label = 'Banco' },
                    }},
                    { type = 'number', label = 'Cantidad' },
                })
                if input then
                    ExecuteCommand('givemoney ' .. input[1] .. ' ' .. input[2] .. ' ' .. input[3])
                end
            end,
        },
        {
            title = 'Dar Item',
            icon = 'box',
            onSelect = function()
                local input = lib.inputDialog('Dar Item', {
                    { type = 'number', label = 'ID del jugador' },
                    { type = 'input', label = 'Nombre del item' },
                    { type = 'number', label = 'Cantidad', default = 1 },
                })
                if input then
                    ExecuteCommand('giveitem ' .. input[1] .. ' ' .. input[2] .. ' ' .. (input[3] or 1))
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_economy',
        title = '💰 Economía',
        menu = 'admin_menu',
        options = options,
    })
    lib.showContext('admin_economy')
end

function OpenServerMenu()
    local options = {
        {
            title = 'Anuncio',
            icon = 'bullhorn',
            onSelect = function()
                local input = lib.inputDialog('Anuncio', {
                    { type = 'textarea', label = 'Mensaje' },
                })
                if input then
                    ExecuteCommand('announce ' .. input[1])
                end
            end,
        },
        {
            title = 'Cambiar Hora',
            icon = 'clock',
            onSelect = function()
                local input = lib.inputDialog('Hora', {
                    { type = 'number', label = 'Hora (0-23)', min = 0, max = 23 },
                })
                if input then
                    ExecuteCommand('tiempo ' .. input[1])
                end
            end,
        },
        {
            title = 'Cambiar Clima',
            icon = 'cloud',
            onSelect = function()
                local input = lib.inputDialog('Clima', {
                    { type = 'select', label = 'Tipo', options = {
                        { value = 'CLEAR', label = 'Despejado' },
                        { value = 'EXTRASUNNY', label = 'Muy Soleado' },
                        { value = 'CLOUDS', label = 'Nubes' },
                        { value = 'OVERCAST', label = 'Nublado' },
                        { value = 'RAIN', label = 'Lluvia' },
                        { value = 'THUNDER', label = 'Tormenta' },
                        { value = 'FOGGY', label = 'Niebla' },
                        { value = 'XMAS', label = 'Navidad' },
                    }},
                })
                if input then
                    ExecuteCommand('clima ' .. input[1])
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_server',
        title = '🌍 Servidor',
        menu = 'admin_menu',
        options = options,
    })
    lib.showContext('admin_server')
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsNoclip', function() return isNoclip end)
exports('IsGodmode', function() return isGodmode end)
exports('IsInvisible', function() return isInvisible end)

return AIT.Admin
