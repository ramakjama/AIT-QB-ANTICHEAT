-- =============================================================================
-- ait-qb ENGINE DE EVENTOS
-- Sistema completo de eventos del servidor
-- Eventos programados, aleatorios, administrativos
-- Drop zones, carreras, cacerías, desafíos
-- Recompensas, participantes, rankings
-- Optimizado para 2048 slots
-- =============================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Events = AIT.Engines.Events or {}

local Events = {
    -- Estado interno
    activos = {},                    -- Eventos actualmente activos
    participantes = {},              -- Participantes por evento
    rankings = {},                   -- Rankings por evento
    historial = {},                  -- Historial de eventos
    cooldowns = {},                  -- Cooldowns por tipo de evento

    -- Configuración de procesamiento
    procesamientoBatch = 50,         -- Eventos a procesar por ciclo
    intervaloTick = 1000,            -- Intervalo de tick en ms
    maxEventosActivos = 10,          -- Máximo eventos simultáneos
    maxHistorial = 500,              -- Máximo en historial

    -- Contadores
    contadorId = 0,
    estadisticas = {
        eventosCreados = 0,
        eventosCompletados = 0,
        eventosCancelados = 0,
        participacionesTotales = 0,
        recompensasEntregadas = 0,
        dineroDistribuido = 0
    }
}

-- =============================================================================
-- CONFIGURACIÓN DE EVENTOS
-- =============================================================================

Events.Configuracion = {
    -- Tipos de eventos predefinidos
    tipos = {
        drop_zone = {
            nombre = 'Zona de Suministros',
            descripcion = 'Recoge los suministros antes que los demás',
            duracionMin = 300,       -- 5 minutos mínimo
            duracionMax = 900,       -- 15 minutos máximo
            cooldown = 1800,         -- 30 minutos entre eventos
            minJugadores = 2,
            maxJugadores = 50,
            recompensaBase = 5000,
            recompensaMultiplier = 1.5,
            requiereAdmin = false,
            automatico = true
        },
        carrera = {
            nombre = 'Carrera Callejera',
            descripcion = 'Compite en una carrera ilegal',
            duracionMin = 180,
            duracionMax = 600,
            cooldown = 2400,
            minJugadores = 2,
            maxJugadores = 20,
            recompensaBase = 10000,
            recompensaMultiplier = 2.0,
            requiereAdmin = false,
            automatico = true,
            inscripcion = 2500       -- Costo de inscripción
        },
        caceria = {
            nombre = 'Cacería de Objetivos',
            descripcion = 'Elimina objetivos marcados',
            duracionMin = 600,
            duracionMax = 1200,
            cooldown = 3600,
            minJugadores = 5,
            maxJugadores = 100,
            recompensaBase = 15000,
            recompensaMultiplier = 2.5,
            requiereAdmin = false,
            automatico = true
        },
        desafio = {
            nombre = 'Desafío del Servidor',
            descripcion = 'Completa el desafío propuesto',
            duracionMin = 120,
            duracionMax = 600,
            cooldown = 1200,
            minJugadores = 1,
            maxJugadores = 200,
            recompensaBase = 2500,
            recompensaMultiplier = 1.2,
            requiereAdmin = false,
            automatico = true
        },
        torneo = {
            nombre = 'Torneo',
            descripcion = 'Participa en el torneo oficial',
            duracionMin = 1800,
            duracionMax = 7200,
            cooldown = 86400,        -- 24 horas
            minJugadores = 8,
            maxJugadores = 64,
            recompensaBase = 50000,
            recompensaMultiplier = 3.0,
            requiereAdmin = true,
            automatico = false,
            inscripcion = 10000
        },
        invasion = {
            nombre = 'Invasión',
            descripcion = 'Defiende la ciudad de la invasión',
            duracionMin = 900,
            duracionMax = 1800,
            cooldown = 7200,
            minJugadores = 10,
            maxJugadores = 200,
            recompensaBase = 8000,
            recompensaMultiplier = 1.8,
            requiereAdmin = false,
            automatico = true
        },
        busqueda_tesoro = {
            nombre = 'Búsqueda del Tesoro',
            descripcion = 'Encuentra las pistas y el tesoro',
            duracionMin = 600,
            duracionMax = 1800,
            cooldown = 5400,
            minJugadores = 3,
            maxJugadores = 30,
            recompensaBase = 20000,
            recompensaMultiplier = 2.2,
            requiereAdmin = false,
            automatico = true
        },
        king_of_hill = {
            nombre = 'Rey de la Colina',
            descripcion = 'Controla el área más tiempo',
            duracionMin = 300,
            duracionMax = 900,
            cooldown = 2700,
            minJugadores = 4,
            maxJugadores = 40,
            recompensaBase = 12000,
            recompensaMultiplier = 2.0,
            requiereAdmin = false,
            automatico = true
        }
    },

    -- Estados de evento
    estados = {
        PENDIENTE = 'pendiente',
        INSCRIPCION = 'inscripcion',
        ACTIVO = 'activo',
        FINALIZANDO = 'finalizando',
        COMPLETADO = 'completado',
        CANCELADO = 'cancelado'
    },

    -- Distribución de premios por posición
    distribucionPremios = {
        [1] = 0.50,   -- 50% para el primero
        [2] = 0.25,   -- 25% para el segundo
        [3] = 0.15,   -- 15% para el tercero
        [4] = 0.05,   -- 5% para el cuarto
        [5] = 0.05    -- 5% para el quinto
    },

    -- Bonificaciones
    bonificaciones = {
        participacion = 0.10,        -- 10% extra por participar
        racha = 0.05,                -- 5% extra por cada evento consecutivo
        primerLugar = 0.20,          -- 20% extra para primer lugar
        mvp = 0.15                   -- 15% extra para MVP
    }
}

