--[[
    AIT-QB: Cliente Principal
    Inicialización y gestión del cliente
    Servidor Español
]]

AIT = AIT or {}
AIT.Client = AIT.Client or {}
AIT.PlayerData = {}
AIT.Ready = false

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(100)
    end

    -- Solicitar datos del jugador
    TriggerServerEvent('ait:server:requestPlayerData')

    -- Esperar datos
    while not AIT.Ready do
        Wait(100)
    end

    -- Inicializar módulos del cliente
    AIT.Client.InitializeModules()

    print('^2[AIT-QB]^7 Cliente inicializado correctamente')
end)

-- Recibir datos del jugador
RegisterNetEvent('ait:client:setPlayerData', function(data)
    AIT.PlayerData = data
    AIT.Ready = true
    TriggerEvent('ait:client:playerLoaded', data)
end)

-- Actualizar datos del jugador
RegisterNetEvent('ait:client:updatePlayerData', function(key, value)
    if key then
        AIT.PlayerData[key] = value
        TriggerEvent('ait:client:playerDataUpdated', key, value)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE MÓDULOS
-- ═══════════════════════════════════════════════════════════════

AIT.Client.Modules = {}

function AIT.Client.RegisterModule(name, module)
    AIT.Client.Modules[name] = module
    print('^3[AIT-QB]^7 Módulo cliente registrado: ' .. name)
end

function AIT.Client.InitializeModules()
    for name, module in pairs(AIT.Client.Modules) do
        if module.Init then
            local success, err = pcall(module.Init)
            if not success then
                print('^1[AIT-QB]^7 Error inicializando módulo ' .. name .. ': ' .. tostring(err))
            end
        end
    end
end

function AIT.Client.GetModule(name)
    return AIT.Client.Modules[name]
end

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES DEL CLIENTE
-- ═══════════════════════════════════════════════════════════════

-- Obtener coordenadas del jugador
function AIT.Client.GetCoords()
    local ped = PlayerPedId()
    return GetEntityCoords(ped)
end

-- Obtener vehículo actual
function AIT.Client.GetCurrentVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end
    return nil
end

-- Verificar si está en un vehículo
function AIT.Client.IsInVehicle()
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

-- Verificar si es conductor
function AIT.Client.IsDriver()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        return GetPedInVehicleSeat(vehicle, -1) == ped
    end
    return false
end

-- Obtener jugadores cercanos
function AIT.Client.GetNearbyPlayers(radius)
    radius = radius or 5.0
    local players = {}
    local myCoords = AIT.Client.GetCoords()
    local myId = PlayerId()

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= myId then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(myCoords - targetCoords)

            if distance <= radius then
                table.insert(players, {
                    id = playerId,
                    serverId = GetPlayerServerId(playerId),
                    ped = targetPed,
                    coords = targetCoords,
                    distance = distance,
                })
            end
        end
    end

    return players
end

-- Obtener jugador más cercano
function AIT.Client.GetClosestPlayer(radius)
    local players = AIT.Client.GetNearbyPlayers(radius)
    local closest = nil
    local closestDist = radius or 5.0

    for _, player in ipairs(players) do
        if player.distance < closestDist then
            closest = player
            closestDist = player.distance
        end
    end

    return closest
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════

function AIT.Client.Notify(message, type, duration)
    type = type or 'info'
    duration = duration or 5000

    -- Usar ox_lib si está disponible
    if GetResourceState('ox_lib') == 'started' then
        lib.notify({
            title = 'AIT-QB',
            description = message,
            type = type,
            duration = duration,
        })
    else
        -- Notificación nativa de GTA
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end

    -- Evento para UI personalizada
    TriggerEvent('ait:client:notification', message, type, duration)
end

-- Tipos de notificación específicos
function AIT.Client.NotifySuccess(message, duration)
    AIT.Client.Notify(message, 'success', duration)
end

function AIT.Client.NotifyError(message, duration)
    AIT.Client.Notify(message, 'error', duration)
end

function AIT.Client.NotifyWarning(message, duration)
    AIT.Client.Notify(message, 'warning', duration)
end

function AIT.Client.NotifyInfo(message, duration)
    AIT.Client.Notify(message, 'info', duration)
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE PROGRESO
-- ═══════════════════════════════════════════════════════════════

function AIT.Client.ProgressBar(options)
    options = options or {}
    local duration = options.duration or 5000
    local label = options.label or 'Procesando...'
    local canCancel = options.canCancel ~= false
    local anim = options.anim
    local prop = options.prop
    local disableControls = options.disableControls or {}

    -- Usar ox_lib si está disponible
    if GetResourceState('ox_lib') == 'started' then
        return lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = canCancel,
            disable = {
                car = disableControls.car or false,
                move = disableControls.move or true,
                combat = disableControls.combat or true,
            },
            anim = anim and {
                dict = anim.dict,
                clip = anim.clip,
            } or nil,
            prop = prop and {
                model = prop.model,
                bone = prop.bone,
                pos = prop.pos,
                rot = prop.rot,
            } or nil,
        })
    else
        -- Fallback simple
        local cancelled = false
        local startTime = GetGameTimer()

        CreateThread(function()
            while GetGameTimer() - startTime < duration do
                if canCancel and IsControlJustPressed(0, 200) then -- ESC
                    cancelled = true
                    break
                end

                -- Mostrar texto de progreso
                local progress = (GetGameTimer() - startTime) / duration * 100
                AIT.Client.DrawText3D(AIT.Client.GetCoords(), label .. ' (' .. math.floor(progress) .. '%)')

                -- Deshabilitar controles si es necesario
                if disableControls.move then
                    DisableControlAction(0, 30, true) -- MoveLeftRight
                    DisableControlAction(0, 31, true) -- MoveUpDown
                end

                Wait(0)
            end
        end)

        Wait(duration)
        return not cancelled
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE MENÚS
-- ═══════════════════════════════════════════════════════════════

