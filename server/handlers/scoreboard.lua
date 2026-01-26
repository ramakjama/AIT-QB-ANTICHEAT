--[[
    AIT-QB: Server Handler - Scoreboard
    Servidor Español
]]

RegisterNetEvent('ait:server:scoreboard:getPlayers', function()
    local source = source
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local player = exports['qb-core']:GetPlayer(playerId)
        if player then
            local ping = GetPlayerPing(playerId)
            local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            local job = player.PlayerData.job.label or player.PlayerData.job.name

            table.insert(players, {
                id = playerId,
                name = name,
                job = job,
                ping = ping,
            })
        end
    end

    TriggerClientEvent('ait:client:scoreboard:updatePlayers', source, players)
end)

print('[AIT-QB] Server handler de scoreboard cargado')