-- =============================================================================
-- INICIALIZACIÓN
-- =============================================================================

function Events.Inicializar()
    -- Cargar eventos activos de BD
    Events.CargarEventosActivos()

    -- Cargar historial reciente
    Events.CargarHistorial()

    -- Registrar tareas programadas
    if AIT.Scheduler then
        -- Tick principal de eventos
        AIT.Scheduler.CadaMs('eventos_tick', Events.Tick, Events.intervaloTick)

        -- Limpieza de historial
        AIT.Scheduler.Cron('eventos_limpieza', Events.LimpiarHistorial, '0 4 * * *')

        -- Estadísticas diarias
        AIT.Scheduler.Cron('eventos_stats_diarias', Events.GuardarEstadisticasDiarias, '0 0 * * *')
    end

    -- Suscribirse a eventos del bus
    if AIT.EventBus then
        AIT.EventBus.on('player.disconnected', Events.OnJugadorDesconectado)
        AIT.EventBus.on('events.*', Events.OnEventoInterno)
    end

    -- Iniciar loop principal
    Events.IniciarLoop()

    if AIT.Log then
        AIT.Log.info('EVENTS', 'Engine de eventos inicializado')
    end

    return true
end

function Events.CargarEventosActivos()
    local eventos = MySQL.query.await([[
        SELECT * FROM ait_events
        WHERE estado IN ('activo', 'inscripcion', 'pendiente')
        ORDER BY creado_en DESC
    ]])

    for _, evento in ipairs(eventos or {}) do
        evento.datos = evento.datos and json.decode(evento.datos) or {}
        evento.config = evento.config and json.decode(evento.config) or {}
        Events.activos[evento.id] = evento

        -- Cargar participantes
        Events.CargarParticipantesEvento(evento.id)
    end
end

function Events.CargarParticipantesEvento(eventoId)
    local participantes = MySQL.query.await([[
        SELECT * FROM ait_event_participants
        WHERE evento_id = ? AND activo = 1
    ]], { eventoId })

    Events.participantes[eventoId] = {}
    for _, p in ipairs(participantes or {}) do
        p.datos = p.datos and json.decode(p.datos) or {}
        Events.participantes[eventoId][p.char_id] = p
    end
end

function Events.CargarHistorial()
    local historial = MySQL.query.await([[
        SELECT * FROM ait_events
        WHERE estado IN ('completado', 'cancelado')
        ORDER BY finalizado_en DESC
        LIMIT ?
    ]], { Events.maxHistorial })

    for _, evento in ipairs(historial or {}) do
        evento.datos = evento.datos and json.decode(evento.datos) or {}
        table.insert(Events.historial, evento)
    end
end

-- =============================================================================
-- CREACIÓN DE EVENTOS
-- =============================================================================

