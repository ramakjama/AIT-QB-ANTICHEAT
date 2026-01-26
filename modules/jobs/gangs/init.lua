--[[
    AIT-QB: Sistema de Bandas/Gangs
    Trabajo ILEGAL - Sistema de territorios, guerras y actividades de banda
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Gangs = {}

local currentGang = nil
local gangRank = 0
local gangRep = 0
local inTerritory = nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Bandas predefinidas
    gangs = {
        ballas = {
            name = 'Ballas',
            label = 'Ballas',
            color = 'purple',
            blipColor = 27, -- Púrpura
            hq = vector3(89.0, -1958.0, 21.0),
            stash = vector3(95.0, -1950.0, 21.0),
            spray = 'ballas_tag',
        },
        vagos = {
            name = 'vagos',
            label = 'Los Santos Vagos',
            color = 'yellow',
            blipColor = 5, -- Amarillo
            hq = vector3(325.0, -2043.0, 21.0),
            stash = vector3(330.0, -2035.0, 21.0),
            spray = 'vagos_tag',
        },
        families = {
            name = 'families',
            label = 'The Families',
            color = 'green',
            blipColor = 2, -- Verde
            hq = vector3(-151.0, -1604.0, 35.0),
            stash = vector3(-145.0, -1598.0, 35.0),
            spray = 'families_tag',
        },
        marabunta = {
            name = 'marabunta',
            label = 'Marabunta Grande',
            color = 'blue',
            blipColor = 3, -- Azul
            hq = vector3(1417.0, -1496.0, 60.0),
            stash = vector3(1422.0, -1490.0, 60.0),
            spray = 'marabunta_tag',
        },
        aztecas = {
            name = 'aztecas',
            label = 'Varrios Los Aztecas',
            color = 'cyan',
            blipColor = 26, -- Turquesa
            hq = vector3(-197.0, -1802.0, 28.0),
            stash = vector3(-192.0, -1795.0, 28.0),
            spray = 'aztecas_tag',
        },
    },

    -- Territorios
    territories = {
        {
            name = 'Grove Street',
            center = vector3(-128.0, -1621.0, 32.0),
            radius = 150.0,
            owner = 'families',
            points = 100,
        },
        {
            name = 'Forum Drive',
            center = vector3(89.0, -1958.0, 21.0),
            radius = 150.0,
            owner = 'ballas',
            points = 100,
        },
        {
            name = 'El Rancho',
            center = vector3(325.0, -2043.0, 21.0),
            radius = 150.0,
            owner = 'vagos',
            points = 100,
        },
        {
            name = 'Cypress Flats',
            center = vector3(820.0, -2141.0, 29.0),
            radius = 200.0,
            owner = 'marabunta',
            points = 100,
        },
        {
            name = 'Vespucci Canals',
            center = vector3(-1061.0, -1295.0, 5.0),
            radius = 180.0,
            owner = 'aztecas',
            points = 100,
        },
        {
            name = 'La Mesa',
            center = vector3(832.0, -1035.0, 28.0),
            radius = 200.0,
            owner = nil, -- Neutral
            points = 0,
        },
        {
            name = 'Strawberry',
            center = vector3(-38.0, -1302.0, 29.0),
            radius = 200.0,
            owner = nil, -- Neutral
            points = 0,
        },
    },

    -- Rangos de banda
    ranks = {
        { level = 0, name = 'Aspirante', permissions = {} },
        { level = 1, name = 'Soldado', permissions = { 'stash', 'spray' } },
        { level = 2, name = 'Veterano', permissions = { 'stash', 'spray', 'recruit' } },
        { level = 3, name = 'Capitán', permissions = { 'stash', 'spray', 'recruit', 'kick', 'territory' } },
        { level = 4, name = 'Underboss', permissions = { 'stash', 'spray', 'recruit', 'kick', 'territory', 'promote' } },
        { level = 5, name = 'Jefe', permissions = { '*' } },
    },

    -- Actividades de banda
    activities = {
        -- Venta de drogas en territorio
        drugDealing = {
            cooldown = 300, -- 5 minutos
            repGain = 10,
            moneyRange = { 200, 500 },
        },

        -- Grafiti / spray
        spray = {
            cooldown = 600,
            repGain = 25,
            requiredItem = 'spray_can',
        },

        -- Robo de territorio
        territoryRaid = {
            minMembers = 3,
            duration = 600, -- 10 minutos
            repGain = 100,
            repLoss = 50, -- Para el defensor
        },

        -- Misiones de banda
        missions = {
            drive_by = { label = 'Drive-By', repGain = 50, danger = 'alto' },
            supply_run = { label = 'Run de Suministros', repGain = 30, danger = 'medio' },
            turf_patrol = { label = 'Patrulla de Territorio', repGain = 15, danger = 'bajo' },
            rival_hit = { label = 'Golpe a Rival', repGain = 75, danger = 'muy alto' },
        },
    },

    -- Reputación necesaria para rangos
    repRequired = {
        [1] = 100,
        [2] = 500,
        [3] = 1500,
        [4] = 4000,
        [5] = 10000,
    },

    -- Tienda de banda (compras con rep)
    gangShop = {
        { item = 'spray_can', label = 'Spray', price = 50, repRequired = 0 },
        { item = 'weapon_knife', label = 'Navaja', price = 100, repRequired = 50 },
        { item = 'weapon_bat', label = 'Bate', price = 150, repRequired = 100 },
        { item = 'weapon_pistol', label = 'Pistola', price = 500, repRequired = 500 },
        { item = 'armor', label = 'Chaleco', price = 300, repRequired = 300 },
        { item = 'bandana', label = 'Bandana', price = 50, repRequired = 0 },
    },
}

-- Estado de territorios (dinámico)
local territoryState = {}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Gangs.Init()
    -- Inicializar estado de territorios
    for i, territory in ipairs(Config.territories) do
        territoryState[i] = {
            owner = territory.owner,
            points = territory.points,
            underAttack = false,
            attackingGang = nil,
        }
    end

    -- Crear zonas de territorio
    for i, territory in ipairs(Config.territories) do
        if lib and lib.zones then
            lib.zones.sphere({
                coords = territory.center,
                radius = territory.radius,
                debug = false,
                onEnter = function()
                    inTerritory = i
                    local state = territoryState[i]
                    local ownerLabel = state.owner and Config.gangs[state.owner].label or 'Neutral'

                    AIT.Notify('Entrando a territorio: ' .. territory.name .. ' (' .. ownerLabel .. ')', 'info')

                    if state.owner and currentGang and state.owner ~= currentGang then
                        AIT.Notify('¡Territorio enemigo! Ten cuidado.', 'warning')
                    end
                end,
                onExit = function()
                    if inTerritory == i then
                        inTerritory = nil
                    end
                end,
            })
        end
    end

    -- Crear blips de HQs
    for gangName, gang in pairs(Config.gangs) do
        local blip = AddBlipForCoord(gang.hq.x, gang.hq.y, gang.hq.z)
        SetBlipSprite(blip, 84)
        SetBlipColour(blip, gang.blipColor)
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(gang.label .. ' HQ')
        EndTextCommandSetBlipName(blip)
    end

    print('[AIT-QB] Sistema de bandas inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- GESTIÓN DE BANDA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:gangs:setGang', function(gangName, rank, rep)
    currentGang = gangName
    gangRank = rank or 0
    gangRep = rep or 0

    if currentGang then
        local gang = Config.gangs[currentGang]
        AIT.Notify('Eres miembro de ' .. gang.label .. ' (Rango: ' .. Config.ranks[gangRank + 1].name .. ')', 'info')
    end
end)

RegisterNetEvent('ait:client:gangs:openMenu', function()
    if not currentGang then
        AIT.Notify('No perteneces a ninguna banda', 'error')
        return
    end

    local gang = Config.gangs[currentGang]
    local rank = Config.ranks[gangRank + 1]

    local options = {
        {
            title = gang.label,
            description = 'Rango: ' .. rank.name .. ' | Reputación: ' .. gangRep,
            icon = 'users',
        },
        {
            title = 'Actividades',
            description = 'Misiones y trabajos de banda',
            icon = 'tasks',
            onSelect = function()
                AIT.Jobs.Gangs.OpenActivitiesMenu()
            end,
        },
        {
            title = 'Tienda de Banda',
            description = 'Comprar con reputación',
            icon = 'store',
            onSelect = function()
                AIT.Jobs.Gangs.OpenGangShop()
            end,
        },
        {
            title = 'Almacén',
            description = 'Acceder al stash de la banda',
            icon = 'box',
            disabled = not AIT.Jobs.Gangs.HasPermission('stash'),
            onSelect = function()
                TriggerServerEvent('ait:server:gangs:openStash', currentGang)
            end,
        },
        {
            title = 'Territorios',
            description = 'Ver mapa de territorios',
            icon = 'map',
            onSelect = function()
                AIT.Jobs.Gangs.ShowTerritoryMap()
            end,
        },
    }

    -- Opciones de gestión (rangos altos)
    if AIT.Jobs.Gangs.HasPermission('recruit') then
        table.insert(options, {
            title = 'Reclutar Miembro',
            description = 'Invitar a alguien a la banda',
            icon = 'user-plus',
            onSelect = function()
                AIT.Jobs.Gangs.RecruitMember()
            end,
        })
    end

    if AIT.Jobs.Gangs.HasPermission('promote') then
        table.insert(options, {
            title = 'Gestionar Miembros',
            description = 'Promover, degradar o expulsar',
            icon = 'users-cog',
            onSelect = function()
                TriggerServerEvent('ait:server:gangs:getMembers', currentGang)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'gang_menu',
            title = 'Menú de Banda',
            options = options,
        })
        lib.showContext('gang_menu')
    end
end)

function AIT.Jobs.Gangs.HasPermission(permission)
    if gangRank >= 5 then return true end -- Jefe tiene todo

    local rank = Config.ranks[gangRank + 1]
    if not rank then return false end

    for _, perm in ipairs(rank.permissions) do
        if perm == '*' or perm == permission then
            return true
        end
    end

    return false
end

-- ═══════════════════════════════════════════════════════════════
-- ACTIVIDADES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Gangs.OpenActivitiesMenu()
    local options = {
        {
            title = 'Vender Droga',
            description = 'Vender en tu territorio',
            icon = 'cannabis',
            onSelect = function()
                AIT.Jobs.Gangs.StartDrugDealing()
            end,
        },
        {
            title = 'Hacer Grafiti',
            description = 'Marcar territorio con spray',
            icon = 'spray-can',
            disabled = not AIT.Jobs.Gangs.HasPermission('spray'),
            onSelect = function()
                AIT.Jobs.Gangs.StartSpray()
            end,
        },
        {
            title = 'Patrullar Territorio',
            description = 'Ganar rep patrullando',
            icon = 'walking',
            onSelect = function()
                AIT.Jobs.Gangs.StartPatrol()
            end,
        },
        {
            title = 'Atacar Territorio',
            description = 'Iniciar guerra por territorio',
            icon = 'crosshairs',
            disabled = not AIT.Jobs.Gangs.HasPermission('territory'),
            onSelect = function()
                AIT.Jobs.Gangs.StartTerritoryRaid()
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'gang_activities',
            title = 'Actividades',
            menu = 'gang_menu',
            options = options,
        })
        lib.showContext('gang_activities')
    end
end

function AIT.Jobs.Gangs.StartDrugDealing()
    if not inTerritory then
        AIT.Notify('Debes estar en un territorio', 'error')
        return
    end

    local territory = Config.territories[inTerritory]
    local state = territoryState[inTerritory]

    -- Mejor pago en tu territorio
    local isOwnTerritory = state.owner == currentGang

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 15000,
            label = 'Vendiendo droga...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            local money = math.random(
                Config.activities.drugDealing.moneyRange[1],
                Config.activities.drugDealing.moneyRange[2]
            )

            if isOwnTerritory then
                money = money * 1.5
            end

            local rep = Config.activities.drugDealing.repGain
            if not isOwnTerritory then
                rep = rep * 0.5 -- Menos rep fuera de tu territorio
            end

            TriggerServerEvent('ait:server:gangs:completeDrugDeal', math.floor(money), math.floor(rep))
            AIT.Notify('Vendiste droga: +$' .. math.floor(money) .. ' | +' .. math.floor(rep) .. ' rep', 'success')

            -- Chance de alerta policial
            if math.random(1, 100) <= 20 then
                TriggerServerEvent('ait:server:police:drugAlert', 'gang', GetEntityCoords(PlayerPedId()))
            end
        end
    end
