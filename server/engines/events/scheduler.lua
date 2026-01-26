-- =============================================================================
-- ait-qb EVENTS SCHEDULER
-- Programador de eventos del servidor
-- Horarios, frecuencias, condiciones
-- Eventos especiales por fecha
-- =============================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Events = AIT.Engines.Events or {}

local EventScheduler = {
    -- Eventos programados
    programados = {},

    -- Plantillas de eventos
    plantillas = {},

    -- Fechas especiales
    fechasEspeciales = {},

    -- Estado
    activo = true,
    ultimoTick = 0,
    intervaloTick = 60000,  -- Verificar cada minuto

    -- Configuración
    config = {
        minJugadoresAutoEvento = 5,
        maxEventosAutoPorHora = 3,
        horasActivas = { inicio = 8, fin = 2 },  -- 8:00 AM a 2:00 AM
        diasSemanaActivos = { 1, 2, 3, 4, 5, 6, 7 }  -- Todos los días
    },

    -- Contadores para límites
    contadores = {
        eventosEstaHora = 0,
        ultimaHora = 0
    }
}

-- =============================================================================
-- CONFIGURACIÓN DE HORARIOS
-- =============================================================================

EventScheduler.Horarios = {
    -- Eventos diarios
    diarios = {
        {
            nombre = 'Suministros Matutinos',
            tipo = 'drop_zone',
            hora = 10,
            minuto = 0,
            dias = { 1, 2, 3, 4, 5, 6, 7 },
            habilitado = true,
            config = {
                recompensaMultiplier = 1.2
            }
        },
        {
            nombre = 'Carrera del Mediodía',
            tipo = 'carrera',
            hora = 13,
            minuto = 30,
            dias = { 1, 2, 3, 4, 5, 6, 7 },
            habilitado = true,
            config = {}
        },
        {
            nombre = 'Cacería Vespertina',
            tipo = 'caceria',
            hora = 18,
            minuto = 0,
            dias = { 1, 2, 3, 4, 5, 6, 7 },
            habilitado = true,
            config = {}
        },
        {
            nombre = 'Evento Nocturno',
            tipo = 'king_of_hill',
            hora = 22,
            minuto = 0,
            dias = { 5, 6, 7 },  -- Viernes, Sábado, Domingo
            habilitado = true,
            config = {
                recompensaMultiplier = 1.5
            }
        },
        {
            nombre = 'Búsqueda del Tesoro Nocturna',
            tipo = 'busqueda_tesoro',
            hora = 0,
            minuto = 30,
            dias = { 6, 7 },  -- Sábado y Domingo
            habilitado = true,
            config = {
                recompensaMultiplier = 2.0
            }
        }
    },

    -- Eventos semanales
    semanales = {
        {
            nombre = 'Gran Torneo Semanal',
            tipo = 'torneo',
            diaSemana = 7,  -- Domingo
            hora = 20,
            minuto = 0,
            habilitado = true,
            config = {
                duracion = 3600,
                recompensaBase = 100000
            }
        },
        {
            nombre = 'Invasión del Fin de Semana',
            tipo = 'invasion',
            diaSemana = 6,  -- Sábado
            hora = 21,
            minuto = 0,
            habilitado = true,
            config = {}
        }
    },

    -- Eventos aleatorios (probabilidad por hora)
    aleatorios = {
        {
            tipo = 'drop_zone',
            probabilidad = 0.15,  -- 15% por hora
            cooldownMinutos = 45,
            horasPreferidas = { 12, 15, 18, 21 },
            habilitado = true
        },
        {
            tipo = 'desafio',
            probabilidad = 0.25,
            cooldownMinutos = 30,
            horasPreferidas = nil,  -- Cualquier hora
            habilitado = true
        },
        {
            tipo = 'caceria',
            probabilidad = 0.10,
            cooldownMinutos = 90,
            horasPreferidas = { 19, 20, 21, 22, 23 },
            habilitado = true
        }
    }
}

-- =============================================================================
-- FECHAS ESPECIALES
-- =============================================================================