--- Crea un nuevo evento
---@param tipo string Tipo de evento
---@param opciones table Opciones del evento
---@return number|nil eventoId
---@return string|nil error
function Events.Crear(tipo, opciones)
    opciones = opciones or {}

    -- Validar tipo
    local tipoConfig = Events.Configuracion.tipos[tipo]
    if not tipoConfig then
        return nil, 'Tipo de evento no válido'
    end

    -- Verificar cooldown
    if Events.cooldowns[tipo] and Events.cooldowns[tipo] > os.time() then
        local restante = Events.cooldowns[tipo] - os.time()
        return nil, string.format('Evento en cooldown (%d segundos restantes)', restante)
    end

    -- Verificar máximo de eventos activos
    local activos = 0
    for _ in pairs(Events.activos) do
        activos = activos + 1
    end
    if activos >= Events.maxEventosActivos then
        return nil, 'Máximo de eventos activos alcanzado'
    end

    -- Verificar permisos de admin si es necesario
    if tipoConfig.requiereAdmin and not opciones.forzarAdmin then
        return nil, 'Este evento requiere permisos de administrador'
    end

    -- Generar ID
    Events.contadorId = Events.contadorId + 1

    -- Calcular duración
    local duracion = opciones.duracion or math.random(tipoConfig.duracionMin, tipoConfig.duracionMax)

    -- Calcular recompensa base
    local recompensaBase = opciones.recompensaBase or tipoConfig.recompensaBase

    -- Crear evento
    local evento = {
        id = nil,  -- Se asignará en BD
        tipo = tipo,
        nombre = opciones.nombre or tipoConfig.nombre,
        descripcion = opciones.descripcion or tipoConfig.descripcion,
        estado = Events.Configuracion.estados.PENDIENTE,

        -- Tiempos
        duracion = duracion,
        tiempoInscripcion = opciones.tiempoInscripcion or 120,  -- 2 minutos
        creadoEn = os.time(),
        inicioEn = nil,
        finalizaEn = nil,

        -- Participación
        minJugadores = opciones.minJugadores or tipoConfig.minJugadores,
        maxJugadores = opciones.maxJugadores or tipoConfig.maxJugadores,
        inscripcion = opciones.inscripcion or tipoConfig.inscripcion or 0,

        -- Recompensas
        recompensaBase = recompensaBase,
        recompensaMultiplier = opciones.multiplier or tipoConfig.recompensaMultiplier,
        pozo = 0,

        -- Ubicación
        zona = opciones.zona,
        coords = opciones.coords,
        radio = opciones.radio or 100.0,

        -- Configuración específica
        config = opciones.config or {},

        -- Datos dinámicos
        datos = {
            objetivos = opciones.objetivos or {},
            checkpoints = opciones.checkpoints or {},
            items = opciones.items or {},
            spawns = opciones.spawns or {}
        },

        -- Admin
        creadoPor = opciones.creadoPor,
        esAutomatico = opciones.automatico or false
    }

    -- Insertar en BD
    local eventoId = MySQL.insert.await([[
        INSERT INTO ait_events
        (tipo, nombre, descripcion, estado, duracion, tiempo_inscripcion,
         min_jugadores, max_jugadores, inscripcion, recompensa_base,
         recompensa_multiplier, zona, coords, radio, config, datos,
         creado_por, es_automatico, creado_en)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        evento.tipo, evento.nombre, evento.descripcion, evento.estado,
        evento.duracion, evento.tiempoInscripcion, evento.minJugadores,
        evento.maxJugadores, evento.inscripcion, evento.recompensaBase,
        evento.recompensaMultiplier, evento.zona,
        evento.coords and json.encode(evento.coords), evento.radio,
        json.encode(evento.config), json.encode(evento.datos),
        evento.creadoPor, evento.esAutomatico
    })

    evento.id = eventoId
    Events.activos[eventoId] = evento
    Events.participantes[eventoId] = {}

    -- Estadísticas
    Events.estadisticas.eventosCreados = Events.estadisticas.eventosCreados + 1

    -- Emitir evento de creación
    if AIT.EventBus then
        AIT.EventBus.emit('events.created', {
            eventoId = eventoId,
            tipo = tipo,
            nombre = evento.nombre
        })
    end

    if AIT.Log then
        AIT.Log.info('EVENTS', 'Evento creado', {
            id = eventoId,
            tipo = tipo,
            nombre = evento.nombre
        })
    end

    return eventoId, nil
end

--- Inicia la fase de inscripción de un evento
---@param eventoId number
---@return boolean
function Events.IniciarInscripcion(eventoId)
    local evento = Events.activos[eventoId]
    if not evento then return false end

    if evento.estado ~= Events.Configuracion.estados.PENDIENTE then
        return false
    end

    evento.estado = Events.Configuracion.estados.INSCRIPCION
    evento.inscripcionIniciaEn = os.time()
    evento.inscripcionFinalizaEn = os.time() + evento.tiempoInscripcion

    -- Actualizar BD
    MySQL.update.await([[
        UPDATE ait_events SET
            estado = ?,
            inscripcion_inicia_en = NOW(),
            inscripcion_finaliza_en = DATE_ADD(NOW(), INTERVAL ? SECOND)
        WHERE id = ?
    ]], { evento.estado, evento.tiempoInscripcion, eventoId })

    -- Notificar a todos los jugadores
    Events.NotificarGlobal(evento, 'inscripcion_abierta')

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.inscription_started', {
            eventoId = eventoId,
            tipo = evento.tipo,
            duracion = evento.tiempoInscripcion
        })
    end

    return true
