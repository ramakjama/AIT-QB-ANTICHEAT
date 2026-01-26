--[[
    AIT-QB: Sistema de Personajes
    Creación y selección de personajes
    Servidor Español
]]

AIT = AIT or {}
AIT.Character = {}

local isCreating = false
local isSelecting = false

-- ═══════════════════════════════════════════════════════════════
-- SELECCIÓN DE PERSONAJE
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:characterSelection', function(characters)
    isSelecting = true

    -- Preparar cámara cinemática
    AIT.Character.SetupSelectionCamera()

    -- Enviar datos a NUI
    SendNUIMessage({
        action = 'showCharacterSelection',
        characters = characters
    })

    SetNuiFocus(true, true)
end)

function AIT.Character.SetupSelectionCamera()
    local ped = PlayerPedId()

    -- Posición de la cámara de selección
    local camCoords = vector3(-75.0, -819.0, 326.0)
    local camRot = vector3(-5.0, 0.0, 230.0)

    -- Ocultar HUD
    DisplayHud(false)
    DisplayRadar(false)

    -- Crear cámara
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)

    -- Teleportar al jugador (invisible)
    SetEntityCoords(ped, -75.0, -827.0, 326.0, false, false, false, false)
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
end

-- Callback de NUI - Seleccionar personaje
RegisterNUICallback('selectCharacter', function(data, cb)
    SetNuiFocus(false, false)
    isSelecting = false

    -- Restaurar cámara
    RenderScriptCams(false, true, 1000, true, true)
    DestroyAllCams(true)
    DisplayHud(true)
    DisplayRadar(true)

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    -- Cargar personaje en servidor
    TriggerServerEvent('ait:server:selectCharacter', data.characterId)

    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- CREACIÓN DE PERSONAJE
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:characterCreation', function()
    isCreating = true

    -- Setup para creación
    AIT.Character.SetupCreationScene()

    -- Enviar a NUI
    SendNUIMessage({
        action = 'showCharacterCreation',
        nationalities = {
            'Los Santos', 'San Andreas', 'Liberty City', 'Vice City',
            'España', 'México', 'Colombia', 'Argentina', 'Estados Unidos'
        }
    })

    SetNuiFocus(true, true)
end)

function AIT.Character.SetupCreationScene()
    local ped = PlayerPedId()

    -- Posición de creación
    local coords = vector3(402.8, -996.7, -99.0)

    -- Cargar interior del espejo
    RequestIpl('ex_dt1_02_office_01a')
    while not IsIplActive('ex_dt1_02_office_01a') do
        Wait(10)
    end

    -- Teleportar
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)

    -- Cámara
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, coords.x + 1.5, coords.y, coords.z + 0.5)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.5)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)

    DisplayHud(false)
    DisplayRadar(false)
end

-- Callback de NUI - Crear personaje
RegisterNUICallback('createCharacter', function(data, cb)
    -- Validar datos
    if not data.firstName or #data.firstName < 2 then
        cb({ success = false, error = 'El nombre debe tener al menos 2 caracteres' })
        return
    end

    if not data.lastName or #data.lastName < 2 then
        cb({ success = false, error = 'El apellido debe tener al menos 2 caracteres' })
        return
    end

    if not data.dateOfBirth then
        cb({ success = false, error = 'Debes introducir tu fecha de nacimiento' })
        return
    end

    -- Enviar al servidor
    TriggerServerEvent('ait:server:createCharacter', {
        firstName = data.firstName,
        lastName = data.lastName,
        dateOfBirth = data.dateOfBirth,
        gender = data.gender or 'male',
        nationality = data.nationality or 'Los Santos',
    })

    cb({ success = true })
end)

RegisterNetEvent('ait:client:characterCreated', function(success, characterId)
    SetNuiFocus(false, false)
    isCreating = false

    -- Restaurar
    RenderScriptCams(false, true, 500, true, true)
    DestroyAllCams(true)
    DisplayHud(true)
    DisplayRadar(true)

    if success then
        AIT.Notify('Personaje creado correctamente', 'success')
        -- Ir a personalización de apariencia
        TriggerEvent('ait:client:characterCustomization', characterId)
    else
        AIT.Notify('Error al crear el personaje', 'error')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PERSONALIZACIÓN DE APARIENCIA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:characterCustomization', function(characterId)
    local ped = PlayerPedId()

    -- Posición de personalización
    local coords = vector3(402.8, -998.0, -99.0)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)

    -- Cámara de cuerpo completo
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, coords.x + 2.0, coords.y, coords.z + 0.5)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.5)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)

    -- Enviar a NUI con opciones de personalización
    SendNUIMessage({
        action = 'showCharacterCustomization',
        characterId = characterId,
        options = AIT.Character.GetCustomizationOptions()
    })

    SetNuiFocus(true, true)
end)

