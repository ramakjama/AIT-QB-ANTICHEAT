--[[
    AIT-QB: Sistema de Scoreboard
    Cliente - Lista de jugadores con TAB
    Servidor Español
]]

AIT = AIT or {}
AIT.Scoreboard = {}

local isOpen = false
local playerList = {}
local lastUpdate = 0
local updateInterval = 2000 -- Actualizar cada 2 segundos

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    key = 'TAB',
    maxPlayersDisplay = 100,
    showPing = true,
    showJob = true,
    showId = true,
    adminCanSeeAll = true,
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Scoreboard.Init()
    RegisterKeyMapping('+scoreboard', 'Abrir Scoreboard', 'keyboard', Config.key)
    RegisterCommand('+scoreboard', function() AIT.Scoreboard.Open() end, false)
    RegisterCommand('-scoreboard', function() AIT.Scoreboard.Close() end, false)

    print('[AIT-QB] Sistema de scoreboard inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- ABRIR/CERRAR
-- ═══════════════════════════════════════════════════════════════

function AIT.Scoreboard.Open()
    if isOpen then return end
    isOpen = true

    -- Solicitar lista de jugadores
    TriggerServerEvent('ait:server:scoreboard:getPlayers')

    -- Mostrar NUI
    SendNUIMessage({
        action = 'openScoreboard',
        data = {
            serverName = 'AIT-QB ROLEPLAY',
            maxPlayers = 2048,
        }
    })

    -- Thread de actualización
    CreateThread(function()
        while isOpen do
            if GetGameTimer() - lastUpdate >= updateInterval then
                TriggerServerEvent('ait:server:scoreboard:getPlayers')
                lastUpdate = GetGameTimer()
            end
            Wait(100)
        end
    end)
end

function AIT.Scoreboard.Close()
    if not isOpen then return end
    isOpen = false

    SendNUIMessage({ action = 'closeScoreboard' })
end

-- ═══════════════════════════════════════════════════════════════
-- RECIBIR DATOS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:scoreboard:updatePlayers', function(players)
    playerList = players

    SendNUIMessage({
        action = 'updateScoreboard',
        data = {
            players = players,
            totalPlayers = #players,
        }
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- NUI
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback('closeScoreboard', function(_, cb)
    AIT.Scoreboard.Close()
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsScoreboardOpen', function() return isOpen end)
exports('GetPlayerList', function() return playerList end)

-- Inicializar
CreateThread(function()
    Wait(1000)
    AIT.Scoreboard.Init()
end)

return AIT.Scoreboard
