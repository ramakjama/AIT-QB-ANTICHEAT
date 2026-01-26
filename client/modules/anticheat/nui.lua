-- ═══════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - NUI HANDLER
-- Panel de administración para el sistema anticheat
-- ═══════════════════════════════════════════════════════════════════════════════

local QBCore = exports['qb-core']:GetCoreObject()
local isPanelOpen = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('closePanel', function(data, cb)
    isPanelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('requestData', function(data, cb)
    -- Solicitar datos actualizados del servidor
    TriggerServerEvent('ait-qb:anticheat:requestPanelData')
    cb('ok')
end)

RegisterNUICallback('requestLogs', function(data, cb)
    TriggerServerEvent('ait-qb:anticheat:requestLogs')
    cb('ok')
end)

RegisterNUICallback('executeAction', function(data, cb)
    if not data.action then
        cb({ success = false, error = 'No action specified' })
        return
    end

    TriggerServerEvent('ait-qb:anticheat:executeAction', data.action, data.data)
    cb({ success = true })
end)

RegisterNUICallback('toggleModule', function(data, cb)
    if not data.module then
        cb({ success = false, error = 'No module specified' })
        return
    end

    TriggerServerEvent('ait-qb:anticheat:toggleModule', data.module, data.enabled)
    cb({ success = true })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLIENT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Abrir panel
RegisterNetEvent('ait-qb:anticheat:openPanel', function(data)
    isPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPanel',
        players = data.players or {},
        logs = data.logs or {},
        stats = data.stats or {},
        modules = data.modules or {}
    })
end)

-- Cerrar panel
RegisterNetEvent('ait-qb:anticheat:closePanel', function()
    isPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closePanel'
    })
end)

-- Actualizar jugadores
RegisterNetEvent('ait-qb:anticheat:updatePlayers', function(players)
    if isPanelOpen then
        SendNUIMessage({
            action = 'updatePlayers',
            players = players
        })
    end
end)

-- Actualizar logs
RegisterNetEvent('ait-qb:anticheat:updateLogs', function(logs)
    if isPanelOpen then
        SendNUIMessage({
            action = 'updateLogs',
            logs = logs
        })
    end
end)

-- Actualizar estadísticas
RegisterNetEvent('ait-qb:anticheat:updateStats', function(stats)
    if isPanelOpen then
        SendNUIMessage({
            action = 'updateStats',
            stats = stats
        })
    end
end)

-- Actualizar módulos
RegisterNetEvent('ait-qb:anticheat:updateModules', function(modules)
    if isPanelOpen then
        SendNUIMessage({
            action = 'updateModules',
            modules = modules
        })
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- KEYBIND
-- ═══════════════════════════════════════════════════════════════════════════════

-- Comando para abrir el panel
RegisterCommand('acpanel', function()
    TriggerServerEvent('ait-qb:anticheat:requestOpenPanel')
end, false)

-- Keybind opcional (F10 por defecto)
RegisterKeyMapping('acpanel', 'Abrir Panel Anticheat', 'keyboard', 'F10')

-- ═══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Cerrar con ESC
CreateThread(function()
    while true do
        Wait(0)
        if isPanelOpen then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride

            if IsDisabledControlJustReleased(0, 322) then
                isPanelOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({
                    action = 'closePanel'
                })
            end
        else
            Wait(500)
        end
    end
end)

-- Export para otros scripts
exports('IsPanelOpen', function()
    return isPanelOpen
end)

exports('OpenPanel', function()
    TriggerServerEvent('ait-qb:anticheat:requestOpenPanel')
end)

exports('ClosePanel', function()
    if isPanelOpen then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'closePanel'
        })
    end
end)