end

--- Inicia un evento activo
---@param eventoId number
---@return boolean
function Events.Iniciar(eventoId)
    local evento = Events.activos[eventoId]
    if not evento then return false end

    -- Verificar estado
    if evento.estado ~= Events.Configuracion.estados.INSCRIPCION and
       evento.estado ~= Events.Configuracion.estados.PENDIENTE then
        return false
    end

    -- Verificar mínimo de jugadores
    local numParticipantes = Events.ContarParticipantes(eventoId)
    if numParticipantes < evento.minJugadores then
        Events.Cancelar(eventoId, 'Insuficientes participantes')
        return false
    end

    evento.estado = Events.Configuracion.estados.ACTIVO
    evento.inicioEn = os.time()
    evento.finalizaEn = os.time() + evento.duracion

    -- Calcular pozo total
    evento.pozo = evento.recompensaBase + (evento.inscripcion * numParticipantes)

    -- Actualizar BD
    MySQL.update.await([[
        UPDATE ait_events SET
            estado = ?,
            inicio_en = NOW(),
            finaliza_en = DATE_ADD(NOW(), INTERVAL ? SECOND),
            pozo = ?
        WHERE id = ?
    ]], { evento.estado, evento.duracion, evento.pozo, eventoId })

    -- Notificar participantes
    Events.NotificarParticipantes(eventoId, 'evento_iniciado', {
        duracion = evento.duracion,
        pozo = evento.pozo
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.started', {
            eventoId = eventoId,
            tipo = evento.tipo,
            participantes = numParticipantes,
            pozo = evento.pozo
        })
    end

    if AIT.Log then
        AIT.Log.info('EVENTS', 'Evento iniciado', {
            id = eventoId,
            participantes = numParticipantes,
            pozo = evento.pozo
        })
    end

    return true
end

-- =============================================================================
-- PARTICIPACIÓN
-- =============================================================================

--- Inscribe a un jugador en un evento
---@param eventoId number
---@param source number
---@param charId number
---@return boolean, string|nil
function Events.Inscribir(eventoId, source, charId)
    local evento = Events.activos[eventoId]
    if not evento then
        return false, 'Evento no encontrado'
    end

    -- Verificar estado
    if evento.estado ~= Events.Configuracion.estados.INSCRIPCION and
       evento.estado ~= Events.Configuracion.estados.PENDIENTE then
        return false, 'Las inscripciones están cerradas'
    end

    -- Verificar si ya está inscrito
    if Events.participantes[eventoId] and Events.participantes[eventoId][charId] then
        return false, 'Ya estás inscrito en este evento'
    end

    -- Verificar máximo de participantes
    local numParticipantes = Events.ContarParticipantes(eventoId)
    if numParticipantes >= evento.maxJugadores then
        return false, 'El evento está lleno'
    end

    -- Verificar si ya está en otro evento activo del mismo tipo
    for id, ev in pairs(Events.activos) do
        if id ~= eventoId and ev.tipo == evento.tipo then
            if Events.participantes[id] and Events.participantes[id][charId] then
                return false, 'Ya estás participando en otro evento similar'
            end
        end
    end

    -- Cobrar inscripción si aplica
    if evento.inscripcion > 0 then
        if AIT.Engines.economy then
            local success, err = AIT.Engines.economy.RemoveMoney(
                source, charId, evento.inscripcion, 'bank',
                'event_inscription', 'Inscripción evento: ' .. evento.nombre
            )
            if not success then
                return false, 'No tienes suficiente dinero para la inscripción'
            end
        end
    end

    -- Crear participante
    local participante = {
        eventoId = eventoId,
        charId = charId,
        source = source,
        inscritoEn = os.time(),
        activo = true,
        puntos = 0,
        posicion = 0,
        checkpoints = 0,
        objetivos = 0,
        datos = {}
    }

    -- Insertar en BD
    local participanteId = MySQL.insert.await([[
        INSERT INTO ait_event_participants
        (evento_id, char_id, source_id, inscrito_en, activo)
        VALUES (?, ?, ?, NOW(), 1)
    ]], { eventoId, charId, source })

    participante.id = participanteId

    if not Events.participantes[eventoId] then
        Events.participantes[eventoId] = {}
    end
    Events.participantes[eventoId][charId] = participante

    -- Estadísticas
    Events.estadisticas.participacionesTotales = Events.estadisticas.participacionesTotales + 1

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.player_joined', {
            eventoId = eventoId,
            charId = charId,
            totalParticipantes = numParticipantes + 1
        })
    end

    -- Notificar al jugador
    TriggerClientEvent('ait:events:inscrito', source, {
        eventoId = eventoId,
        nombre = evento.nombre,
        tipo = evento.tipo
    })

    return true, nil