EventScheduler.FechasEspeciales = {
    -- Año Nuevo
    ['01-01'] = {
        nombre = 'Celebración de Año Nuevo',
        eventos = {
            { tipo = 'drop_zone', hora = 0, config = { recompensaMultiplier = 3.0, nombre = 'Suministros de Año Nuevo' } },
            { tipo = 'busqueda_tesoro', hora = 12, config = { recompensaMultiplier = 2.5 } },
            { tipo = 'torneo', hora = 20, config = { recompensaMultiplier = 3.0, inscripcion = 0 } }
        },
        modificadores = {
            recompensaGlobal = 1.5,
            experienciaExtra = 2.0
        }
    },

    -- San Valentín
    ['02-14'] = {
        nombre = 'Evento de San Valentín',
        eventos = {
            { tipo = 'busqueda_tesoro', hora = 18, config = { nombre = 'Búsqueda del Corazón', recompensaMultiplier = 2.0 } }
        },
        modificadores = {
            recompensaGlobal = 1.25
        }
    },

    -- Semana Santa (aproximado)
    ['04-09'] = {
        nombre = 'Evento de Pascua',
        eventos = {
            { tipo = 'busqueda_tesoro', hora = 10, config = { nombre = 'Búsqueda de Huevos', recompensaMultiplier = 2.0 } },
            { tipo = 'busqueda_tesoro', hora = 16, config = { nombre = 'Gran Búsqueda de Pascua', recompensaMultiplier = 2.5 } }
        },
        modificadores = {}
    },

    -- Día del Trabajador
    ['05-01'] = {
        nombre = 'Día del Trabajador',
        eventos = {
            { tipo = 'desafio', hora = 12, config = { nombre = 'Desafío del Trabajador', recompensaMultiplier = 2.0 } }
        },
        modificadores = {
            recompensaGlobal = 1.5
        }
    },

    -- Halloween
    ['10-31'] = {
        nombre = 'Noche de Halloween',
        eventos = {
            { tipo = 'caceria', hora = 20, config = { nombre = 'Cacería de Monstruos', recompensaMultiplier = 2.5 } },
            { tipo = 'invasion', hora = 22, config = { nombre = 'Invasión Zombie', recompensaMultiplier = 3.0 } },
            { tipo = 'busqueda_tesoro', hora = 0, config = { nombre = 'Tesoro Maldito', recompensaMultiplier = 2.0 } }
        },
        modificadores = {
            recompensaGlobal = 1.5,
            atmosferaEspecial = 'halloween'
        }
    },

    -- Navidad
    ['12-25'] = {
        nombre = 'Navidad',
        eventos = {
            { tipo = 'drop_zone', hora = 10, config = { nombre = 'Regalos de Santa', recompensaMultiplier = 3.0 } },
            { tipo = 'busqueda_tesoro', hora = 14, config = { nombre = 'Tesoro Navideño', recompensaMultiplier = 2.5 } },
            { tipo = 'desafio', hora = 18, config = { nombre = 'Desafío de Navidad', recompensaMultiplier = 2.0 } }
        },
        modificadores = {
            recompensaGlobal = 2.0,
            experienciaExtra = 2.0,
            atmosferaEspecial = 'navidad'
        }
    },

    -- Nochevieja
    ['12-31'] = {
        nombre = 'Nochevieja',
        eventos = {
            { tipo = 'torneo', hora = 21, config = { nombre = 'Torneo de Fin de Año', recompensaMultiplier = 3.0 } },
            { tipo = 'king_of_hill', hora = 23, config = { nombre = 'Rey del Año', recompensaMultiplier = 2.5 } }
        },
        modificadores = {
            recompensaGlobal = 1.75
        }
    }
}

-- =============================================================================
-- INICIALIZACIÓN
-- =============================================================================

function EventScheduler.Inicializar()
    -- Cargar eventos programados de BD
    EventScheduler.CargarProgramados()

    -- Cargar plantillas personalizadas
    EventScheduler.CargarPlantillas()

    -- Iniciar loop principal
    EventScheduler.IniciarLoop()

    -- Registrar en scheduler global
    if AIT.Scheduler then
        AIT.Scheduler.CadaMs('event_scheduler_tick', EventScheduler.Tick, EventScheduler.intervaloTick)

        -- Resetear contadores cada hora
        AIT.Scheduler.Cron('event_scheduler_reset', EventScheduler.ResetearContadores, '0 * * * *')
    end

    if AIT.Log then
        AIT.Log.info('EVENTS.SCHEDULER', 'Programador de eventos inicializado')
    end

    return true
