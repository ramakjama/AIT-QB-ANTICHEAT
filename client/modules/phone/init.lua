--[[
    AIT-QB: Sistema de Teléfono
    Cliente - Teléfono con apps completas
    Servidor Español
]]

AIT = AIT or {}
AIT.Phone = {}

local isPhoneOpen = false
local phoneData = {
    contacts = {},
    messages = {},
    calls = {},
    notifications = {},
    apps = {},
    settings = {
        wallpaper = 'default',
        ringtone = 'default',
        volume = 100,
        airplane = false,
        wifi = true,
    },
    bank = {
        balance = 0,
        transactions = {},
    },
    garage = {},
    properties = {},
    job = {},
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Apps disponibles
    apps = {
        { id = 'phone', name = 'Teléfono', icon = 'phone', color = '#22c55e' },
        { id = 'messages', name = 'Mensajes', icon = 'message-square', color = '#3b82f6' },
        { id = 'contacts', name = 'Contactos', icon = 'users', color = '#f97316' },
        { id = 'camera', name = 'Cámara', icon = 'camera', color = '#8b5cf6' },
        { id = 'gallery', name = 'Galería', icon = 'image', color = '#ec4899' },
        { id = 'bank', name = 'Banco', icon = 'landmark', color = '#14b8a6' },
        { id = 'garage', name = 'Garaje', icon = 'car', color = '#ef4444' },
        { id = 'gps', name = 'GPS', icon = 'map-pin', color = '#6366f1' },
        { id = 'twitter', name = 'Twitter', icon = 'twitter', color = '#1da1f2' },
        { id = 'instagram', name = 'Instagram', icon = 'instagram', color = '#e1306c' },
        { id = 'tinder', name = 'Tinder', icon = 'heart', color = '#ff6b6b' },
        { id = 'uber', name = 'Uber', icon = 'car', color = '#000000' },
        { id = 'marketplace', name = 'Marketplace', icon = 'shopping-bag', color = '#f59e0b' },
        { id = 'darkweb', name = 'TOR', icon = 'globe', color = '#7c3aed' },
        { id = 'email', name = 'Email', icon = 'mail', color = '#dc2626' },
        { id = 'notes', name = 'Notas', icon = 'file-text', color = '#fbbf24' },
        { id = 'calculator', name = 'Calculadora', icon = 'calculator', color = '#64748b' },
        { id = 'settings', name = 'Ajustes', icon = 'settings', color = '#475569' },
        { id = 'job', name = 'Trabajo', icon = 'briefcase', color = '#0ea5e9' },
        { id = 'house', name = 'Casa', icon = 'home', color = '#84cc16' },
        { id = '911', name = '911', icon = 'siren', color = '#ef4444' },
        { id = 'crypto', name = 'Crypto', icon = 'bitcoin', color = '#f7931a' },
    },

    -- Servicios de emergencia
    emergencyNumbers = {
        { number = '911', service = 'police', label = 'Policía' },
        { number = '912', service = 'ambulance', label = 'Ambulancia' },
        { number = '913', service = 'mechanic', label = 'Mecánico' },
        { number = '914', service = 'taxi', label = 'Taxi' },
    },

    -- Keybind
    openKey = 'F1',
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Phone.Init()
    -- Keybind para abrir teléfono
    RegisterKeyMapping('phone', 'Abrir Teléfono', 'keyboard', Config.openKey)

    RegisterCommand('phone', function()
        AIT.Phone.Toggle()
    end, false)

    print('[AIT-QB] Sistema de teléfono inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- TOGGLE TELÉFONO
-- ═══════════════════════════════════════════════════════════════

function AIT.Phone.Toggle()
    if isPhoneOpen then
        AIT.Phone.Close()
    else
        AIT.Phone.Open()
    end
end

function AIT.Phone.Open()
    if phoneData.settings.airplane then
        AIT.Notify('Modo avión activado', 'error')
        return
    end

    isPhoneOpen = true

    -- Cargar datos
    TriggerServerEvent('ait:server:phone:getData')

    -- Animación de sacar teléfono
    local ped = PlayerPedId()
    local dict = 'cellphone@'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    -- Prop del teléfono
    local phoneModel = GetHashKey('prop_amb_phone')
    RequestModel(phoneModel)
    while not HasModelLoaded(phoneModel) do Wait(10) end

    local phone = CreateObject(phoneModel, 0, 0, 0, true, true, true)
    AttachEntityToEntity(phone, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    TaskPlayAnim(ped, dict, 'cellphone_text_in', 8.0, -8.0, -1, 50, 0, false, false, false)

    phoneData.phoneProp = phone

    -- Abrir NUI
    SendNUIMessage({
        action = 'openPhone',
        data = {
            apps = Config.apps,
            settings = phoneData.settings,
            time = AIT.Phone.GetTime(),
            battery = math.random(60, 100),
            signal = math.random(3, 5),
            notifications = #phoneData.notifications,
        }
    })

    SetNuiFocus(true, true)
end

function AIT.Phone.Close()
    isPhoneOpen = false

    -- Animación de guardar
    local ped = PlayerPedId()

    if phoneData.phoneProp then
        DeleteObject(phoneData.phoneProp)
        phoneData.phoneProp = nil
    end

    ClearPedTasks(ped)

    -- Cerrar NUI
    SendNUIMessage({ action = 'closePhone' })
    SetNuiFocus(false, false)
end

function AIT.Phone.GetTime()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    return string.format('%02d:%02d', hour, minute)
end

-- ═══════════════════════════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback('closePhone', function(data, cb)
    AIT.Phone.Close()
    cb('ok')
end)

RegisterNUICallback('openApp', function(data, cb)
    local appId = data.app

    if appId == 'phone' then
        AIT.Phone.OpenDialer()
    elseif appId == 'messages' then
        AIT.Phone.OpenMessages()
    elseif appId == 'contacts' then
        AIT.Phone.OpenContacts()
    elseif appId == 'bank' then
        AIT.Phone.OpenBank()
    elseif appId == 'garage' then
        AIT.Phone.OpenGarage()
    elseif appId == 'gps' then
        AIT.Phone.OpenGPS()
    elseif appId == 'twitter' then
        AIT.Phone.OpenTwitter()
    elseif appId == 'marketplace' then
        AIT.Phone.OpenMarketplace()
    elseif appId == 'darkweb' then
        AIT.Phone.OpenDarkweb()
    elseif appId == 'settings' then
        AIT.Phone.OpenSettings()
    elseif appId == 'job' then
        AIT.Phone.OpenJobApp()
    elseif appId == '911' then
        AIT.Phone.Open911()
    elseif appId == 'crypto' then
        AIT.Phone.OpenCrypto()
    elseif appId == 'camera' then
        AIT.Phone.OpenCamera()
    end

    cb('ok')
end)

RegisterNUICallback('makeCall', function(data, cb)
    AIT.Phone.MakeCall(data.number)
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('ait:server:phone:sendMessage', data.to, data.message)
    cb('ok')
end)

RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('ait:server:phone:addContact', data.name, data.number)
    cb('ok')
end)

RegisterNUICallback('bankTransfer', function(data, cb)
    TriggerServerEvent('ait:server:phone:bankTransfer', data.to, data.amount)
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    SetNewWaypoint(data.x, data.y)
    AIT.Notify('GPS marcado', 'info')
    cb('ok')
end)

RegisterNUICallback('postTweet', function(data, cb)
    TriggerServerEvent('ait:server:phone:postTweet', data.message)
    cb('ok')
end)

RegisterNUICallback('updateSetting', function(data, cb)
    phoneData.settings[data.setting] = data.value
    TriggerServerEvent('ait:server:phone:updateSetting', data.setting, data.value)
    cb('ok')
end)

RegisterNUICallback('call911', function(data, cb)
    TriggerServerEvent('ait:server:phone:call911', data.service, data.message)
    AIT.Notify('Llamada de emergencia enviada', 'success')
    cb('ok')
end)

RegisterNUICallback('buyCrypto', function(data, cb)
    TriggerServerEvent('ait:server:phone:buyCrypto', data.coin, data.amount)
    cb('ok')
end)

RegisterNUICallback('sellCrypto', function(data, cb)
    TriggerServerEvent('ait:server:phone:sellCrypto', data.coin, data.amount)
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- APPS
-- ═══════════════════════════════════════════════════════════════

function AIT.Phone.OpenDialer()
    SendNUIMessage({
        action = 'showDialer',
        data = {
            recent = phoneData.calls,
        }
    })
end

function AIT.Phone.MakeCall(number)
    -- Verificar si es emergencia
    for _, emergency in ipairs(Config.emergencyNumbers) do
        if emergency.number == number then
            TriggerServerEvent('ait:server:phone:emergencyCall', emergency.service)
            AIT.Notify('Llamando a ' .. emergency.label .. '...', 'info')
            return
        end
    end

    -- Llamada normal
    TriggerServerEvent('ait:server:phone:makeCall', number)
end

function AIT.Phone.OpenMessages()
    TriggerServerEvent('ait:server:phone:getMessages')
end

RegisterNetEvent('ait:client:phone:showMessages', function(messages)
    phoneData.messages = messages
    SendNUIMessage({
        action = 'showMessages',
        data = {
            conversations = messages,
        }
    })
end)

function AIT.Phone.OpenContacts()
    TriggerServerEvent('ait:server:phone:getContacts')
end

RegisterNetEvent('ait:client:phone:showContacts', function(contacts)
    phoneData.contacts = contacts
    SendNUIMessage({
        action = 'showContacts',
        data = {
            contacts = contacts,
        }
    })
end)

function AIT.Phone.OpenBank()
    TriggerServerEvent('ait:server:phone:getBankData')
end

RegisterNetEvent('ait:client:phone:showBank', function(bankData)
    phoneData.bank = bankData
    SendNUIMessage({
        action = 'showBank',
        data = bankData,
    })
end)

function AIT.Phone.OpenGarage()
    TriggerServerEvent('ait:server:phone:getGarage')
end

RegisterNetEvent('ait:client:phone:showGarage', function(vehicles)
    phoneData.garage = vehicles
    SendNUIMessage({
        action = 'showGarage',
        data = {
            vehicles = vehicles,
        }
    })
end)

function AIT.Phone.OpenGPS()
    local locations = {
        { name = 'Hospital Central', coords = { x = 340.0, y = -583.0 }, icon = 'hospital' },
        { name = 'Comisaría LSPD', coords = { x = 428.0, y = -984.0 }, icon = 'police' },
        { name = 'Banco Fleeca (Centro)', coords = { x = 149.0, y = -1042.0 }, icon = 'bank' },
        { name = 'Pacific Standard', coords = { x = 235.0, y = 216.0 }, icon = 'bank' },
        { name = 'Ayuntamiento', coords = { x = -544.0, y = -204.0 }, icon = 'building' },
        { name = 'Aeropuerto', coords = { x = -1037.0, y = -2737.0 }, icon = 'plane' },
        { name = 'Concesionario PDM', coords = { x = -56.0, y = -1096.0 }, icon = 'car' },
        { name = 'Taller LS Customs', coords = { x = -337.0, y = -137.0 }, icon = 'wrench' },
        { name = 'Tienda 24/7 Centro', coords = { x = 25.0, y = -1346.0 }, icon = 'store' },
        { name = 'Gasolinera Centro', coords = { x = 265.0, y = -1261.0 }, icon = 'gas' },
        { name = 'Ammunation', coords = { x = 22.0, y = -1107.0 }, icon = 'gun' },
        { name = 'Joyería Vangelico', coords = { x = -630.0, y = -236.0 }, icon = 'gem' },
        { name = 'Casino Diamond', coords = { x = 924.0, y = 47.0 }, icon = 'dice' },
        { name = 'Puerto de LS', coords = { x = -280.0, y = -2750.0 }, icon = 'ship' },
    }

    SendNUIMessage({
        action = 'showGPS',
        data = {
            locations = locations,
            playerCoords = GetEntityCoords(PlayerPedId()),
        }
    })
end

function AIT.Phone.OpenTwitter()
    TriggerServerEvent('ait:server:phone:getTweets')
end

RegisterNetEvent('ait:client:phone:showTweets', function(tweets)
    SendNUIMessage({
        action = 'showTwitter',
        data = {
            tweets = tweets,
        }
    })
end)

function AIT.Phone.OpenMarketplace()
    TriggerServerEvent('ait:server:phone:getMarketplace')
end

RegisterNetEvent('ait:client:phone:showMarketplace', function(listings)
    SendNUIMessage({
        action = 'showMarketplace',
        data = {
            listings = listings,
        }
    })
end)

function AIT.Phone.OpenDarkweb()
    -- Solo disponible con item especial
    TriggerServerEvent('ait:server:phone:checkDarkwebAccess')
end

RegisterNetEvent('ait:client:phone:showDarkweb', function(hasAccess, listings)
    if not hasAccess then
        AIT.Notify('Necesitas un USB especial para acceder', 'error')
        return
    end

    SendNUIMessage({
        action = 'showDarkweb',
        data = {
            listings = listings,
        }
    })
end)

function AIT.Phone.OpenSettings()
    SendNUIMessage({
        action = 'showSettings',
        data = phoneData.settings,
    })
end

function AIT.Phone.OpenJobApp()
    local playerData = exports['ait-qb']:GetPlayerData()

    SendNUIMessage({
        action = 'showJobApp',
        data = {
            job = playerData.job,
            onDuty = playerData.job.onduty,
        }
    })
end

function AIT.Phone.Open911()
    local coords = GetEntityCoords(PlayerPedId())
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))

    SendNUIMessage({
        action = 'show911',
        data = {
            location = street,
            coords = coords,
        }
    })
end

function AIT.Phone.OpenCrypto()
    TriggerServerEvent('ait:server:phone:getCrypto')
end

RegisterNetEvent('ait:client:phone:showCrypto', function(cryptoData)
    SendNUIMessage({
        action = 'showCrypto',
        data = cryptoData,
    })
end)

function AIT.Phone.OpenCamera()
    AIT.Phone.Close()

    -- Activar modo cámara
    CreateThread(function()
        local scaleform = RequestScaleformMovie('CELLPHONE_CAMERA_SELFIE')
        while not HasScaleformMovieLoaded(scaleform) do Wait(10) end

        local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        local ped = PlayerPedId()

        SetCamActive(cam, true)
        RenderScriptCams(true, true, 500, true, true)

        AIT.Notify('Presiona E para tomar foto, ESC para salir', 'info')

        while true do
            Wait(0)

            -- Controles de cámara
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)

            local pedCoords = GetEntityCoords(ped)
            local camOffset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.6)

            SetCamCoord(cam, camOffset.x, camOffset.y, camOffset.z)
            PointCamAtCoord(cam, pedCoords.x, pedCoords.y, pedCoords.z + 0.5)

            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

            if IsControlJustPressed(0, 38) then -- E
                -- Tomar foto (simulado)
                PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_SoundSet_Default', true)
                AIT.Notify('Foto tomada', 'success')
            end

            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 200) then -- ESC
                break
            end
        end

        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cam, true)
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:phone:notification', function(notif)
    table.insert(phoneData.notifications, notif)

    if isPhoneOpen then
        SendNUIMessage({
            action = 'phoneNotification',
            data = notif,
        })
    else
        -- Sonido de notificación
        PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)

        -- Mostrar en pantalla
        AIT.Notify('📱 ' .. notif.title .. ': ' .. notif.message, 'info')
    end
