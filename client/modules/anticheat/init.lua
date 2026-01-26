-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - CLIENT SIDE
-- Detección de RedEngine, PhazeMenu, y todos los menús de hack
-- ═══════════════════════════════════════════════════════════════════════════════════════

local ClientAC = {}
ClientAC.Detections = {}
ClientAC.LastCheck = 0
ClientAC.LastCoords = nil
ClientAC.LastHealth = 0
ClientAC.Spawned = false
ClientAC.InvincibleFrames = 0

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    while not Config or not Config.Anticheat do
        Wait(100)
    end

    if not Config.Anticheat.Enabled then
        return
    end

    Wait(5000) -- Esperar a que el cliente cargue completamente

    -- Iniciar detectores
    ClientAC.StartResourceDetector()
    ClientAC.StartBehaviorMonitor()
    ClientAC.StartEntityMonitor()
    ClientAC.StartWeaponMonitor()
    ClientAC.StartHealthMonitor()

    print("^2[AIT-ANTICHEAT CLIENT]^0 Sistema de protección activo")
end)

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- DETECTOR DE RECURSOS MALICIOSOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ClientAC.StartResourceDetector()
    CreateThread(function()
        while true do
            Wait(10000) -- Cada 10 segundos

            -- Buscar recursos de cheat
            local numResources = GetNumResources()
            for i = 0, numResources - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName then
                    ClientAC.CheckResourceSignature(resourceName)
                end
            end

            -- Buscar exports sospechosos
            ClientAC.CheckSuspiciousExports()
        end
    end)
end

function ClientAC.CheckResourceSignature(resourceName)
    local lowerName = string.lower(resourceName)

    for _, signature in ipairs(Config.Anticheat.CheatSignatures.Resources) do
        if string.find(lowerName, string.lower(signature)) then
            ClientAC.ReportDetection("cheat_menu", {
                reason = string.format("Recurso de cheat detectado: %s", resourceName),
                signature = signature,
                resource = resourceName
            })
            return true
        end
    end

    return false
end