end

function EventScheduler.CargarProgramados()
    local programados = MySQL.query.await([[
        SELECT * FROM ait_scheduled_events
        WHERE habilitado = 1
        ORDER BY proxima_ejecucion ASC
    ]])

    for _, p in ipairs(programados or {}) do
        p.config = p.config and json.decode(p.config) or {}
        EventScheduler.programados[p.id] = p
    end
end

function EventScheduler.CargarPlantillas()
    local plantillas = MySQL.query.await([[
        SELECT * FROM ait_event_templates
        WHERE activa = 1
    ]])

    for _, t in ipairs(plantillas or {}) do
        t.config = t.config and json.decode(t.config) or {}
        t.datos = t.datos and json.decode(t.datos) or {}
        EventScheduler.plantillas[t.id] = t
    end
end

-- =============================================================================
-- LOOP PRINCIPAL
-- =============================================================================

function EventScheduler.IniciarLoop()
    CreateThread(function()
        while true do
            Wait(EventScheduler.intervaloTick)
            if EventScheduler.activo then
                EventScheduler.Tick()
            end
        end
    end)
end

function EventScheduler.Tick()
    local ahora = os.time()
    local fecha = os.date('*t', ahora)

    -- Verificar si estamos en horas activas
    if not EventScheduler.EstaEnHorasActivas(fecha.hour) then
        return
    end

    -- Verificar si hay suficientes jugadores
    local jugadores = #GetPlayers()
    if jugadores < EventScheduler.config.minJugadoresAutoEvento then
        return
    end

    -- Actualizar contador de hora
    if fecha.hour ~= EventScheduler.contadores.ultimaHora then
        EventScheduler.contadores.ultimaHora = fecha.hour
        EventScheduler.contadores.eventosEstaHora = 0
    end

    -- Verificar límite por hora
    if EventScheduler.contadores.eventosEstaHora >= EventScheduler.config.maxEventosAutoPorHora then
        return
    end

    -- Procesar eventos programados
    EventScheduler.ProcesarProgramados(fecha)

    -- Procesar eventos diarios
    EventScheduler.ProcesarDiarios(fecha)

    -- Procesar eventos semanales
    EventScheduler.ProcesarSemanales(fecha)

    -- Procesar fechas especiales
    EventScheduler.ProcesarFechasEspeciales(fecha)

    -- Procesar eventos aleatorios
    EventScheduler.ProcesarAleatorios(fecha, jugadores)

    EventScheduler.ultimoTick = ahora
end

-- =============================================================================
-- PROCESAMIENTO DE EVENTOS
-- =============================================================================

function EventScheduler.ProcesarProgramados(fecha)
    local ahora = os.time()

    for id, programado in pairs(EventScheduler.programados) do
        if programado.habilitado and programado.proxima_ejecucion then
            local proximaEjecucion = programado.proxima_ejecucion
            if type(proximaEjecucion) == 'string' then
                -- Convertir de formato MySQL
                local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
                local y, m, d, h, min, s = proximaEjecucion:match(pattern)
                if y then
                    proximaEjecucion = os.time({
                        year = tonumber(y), month = tonumber(m), day = tonumber(d),
                        hour = tonumber(h), min = tonumber(min), sec = tonumber(s)
                    })
                end
            end

            if proximaEjecucion and ahora >= proximaEjecucion then
                EventScheduler.EjecutarProgramado(programado)

                -- Calcular próxima ejecución si es recurrente
                if programado.recurrente and programado.intervalo_segundos then
                    programado.proxima_ejecucion = ahora + programado.intervalo_segundos
                    MySQL.update([[
                        UPDATE ait_scheduled_events
                        SET proxima_ejecucion = FROM_UNIXTIME(?), ultima_ejecucion = NOW()
                        WHERE id = ?
                    ]], { programado.proxima_ejecucion, id })
                else
                    -- Desactivar si no es recurrente
                    programado.habilitado = false
                    MySQL.update([[
                        UPDATE ait_scheduled_events
                        SET habilitado = 0, ultima_ejecucion = NOW()
                        WHERE id = ?
                    ]], { id })
                end
            end
        end
    end
end