end

--- Retira a un jugador de un evento
---@param eventoId number
---@param charId number
---@param razon? string
---@return boolean
function Events.Retirar(eventoId, charId, razon)
    local evento = Events.activos[eventoId]
    if not evento then return false end

    local participante = Events.participantes[eventoId] and Events.participantes[eventoId][charId]
    if not participante then return false end

    participante.activo = false
    participante.retiradoEn = os.time()
    participante.razonRetiro = razon

    -- Actualizar BD
    MySQL.update.await([[
        UPDATE ait_event_participants SET
            activo = 0,
            retirado_en = NOW(),
            razon_retiro = ?
        WHERE evento_id = ? AND char_id = ?
    ]], { razon, eventoId, charId })

    -- Si el evento no ha iniciado, devolver inscripción
    if evento.estado == Events.Configuracion.estados.INSCRIPCION and evento.inscripcion > 0 then
        if AIT.Engines.economy and participante.source then
            AIT.Engines.economy.AddMoney(
                participante.source, charId, evento.inscripcion, 'bank',
                'event_refund', 'Reembolso inscripción: ' .. evento.nombre
            )
        end
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.player_left', {
            eventoId = eventoId,
            charId = charId,
            razon = razon
        })
    end

    return true
end

--- Actualiza los puntos de un participante
---@param eventoId number
---@param charId number
---@param puntos number
---@param tipo? string 'add' o 'set'
---@return boolean
function Events.ActualizarPuntos(eventoId, charId, puntos, tipo)
    tipo = tipo or 'add'

    local participante = Events.participantes[eventoId] and Events.participantes[eventoId][charId]
    if not participante or not participante.activo then return false end

    if tipo == 'add' then
        participante.puntos = participante.puntos + puntos
    else
        participante.puntos = puntos
    end

    -- Actualizar BD
    MySQL.update([[
        UPDATE ait_event_participants SET puntos = ?
        WHERE evento_id = ? AND char_id = ?
    ]], { participante.puntos, eventoId, charId })

    -- Recalcular rankings
    Events.RecalcularRanking(eventoId)

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.points_updated', {
            eventoId = eventoId,
            charId = charId,
            puntos = participante.puntos,
            posicion = participante.posicion
        })
    end

    return true
end

--- Registra un checkpoint completado
---@param eventoId number
---@param charId number
---@param checkpointId number|string
---@return boolean
function Events.RegistrarCheckpoint(eventoId, charId, checkpointId)
    local participante = Events.participantes[eventoId] and Events.participantes[eventoId][charId]
    if not participante or not participante.activo then return false end

    participante.checkpoints = participante.checkpoints + 1
    if not participante.datos.checkpointsCompletados then
        participante.datos.checkpointsCompletados = {}
    end
    table.insert(participante.datos.checkpointsCompletados, {
        id = checkpointId,
        tiempo = os.time()
    })

    -- Actualizar BD
    MySQL.update([[
        UPDATE ait_event_participants SET
            checkpoints = ?,
            datos = ?
        WHERE evento_id = ? AND char_id = ?
    ]], { participante.checkpoints, json.encode(participante.datos), eventoId, charId })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.checkpoint_completed', {
            eventoId = eventoId,
            charId = charId,
            checkpointId = checkpointId,
            total = participante.checkpoints
        })
    end

    return true
end

--- Registra un objetivo completado
---@param eventoId number
---@param charId number
---@param objetivoId number|string
---@param puntos? number
---@return boolean
function Events.RegistrarObjetivo(eventoId, charId, objetivoId, puntos)
    puntos = puntos or 100

    local participante = Events.participantes[eventoId] and Events.participantes[eventoId][charId]
    if not participante or not participante.activo then return false end

    participante.objetivos = participante.objetivos + 1
    if not participante.datos.objetivosCompletados then
        participante.datos.objetivosCompletados = {}
    end
    table.insert(participante.datos.objetivosCompletados, {
        id = objetivoId,
        tiempo = os.time(),
        puntos = puntos
    })

    -- Añadir puntos
    Events.ActualizarPuntos(eventoId, charId, puntos, 'add')

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.objective_completed', {
            eventoId = eventoId,
            charId = charId,
            objetivoId = objetivoId,
            puntos = puntos
        })
    end

    return true
end

-- =============================================================================
-- RANKINGS Y RESULTADOS
-- =============================================================================

