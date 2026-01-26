--[[
    AIT-QB: Sistema de Propiedades/Housing
    Cliente - Compra, venta, alquiler y gestión de propiedades
    Servidor Español
]]

AIT = AIT or {}
AIT.Housing = {}

local currentProperty = nil
local isInProperty = false
local ownedProperties = {}
local propertyBlips = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Agencia inmobiliaria
    realtor = {
        coords = vector3(-706.0, 260.0, 83.0),
        blip = { sprite = 374, color = 2, scale = 0.8 },
    },

    -- Tipos de propiedades
    propertyTypes = {
        apartment_low = {
            name = 'Apartamento Económico',
            interior = 'v_res_tre_apartment',
            storage = 50,
            garage = 1,
            priceRange = { 50000, 150000 },
        },
        apartment_mid = {
            name = 'Apartamento Medio',
            interior = 'v_res_msonoffice',
            storage = 100,
            garage = 2,
            priceRange = { 150000, 400000 },
        },
        apartment_high = {
            name = 'Apartamento de Lujo',
            interior = 'v_res_tre_intmain',
            storage = 200,
            garage = 3,
            priceRange = { 400000, 1000000 },
        },
        house_small = {
            name = 'Casa Pequeña',
            interior = 'v_res_old_house24_0',
            storage = 150,
            garage = 2,
            priceRange = { 200000, 500000 },
        },
        house_medium = {
            name = 'Casa Mediana',
            interior = 'v_res_m_h_hallways',
            storage = 250,
            garage = 3,
            priceRange = { 500000, 1000000 },
        },
        house_large = {
            name = 'Casa Grande',
            interior = 'v_res_gt_house',
            storage = 400,
            garage = 4,
            priceRange = { 1000000, 2500000 },
        },
        mansion = {
            name = 'Mansión',
            interior = 'v_res_mdstudio',
            storage = 500,
            garage = 6,
            priceRange = { 2500000, 10000000 },
        },
    },

    -- Propiedades disponibles
    properties = {
        -- Apartamentos económicos
        { id = 1, type = 'apartment_low', name = 'Apartamento 1A', coords = vector3(-271.0, -939.0, 92.5), price = 75000 },
        { id = 2, type = 'apartment_low', name = 'Apartamento 2B', coords = vector3(-271.0, -939.0, 92.5), price = 80000 },
        { id = 3, type = 'apartment_low', name = 'Apartamento 3C', coords = vector3(-271.0, -939.0, 92.5), price = 85000 },

        -- Apartamentos medios
        { id = 4, type = 'apartment_mid', name = 'Suite Del Perro 12', coords = vector3(-1461.0, -542.0, 73.0), price = 250000 },
        { id = 5, type = 'apartment_mid', name = 'Suite Del Perro 24', coords = vector3(-1461.0, -542.0, 73.0), price = 280000 },

        -- Apartamentos de lujo
        { id = 6, type = 'apartment_high', name = 'Eclipse Towers A1', coords = vector3(-773.0, 312.0, 212.0), price = 750000 },
        { id = 7, type = 'apartment_high', name = 'Eclipse Towers A2', coords = vector3(-773.0, 312.0, 212.0), price = 800000 },
        { id = 8, type = 'apartment_high', name = 'Eclipse Towers Penthouse', coords = vector3(-773.0, 312.0, 212.0), price = 1500000 },

        -- Casas pequeñas
        { id = 9, type = 'house_small', name = 'Casa Grove Street', coords = vector3(-14.0, -1441.0, 31.0), price = 300000 },
        { id = 10, type = 'house_small', name = 'Casa Strawberry', coords = vector3(260.0, -1000.0, 29.0), price = 280000 },

        -- Casas medianas
        { id = 11, type = 'house_medium', name = 'Casa Vinewood Hills', coords = vector3(-175.0, 497.0, 137.0), price = 650000 },
        { id = 12, type = 'house_medium', name = 'Casa Rockford Hills', coords = vector3(-852.0, 154.0, 65.0), price = 700000 },

        -- Casas grandes
        { id = 13, type = 'house_large', name = 'Mansión Vinewood', coords = vector3(-1543.0, 116.0, 56.0), price = 1800000 },
        { id = 14, type = 'house_large', name = 'Casa Richman', coords = vector3(-1527.0, 127.0, 56.0), price = 2000000 },

        -- Mansiones
        { id = 15, type = 'mansion', name = 'Mansión Playboy', coords = vector3(-1524.0, -45.0, 56.0), price = 5000000 },
        { id = 16, type = 'mansion', name = 'Mansión de Madrazo', coords = vector3(1408.0, 1118.0, 115.0), price = 8000000 },
    },

    -- Muebles disponibles
    furniture = {
        -- Sofás
        { id = 'sofa_1', name = 'Sofá Moderno', price = 5000, category = 'sofas' },
        { id = 'sofa_2', name = 'Sofá de Cuero', price = 8000, category = 'sofas' },
        { id = 'sofa_3', name = 'Sofá Esquinero', price = 12000, category = 'sofas' },

        -- Mesas
        { id = 'table_1', name = 'Mesa de Centro', price = 2000, category = 'tables' },
        { id = 'table_2', name = 'Mesa de Comedor', price = 5000, category = 'tables' },
        { id = 'desk_1', name = 'Escritorio', price = 3000, category = 'tables' },

        -- Camas
        { id = 'bed_1', name = 'Cama Individual', price = 3000, category = 'beds' },
        { id = 'bed_2', name = 'Cama Doble', price = 6000, category = 'beds' },
        { id = 'bed_3', name = 'Cama King Size', price = 10000, category = 'beds' },

        -- Almacenamiento
        { id = 'wardrobe_1', name = 'Armario', price = 4000, category = 'storage' },
        { id = 'shelf_1', name = 'Estantería', price = 1500, category = 'storage' },
        { id = 'safe_1', name = 'Caja Fuerte', price = 25000, category = 'storage' },

        -- Decoración
        { id = 'tv_1', name = 'TV 50"', price = 5000, category = 'decor' },
        { id = 'tv_2', name = 'TV 70"', price = 15000, category = 'decor' },
        { id = 'lamp_1', name = 'Lámpara de Pie', price = 1000, category = 'decor' },
        { id = 'plant_1', name = 'Planta', price = 500, category = 'decor' },
        { id = 'painting_1', name = 'Cuadro', price = 2000, category = 'decor' },
    },

    -- Mejoras de propiedad
    upgrades = {
        { id = 'security_basic', name = 'Alarma Básica', price = 10000, effect = 'security', level = 1 },
        { id = 'security_advanced', name = 'Sistema de Seguridad', price = 50000, effect = 'security', level = 2 },
        { id = 'security_full', name = 'Seguridad Total + CCTV', price = 150000, effect = 'security', level = 3 },
        { id = 'storage_upgrade', name = 'Ampliación de Almacén', price = 25000, effect = 'storage', bonus = 100 },
        { id = 'garage_upgrade', name = 'Plaza de Garaje Extra', price = 75000, effect = 'garage', bonus = 1 },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.Init()
    -- Blip de la inmobiliaria
    local blip = AddBlipForCoord(Config.realtor.coords.x, Config.realtor.coords.y, Config.realtor.coords.z)
    SetBlipSprite(blip, Config.realtor.blip.sprite)
    SetBlipColour(blip, Config.realtor.blip.color)
    SetBlipScale(blip, Config.realtor.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Inmobiliaria')
    EndTextCommandSetBlipName(blip)

    -- Crear zonas de entrada para propiedades del jugador
    TriggerServerEvent('ait:server:housing:getOwnedProperties')

    print('[AIT-QB] Sistema de propiedades inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- MENÚ INMOBILIARIA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:housing:openRealtor', function()
    local options = {
        {
            title = 'Ver Propiedades en Venta',
            description = 'Explora las propiedades disponibles',
            icon = 'house',
            onSelect = function()
                AIT.Housing.OpenPropertiesForSale()
            end,
        },
        {
            title = 'Mis Propiedades',
            description = 'Gestionar tus propiedades',
            icon = 'key',
            onSelect = function()
                AIT.Housing.OpenMyProperties()
            end,
        },
        {
            title = 'Vender Propiedad',
            description = 'Poner una propiedad en venta',
            icon = 'dollar-sign',
            onSelect = function()
                AIT.Housing.OpenSellProperty()
            end,
        },
        {
            title = 'Alquileres',
            description = 'Ver propiedades en alquiler',
            icon = 'file-contract',
            onSelect = function()
                AIT.Housing.OpenRentals()
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'realtor_menu',
            title = 'Inmobiliaria Dynasty 8',
            options = options,
        })
        lib.showContext('realtor_menu')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PROPIEDADES EN VENTA
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.OpenPropertiesForSale()
    TriggerServerEvent('ait:server:housing:getAvailableProperties')
end

RegisterNetEvent('ait:client:housing:showAvailableProperties', function(available)
    local options = {}

    -- Filtrar por tipo
    local types = {}
    for _, prop in ipairs(available) do
        if not types[prop.type] then
            types[prop.type] = {}
        end
        table.insert(types[prop.type], prop)
    end

    for typeName, props in pairs(types) do
        local typeData = Config.propertyTypes[typeName]

        table.insert(options, {
            title = typeData.name .. ' (' .. #props .. ' disponibles)',
            description = 'Garaje: ' .. typeData.garage .. ' | Almacén: ' .. typeData.storage,
            icon = 'building',
            onSelect = function()
                AIT.Housing.ShowPropertiesByType(typeName, props)
            end,
        })
    end

    if #options == 0 then
        AIT.Notify('No hay propiedades disponibles', 'info')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'properties_for_sale',
            title = 'Propiedades en Venta',
            menu = 'realtor_menu',
            options = options,
        })
        lib.showContext('properties_for_sale')
    end
end)

function AIT.Housing.ShowPropertiesByType(typeName, properties)
    local options = {}

    for _, prop in ipairs(properties) do
        table.insert(options, {
            title = prop.name,
            description = 'Precio: $' .. prop.price,
            icon = 'house',
            onSelect = function()
                AIT.Housing.ViewProperty(prop)
            end,
            metadata = {
                { label = 'Tipo', value = Config.propertyTypes[prop.type].name },
                { label = 'Garaje', value = Config.propertyTypes[prop.type].garage .. ' plazas' },
                { label = 'Almacén', value = Config.propertyTypes[prop.type].storage .. ' slots' },
            }
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'properties_type_' .. typeName,
            title = Config.propertyTypes[typeName].name,
            menu = 'properties_for_sale',
            options = options,
        })
        lib.showContext('properties_type_' .. typeName)
    end
end

function AIT.Housing.ViewProperty(property)
    local options = {
        {
            title = 'Ver Ubicación',
            description = 'Marcar en el GPS',
            icon = 'map-marker',
            onSelect = function()
                SetNewWaypoint(property.coords.x, property.coords.y)
                AIT.Notify('Ubicación marcada en el GPS', 'info')
            end,
        },
        {
            title = 'Visitar Interior',
            description = 'Ver el interior de la propiedad',
            icon = 'door-open',
            onSelect = function()
                AIT.Housing.VisitProperty(property)
            end,
        },
        {
            title = 'Comprar - $' .. property.price,
            description = 'Adquirir esta propiedad',
            icon = 'shopping-cart',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:buyProperty', property.id)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'property_view_' .. property.id,
            title = property.name,
            options = options,
        })
        lib.showContext('property_view_' .. property.id)
    end
end

function AIT.Housing.VisitProperty(property)
    local typeData = Config.propertyTypes[property.type]

    -- Teleportar al interior (simplificado)
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(500)

    -- Interior genérico
    SetEntityCoords(ped, -786.8663, 315.7642, 217.6385)

    DoScreenFadeIn(500)

    AIT.Notify('Visitando: ' .. property.name .. '. Presiona G para salir.', 'info')

    -- Thread para salir
    CreateThread(function()
        while true do
            Wait(0)
            if IsControlJustPressed(0, 47) then -- G
                DoScreenFadeOut(500)
                Wait(500)
                SetEntityCoords(ped, property.coords.x, property.coords.y, property.coords.z)
                DoScreenFadeIn(500)
                break
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MIS PROPIEDADES
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.OpenMyProperties()
    TriggerServerEvent('ait:server:housing:getOwnedProperties')
end

RegisterNetEvent('ait:client:housing:showOwnedProperties', function(properties)
    ownedProperties = properties

    if #properties == 0 then
        AIT.Notify('No tienes propiedades', 'info')
        return
    end

    local options = {}

    for _, prop in ipairs(properties) do
        local typeData = Config.propertyTypes[prop.type]

        table.insert(options, {
            title = prop.name,
            description = typeData.name,
            icon = 'home',
            onSelect = function()
                AIT.Housing.OpenPropertyManagement(prop)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'my_properties',
            title = 'Mis Propiedades',
            menu = 'realtor_menu',
            options = options,
        })
        lib.showContext('my_properties')
    end
end)

function AIT.Housing.OpenPropertyManagement(property)
    local typeData = Config.propertyTypes[property.type]

    local options = {
        {
            title = 'Entrar',
            description = 'Ir a tu propiedad',
            icon = 'door-open',
            onSelect = function()
                AIT.Housing.EnterProperty(property)
            end,
        },
        {
            title = 'Almacén',
            description = 'Acceder a tu stash',
            icon = 'box',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:openStash', property.id)
            end,
        },
        {
            title = 'Garaje',
            description = typeData.garage .. ' plazas disponibles',
            icon = 'car',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:openGarage', property.id)
            end,
        },
        {
            title = 'Gestionar Llaves',
            description = 'Dar/quitar acceso a otros',
            icon = 'key',
            onSelect = function()
                AIT.Housing.ManageKeys(property)
            end,
        },
        {
            title = 'Decorar',
            description = 'Comprar y colocar muebles',
            icon = 'couch',
            onSelect = function()
                AIT.Housing.OpenFurnitureShop(property)
            end,
        },
        {
            title = 'Mejoras',
            description = 'Mejorar tu propiedad',
            icon = 'arrow-up',
            onSelect = function()
                AIT.Housing.OpenUpgrades(property)
            end,
        },
        {
            title = 'Poner en Venta',
            description = 'Vender esta propiedad',
            icon = 'dollar-sign',
            onSelect = function()
                AIT.Housing.SellPropertyPrompt(property)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'manage_property_' .. property.id,
            title = property.name,
            menu = 'my_properties',
            options = options,
        })
        lib.showContext('manage_property_' .. property.id)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ENTRADA/SALIDA DE PROPIEDADES
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.EnterProperty(property)
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(500)

    -- Interior (simplificado - en producción usarías interiores reales)
    SetEntityCoords(ped, -786.8663, 315.7642, 217.6385)
    isInProperty = true
    currentProperty = property

    DoScreenFadeIn(500)

    AIT.Notify('Bienvenido a ' .. property.name, 'success')

    -- HUD de propiedad
    SendNUIMessage({
        action = 'showPropertyHUD',
        data = {
            name = property.name,
        }
    })
end

function AIT.Housing.ExitProperty()
    if not isInProperty or not currentProperty then return end

    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(500)

    -- Volver a la entrada
    local prop = nil
    for _, p in ipairs(Config.properties) do
        if p.id == currentProperty.id then
            prop = p
            break
        end
    end

    if prop then
        SetEntityCoords(ped, prop.coords.x, prop.coords.y, prop.coords.z)
    end

    isInProperty = false
    currentProperty = nil

    DoScreenFadeIn(500)

    SendNUIMessage({ action = 'hidePropertyHUD' })
end

-- Keybind para salir
RegisterCommand('salipropiedad', function()
    AIT.Housing.ExitProperty()
end, false)

RegisterKeyMapping('salipropiedad', 'Salir de Propiedad', 'keyboard', 'G')

-- ═══════════════════════════════════════════════════════════════
-- GESTIÓN DE LLAVES
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.ManageKeys(property)
    local options = {
        {
            title = 'Dar Llave',
            description = 'Dar acceso a alguien cercano',
            icon = 'plus',
            onSelect = function()
                AIT.Housing.GiveKey(property)
            end,
        },
        {
            title = 'Quitar Llave',
            description = 'Revocar acceso',
            icon = 'minus',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:getKeyHolders', property.id)
            end,
        },
        {
            title = 'Cambiar Cerradura',
            description = 'Quitar todas las llaves ($5,000)',
            icon = 'lock',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:changeLocks', property.id)
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'manage_keys_' .. property.id,
            title = 'Gestionar Llaves',
            menu = 'manage_property_' .. property.id,
            options = options,
        })
        lib.showContext('manage_keys_' .. property.id)
    end
end

function AIT.Housing.GiveKey(property)
    local closestPlayer, closestDist = nil, 5.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(coords - targetCoords)

            if dist < closestDist then
                closestPlayer = GetPlayerServerId(playerId)
                closestDist = dist
            end
        end
    end

    if closestPlayer then
        TriggerServerEvent('ait:server:housing:giveKey', property.id, closestPlayer)
        AIT.Notify('Llave entregada', 'success')
    else
        AIT.Notify('No hay nadie cerca', 'error')
    end
end

RegisterNetEvent('ait:client:housing:showKeyHolders', function(propertyId, keyHolders)
    local options = {}

    for _, holder in ipairs(keyHolders) do
        table.insert(options, {
            title = holder.name,
            description = 'Click para quitar llave',
            icon = 'user',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:removeKey', propertyId, holder.citizenid)
            end,
        })
    end

    if #options == 0 then
        AIT.Notify('Nadie más tiene llaves', 'info')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'key_holders_' .. propertyId,
            title = 'Personas con Llave',
            options = options,
        })
        lib.showContext('key_holders_' .. propertyId)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- TIENDA DE MUEBLES
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.OpenFurnitureShop(property)
    local categories = {
        { id = 'sofas', name = 'Sofás', icon = 'couch' },
        { id = 'tables', name = 'Mesas', icon = 'table' },
        { id = 'beds', name = 'Camas', icon = 'bed' },
        { id = 'storage', name = 'Almacenamiento', icon = 'box' },
        { id = 'decor', name = 'Decoración', icon = 'palette' },
    }

    local options = {}

    for _, cat in ipairs(categories) do
        table.insert(options, {
            title = cat.name,
            icon = cat.icon,
            onSelect = function()
                AIT.Housing.ShowFurnitureCategory(property, cat.id)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'furniture_shop',
            title = 'Tienda de Muebles',
            menu = 'manage_property_' .. property.id,
            options = options,
        })
        lib.showContext('furniture_shop')
    end
end

function AIT.Housing.ShowFurnitureCategory(property, category)
    local options = {}

    for _, item in ipairs(Config.furniture) do
        if item.category == category then
            table.insert(options, {
                title = item.name,
                description = 'Precio: $' .. item.price,
                icon = 'shopping-cart',
                onSelect = function()
                    TriggerServerEvent('ait:server:housing:buyFurniture', property.id, item.id, item.price)
                end,
            })
        end
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'furniture_' .. category,
            title = 'Muebles',
            menu = 'furniture_shop',
            options = options,
        })
        lib.showContext('furniture_' .. category)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MEJORAS
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.OpenUpgrades(property)
    local options = {}

    for _, upgrade in ipairs(Config.upgrades) do
        table.insert(options, {
            title = upgrade.name,
            description = 'Precio: $' .. upgrade.price,
            icon = 'arrow-up',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:buyUpgrade', property.id, upgrade.id, upgrade.price)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'property_upgrades',
            title = 'Mejoras',
            menu = 'manage_property_' .. property.id,
            options = options,
        })
        lib.showContext('property_upgrades')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- VENTA DE PROPIEDAD
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.SellPropertyPrompt(property)
    if lib and lib.inputDialog then
        local input = lib.inputDialog('Vender ' .. property.name, {
            { type = 'number', label = 'Precio de venta', default = property.price, min = 1 },
        })

        if input and input[1] then
            local price = tonumber(input[1])
            TriggerServerEvent('ait:server:housing:listForSale', property.id, price)
        end
    end