function EventScheduler.ProcesarDiarios(fecha)
    for _, horario in ipairs(EventScheduler.Horarios.diarios) do
        if horario.habilitado then
            -- Verificar día de la semana
            local diaValido = false
            for _, dia in ipairs(horario.dias) do
                if dia == fecha.wday then
                    diaValido = true
                    break
                end
            end

            if diaValido and fecha.hour == horario.hora and fecha.min == horario.minuto then
                -- Verificar que no se haya ejecutado ya
                local clave = string.format('diario_%s_%d_%d', horario.tipo, fecha.yday, fecha.hour)
                if not EventScheduler.YaEjecutado(clave) then
                    EventScheduler.CrearEventoDesdeHorario(horario)
                    EventScheduler.MarcarEjecutado(clave)
                end
            end
        end
    end
end

function EventScheduler.ProcesarSemanales(fecha)
    for _, horario in ipairs(EventScheduler.Horarios.semanales) do
        if horario.habilitado then
            if fecha.wday == horario.diaSemana and
               fecha.hour == horario.hora and
               fecha.min == horario.minuto then

                local clave = string.format('semanal_%s_%d', horario.tipo, fecha.yday)
                if not EventScheduler.YaEjecutado(clave) then
                    EventScheduler.CrearEventoDesdeHorario(horario)
                    EventScheduler.MarcarEjecutado(clave)
                end
            end
        end
    end
end

function EventScheduler.ProcesarFechasEspeciales(fecha)
    local claveFecha = string.format('%02d-%02d', fecha.month, fecha.day)
    local fechaEspecial = EventScheduler.FechasEspeciales[claveFecha]

    if fechaEspecial then
        for _, eventoConfig in ipairs(fechaEspecial.eventos) do
            if fecha.hour == eventoConfig.hora and fecha.min == 0 then
                local clave = string.format('especial_%s_%s_%d', claveFecha, eventoConfig.tipo, fecha.hour)
                if not EventScheduler.YaEjecutado(clave) then
                    local config = eventoConfig.config or {}
                    config.esEventoEspecial = true
                    config.nombreFecha = fechaEspecial.nombre

                    -- Aplicar modificadores globales
                    if fechaEspecial.modificadores and fechaEspecial.modificadores.recompensaGlobal then
                        config.recompensaMultiplier = (config.recompensaMultiplier or 1.0) *
                                                       fechaEspecial.modificadores.recompensaGlobal
                    end

                    EventScheduler.CrearEvento(eventoConfig.tipo, config)
                    EventScheduler.MarcarEjecutado(clave)
                end
            end
        end
    end
end

function EventScheduler.ProcesarAleatorios(fecha, jugadores)
    for _, aleatorio in ipairs(EventScheduler.Horarios.aleatorios) do
        if aleatorio.habilitado then
            -- Verificar cooldown
            local cooldownKey = 'aleatorio_' .. aleatorio.tipo
            if EventScheduler.EnCooldown(cooldownKey) then
                goto continuar
            end

            -- Verificar horas preferidas
            local horaPreferida = true
            if aleatorio.horasPreferidas then
                horaPreferida = false
                for _, h in ipairs(aleatorio.horasPreferidas) do
                    if h == fecha.hour then
                        horaPreferida = true
                        break
                    end
                end
            end

            if horaPreferida then
                -- Calcular probabilidad ajustada por jugadores
                local probAjustada = aleatorio.probabilidad * (1 + (jugadores / 100))
                probAjustada = math.min(probAjustada, 0.5)  -- Máximo 50%

                if math.random() < probAjustada then
                    EventScheduler.CrearEvento(aleatorio.tipo, { automatico = true })
                    EventScheduler.EstablecerCooldown(cooldownKey, aleatorio.cooldownMinutos * 60)
                end
            end

            ::continuar::
        end
    end
end

-- =============================================================================
-- CREACIÓN DE EVENTOS
-- =============================================================================

function EventScheduler.CrearEventoDesdeHorario(horario)
    local config = horario.config or {}
    config.nombre = horario.nombre
    config.automatico = true

    return EventScheduler.CrearEvento(horario.tipo, config)
end