--- Recalcula el ranking de un evento
---@param eventoId number
function Events.RecalcularRanking(eventoId)
    local participantes = Events.participantes[eventoId]
    if not participantes then return end

    -- Crear lista ordenable
    local lista = {}
    for charId, p in pairs(participantes) do
        if p.activo then
            table.insert(lista, {
                charId = charId,
                puntos = p.puntos,
                checkpoints = p.checkpoints,
                objetivos = p.objetivos,
                inscritoEn = p.inscritoEn
            })
        end
    end

    -- Ordenar por puntos (descendente), luego por checkpoints, luego por tiempo
    table.sort(lista, function(a, b)
        if a.puntos ~= b.puntos then
            return a.puntos > b.puntos
        elseif a.checkpoints ~= b.checkpoints then
            return a.checkpoints > b.checkpoints
        else
            return a.inscritoEn < b.inscritoEn
        end
    end)

    -- Asignar posiciones
    for i, item in ipairs(lista) do
        if participantes[item.charId] then
            participantes[item.charId].posicion = i
        end
    end

    -- Guardar ranking
    Events.rankings[eventoId] = lista
end

--- Obtiene el ranking actual de un evento
---@param eventoId number
---@param limite? number
---@return table
function Events.ObtenerRanking(eventoId, limite)
    limite = limite or 10

    Events.RecalcularRanking(eventoId)

    local ranking = Events.rankings[eventoId] or {}
    local resultado = {}

    for i = 1, math.min(limite, #ranking) do
        table.insert(resultado, ranking[i])
    end

    return resultado
end

-- =============================================================================
-- FINALIZACIÓN Y RECOMPENSAS
-- =============================================================================

--- Finaliza un evento
---@param eventoId number
---@param ganadorCharId? number
---@return boolean
function Events.Finalizar(eventoId, ganadorCharId)
    local evento = Events.activos[eventoId]
    if not evento then return false end

    if evento.estado ~= Events.Configuracion.estados.ACTIVO then
        return false
    end

    evento.estado = Events.Configuracion.estados.FINALIZANDO

    -- Recalcular ranking final
    Events.RecalcularRanking(eventoId)

    -- Determinar ganador si no se especificó
    local ranking = Events.rankings[eventoId] or {}
    if not ganadorCharId and #ranking > 0 then
        ganadorCharId = ranking[1].charId
    end

    -- Distribuir recompensas
    Events.DistribuirRecompensas(eventoId)

    -- Marcar como completado
    evento.estado = Events.Configuracion.estados.COMPLETADO
    evento.finalizadoEn = os.time()
    evento.ganadorCharId = ganadorCharId

    -- Actualizar BD
    MySQL.update.await([[
        UPDATE ait_events SET
            estado = ?,
            finalizado_en = NOW(),
            ganador_char_id = ?
        WHERE id = ?
    ]], { evento.estado, ganadorCharId, eventoId })

    -- Establecer cooldown
    local tipoConfig = Events.Configuracion.tipos[evento.tipo]
    if tipoConfig then
        Events.cooldowns[evento.tipo] = os.time() + tipoConfig.cooldown
    end

    -- Notificar
    Events.NotificarGlobal(evento, 'evento_finalizado', {
        ganador = ganadorCharId,
        ranking = ranking
    })

    -- Mover a historial
    table.insert(Events.historial, 1, evento)
    if #Events.historial > Events.maxHistorial then
        table.remove(Events.historial)
    end

    -- Remover de activos
    Events.activos[eventoId] = nil

    -- Estadísticas
    Events.estadisticas.eventosCompletados = Events.estadisticas.eventosCompletados + 1

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.completed', {
            eventoId = eventoId,
            tipo = evento.tipo,
            ganador = ganadorCharId,
            pozo = evento.pozo
        })
    end

    if AIT.Log then
        AIT.Log.info('EVENTS', 'Evento finalizado', {
            id = eventoId,
            ganador = ganadorCharId
        })
    end

    return true
end

--- Cancela un evento
---@param eventoId number
---@param razon? string
---@return boolean
function Events.Cancelar(eventoId, razon)
    local evento = Events.activos[eventoId]
    if not evento then return false end

    razon = razon or 'Cancelado por el sistema'

    evento.estado = Events.Configuracion.estados.CANCELADO
    evento.finalizadoEn = os.time()
    evento.razonCancelacion = razon

    -- Devolver inscripciones
    if evento.inscripcion > 0 then
        local participantes = Events.participantes[eventoId] or {}
        for charId, p in pairs(participantes) do
            if p.activo and AIT.Engines.economy then
                AIT.Engines.economy.AddMoney(
                    p.source, charId, evento.inscripcion, 'bank',
                    'event_refund', 'Reembolso por cancelación: ' .. evento.nombre
                )
            end
        end
    end

    -- Actualizar BD
    MySQL.update.await([[
        UPDATE ait_events SET
            estado = ?,
            finalizado_en = NOW(),
            razon_cancelacion = ?
        WHERE id = ?
    ]], { evento.estado, razon, eventoId })

    -- Notificar
    Events.NotificarGlobal(evento, 'evento_cancelado', { razon = razon })

    -- Mover a historial
    table.insert(Events.historial, 1, evento)
    Events.activos[eventoId] = nil

    -- Estadísticas
    Events.estadisticas.eventosCancelados = Events.estadisticas.eventosCancelados + 1

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('events.cancelled', {
            eventoId = eventoId,
            razon = razon
        })
    end

    return true
