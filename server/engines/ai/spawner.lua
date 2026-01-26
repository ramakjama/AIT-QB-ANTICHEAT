-- =====================================================================================
-- ait-qb ENGINE DE SPAWNER DE NPCs
-- Sistema de zonas de spawn, densidad dinamica y despawn por distancia
-- Namespace: AIT.Engines.AI.Spawner
-- Optimizado para 2048 slots con control de poblacion
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.AI = AIT.Engines.AI or {}

local Spawner = {
    -- Zonas activas
    zonasActivas = {},
    -- NPCs por zona
    npcsPorZona = {},
    -- Jugadores por zona
    jugadoresPorZona = {},
    -- Configuracion global
    config = {
        -- Limite global de NPCs spawneados
        limiteGlobal = 500,
        -- NPCs maximos por zona
        maxPorZona = 30,
        -- NPCs minimos por zona con jugadores
        minPorZona = 5,
        -- Factor de densidad base
        factorDensidad = 1.0,
        -- Distancia de spawn
        distanciaSpawn = 80.0,
        -- Distancia de despawn
        distanciaDespawn = 120.0,
        -- Intervalo de chequeo (ms)
        intervaloChequeo = 3000,
        -- Delay entre spawns (ms)
        delaySpawn = 500,
        -- Horario de spawn (afecta densidad)
        horarioAfecta = true,
    },
    -- Estado del spawner
    activo = true,
    procesando = false,
    ultimoChequeo = 0,
}

-- =====================================================================================
-- CONFIGURACION DE ZONAS PREDEFINIDAS
-- =====================================================================================