function EventScheduler.CrearEvento(tipo, config)
    config = config or {}

    -- Verificar que el engine de eventos esté disponible
    if not AIT.Engines.Events or not AIT.Engines.Events.Crear then
        if AIT.Log then
            AIT.Log.warn('EVENTS.SCHEDULER', 'Engine de eventos no disponible')
        end
        return nil
    end

    -- Crear el evento
    local eventoId, error = AIT.Engines.Events.Crear(tipo, config)

    if eventoId then
        EventScheduler.contadores.eventosEstaHora = EventScheduler.contadores.eventosEstaHora + 1

        -- Iniciar inscripción automáticamente
        AIT.Engines.Events.IniciarInscripcion(eventoId)

        if AIT.Log then
            AIT.Log.info('EVENTS.SCHEDULER', 'Evento programado creado', {
                id = eventoId,
                tipo = tipo
            })
        end

        -- Emitir evento
        if AIT.EventBus then
            AIT.EventBus.emit('events.scheduled.created', {
                eventoId = eventoId,
                tipo = tipo,
                automatico = config.automatico or false
            })
        end
    else
        if AIT.Log then
            AIT.Log.warn('EVENTS.SCHEDULER', 'Error al crear evento programado', {
                tipo = tipo,
                error = error
            })
        end
    end

    return eventoId
end

function EventScheduler.EjecutarProgramado(programado)
    return EventScheduler.CrearEvento(programado.tipo, programado.config)
end

-- =============================================================================
-- GESTIÓN DE PROGRAMADOS
-- =============================================================================

--- Programa un nuevo evento
---@param opciones table
---@return number|nil id
function EventScheduler.Programar(opciones)
    if not opciones.tipo then
        return nil, 'Se requiere un tipo de evento'
    end

    local proximaEjecucion = opciones.proximaEjecucion or os.time()

    local id = MySQL.insert.await([[
        INSERT INTO ait_scheduled_events
        (tipo, nombre, descripcion, config, proxima_ejecucion,
         recurrente, intervalo_segundos, habilitado, creado_por)
        VALUES (?, ?, ?, ?, FROM_UNIXTIME(?), ?, ?, 1, ?)
    ]], {
        opciones.tipo,
        opciones.nombre or 'Evento Programado',
        opciones.descripcion,
        json.encode(opciones.config or {}),
        proximaEjecucion,
        opciones.recurrente or false,
        opciones.intervaloSegundos,
        opciones.creadoPor
    })

    local programado = {
        id = id,
        tipo = opciones.tipo,
        nombre = opciones.nombre,
        descripcion = opciones.descripcion,
        config = opciones.config or {},
        proxima_ejecucion = proximaEjecucion,
        recurrente = opciones.recurrente or false,
        intervalo_segundos = opciones.intervaloSegundos,
        habilitado = true
    }

    EventScheduler.programados[id] = programado

    return id
end

--- Cancela un evento programado
---@param id number
---@return boolean
function EventScheduler.CancelarProgramado(id)
    if not EventScheduler.programados[id] then
        return false
    end

    EventScheduler.programados[id].habilitado = false

    MySQL.update([[
        UPDATE ait_scheduled_events SET habilitado = 0 WHERE id = ?
    ]], { id })

    return true
end

--- Obtiene los eventos programados
---@return table
function EventScheduler.ObtenerProgramados()
    local lista = {}
    for id, p in pairs(EventScheduler.programados) do
        if p.habilitado then
            table.insert(lista, {
                id = id,
                tipo = p.tipo,
                nombre = p.nombre,
                proximaEjecucion = p.proxima_ejecucion,
                recurrente = p.recurrente
            })
        end
    end

    table.sort(lista, function(a, b)
        return (a.proximaEjecucion or 0) < (b.proximaEjecucion or 0)
    end)

    return lista
end

-- =============================================================================
-- GESTIÓN DE PLANTILLAS
-- =============================================================================

--- Crea una plantilla de evento
---@param opciones table
---@return number|nil id
function EventScheduler.CrearPlantilla(opciones)
    local id = MySQL.insert.await([[
        INSERT INTO ait_event_templates
        (nombre, tipo, descripcion, config, datos, activa, creado_por)
        VALUES (?, ?, ?, ?, ?, 1, ?)
    ]], {
        opciones.nombre,
        opciones.tipo,
        opciones.descripcion,
        json.encode(opciones.config or {}),
        json.encode(opciones.datos or {}),
        opciones.creadoPor
    })

    local plantilla = {
        id = id,
        nombre = opciones.nombre,
        tipo = opciones.tipo,
        descripcion = opciones.descripcion,
        config = opciones.config or {},
        datos = opciones.datos or {},
        activa = true
    }

    EventScheduler.plantillas[id] = plantilla

    return id