end)

RegisterNetEvent('ait:client:phone:incomingCall', function(callerName, callerNumber)
    if isPhoneOpen then
        SendNUIMessage({
            action = 'incomingCall',
            data = {
                name = callerName,
                number = callerNumber,
            }
        })
    else
        AIT.Phone.Open()
        Wait(500)
        SendNUIMessage({
            action = 'incomingCall',
            data = {
                name = callerName,
                number = callerNumber,
            }
        })
    end

    -- Sonido de llamada
    PlaySoundFrontend(-1, 'Remote_Ring', 'Phone_SoundSet_Default', true)
end)

RegisterNetEvent('ait:client:phone:newMessage', function(from, message)
    TriggerEvent('ait:client:phone:notification', {
        title = 'Nuevo mensaje',
        message = from .. ': ' .. message,
        app = 'messages',
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- CARGAR DATOS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:phone:loadData', function(data)
    phoneData.contacts = data.contacts or {}
    phoneData.messages = data.messages or {}
    phoneData.calls = data.calls or {}
    phoneData.settings = data.settings or phoneData.settings
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsPhoneOpen', function() return isPhoneOpen end)
exports('OpenPhone', AIT.Phone.Open)
exports('ClosePhone', AIT.Phone.Close)
exports('SendNotification', function(title, message, app)
    TriggerEvent('ait:client:phone:notification', {
        title = title,
        message = message,
        app = app,
    })
end)

-- Inicializar
CreateThread(function()
    Wait(1000)
    AIT.Phone.Init()
end)

return AIT.Phone