function AIT.Client.OpenMenu(options)
    options = options or {}

    -- Usar ox_lib si está disponible
    if GetResourceState('ox_lib') == 'started' then
        lib.registerContext({
            id = options.id or 'ait_menu',
            title = options.title or 'Menú',
            options = options.options or {},
        })
        lib.showContext(options.id or 'ait_menu')
    else
        -- Enviar a NUI
        SendNUIMessage({
            action = 'openMenu',
            data = options,
        })
        SetNuiFocus(true, true)
    end
end

function AIT.Client.CloseMenu()
    if GetResourceState('ox_lib') == 'started' then
        lib.hideContext()
    else
        SendNUIMessage({ action = 'closeMenu' })
        SetNuiFocus(false, false)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE INPUT
-- ═══════════════════════════════════════════════════════════════

function AIT.Client.TextInput(options)
    options = options or {}
    local header = options.header or 'Entrada'
    local placeholder = options.placeholder or ''
    local maxLength = options.maxLength or 50

    -- Usar ox_lib si está disponible
    if GetResourceState('ox_lib') == 'started' then
        local input = lib.inputDialog(header, {
            {
                type = 'input',
                label = options.label or 'Texto',
                placeholder = placeholder,
                max = maxLength,
            },
        })
        return input and input[1] or nil
    else
        -- Usar input nativo
        AddTextEntry('AIT_INPUT', header)
        DisplayOnscreenKeyboard(true, 'AIT_INPUT', '', placeholder, '', '', '', maxLength)

        while UpdateOnscreenKeyboard() == 0 do
            Wait(0)
        end

        if GetOnscreenKeyboardResult() then
            return GetOnscreenKeyboardResult()
        end
        return nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES DE RENDERIZADO
-- ═══════════════════════════════════════════════════════════════