end

--- Crea un evento desde una plantilla
---@param plantillaId number
---@param sobreescribirConfig? table
---@return number|nil eventoId
function EventScheduler.CrearDesdePlantilla(plantillaId, sobreescribirConfig)
    local plantilla = EventScheduler.plantillas[plantillaId]
    if not plantilla then
        return nil, 'Plantilla no encontrada'
    end

    local config = {}
    -- Copiar config de plantilla
    for k, v in pairs(plantilla.config) do
        config[k] = v
    end
    -- Sobreescribir con config adicional
    if sobreescribirConfig then
        for k, v in pairs(sobreescribirConfig) do
            config[k] = v
        end
    end

    config.nombre = config.nombre or plantilla.nombre
    config.descripcion = config.descripcion or plantilla.descripcion

    return EventScheduler.CrearEvento(plantilla.tipo, config)
end

--- Obtiene las plantillas disponibles
---@return table
function EventScheduler.ObtenerPlantillas()
    local lista = {}
    for id, t in pairs(EventScheduler.plantillas) do
        if t.activa then
            table.insert(lista, {
                id = id,
                nombre = t.nombre,
                tipo = t.tipo,
                descripcion = t.descripcion
            })
        end
    end
    return lista
end

-- =============================================================================
-- UTILIDADES
-- =============================================================================

-- Cache de ejecuciones (para evitar duplicados)
local cacheEjecuciones = {}
local cacheCooldowns = {}

function EventScheduler.YaEjecutado(clave)
    return cacheEjecuciones[clave] == true
end

function EventScheduler.MarcarEjecutado(clave)
    cacheEjecuciones[clave] = true

    -- Limpiar después de 24 horas
    SetTimeout(86400000, function()
        cacheEjecuciones[clave] = nil
    end)
end

function EventScheduler.EnCooldown(clave)
    return cacheCooldowns[clave] and cacheCooldowns[clave] > os.time()
end

function EventScheduler.EstablecerCooldown(clave, segundos)
    cacheCooldowns[clave] = os.time() + segundos
end

function EventScheduler.EstaEnHorasActivas(hora)
    local inicio = EventScheduler.config.horasActivas.inicio
    local fin = EventScheduler.config.horasActivas.fin

    if inicio < fin then
        return hora >= inicio and hora < fin
    else
        -- Rango que cruza medianoche (ej: 8:00 - 2:00)
        return hora >= inicio or hora < fin
    end
end

function EventScheduler.ResetearContadores()
    EventScheduler.contadores.eventosEstaHora = 0
end

-- =============================================================================
-- API DE CONFIGURACIÓN
-- =============================================================================

--- Configura el scheduler
---@param nuevaConfig table
function EventScheduler.Configurar(nuevaConfig)
    for k, v in pairs(nuevaConfig) do
        if EventScheduler.config[k] ~= nil then
            EventScheduler.config[k] = v
        end
    end
end

--- Pausa el scheduler
function EventScheduler.Pausar()
    EventScheduler.activo = false
    if AIT.Log then
        AIT.Log.info('EVENTS.SCHEDULER', 'Scheduler pausado')
    end
end

--- Reanuda el scheduler
function EventScheduler.Reanudar()
    EventScheduler.activo = true
    if AIT.Log then
        AIT.Log.info('EVENTS.SCHEDULER', 'Scheduler reanudado')
    end
end

--- Obtiene el estado del scheduler
---@return table
function EventScheduler.ObtenerEstado()
    return {
        activo = EventScheduler.activo,
        ultimoTick = EventScheduler.ultimoTick,
        eventosEstaHora = EventScheduler.contadores.eventosEstaHora,
        maxEventosPorHora = EventScheduler.config.maxEventosAutoPorHora,
        programadosActivos = 0,
        plantillasActivas = 0
    }
end

-- =============================================================================
-- REGISTRO
-- =============================================================================

AIT.Engines.Events.Scheduler = EventScheduler

return EventScheduler