end

function AIT.Jobs.Gangs.StartSpray()
    -- Verificar que tiene spray
    TriggerServerEvent('ait:server:gangs:checkSpray')
end

RegisterNetEvent('ait:client:gangs:doSpray', function()
    if lib and lib.progressBar then
        if lib.progressBar({
            duration = 10000,
            label = 'Pintando grafiti...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                scenario = 'WORLD_HUMAN_SPRAY_PAINT',
            },
        }) then
            TriggerServerEvent('ait:server:gangs:completeSpray', inTerritory)
            AIT.Notify('Grafiti completado +' .. Config.activities.spray.repGain .. ' rep', 'success')
        end
    end
end)

function AIT.Jobs.Gangs.StartPatrol()
    if not inTerritory then
        AIT.Notify('Debes estar en un territorio', 'error')
        return
    end

    local territory = Config.territories[inTerritory]
    local state = territoryState[inTerritory]

    if state.owner ~= currentGang then
        AIT.Notify('Solo puedes patrullar tu territorio', 'error')
        return
    end

    AIT.Notify('Patrulla iniciada. Camina por el territorio durante 5 minutos.', 'info')

    local startTime = GetGameTimer()
    local patrolDuration = 300000 -- 5 minutos

    CreateThread(function()
        while GetGameTimer() - startTime < patrolDuration do
            Wait(10000) -- Cada 10 segundos

            if inTerritory and territoryState[inTerritory].owner == currentGang then
                -- Dar pequeña cantidad de rep
                gangRep = gangRep + 1
                TriggerServerEvent('ait:server:gangs:addRep', 1)
            else
                AIT.Notify('Saliste del territorio. Patrulla cancelada.', 'error')
                return
            end
        end

        TriggerServerEvent('ait:server:gangs:completePatrol')
        AIT.Notify('Patrulla completada +' .. Config.activities.missions.turf_patrol.repGain .. ' rep', 'success')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- GUERRA DE TERRITORIOS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Gangs.StartTerritoryRaid()
    if not inTerritory then
        AIT.Notify('Debes estar en un territorio para atacarlo', 'error')
        return
    end

    local state = territoryState[inTerritory]

    if state.owner == currentGang then
        AIT.Notify('Este territorio ya es tuyo', 'error')
        return
    end

    if state.underAttack then
        AIT.Notify('Este territorio ya está siendo atacado', 'error')
        return
    end

    -- Verificar miembros online
    TriggerServerEvent('ait:server:gangs:checkRaidRequirements', inTerritory)
end

RegisterNetEvent('ait:client:gangs:startRaid', function(territoryIndex)
    local territory = Config.territories[territoryIndex]
    local state = territoryState[territoryIndex]

    state.underAttack = true
    state.attackingGang = currentGang

    AIT.Notify('¡GUERRA DE TERRITORIO INICIADA! Defiende la zona durante 10 minutos.', 'warning')

    -- Alertar a la banda defensora
    TriggerServerEvent('ait:server:gangs:alertDefenders', territoryIndex, state.owner)

    -- Crear zona de captura
    local raidDuration = Config.activities.territoryRaid.duration * 1000
    local startTime = GetGameTimer()
    local attackPoints = 0
    local defendPoints = 0

    CreateThread(function()
        while GetGameTimer() - startTime < raidDuration do
            Wait(5000) -- Cada 5 segundos

            -- Contar miembros de cada banda en la zona
            -- Simplificado: dar puntos al atacante si está en zona
            if inTerritory == territoryIndex then
                attackPoints = attackPoints + 1
                TriggerServerEvent('ait:server:gangs:raidTick', territoryIndex, 'attack')
            end
        end

        -- Determinar ganador
        TriggerServerEvent('ait:server:gangs:endRaid', territoryIndex, attackPoints, defendPoints)
    end)
end)

RegisterNetEvent('ait:client:gangs:raidEnded', function(territoryIndex, winner, wasAttacker)
    local territory = Config.territories[territoryIndex]

    territoryState[territoryIndex].underAttack = false
    territoryState[territoryIndex].attackingGang = nil

    if winner == currentGang then
        if wasAttacker then
            territoryState[territoryIndex].owner = currentGang
            AIT.Notify('¡VICTORIA! ' .. territory.name .. ' ahora pertenece a tu banda!', 'success')
        else
            AIT.Notify('¡VICTORIA! Has defendido ' .. territory.name .. ' exitosamente!', 'success')
        end
    else
        if wasAttacker then
            AIT.Notify('DERROTA. No pudiste conquistar ' .. territory.name, 'error')
        else
            territoryState[territoryIndex].owner = winner
            AIT.Notify('DERROTA. Perdiste el control de ' .. territory.name, 'error')
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- TIENDA DE BANDA
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Gangs.OpenGangShop()
    local options = {}

    for _, item in ipairs(Config.gangShop) do
        local canBuy = gangRep >= item.repRequired

        table.insert(options, {
            title = item.label,
            description = canBuy and ('Precio: ' .. item.price .. ' rep') or ('Requiere ' .. item.repRequired .. ' rep'),
            icon = 'shopping-cart',
            disabled = not canBuy or gangRep < item.price,
            onSelect = function()
                TriggerServerEvent('ait:server:gangs:buyItem', item.item, item.price)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'gang_shop',
            title = 'Tienda de Banda',
            menu = 'gang_menu',
            options = options,
        })
        lib.showContext('gang_shop')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MAPA DE TERRITORIOS
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Gangs.ShowTerritoryMap()
    local options = {}

    for i, territory in ipairs(Config.territories) do
        local state = territoryState[i]
        local ownerLabel = state.owner and Config.gangs[state.owner].label or 'Neutral'
        local statusIcon = state.underAttack and '⚔️ ' or ''

        table.insert(options, {
            title = statusIcon .. territory.name,
            description = 'Controlado por: ' .. ownerLabel,
            icon = state.owner == currentGang and 'flag' or 'map-marker',
            onSelect = function()
                SetNewWaypoint(territory.center.x, territory.center.y)
                AIT.Notify('GPS marcado: ' .. territory.name, 'info')
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'gang_territories',
            title = 'Mapa de Territorios',
            menu = 'gang_menu',
            options = options,
        })
        lib.showContext('gang_territories')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- RECLUTAMIENTO
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Gangs.RecruitMember()
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
        TriggerServerEvent('ait:server:gangs:sendInvite', closestPlayer, currentGang)
        AIT.Notify('Invitación enviada', 'success')
    else
        AIT.Notify('No hay nadie cerca para reclutar', 'error')
    end
end

RegisterNetEvent('ait:client:gangs:receiveInvite', function(gangName, inviterName)
    local gang = Config.gangs[gangName]

    if lib and lib.alertDialog then
        local alert = lib.alertDialog({
            header = 'Invitación de Banda',
            content = inviterName .. ' te invita a unirte a ' .. gang.label,
            centered = true,
            cancel = true,
        })

        if alert == 'confirm' then
            TriggerServerEvent('ait:server:gangs:acceptInvite', gangName)
        else
            TriggerServerEvent('ait:server:gangs:declineInvite', gangName)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ACTUALIZACIÓN DE REP
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:gangs:updateRep', function(newRep, newRank)
    local oldRank = gangRank
    gangRep = newRep
    gangRank = newRank

    if newRank > oldRank then
        local rankData = Config.ranks[newRank + 1]
        AIT.Notify('¡Has sido promovido a ' .. rankData.name .. '!', 'success')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('GetCurrentGang', function() return currentGang end)
exports('GetGangRank', function() return gangRank end)
exports('GetGangRep', function() return gangRep end)
exports('IsInTerritory', function() return inTerritory end)
exports('HasGangPermission', AIT.Jobs.Gangs.HasPermission)

return AIT.Jobs.Gangs