end

--- Distribuye las recompensas de un evento
---@param eventoId number
function Events.DistribuirRecompensas(eventoId)
    local evento = Events.activos[eventoId]
    if not evento then return end

    local ranking = Events.rankings[eventoId] or {}
    local pozo = evento.pozo or evento.recompensaBase
    local distribucion = Events.Configuracion.distribucionPremios

    for i, item in ipairs(ranking) do
        local participante = Events.participantes[eventoId] and Events.participantes[eventoId][item.charId]
        if participante and participante.activo then
            local porcentaje = distribucion[i] or 0
            local recompensa = math.floor(pozo * porcentaje)

            -- Aplicar bonificaciones
            if i == 1 then
                recompensa = math.floor(recompensa * (1 + Events.Configuracion.bonificaciones.primerLugar))
            end

            -- Bonus por participación
            local bonusParticipacion = math.floor(evento.recompensaBase * Events.Configuracion.bonificaciones.participacion)
            recompensa = recompensa + bonusParticipacion

            if recompensa > 0 and AIT.Engines.economy then
                local moneda = evento.config.monedaRecompensa or 'bank'
                AIT.Engines.economy.AddMoney(
                    participante.source, item.charId, recompensa, moneda,
                    'event_reward', string.format('%s - Posición #%d', evento.nombre, i)
                )

                -- Actualizar participante
                participante.recompensa = recompensa
                participante.posicionFinal = i

                -- BD
                MySQL.update([[
                    UPDATE ait_event_participants SET
                        recompensa = ?,
                        posicion_final = ?
                    WHERE evento_id = ? AND char_id = ?
                ]], { recompensa, i, eventoId, item.charId })

                -- Estadísticas
                Events.estadisticas.recompensasEntregadas = Events.estadisticas.recompensasEntregadas + 1
                Events.estadisticas.dineroDistribuido = Events.estadisticas.dineroDistribuido + recompensa

                -- Notificar al jugador
                if participante.source then
                    TriggerClientEvent('ait:events:recompensa', participante.source, {
                        eventoId = eventoId,
                        nombre = evento.nombre,
                        posicion = i,
                        recompensa = recompensa
                    })
                end
            end
        end
    end
end

-- =============================================================================
-- LOOP PRINCIPAL Y TICK
-- =============================================================================

function Events.IniciarLoop()
    CreateThread(function()
        while true do
            Wait(Events.intervaloTick)
            Events.Tick()
        end
    end)
end

function Events.Tick()
    local ahora = os.time()

    for eventoId, evento in pairs(Events.activos) do
        -- Verificar transición de inscripción a activo
        if evento.estado == Events.Configuracion.estados.INSCRIPCION then
            if evento.inscripcionFinalizaEn and ahora >= evento.inscripcionFinalizaEn then
                Events.Iniciar(eventoId)
            end
        end

        -- Verificar fin de evento
        if evento.estado == Events.Configuracion.estados.ACTIVO then
            if evento.finalizaEn and ahora >= evento.finalizaEn then
                Events.Finalizar(eventoId)
            end
        end

        -- Verificar eventos pendientes que deben iniciar inscripción
        if evento.estado == Events.Configuracion.estados.PENDIENTE then
            if evento.inicioInscripcionEn and ahora >= evento.inicioInscripcionEn then
                Events.IniciarInscripcion(eventoId)
            end
        end
    end
end

-- =============================================================================
-- NOTIFICACIONES
-- =============================================================================

function Events.NotificarGlobal(evento, tipo, datos)
    datos = datos or {}
    datos.eventoId = evento.id
    datos.tipo = evento.tipo
    datos.nombre = evento.nombre

    TriggerClientEvent('ait:events:notificacion', -1, tipo, datos)
end

function Events.NotificarParticipantes(eventoId, tipo, datos)
    local participantes = Events.participantes[eventoId]
    if not participantes then return end

    datos = datos or {}
    datos.eventoId = eventoId

    for charId, p in pairs(participantes) do
        if p.activo and p.source then
            TriggerClientEvent('ait:events:notificacion', p.source, tipo, datos)
        end
    end