end

function AIT.Housing.OpenSellProperty()
    AIT.Housing.OpenMyProperties()
end

function AIT.Housing.OpenRentals()
    TriggerServerEvent('ait:server:housing:getRentals')
end

RegisterNetEvent('ait:client:housing:showRentals', function(rentals)
    local options = {}

    for _, rental in ipairs(rentals) do
        table.insert(options, {
            title = rental.name,
            description = 'Alquiler: $' .. rental.rentPrice .. '/semana',
            icon = 'file-contract',
            onSelect = function()
                TriggerServerEvent('ait:server:housing:rentProperty', rental.id)
            end,
        })
    end

    if #options == 0 then
        AIT.Notify('No hay propiedades en alquiler', 'info')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'rentals_list',
            title = 'Propiedades en Alquiler',
            menu = 'realtor_menu',
            options = options,
        })
        lib.showContext('rentals_list')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- BLIPS DE PROPIEDADES
-- ═══════════════════════════════════════════════════════════════

function AIT.Housing.CreatePropertyBlips()
    -- Limpiar blips anteriores
    for _, blip in ipairs(propertyBlips) do
        RemoveBlip(blip)
    end
    propertyBlips = {}

    -- Crear blips para propiedades del jugador
    for _, prop in ipairs(ownedProperties) do
        local propData = nil
        for _, p in ipairs(Config.properties) do
            if p.id == prop.id then
                propData = p
                break
            end
        end

        if propData then
            local blip = AddBlipForCoord(propData.coords.x, propData.coords.y, propData.coords.z)
            SetBlipSprite(blip, 40)
            SetBlipColour(blip, 2)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(prop.name)
            EndTextCommandSetBlipName(blip)
            table.insert(propertyBlips, blip)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsInProperty', function() return isInProperty end)
exports('GetCurrentProperty', function() return currentProperty end)
exports('GetOwnedProperties', function() return ownedProperties end)

-- Inicializar
CreateThread(function()
    Wait(1000)
    AIT.Housing.Init()
end)

return AIT.Housing