function AIT.Character.GetCustomizationOptions()
    return {
        -- Herencia (padres)
        inheritance = {
            fathers = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 },
            mothers = { 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41 },
        },
        -- Rasgos faciales
        features = {
            { name = 'nose_width', label = 'Ancho de nariz', min = -1.0, max = 1.0 },
            { name = 'nose_peak', label = 'Altura de nariz', min = -1.0, max = 1.0 },
            { name = 'nose_length', label = 'Largo de nariz', min = -1.0, max = 1.0 },
            { name = 'nose_bone', label = 'Puente nasal', min = -1.0, max = 1.0 },
            { name = 'nose_tip', label = 'Punta de nariz', min = -1.0, max = 1.0 },
            { name = 'nose_twist', label = 'Desviación nariz', min = -1.0, max = 1.0 },
            { name = 'eyebrow_height', label = 'Altura cejas', min = -1.0, max = 1.0 },
            { name = 'eyebrow_depth', label = 'Profundidad cejas', min = -1.0, max = 1.0 },
            { name = 'cheek_height', label = 'Altura pómulos', min = -1.0, max = 1.0 },
            { name = 'cheek_width', label = 'Ancho pómulos', min = -1.0, max = 1.0 },
            { name = 'cheek_depth', label = 'Profundidad pómulos', min = -1.0, max = 1.0 },
            { name = 'eye_size', label = 'Tamaño ojos', min = -1.0, max = 1.0 },
            { name = 'lip_thickness', label = 'Grosor labios', min = -1.0, max = 1.0 },
            { name = 'jaw_width', label = 'Ancho mandíbula', min = -1.0, max = 1.0 },
            { name = 'jaw_depth', label = 'Profundidad mandíbula', min = -1.0, max = 1.0 },
            { name = 'chin_height', label = 'Altura mentón', min = -1.0, max = 1.0 },
            { name = 'chin_depth', label = 'Profundidad mentón', min = -1.0, max = 1.0 },
            { name = 'chin_width', label = 'Ancho mentón', min = -1.0, max = 1.0 },
            { name = 'chin_shape', label = 'Forma mentón', min = -1.0, max = 1.0 },
            { name = 'neck_width', label = 'Ancho cuello', min = -1.0, max = 1.0 },
        },
        -- Pelo
        hair = {
            styles_male = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 },
            styles_female = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 },
            colors = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 },
        },
        -- Barba (solo masculino)
        beard = {
            styles = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28 },
        },
        -- Color de ojos
        eyeColor = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
    }
end

-- Callback de NUI - Guardar apariencia
RegisterNUICallback('saveAppearance', function(data, cb)
    SetNuiFocus(false, false)

    -- Restaurar cámara
    RenderScriptCams(false, true, 500, true, true)
    DestroyAllCams(true)
    DisplayHud(true)
    DisplayRadar(true)

    -- Guardar en servidor
    TriggerServerEvent('ait:server:saveAppearance', data.characterId, data.appearance)

    -- Spawn del jugador
    TriggerServerEvent('ait:server:selectCharacter', data.characterId)

    cb({ success = true })
end)

-- Callback de NUI - Previsualizar cambio
RegisterNUICallback('previewAppearance', function(data, cb)
    local ped = PlayerPedId()

    -- Aplicar cambios en tiempo real para previsualización
    if data.type == 'hair' then
        SetPedComponentVariation(ped, 2, data.value, 0, 0)
    elseif data.type == 'hairColor' then
        SetPedHairColor(ped, data.value, data.highlight or 0)
    elseif data.type == 'beard' then
        SetPedHeadOverlay(ped, 1, data.value, 1.0)
    elseif data.type == 'eyeColor' then
        SetPedEyeColor(ped, data.value)
    elseif data.type == 'feature' then
        SetPedFaceFeature(ped, data.index, data.value)
    elseif data.type == 'inheritance' then
        SetPedHeadBlendData(ped, data.father, data.mother, 0, data.father, data.mother, 0, data.shapeMix, data.skinMix, 0.0, false)
    end

    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- ELIMINAR PERSONAJE
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback('deleteCharacter', function(data, cb)
    -- Confirmar eliminación
    TriggerServerEvent('ait:server:deleteCharacter', data.characterId)
    cb({ success = true })
end)

RegisterNetEvent('ait:client:characterDeleted', function(success)
    if success then
        AIT.Notify('Personaje eliminado', 'info')
        -- Recargar selección
        TriggerServerEvent('ait:server:requestPlayerData')
    else
        AIT.Notify('Error al eliminar el personaje', 'error')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════

function AIT.Character.ApplyAppearance(ped, appearance)
    if not appearance then return end

    -- Aplicar herencia
    if appearance.inheritance then
        SetPedHeadBlendData(ped,
            appearance.inheritance.father or 0,
            appearance.inheritance.mother or 21,
            0,
            appearance.inheritance.father or 0,
            appearance.inheritance.mother or 21,
            0,
            appearance.inheritance.shapeMix or 0.5,
            appearance.inheritance.skinMix or 0.5,
            0.0,
            false
        )
    end

    -- Aplicar rasgos faciales
    if appearance.features then
        for i, value in ipairs(appearance.features) do
            SetPedFaceFeature(ped, i - 1, value)
        end
    end

    -- Aplicar pelo
    if appearance.hair then
        SetPedComponentVariation(ped, 2, appearance.hair.style or 0, 0, 0)
        SetPedHairColor(ped, appearance.hair.color or 0, appearance.hair.highlight or 0)
    end

    -- Aplicar barba
    if appearance.beard then
        SetPedHeadOverlay(ped, 1, appearance.beard.style or 0, appearance.beard.opacity or 1.0)
        SetPedHeadOverlayColor(ped, 1, 1, appearance.beard.color or 0, 0)
    end

    -- Aplicar color de ojos
    if appearance.eyeColor then
        SetPedEyeColor(ped, appearance.eyeColor)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('ApplyAppearance', AIT.Character.ApplyAppearance)

return AIT.Character