end

-- =============================================================================
-- EVENTOS INTERNOS
-- =============================================================================

function Events.OnJugadorDesconectado(event)
    local charId = event.payload and event.payload.charId
    if not charId then return end

    -- Retirar de todos los eventos activos
    for eventoId, participantes in pairs(Events.participantes) do
        if participantes[charId] and participantes[charId].activo then
            Events.Retirar(eventoId, charId, 'Desconexión')
        end
    end
end

function Events.OnEventoInterno(event)
    -- Manejar eventos internos del sistema de eventos
end

-- =============================================================================
-- UTILIDADES
-- =============================================================================

function Events.ContarParticipantes(eventoId)
    local count = 0
    local participantes = Events.participantes[eventoId]
    if participantes then
        for _, p in pairs(participantes) do
            if p.activo then
                count = count + 1
            end
        end
    end
    return count
end

function Events.ObtenerEvento(eventoId)
    return Events.activos[eventoId]
end

function Events.ObtenerEventosActivos()
    local lista = {}
    for id, evento in pairs(Events.activos) do
        table.insert(lista, {
            id = id,
            tipo = evento.tipo,
            nombre = evento.nombre,
            estado = evento.estado,
            participantes = Events.ContarParticipantes(id),
            maxJugadores = evento.maxJugadores,
            pozo = evento.pozo,
            tiempoRestante = evento.finalizaEn and (evento.finalizaEn - os.time()) or nil
        })
    end
    return lista
end

function Events.ObtenerHistorial(limite)
    limite = limite or 20
    local resultado = {}
    for i = 1, math.min(limite, #Events.historial) do
        table.insert(resultado, Events.historial[i])
    end
    return resultado
end

function Events.ObtenerEstadisticas()
    return {
        eventosCreados = Events.estadisticas.eventosCreados,
        eventosCompletados = Events.estadisticas.eventosCompletados,
        eventosCancelados = Events.estadisticas.eventosCancelados,
        participacionesTotales = Events.estadisticas.participacionesTotales,
        recompensasEntregadas = Events.estadisticas.recompensasEntregadas,
        dineroDistribuido = Events.estadisticas.dineroDistribuido,
        eventosActivos = 0
    }
end

function Events.LimpiarHistorial()
    -- Limpiar eventos muy antiguos (más de 30 días)
    local limite = os.time() - (30 * 24 * 60 * 60)

    MySQL.query([[
        DELETE FROM ait_events
        WHERE estado IN ('completado', 'cancelado')
        AND finalizado_en < FROM_UNIXTIME(?)
    ]], { limite })

    MySQL.query([[
        DELETE FROM ait_event_participants
        WHERE evento_id NOT IN (SELECT id FROM ait_events)
    ]])
end

function Events.GuardarEstadisticasDiarias()
    local fecha = os.date('%Y-%m-%d')

    MySQL.insert([[
        INSERT INTO ait_events_daily_stats
        (fecha, eventos_creados, eventos_completados, eventos_cancelados,
         participaciones, recompensas, dinero_distribuido)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            eventos_creados = ?,
            eventos_completados = ?,
            eventos_cancelados = ?,
            participaciones = ?,
            recompensas = ?,
            dinero_distribuido = ?
    ]], {
        fecha,
        Events.estadisticas.eventosCreados,
        Events.estadisticas.eventosCompletados,
        Events.estadisticas.eventosCancelados,
        Events.estadisticas.participacionesTotales,
        Events.estadisticas.recompensasEntregadas,
        Events.estadisticas.dineroDistribuido,
        Events.estadisticas.eventosCreados,
        Events.estadisticas.eventosCompletados,
        Events.estadisticas.eventosCancelados,
        Events.estadisticas.participacionesTotales,
        Events.estadisticas.recompensasEntregadas,
        Events.estadisticas.dineroDistribuido
    })
end

-- =============================================================================
-- EXPORTS Y REGISTRO
-- =============================================================================

-- API Principal
Events.EventoCrear = Events.Crear
Events.EventoIniciar = Events.Iniciar
Events.EventoFinalizar = Events.Finalizar
Events.EventoCancelar = Events.Cancelar
Events.ParticipanteInscribir = Events.Inscribir
Events.ParticipanteRetirar = Events.Retirar
Events.PuntosActualizar = Events.ActualizarPuntos
Events.CheckpointRegistrar = Events.RegistrarCheckpoint
Events.ObjetivoRegistrar = Events.RegistrarObjetivo
Events.RankingObtener = Events.ObtenerRanking

-- Registrar engine
AIT.Engines.Events = Events

return Events