Spawner.ZonasDefault = {
    -- Zona centro de Los Santos
    {
        nombre = 'Centro Los Santos',
        tipo = 'urbana',
        centro = vector3(-250.0, -900.0, 30.0),
        radio = 300.0,
        densidadMax = 25,
        densidadMin = 10,
        tiposNPC = { 'civil' },
        modelos = nil, -- Usa default
        horario = nil, -- Siempre activa
        prioridad = 2,
    },
    -- Zona comercial
    {
        nombre = 'Zona Comercial Vinewood',
        tipo = 'comercial',
        centro = vector3(300.0, 200.0, 100.0),
        radio = 200.0,
        densidadMax = 20,
        densidadMin = 8,
        tiposNPC = { 'civil', 'vendedor' },
        horario = { inicio = 8, fin = 22 },
        prioridad = 2,
    },
    -- Zona industrial
    {
        nombre = 'Puerto Los Santos',
        tipo = 'industrial',
        centro = vector3(800.0, -3000.0, 5.0),
        radio = 400.0,
        densidadMax = 15,
        densidadMin = 3,
        tiposNPC = { 'civil' },
        horario = { inicio = 6, fin = 20 },
        prioridad = 1,
    },
    -- Zona rural
    {
        nombre = 'Sandy Shores',
        tipo = 'rural',
        centro = vector3(1900.0, 3700.0, 32.0),
        radio = 300.0,
        densidadMax = 8,
        densidadMin = 2,
        tiposNPC = { 'civil' },
        prioridad = 1,
    },
    -- Zona policial
    {
        nombre = 'Comisaria Central',
        tipo = 'policial',
        centro = vector3(428.0, -981.0, 30.0),
        radio = 50.0,
        densidadMax = 10,
        densidadMin = 5,
        tiposNPC = { 'policia' },
        persistente = true,
        prioridad = 3,
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Spawner.Initialize()
    -- Cargar zonas de la base de datos
    Spawner.CargarZonas()

    -- Si no hay zonas en BD, crear las default
    if Spawner.ContarZonas() == 0 then
        Spawner.CrearZonasDefault()
    end

    -- Iniciar thread principal
    Spawner.IniciarThreadPrincipal()

    -- Iniciar thread de balance
    Spawner.IniciarThreadBalance()

    if AIT.Log then
        AIT.Log.info('AI:SPAWNER', 'Sistema de spawning inicializado')
    end

    return true
end

-- =====================================================================================
-- GESTION DE ZONAS
-- =====================================================================================

--- Carga zonas desde la base de datos
function Spawner.CargarZonas()
    local AI = AIT.Engines.AI

    if AI.poolsZona then
        for zonaId, zona in pairs(AI.poolsZona) do
            Spawner.zonasActivas[zonaId] = {
                id = zonaId,
                nombre = zona.nombre,
                tipo = zona.tipo,
                centro = vector3(zona.centro_x, zona.centro_y, zona.centro_z),
                radio = zona.radio,
                densidadMax = zona.densidad_max,
                densidadMin = zona.densidad_min,
                tiposNPC = zona.tipos_npc,
                modelos = zona.modelos,
                comportamientos = zona.comportamientos,
                horario = zona.horario_activo,
                prioridad = zona.prioridad,
                activa = true,
            }
            Spawner.npcsPorZona[zonaId] = {}
            Spawner.jugadoresPorZona[zonaId] = {}
        end
    end
end

--- Crea las zonas por defecto
function Spawner.CrearZonasDefault()
    for _, zonaData in ipairs(Spawner.ZonasDefault) do
        Spawner.CrearZona(zonaData)
    end
end

--- Crea una nueva zona de spawn
---@param params table
---@return number|nil zonaId
function Spawner.CrearZona(params)
    local zonaId = MySQL.insert.await([[
        INSERT INTO ait_npc_zonas
        (nombre, tipo, centro_x, centro_y, centro_z, radio, densidad_max, densidad_min,
         tipos_npc, modelos, comportamientos, horario_activo, prioridad)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        params.nombre,
        params.tipo or 'general',
        params.centro.x,
        params.centro.y,
        params.centro.z,
        params.radio or 100.0,
        params.densidadMax or 10,
        params.densidadMin or 2,
        params.tiposNPC and json.encode(params.tiposNPC) or nil,
        params.modelos and json.encode(params.modelos) or nil,
        params.comportamientos and json.encode(params.comportamientos) or nil,
        params.horario and json.encode(params.horario) or nil,
        params.prioridad or 1,
    })

    if zonaId then
        Spawner.zonasActivas[zonaId] = {
            id = zonaId,
            nombre = params.nombre,
            tipo = params.tipo or 'general',
            centro = params.centro,
            radio = params.radio or 100.0,
            densidadMax = params.densidadMax or 10,
            densidadMin = params.densidadMin or 2,
            tiposNPC = params.tiposNPC or { 'civil' },
            modelos = params.modelos,
            comportamientos = params.comportamientos,
            horario = params.horario,
            prioridad = params.prioridad or 1,
            activa = true,
        }
        Spawner.npcsPorZona[zonaId] = {}
        Spawner.jugadoresPorZona[zonaId] = {}

        if AIT.Log then
            AIT.Log.info('AI:SPAWNER', ('Zona creada: %s (ID: %d)'):format(params.nombre, zonaId))
        end
    end

    return zonaId
end

--- Elimina una zona de spawn
---@param zonaId number
---@return boolean
function Spawner.EliminarZona(zonaId)
    -- Despawnear todos los NPCs de la zona
    local npcs = Spawner.npcsPorZona[zonaId] or {}
    local AI = AIT.Engines.AI

    for identificador, _ in pairs(npcs) do
        AI.Despawn(identificador, false)
    end

    -- Eliminar de BD
    MySQL.query([[
        DELETE FROM ait_npc_zonas WHERE zona_id = ?
    ]], { zonaId })

    -- Limpiar memoria
    Spawner.zonasActivas[zonaId] = nil
    Spawner.npcsPorZona[zonaId] = nil
    Spawner.jugadoresPorZona[zonaId] = nil

    return true
end

--- Cuenta las zonas activas
---@return number
function Spawner.ContarZonas()
    local total = 0
    for _ in pairs(Spawner.zonasActivas) do
        total = total + 1
    end
    return total
end

-- =====================================================================================
-- CONTROL DE POBLACION
-- =====================================================================================

--- Calcula la densidad objetivo para una zona
---@param zona table
---@return number
function Spawner.CalcularDensidadObjetivo(zona)
    local densidad = zona.densidadMax

    -- Factor por hora del dia
    if Spawner.config.horarioAfecta then
        local hora = tonumber(os.date('%H'))

        -- Reducir densidad en horario nocturno
        if hora >= 22 or hora < 6 then
            densidad = densidad * 0.3
        elseif hora >= 6 and hora < 9 then
            densidad = densidad * 0.7
        elseif hora >= 18 and hora < 22 then
            densidad = densidad * 0.8
        end

        -- Verificar horario especifico de la zona
        if zona.horario then
            if hora < zona.horario.inicio or hora >= zona.horario.fin then
                densidad = densidad * 0.2
            end
        end
    end

    -- Factor por numero de jugadores en zona
    local jugadoresEnZona = Spawner.ContarJugadoresEnZona(zona.id)
    if jugadoresEnZona > 0 then
        -- Mas jugadores = mas NPCs (hasta el maximo)
        densidad = math.min(densidad, zona.densidadMin + (jugadoresEnZona * 3))
    else
        -- Sin jugadores = densidad minima o cero
        densidad = 0
    end

    -- Aplicar factor global
    densidad = densidad * Spawner.config.factorDensidad

    -- Respetar limites
    densidad = math.max(0, math.min(zona.densidadMax, densidad))

    return math.floor(densidad)
end

--- Cuenta jugadores en una zona
---@param zonaId number
---@return number
function Spawner.ContarJugadoresEnZona(zonaId)
    local jugadores = Spawner.jugadoresPorZona[zonaId] or {}
    local total = 0
    for _ in pairs(jugadores) do
        total = total + 1
    end
    return total
end

--- Cuenta NPCs en una zona
---@param zonaId number
---@return number
function Spawner.ContarNPCsEnZona(zonaId)
    local npcs = Spawner.npcsPorZona[zonaId] or {}
    local total = 0
    for _ in pairs(npcs) do
        total = total + 1
    end
    return total
end

--- Cuenta total de NPCs spawneados
---@return number
function Spawner.ContarNPCsTotales()
    local AI = AIT.Engines.AI
    return AI.ContarSpawneados()
end

-- =====================================================================================
-- SPAWNING
-- =====================================================================================

--- Spawner NPCs en una zona
---@param zona table
---@param cantidad number
function Spawner.SpawnEnZona(zona, cantidad)
    local AI = AIT.Engines.AI

    for i = 1, cantidad do
        -- Verificar limite global
        if Spawner.ContarNPCsTotales() >= Spawner.config.limiteGlobal then
            if AIT.Log then
                AIT.Log.debug('AI:SPAWNER', 'Limite global alcanzado')
            end
            break
        end

        -- Generar posicion aleatoria dentro de la zona
        local posicion = Spawner.GenerarPosicionEnZona(zona)

        -- Seleccionar tipo de NPC
        local tipoNPC = Spawner.SeleccionarTipoNPC(zona)

        -- Seleccionar modelo
        local modelo = Spawner.SeleccionarModelo(zona, tipoNPC)

        -- Seleccionar comportamiento
        local comportamiento = Spawner.SeleccionarComportamiento(zona, tipoNPC)

        -- Crear NPC
        local npc, identificador = AI.Crear({
            tipo = tipoNPC,
            modelo = modelo,
            posicion = posicion,
            rotacion = math.random(0, 359),
            zona_id = zona.id,
            comportamiento = comportamiento,
            persistente = false,
        })

        if npc then
            -- Registrar en zona
            if not Spawner.npcsPorZona[zona.id] then
                Spawner.npcsPorZona[zona.id] = {}
            end
            Spawner.npcsPorZona[zona.id][identificador] = true

            -- Obtener cliente cercano para spawn
            local clienteCercano = AI.ObtenerClienteMasCercano(posicion)
            if clienteCercano then
                AI.Spawn(identificador, clienteCercano)
            end
        end

        -- Delay entre spawns para no saturar
        Wait(Spawner.config.delaySpawn)
    end
end

--- Genera una posicion aleatoria dentro de una zona
---@param zona table
---@return vector3
function Spawner.GenerarPosicionEnZona(zona)
    local intentos = 0
    local maxIntentos = 10

    while intentos < maxIntentos do
        local angulo = math.random() * math.pi * 2
        local distancia = math.sqrt(math.random()) * zona.radio -- sqrt para distribucion uniforme

        local x = zona.centro.x + math.cos(angulo) * distancia
        local y = zona.centro.y + math.sin(angulo) * distancia
        local z = zona.centro.z

        -- Aqui se podria validar que la posicion sea valida (no en agua, etc.)
        -- Por ahora retornamos directamente
        return vector3(x, y, z)
    end

    return zona.centro
end

--- Selecciona un tipo de NPC para la zona
---@param zona table
---@return string
function Spawner.SeleccionarTipoNPC(zona)
    local tipos = zona.tiposNPC or { 'civil' }
    return tipos[math.random(#tipos)]
end

--- Selecciona un modelo para el NPC
---@param zona table
---@param tipoNPC string
---@return string
function Spawner.SeleccionarModelo(zona, tipoNPC)
    local AI = AIT.Engines.AI

    -- Modelos especificos de zona
    if zona.modelos and #zona.modelos > 0 then
        return zona.modelos[math.random(#zona.modelos)]
    end

    -- Modelos por tipo
    local modelosPorTipo = AI.ModelosDefault[tipoNPC]
    if modelosPorTipo then
        return modelosPorTipo[math.random(#modelosPorTipo)]
    end

    -- Default civil
    local genero = math.random() > 0.5 and 'civil_masculino' or 'civil_femenino'
    local modelos = AI.ModelosDefault[genero]
    return modelos[math.random(#modelos)]
end

--- Selecciona un comportamiento para el NPC
---@param zona table
---@param tipoNPC string
---@return string
function Spawner.SeleccionarComportamiento(zona, tipoNPC)
    local AI = AIT.Engines.AI

    -- Comportamientos especificos de zona
    if zona.comportamientos and #zona.comportamientos > 0 then
        return zona.comportamientos[math.random(#zona.comportamientos)]
    end

    -- Comportamiento por tipo
    local tipoConfig = AI.TiposNPC[tipoNPC]
    if tipoConfig then
        return tipoConfig.comportamientoDefault
    end

    return 'idle'
end

-- =====================================================================================
-- DESPAWNING
-- =====================================================================================

--- Despawnea NPCs de una zona
---@param zona table
---@param cantidad number
function Spawner.DespawnDeZona(zona, cantidad)
    local AI = AIT.Engines.AI
    local npcs = Spawner.npcsPorZona[zona.id] or {}

    local despawneados = 0
    local aDespawnear = {}

    -- Recolectar NPCs a despawnear (los mas lejanos de jugadores)
    for identificador, _ in pairs(npcs) do
        local npc = AI.Obtener(identificador)
        if npc and npc.estado == 'spawned' and not npc.persistente then
            local distanciaMinima = Spawner.ObtenerDistanciaMinJugador(npc.posicion)
            table.insert(aDespawnear, {
                identificador = identificador,
                distancia = distanciaMinima,
            })
        end
    end

    -- Ordenar por distancia (mas lejanos primero)
    table.sort(aDespawnear, function(a, b)
        return a.distancia > b.distancia
    end)

    -- Despawnear
    for i = 1, math.min(cantidad, #aDespawnear) do
        local npcData = aDespawnear[i]
        if AI.Despawn(npcData.identificador, false) then
            Spawner.npcsPorZona[zona.id][npcData.identificador] = nil
            despawneados = despawneados + 1
        end
    end

    return despawneados
end

--- Obtiene la distancia minima a cualquier jugador
---@param posicion vector3
---@return number
function Spawner.ObtenerDistanciaMinJugador(posicion)
    local jugadores = GetPlayers()
    local distanciaMin = 999999

    for _, playerId in ipairs(jugadores) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            local distancia = #(posicion - playerCoords)
            if distancia < distanciaMin then
                distanciaMin = distancia
            end
        end
    end

    return distanciaMin
end

-- =====================================================================================
-- BALANCEO
-- =====================================================================================

--- Balancea la poblacion de NPCs en todas las zonas
function Spawner.BalancearZonas()
    if Spawner.procesando or not Spawner.activo then
        return
    end

    Spawner.procesando = true

    for zonaId, zona in pairs(Spawner.zonasActivas) do
        if zona.activa then
            local densidadObjetivo = Spawner.CalcularDensidadObjetivo(zona)
            local densidadActual = Spawner.ContarNPCsEnZona(zonaId)

            local diferencia = densidadObjetivo - densidadActual

            if diferencia > 0 then
                -- Necesitamos mas NPCs
                Spawner.SpawnEnZona(zona, diferencia)
            elseif diferencia < 0 then
                -- Tenemos demasiados NPCs
                Spawner.DespawnDeZona(zona, -diferencia)
            end
        end
    end

    Spawner.procesando = false
end

--- Despawnea NPCs fuera de rango de todos los jugadores
function Spawner.DespawnFueraDeRango()
    local AI = AIT.Engines.AI

    for identificador, npc in pairs(AI.npcsActivos) do
        if npc.estado == 'spawned' and not npc.persistente then
            local distanciaMin = Spawner.ObtenerDistanciaMinJugador(npc.posicion)

            if distanciaMin > Spawner.config.distanciaDespawn then
                AI.Despawn(identificador, false)

                -- Remover de zona
                if npc.zona_id and Spawner.npcsPorZona[npc.zona_id] then
                    Spawner.npcsPorZona[npc.zona_id][identificador] = nil
                end
            end
        end
    end
end

-- =====================================================================================
-- TRACKING DE JUGADORES
-- =====================================================================================

--- Callback cuando un jugador entra en una zona
---@param source number
---@param zonaId number
function Spawner.JugadorEntraZona(source, zonaId)
    if not Spawner.jugadoresPorZona[zonaId] then
        Spawner.jugadoresPorZona[zonaId] = {}
    end

    Spawner.jugadoresPorZona[zonaId][source] = true

    if AIT.Log then
        AIT.Log.debug('AI:SPAWNER', ('Jugador %d entro en zona %d'):format(source, zonaId))
    end

    -- Trigger spawn inmediato si la zona esta vacia
    local zona = Spawner.zonasActivas[zonaId]
    if zona then
        local npcsEnZona = Spawner.ContarNPCsEnZona(zonaId)
        if npcsEnZona < zona.densidadMin then
            Spawner.SpawnEnZona(zona, zona.densidadMin - npcsEnZona)
        end
    end
end

--- Callback cuando un jugador sale de una zona
---@param source number
---@param zonaId number
function Spawner.JugadorSaleZona(source, zonaId)
    if Spawner.jugadoresPorZona[zonaId] then
        Spawner.jugadoresPorZona[zonaId][source] = nil
    end

    if AIT.Log then
        AIT.Log.debug('AI:SPAWNER', ('Jugador %d salio de zona %d'):format(source, zonaId))
    end

    -- Si no quedan jugadores en la zona, programar despawn gradual
    local jugadoresRestantes = Spawner.ContarJugadoresEnZona(zonaId)
    if jugadoresRestantes == 0 then
        SetTimeout(10000, function()
            -- Verificar de nuevo
            if Spawner.ContarJugadoresEnZona(zonaId) == 0 then
                local zona = Spawner.zonasActivas[zonaId]
                if zona and not zona.persistente then
                    local npcsEnZona = Spawner.ContarNPCsEnZona(zonaId)
                    Spawner.DespawnDeZona(zona, npcsEnZona)
                end
            end
        end)
    end
end

--- Actualiza las zonas de todos los jugadores
function Spawner.ActualizarZonasJugadores()
    local jugadores = GetPlayers()

    -- Limpiar jugadores desconectados
    for zonaId, jugadoresZona in pairs(Spawner.jugadoresPorZona) do
        for source, _ in pairs(jugadoresZona) do
            local encontrado = false
            for _, playerId in ipairs(jugadores) do
                if tonumber(playerId) == source then
                    encontrado = true
                    break
                end
            end
            if not encontrado then
                Spawner.jugadoresPorZona[zonaId][source] = nil
            end
        end
    end

    -- Actualizar posiciones
    for _, playerId in ipairs(jugadores) do
        local source = tonumber(playerId)
        local ped = GetPlayerPed(source)

        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)

            -- Verificar en que zonas esta
            for zonaId, zona in pairs(Spawner.zonasActivas) do
                local distancia = #(playerCoords - zona.centro)
                local estaEnZona = distancia <= zona.radio

                local estaba = Spawner.jugadoresPorZona[zonaId] and Spawner.jugadoresPorZona[zonaId][source]

                if estaEnZona and not estaba then
                    Spawner.JugadorEntraZona(source, zonaId)
                elseif not estaEnZona and estaba then
                    Spawner.JugadorSaleZona(source, zonaId)
                end
            end
        end
    end
end

-- =====================================================================================
-- THREADS
-- =====================================================================================

function Spawner.IniciarThreadPrincipal()
    CreateThread(function()
        while true do
            Wait(Spawner.config.intervaloChequeo)

            if Spawner.activo then
                -- Actualizar zonas de jugadores
                Spawner.ActualizarZonasJugadores()

                -- Despawnear fuera de rango
                Spawner.DespawnFueraDeRango()
            end
        end
    end)
end

function Spawner.IniciarThreadBalance()
    CreateThread(function()
        while true do
            Wait(10000) -- Cada 10 segundos

            if Spawner.activo then
                Spawner.BalancearZonas()
            end
        end
    end)
end

-- =====================================================================================
-- CONTROL DEL SISTEMA
-- =====================================================================================

--- Activa el spawner
function Spawner.Activar()
    Spawner.activo = true
    if AIT.Log then
        AIT.Log.info('AI:SPAWNER', 'Spawner activado')
    end
end

--- Desactiva el spawner
function Spawner.Desactivar()
    Spawner.activo = false
    if AIT.Log then
        AIT.Log.info('AI:SPAWNER', 'Spawner desactivado')
    end
end

--- Cambia el factor de densidad global
---@param factor number
function Spawner.SetFactorDensidad(factor)
    Spawner.config.factorDensidad = math.max(0, math.min(2.0, factor))
    if AIT.Log then
        AIT.Log.info('AI:SPAWNER', ('Factor de densidad cambiado a: %.2f'):format(factor))
    end
end

--- Obtiene estadisticas del spawner
---@return table
function Spawner.ObtenerEstadisticas()
    local stats = {
        activo = Spawner.activo,
        zonasActivas = Spawner.ContarZonas(),
        npcsTotales = Spawner.ContarNPCsTotales(),
        limiteGlobal = Spawner.config.limiteGlobal,
        factorDensidad = Spawner.config.factorDensidad,
        zonas = {},
    }

    for zonaId, zona in pairs(Spawner.zonasActivas) do
        stats.zonas[zonaId] = {
            nombre = zona.nombre,
            tipo = zona.tipo,
            npcs = Spawner.ContarNPCsEnZona(zonaId),
            jugadores = Spawner.ContarJugadoresEnZona(zonaId),
            densidadMax = zona.densidadMax,
            densidadObjetivo = Spawner.CalcularDensidadObjetivo(zona),
        }
    end

    return stats
end

--- Limpia todos los NPCs spawneados
function Spawner.LimpiarTodo()
    local AI = AIT.Engines.AI

    for identificador, npc in pairs(AI.npcsActivos) do
        if npc.estado == 'spawned' and not npc.persistente then
            AI.Despawn(identificador, false)
        end
    end

    -- Limpiar registros de zonas
    for zonaId, _ in pairs(Spawner.npcsPorZona) do
        Spawner.npcsPorZona[zonaId] = {}
    end

    if AIT.Log then
        AIT.Log.info('AI:SPAWNER', 'Todos los NPCs no persistentes han sido despawneados')
    end
end

-- =====================================================================================
-- COMANDOS
-- =====================================================================================

RegisterCommand('spawnerstats', function(source, args, rawCommand)
    if source > 0 then
        if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.admin') then
            TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
            return
        end
    end

    local stats = Spawner.ObtenerEstadisticas()
    local msg = ([[
        === SPAWNER STATS ===
        Activo: %s
        Zonas: %d
        NPCs Totales: %d / %d
        Factor Densidad: %.2f
    ]]):format(
        stats.activo and 'Si' or 'No',
        stats.zonasActivas,
        stats.npcsTotales,
        stats.limiteGlobal,
        stats.factorDensidad
    )

    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { 'AI', msg } })
    else
        print(msg)
    end
end, false)

RegisterCommand('spawnertoggle', function(source, args, rawCommand)
    if source > 0 then
        if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.admin') then
            TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
            return
        end
    end

    if Spawner.activo then
        Spawner.Desactivar()
    else
        Spawner.Activar()
    end

    local msg = 'Spawner ' .. (Spawner.activo and 'activado' or 'desactivado')
    if source > 0 then
        TriggerClientEvent('QBCore:Notify', source, msg, 'success')
    else
        print(msg)
    end
end, false)

RegisterCommand('spawnerdensidad', function(source, args, rawCommand)
    if source > 0 then
        if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.admin') then
            TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
            return
        end
    end

    local factor = tonumber(args[1])
    if not factor then
        local msg = 'Uso: /spawnerdensidad [0.0 - 2.0]'
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, msg, 'error')
        else
            print(msg)
        end
        return
    end

    Spawner.SetFactorDensidad(factor)

    local msg = ('Factor de densidad: %.2f'):format(Spawner.config.factorDensidad)
    if source > 0 then
        TriggerClientEvent('QBCore:Notify', source, msg, 'success')
    else
        print(msg)
    end
end, false)

RegisterCommand('spawnerlimpiar', function(source, args, rawCommand)
    if source > 0 then
        if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.admin') then
            TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
            return
        end
    end

    Spawner.LimpiarTodo()

    local msg = 'NPCs limpiados'
    if source > 0 then
        TriggerClientEvent('QBCore:Notify', source, msg, 'success')
    else
        print(msg)
    end
end, false)

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Zonas
Spawner.CreateZone = Spawner.CrearZona
Spawner.DeleteZone = Spawner.EliminarZona
Spawner.GetZones = function() return Spawner.zonasActivas end

-- Control
Spawner.Enable = Spawner.Activar
Spawner.Disable = Spawner.Desactivar
Spawner.SetDensity = Spawner.SetFactorDensidad
Spawner.GetStats = Spawner.ObtenerEstadisticas
Spawner.ClearAll = Spawner.LimpiarTodo

-- Balance
Spawner.Balance = Spawner.BalancearZonas
Spawner.PlayerEnterZone = Spawner.JugadorEntraZona
Spawner.PlayerExitZone = Spawner.JugadorSaleZona

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.AI.Spawner = Spawner

return Spawner