function AIT.Client.DrawText3D(coords, text, scale, font)
    scale = scale or 0.35
    font = font or 4

    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function AIT.Client.DrawMarker(options)
    local type = options.type or 1
    local coords = options.coords
    local scale = options.scale or vector3(1.0, 1.0, 1.0)
    local color = options.color or { r = 255, g = 255, b = 255, a = 100 }
    local rotate = options.rotate or false
    local bobUpAndDown = options.bobUpAndDown or false

    DrawMarker(
        type,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        scale.x, scale.y, scale.z,
        color.r, color.g, color.b, color.a,
        bobUpAndDown, false, 2, rotate, nil, nil, false
    )
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE CALLBACKS
-- ═══════════════════════════════════════════════════════════════

AIT.Client.Callbacks = {}
AIT.Client.CallbackId = 0

function AIT.Client.TriggerCallback(name, cb, ...)
    AIT.Client.CallbackId = AIT.Client.CallbackId + 1
    local id = AIT.Client.CallbackId
    AIT.Client.Callbacks[id] = cb
    TriggerServerEvent('ait:server:triggerCallback', name, id, ...)
end

RegisterNetEvent('ait:client:callbackResponse', function(id, ...)
    if AIT.Client.Callbacks[id] then
        AIT.Client.Callbacks[id](...)
        AIT.Client.Callbacks[id] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENTOS COMUNES
-- ═══════════════════════════════════════════════════════════════

-- Muerte del jugador
AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        local attacker = data[2]
        local isDead = data[4]

        if victim == PlayerPedId() and isDead then
            TriggerEvent('ait:client:playerDied', attacker)
            TriggerServerEvent('ait:server:playerDied', GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker)))
        end
    end
end)

-- Entrada/salida de vehículo
CreateThread(function()
    local wasInVehicle = false
    local lastVehicle = nil

    while true do
        local inVehicle = AIT.Client.IsInVehicle()
        local currentVehicle = AIT.Client.GetCurrentVehicle()

        if inVehicle and not wasInVehicle then
            -- Entró a un vehículo
            lastVehicle = currentVehicle
            TriggerEvent('ait:client:enteredVehicle', currentVehicle, GetEntityModel(currentVehicle))
            TriggerServerEvent('ait:server:playerEnteredVehicle', NetworkGetNetworkIdFromEntity(currentVehicle))
        elseif not inVehicle and wasInVehicle then
            -- Salió del vehículo
            TriggerEvent('ait:client:exitedVehicle', lastVehicle)
            TriggerServerEvent('ait:server:playerExitedVehicle', lastVehicle and NetworkGetNetworkIdFromEntity(lastVehicle) or 0)
            lastVehicle = nil
        end

        wasInVehicle = inVehicle
        Wait(500)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- COMANDOS DEL CLIENTE
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('coords', function()
    local coords = AIT.Client.GetCoords()
    local heading = GetEntityHeading(PlayerPedId())
    local str = string.format('vector4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, heading)
    print(str)
    AIT.Client.Notify('Coordenadas copiadas a consola', 'info')
end, false)

RegisterCommand('ait_debug', function()
    AIT.Debug = not AIT.Debug
    AIT.Client.Notify('Debug: ' .. (AIT.Debug and 'Activado' or 'Desactivado'), 'info')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('menuSelect', function(data, cb)
    if data.event then
        TriggerEvent(data.event, data.args)
    end
    if data.serverEvent then
        TriggerServerEvent(data.serverEvent, data.args)
    end
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('GetPlayerData', function()
    return AIT.PlayerData
end)

exports('IsReady', function()
    return AIT.Ready
end)

exports('Notify', function(message, type, duration)
    AIT.Client.Notify(message, type, duration)
end)

exports('ProgressBar', function(options)
    return AIT.Client.ProgressBar(options)
end)

exports('GetCoords', function()
    return AIT.Client.GetCoords()
end)

exports('GetClosestPlayer', function(radius)
    return AIT.Client.GetClosestPlayer(radius)
end)

exports('TriggerCallback', function(name, cb, ...)
    AIT.Client.TriggerCallback(name, cb, ...)
end)