function ClientAC.CheckSuspiciousExports()
    -- Intentar detectar exports maliciosos
    for _, exportName in ipairs(Config.Anticheat.CheatSignatures.Exports) do
        -- Verificar si existe algún recurso con este export
        local numResources = GetNumResources()
        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName then
                local success, result = pcall(function()
                    return exports[resourceName][exportName]
                end)
                if success and result ~= nil then
                    ClientAC.ReportDetection("cheat_menu", {
                        reason = string.format("Export sospechoso: %s:%s", resourceName, exportName),
                        export = exportName,
                        resource = resourceName
                    })
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE COMPORTAMIENTO
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ClientAC.StartBehaviorMonitor()
    CreateThread(function()
        while true do
            Wait(500)

            if not ClientAC.Spawned then
                Wait(1000)
                goto continue
            end

            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then
                goto continue
            end

            local coords = GetEntityCoords(ped)

            -- Detección de teleport
            if ClientAC.LastCoords then
                local distance = #(coords - ClientAC.LastCoords)
                local timeDelta = 0.5 -- 500ms

                -- Verificar teleport sospechoso
                if distance > Config.Anticheat.Detection.Teleport.MaxDistancePerTick then
                    if not ClientAC.IsInSafeZone(coords) then
                        ClientAC.ReportDetection("teleport", {
                            reason = string.format("Teleport: %.0f metros", distance),
                            from = ClientAC.LastCoords,
                            to = coords,
                            distance = distance
                        })
                    end
                end

                -- Detección de speedhack
                local speed = distance / timeDelta
                local maxSpeed = IsPedInAnyVehicle(ped, false) and
                    Config.Anticheat.Detection.Speed.MaxVehicleSpeed or
                    Config.Anticheat.Detection.Speed.MaxFootSpeed

                -- Ajustar para aviones
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    local class = GetVehicleClass(vehicle)
                    if class == 15 or class == 16 then -- Helicopters & Planes
                        maxSpeed = Config.Anticheat.Detection.Speed.MaxAircraftSpeed
                    end
                end

                if speed > (maxSpeed * Config.Anticheat.Detection.Speed.Tolerance) then
                    ClientAC.ReportDetection("speedhack", {
                        reason = string.format("SpeedHack: %.0f m/s (max: %.0f)", speed, maxSpeed),
                        speed = speed,
                        maxSpeed = maxSpeed
                    })
                end
            end

            ClientAC.LastCoords = coords

            ::continue::
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE ENTIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ClientAC.StartEntityMonitor()
    CreateThread(function()
        while true do
            Wait(5000)

            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then goto continue end

            -- Verificar invisibilidad
            if not IsEntityVisible(ped) and ClientAC.Spawned then
                -- Dar un poco de tolerancia para cutscenes, etc.
                Wait(2000)
                if not IsEntityVisible(ped) then
                    ClientAC.ReportDetection("godmode", {
                        reason = "Invisibilidad detectada"
                    })
                end
            end

            -- Verificar colisión desactivada (no-clip)
            if GetEntityCollisionDisabled(ped) then
                -- No-clip detection - verificar si está en el aire sin vehículo
                if IsEntityInAir(ped) and not IsPedInAnyVehicle(ped, false) then
                    ClientAC.ReportDetection("godmode", {
                        reason = "No-clip detectado"
                    })
                end
            end

            ::continue::
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE ARMAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ClientAC.StartWeaponMonitor()
    CreateThread(function()
        local lastAmmo = {}
        local lastShot = {}

        while true do
            Wait(1000)

            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then goto continue end

            -- Obtener arma actual
            local success, weapon = GetCurrentPedWeapon(ped, true)
            if success and weapon ~= `WEAPON_UNARMED` then

                -- Verificar armas blacklisted
                for _, blacklisted in ipairs(Config.Anticheat.Detection.Weapons.BlacklistedWeapons) do
                    if weapon == blacklisted then
                        -- Quitar arma y reportar
                        RemoveWeaponFromPed(ped, weapon)
                        ClientAC.ReportDetection("weapon_exploit", {
                            reason = "Arma prohibida detectada",
                            weapon = weapon
                        })
                    end
                end

                -- Detectar munición infinita
                if Config.Anticheat.Detection.Weapons.DetectInfiniteAmmo then
                    local ammo = GetAmmoInPedWeapon(ped, weapon)

                    if lastAmmo[weapon] then
                        -- Si dispara pero la munición no baja
                        if IsPedShooting(ped) then
                            if ammo >= lastAmmo[weapon] and ammo > 0 then
                                ClientAC.ReportDetection("weapon_exploit", {
                                    reason = "Munición infinita detectada",
                                    weapon = weapon
                                })
                            end
                        end
                    end

                    lastAmmo[weapon] = ammo
                end

                -- Detectar disparo rápido
                if Config.Anticheat.Detection.Weapons.DetectRapidFire then
                    if IsPedShooting(ped) then
                        local now = GetGameTimer()
                        if lastShot[weapon] then
                            local timeBetweenShots = now - lastShot[weapon]
                            -- Si dispara demasiado rápido (menos de 50ms entre disparos para armas que no lo permiten)
                            if timeBetweenShots < 50 then
                                ClientAC.ReportDetection("weapon_exploit", {
                                    reason = "Disparo rápido detectado",
                                    weapon = weapon,
                                    interval = timeBetweenShots
                                })
                            end
                        end
                        lastShot[weapon] = now
                    end
                end
            end

            ::continue::
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITOR DE HEALTH/GODMODE
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ClientAC.StartHealthMonitor()
    CreateThread(function()
        local damageReceived = 0
        local lastDamageCheck = GetGameTimer()

        while true do
            Wait(1000)

            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then goto continue end

            local health = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local armor = GetPedArmour(ped)

            -- Verificar health anormal
            if health > 300 or maxHealth > 300 then
                ClientAC.ReportDetection("godmode", {
                    reason = string.format("Health anormal: %d/%d", health, maxHealth)
                })
            end

            -- Verificar armor anormal
            if armor > 150 then
                ClientAC.ReportDetection("godmode", {
                    reason = string.format("Armor anormal: %d", armor)
                })
            end

            -- Detectar invencibilidad
            if GetPlayerInvincible(PlayerId()) then
                ClientAC.InvincibleFrames = ClientAC.InvincibleFrames + 1

                -- Si lleva más de 5 segundos invencible, es sospechoso
                if ClientAC.InvincibleFrames > 5 then
                    ClientAC.ReportDetection("godmode", {
                        reason = "Invencibilidad activada"
                    })
                end
            else
                ClientAC.InvincibleFrames = 0
            end

            -- Verificar si recibe daño
            if ClientAC.LastHealth > 0 and health < ClientAC.LastHealth then
                damageReceived = damageReceived + (ClientAC.LastHealth - health)
                lastDamageCheck = GetGameTimer()
            end

            -- Si lleva mucho tiempo en combate sin recibir daño real
            -- (esto es difícil de detectar sin falsos positivos, así que es conservador)

            ClientAC.LastHealth = health

            ::continue::
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- PROTECCIONES ACTIVAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Bloquear eventos maliciosos del lado del cliente
CreateThread(function()
    while true do
        Wait(0)

        -- Desactivar GodMode si está activado (protección activa)
        local playerId = PlayerId()
        if GetPlayerInvincible(playerId) then
            SetPlayerInvincible(playerId, false)
        end

        -- Desactivar SuperJump
        if IsPedJumping(PlayerPedId()) then
            local jumpHeight = GetEntityHeightAboveGround(PlayerPedId())
            if jumpHeight > 10.0 then -- Salto normal no supera ~2m
                SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, false, false, false)
            end
        end
    end
end)

-- Bloquear teclas de menús de cheat comunes
CreateThread(function()
    while true do
        Wait(0)

        -- Teclas comúnmente usadas por menús de cheat
        -- F8 (abre consola, usada por algunos trainers)
        -- INSERT, DELETE, HOME, END, PAGE UP, PAGE DOWN
        -- Estas teclas por sí solas no son indicativas, pero
        -- podemos monitorear combinaciones sospechosas
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function ClientAC.IsInSafeZone(coords)
    -- Verificar si las coordenadas están en una zona segura (TP permitido)
    for _, zone in ipairs(Config.Anticheat.Detection.Teleport.WhitelistedZones or {}) do
        if #(coords - zone.coords) < (zone.radius or 50.0) then
            return true
        end
    end
    return false
end

function ClientAC.ReportDetection(detectionType, data)
    -- Evitar spam de detecciones
    local key = detectionType .. (data.reason or "")
    if ClientAC.Detections[key] then
        if GetGameTimer() - ClientAC.Detections[key] < 30000 then -- 30 segundos cooldown
            return
        end
    end
    ClientAC.Detections[key] = GetGameTimer()

    print(string.format("^1[AIT-ANTICHEAT CLIENT] Detección: %s - %s^0", detectionType, data.reason or ""))

    -- Enviar al servidor
    TriggerServerEvent('ait-qb:server:anticheat:detection', detectionType, data)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Cuando el jugador spawnea
RegisterNetEvent('ait-qb:client:playerLoaded')
AddEventHandler('ait-qb:client:playerLoaded', function()
    ClientAC.Spawned = true
    ClientAC.LastCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('ait-qb:server:anticheat:playerSpawned')
end)

-- Alternativamente para otros frameworks
AddEventHandler('playerSpawned', function()
    ClientAC.Spawned = true
    ClientAC.LastCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('ait-qb:server:anticheat:playerSpawned')
end)

-- Recibir advertencia
RegisterNetEvent('ait-qb:client:anticheat:warn')
AddEventHandler('ait-qb:client:anticheat:warn', function(reason)
    -- Mostrar advertencia al jugador
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName("~r~ADVERTENCIA~s~: " .. reason)
    EndTextCommandThefeedPostTicker(true, true)
end)

-- Notificación para admins
RegisterNetEvent('ait-qb:client:anticheat:adminNotify')
AddEventHandler('ait-qb:client:anticheat:adminNotify', function(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName("~y~[AC ADMIN]~s~: " .. message)
    EndTextCommandThefeedPostTicker(true, true)
end)

-- Enviar check periódico al servidor
CreateThread(function()
    while true do
        Wait(30000) -- Cada 30 segundos

        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local weapons = {}
            -- Obtener lista de armas del jugador
            -- (simplificado, en producción usar un sistema más completo)

            TriggerServerEvent('ait-qb:server:anticheat:clientCheck', {
                health = GetEntityHealth(ped),
                armor = GetPedArmour(ped),
                coords = GetEntityCoords(ped),
                weapons = weapons,
                timestamp = GetGameTimer()
            })
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ANTI-INJECTION
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Proteger contra inyección de código via eventos
local originalTriggerServerEvent = TriggerServerEvent
_G.TriggerServerEvent = function(eventName, ...)
    -- Verificar si el evento está bloqueado
    for _, blocked in ipairs(Config.Anticheat.CheatSignatures.Events) do
        if string.find(eventName, blocked) then
            ClientAC.ReportDetection("event_injection", {
                reason = string.format("Intento de trigger bloqueado: %s", eventName)
            })
            return
        end
    end

    return originalTriggerServerEvent(eventName, ...)
end

-- Exportar módulo
_G.ClientAC = ClientAC

return ClientAC
