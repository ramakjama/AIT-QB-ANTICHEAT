-- =====================================================================================
-- ait-qb TRACKER DE MISIONES
-- Sistema de seguimiento de progreso con objetivos parciales y notificaciones
-- Namespace: AIT.Engines.Missions.Tracker
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Missions = AIT.Engines.Missions or {}

local Tracker = {
    -- Progreso en tiempo real por mision
    progresoActivo = {},
    -- Checkpoints activos por jugador
    checkpointsActivos = {},
    -- Subscripciones a actualizaciones
    subscripciones = {},
    -- Cola de notificaciones pendientes
    colaNotificaciones = {},
    -- Configuracion de notificaciones
    configNotificaciones = {
        mostrarPorcentaje = true,
        intervaloPorcentaje = 25, -- Notificar cada 25%
        sonidoProgreso = true,
        sonidoCheckpoint = true,
        sonidoObjetivo = true,
    },
}

-- =====================================================================================
-- TIPOS DE OBJETIVOS
-- =====================================================================================

Tracker.TiposObjetivo = {
    ir_a = {
        nombre = 'Desplazarse',
        icono = 'fa-map-marker-alt',
        verificador = 'VerificarDistancia',
        parametros = { distancia_minima = 3.0 },
    },
    entregar = {
        nombre = 'Entregar',
        icono = 'fa-hand-holding',
        verificador = 'VerificarEntrega',
        parametros = { distancia_minima = 2.0, requiere_interaccion = true },
    },
    recoger = {
        nombre = 'Recoger',
        icono = 'fa-hand-rock',
        verificador = 'VerificarRecoleccion',
        parametros = { distancia_minima = 2.0, requiere_interaccion = true },
    },
    eliminar = {
        nombre = 'Eliminar',
        icono = 'fa-crosshairs',
        verificador = 'VerificarEliminacion',
        parametros = { contar_muertes = true },
    },
    escoltar_a = {
        nombre = 'Escoltar',
        icono = 'fa-users',
        verificador = 'VerificarEscolta',
        parametros = { distancia_maxima_npc = 30.0, verificar_salud_npc = true },
    },
    pasar_checkpoint = {
        nombre = 'Checkpoint',
        icono = 'fa-flag-checkered',
        verificador = 'VerificarCheckpoint',
        parametros = { distancia_minima = 8.0 },
    },
    sobrevivir = {
        nombre = 'Sobrevivir',
        icono = 'fa-heart',
        verificador = 'VerificarSupervivencia',
        parametros = { tiempo_segundos = 0 },
    },
    tiempo_limite = {
        nombre = 'Contrarreloj',
        icono = 'fa-clock',
        verificador = 'VerificarTiempo',
        parametros = { cronometro = true },
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Tracker.Initialize()
    -- Iniciar thread de actualizacion
    Tracker.IniciarThreadActualizacion()

    -- Iniciar thread de notificaciones
    Tracker.IniciarThreadNotificaciones()

    -- Registrar eventos del cliente
    Tracker.RegistrarEventos()

    if AIT.Log then
        AIT.Log.info('MISSIONS:TRACKER', 'Tracker de misiones inicializado')
    end

    return true
end

-- =====================================================================================
-- GESTION DE PROGRESO
-- =====================================================================================

--- Iniciar tracking de una mision
---@param misionId number
---@param charId number
---@param objetivos table
---@param checkpoints table
function Tracker.IniciarTracking(misionId, charId, objetivos, checkpoints)
    -- Inicializar estructura de progreso
    Tracker.progresoActivo[misionId] = {
        char_id = charId,
        mision_id = misionId,
        objetivos = {},
        checkpoints = {},
        objetivo_actual = 1,
        checkpoint_actual = 1,
        porcentaje_total = 0,
        ultimo_update = os.time(),
        pausado = false,
    }

    -- Procesar objetivos
    for i, objetivo in ipairs(objetivos) do
        Tracker.progresoActivo[misionId].objetivos[i] = {
            tipo = objetivo.tipo,
            descripcion = objetivo.descripcion,
            cantidad_requerida = objetivo.cantidad or 1,
            cantidad_actual = 0,
            completado = false,
            ubicacion = objetivo.ubicacion,
            metadata = objetivo.metadata or {},
            tiempo_inicio = nil,
            tiempo_fin = nil,
        }
    end

    -- Procesar checkpoints
    for i, checkpoint in ipairs(checkpoints) do
        Tracker.progresoActivo[misionId].checkpoints[i] = {
            x = checkpoint.x,
            y = checkpoint.y,
            z = checkpoint.z,
            tipo = checkpoint.tipo,
            radio = checkpoint.radio or 3.0,
            orden = checkpoint.orden or i,
            alcanzado = false,
            tiempo_alcanzado = nil,
        }
    end

    -- Inicializar checkpoints para el jugador
    if not Tracker.checkpointsActivos[charId] then
        Tracker.checkpointsActivos[charId] = {}
    end
    Tracker.checkpointsActivos[charId][misionId] = Tracker.progresoActivo[misionId].checkpoints

    -- Notificar inicio
    Tracker.EnviarNotificacion(charId, {
        tipo = 'mision_iniciada',
        titulo = 'Mision Iniciada',
        mensaje = ('Objetivo 1/%d: %s'):format(
            #objetivos,
            objetivos[1] and objetivos[1].descripcion or 'Completar mision'
        ),
        icono = 'fa-flag',
        duracion = 5000,
    })

    -- Enviar datos al cliente
    local source = Tracker.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:missions:tracker:init', source, {
            mision_id = misionId,
            objetivos = Tracker.progresoActivo[misionId].objetivos,
            checkpoints = Tracker.progresoActivo[misionId].checkpoints,
            objetivo_actual = 1,
        })
    end

    if AIT.Log then
        AIT.Log.debug('MISSIONS:TRACKER', ('Iniciado tracking mision %d para char %d'):format(misionId, charId))
    end
end

--- Detener tracking de una mision
---@param misionId number
function Tracker.DetenerTracking(misionId)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then return end

    local charId = progreso.char_id

    -- Limpiar checkpoints del jugador
    if Tracker.checkpointsActivos[charId] then
        Tracker.checkpointsActivos[charId][misionId] = nil
    end

    -- Notificar al cliente
    local source = Tracker.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:missions:tracker:stop', source, { mision_id = misionId })
    end

    -- Limpiar progreso
    Tracker.progresoActivo[misionId] = nil
end

--- Actualizar progreso de un objetivo
---@param misionId number
---@param objetivoIndex number
---@param cantidad number
---@param metadata table|nil
---@return boolean, string|nil
function Tracker.ActualizarProgreso(misionId, objetivoIndex, cantidad, metadata)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then
        return false, 'Mision no encontrada en tracker'
    end

    local objetivo = progreso.objetivos[objetivoIndex]
    if not objetivo then
        return false, 'Objetivo no encontrado'
    end

    if objetivo.completado then
        return false, 'Objetivo ya completado'
    end

    -- Actualizar cantidad
    local cantidadAnterior = objetivo.cantidad_actual
    objetivo.cantidad_actual = math.min(objetivo.cantidad_actual + cantidad, objetivo.cantidad_requerida)

    -- Registrar tiempo de inicio si es el primer progreso
    if cantidadAnterior == 0 and objetivo.cantidad_actual > 0 then
        objetivo.tiempo_inicio = os.time()
    end

    -- Verificar si se completo
    if objetivo.cantidad_actual >= objetivo.cantidad_requerida then
        objetivo.completado = true
        objetivo.tiempo_fin = os.time()

        -- Avanzar al siguiente objetivo
        if progreso.objetivo_actual == objetivoIndex then
            progreso.objetivo_actual = progreso.objetivo_actual + 1
        end

        -- Notificar objetivo completado
        Tracker.NotificarObjetivoCompletado(progreso.char_id, misionId, objetivoIndex, objetivo)
    else
        -- Notificar progreso parcial
        Tracker.NotificarProgresoParcial(progreso.char_id, misionId, objetivoIndex, objetivo)
    end

    -- Actualizar porcentaje total
    Tracker.RecalcularPorcentaje(misionId)

    -- Guardar en base de datos
    Tracker.GuardarProgreso(misionId)

    progreso.ultimo_update = os.time()

    return true
end

--- Marcar checkpoint como alcanzado
---@param misionId number
---@param checkpointIndex number
---@return boolean
function Tracker.MarcarCheckpoint(misionId, checkpointIndex)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then return false end

    local checkpoint = progreso.checkpoints[checkpointIndex]
    if not checkpoint or checkpoint.alcanzado then return false end

    checkpoint.alcanzado = true
    checkpoint.tiempo_alcanzado = os.time()

    -- Avanzar checkpoint actual
    if progreso.checkpoint_actual == checkpointIndex then
        progreso.checkpoint_actual = progreso.checkpoint_actual + 1
    end

    -- Notificar
    Tracker.EnviarNotificacion(progreso.char_id, {
        tipo = 'checkpoint',
        titulo = 'Checkpoint',
        mensaje = ('Checkpoint %d/%d alcanzado'):format(checkpointIndex, #progreso.checkpoints),
        icono = 'fa-flag-checkered',
        duracion = 3000,
        sonido = Tracker.configNotificaciones.sonidoCheckpoint,
    })

    -- Actualizar cliente
    local source = Tracker.ObtenerSourceDeCharId(progreso.char_id)
    if source then
        TriggerClientEvent('ait:missions:tracker:checkpoint', source, {
            mision_id = misionId,
            checkpoint_index = checkpointIndex,
            siguiente = progreso.checkpoint_actual,
        })
    end

    return true
end

--- Recalcular porcentaje total de progreso
function Tracker.RecalcularPorcentaje(misionId)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then return end

    local totalRequerido = 0
    local totalActual = 0

    for _, objetivo in pairs(progreso.objetivos) do
        totalRequerido = totalRequerido + objetivo.cantidad_requerida
        totalActual = totalActual + objetivo.cantidad_actual
    end

    local porcentajeAnterior = progreso.porcentaje_total
    progreso.porcentaje_total = totalRequerido > 0 and math.floor((totalActual / totalRequerido) * 100) or 0

    -- Notificar si cruzo un umbral de porcentaje
    if Tracker.configNotificaciones.mostrarPorcentaje then
        local intervalo = Tracker.configNotificaciones.intervaloPorcentaje
        local umbralAnterior = math.floor(porcentajeAnterior / intervalo)
        local umbralActual = math.floor(progreso.porcentaje_total / intervalo)

        if umbralActual > umbralAnterior and progreso.porcentaje_total < 100 then
            Tracker.EnviarNotificacion(progreso.char_id, {
                tipo = 'progreso',
                titulo = 'Progreso',
                mensaje = ('%d%% completado'):format(progreso.porcentaje_total),
                icono = 'fa-tasks',
                duracion = 2000,
                sonido = Tracker.configNotificaciones.sonidoProgreso,
            })
        end
    end
end

-- =====================================================================================
-- VERIFICADORES DE OBJETIVOS
-- =====================================================================================

--- Verificar distancia a ubicacion
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean
function Tracker.VerificarDistancia(charId, objetivo, datosCliente)
    if not objetivo.ubicacion or not datosCliente.posicion then
        return false
    end

    local dx = objetivo.ubicacion.x - datosCliente.posicion.x
    local dy = objetivo.ubicacion.y - datosCliente.posicion.y
    local dz = objetivo.ubicacion.z - datosCliente.posicion.z

    local distancia = math.sqrt(dx*dx + dy*dy + dz*dz)
    local distanciaMinima = Tracker.TiposObjetivo.ir_a.parametros.distancia_minima

    return distancia <= distanciaMinima
end

--- Verificar entrega de item
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean
function Tracker.VerificarEntrega(charId, objetivo, datosCliente)
    -- Primero verificar distancia
    if not Tracker.VerificarDistancia(charId, objetivo, datosCliente) then
        return false
    end

    -- Verificar si se realizo la interaccion
    return datosCliente.interaccion_completada == true
end

--- Verificar recoleccion de item
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean
function Tracker.VerificarRecoleccion(charId, objetivo, datosCliente)
    -- Primero verificar distancia
    if not Tracker.VerificarDistancia(charId, objetivo, datosCliente) then
        return false
    end

    -- Verificar si se realizo la interaccion
    return datosCliente.interaccion_completada == true
end

--- Verificar eliminacion de objetivo
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean, number
function Tracker.VerificarEliminacion(charId, objetivo, datosCliente)
    local eliminados = datosCliente.enemigos_eliminados or 0
    local requeridos = objetivo.cantidad_requerida

    return eliminados >= requeridos, eliminados
end

--- Verificar estado de escolta
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean, string|nil
function Tracker.VerificarEscolta(charId, objetivo, datosCliente)
    -- Verificar que el NPC sigue vivo
    if datosCliente.npc_muerto then
        return false, 'El objetivo de escolta ha muerto'
    end

    -- Verificar distancia al NPC
    if datosCliente.distancia_npc then
        local distanciaMaxima = Tracker.TiposObjetivo.escoltar_a.parametros.distancia_maxima_npc
        if datosCliente.distancia_npc > distanciaMaxima then
            return false, 'Te has alejado demasiado del objetivo'
        end
    end

    -- Verificar llegada al destino
    if objetivo.ubicacion and datosCliente.posicion_npc then
        local dx = objetivo.ubicacion.x - datosCliente.posicion_npc.x
        local dy = objetivo.ubicacion.y - datosCliente.posicion_npc.y
        local distancia = math.sqrt(dx*dx + dy*dy)

        return distancia <= 5.0
    end

    return false
end

--- Verificar paso por checkpoint
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean
function Tracker.VerificarCheckpoint(charId, objetivo, datosCliente)
    if not objetivo.ubicacion or not datosCliente.posicion then
        return false
    end

    local dx = objetivo.ubicacion.x - datosCliente.posicion.x
    local dy = objetivo.ubicacion.y - datosCliente.posicion.y

    local distancia = math.sqrt(dx*dx + dy*dy)
    local radioCheckpoint = Tracker.TiposObjetivo.pasar_checkpoint.parametros.distancia_minima

    return distancia <= radioCheckpoint
end

--- Verificar supervivencia
---@param charId number
---@param objetivo table
---@param datosCliente table
---@return boolean
function Tracker.VerificarSupervivencia(charId, objetivo, datosCliente)
    -- Verificar que el jugador sigue vivo
    if datosCliente.jugador_muerto then
        return false
    end

    -- Verificar tiempo transcurrido si es objetivo de tiempo
    if objetivo.metadata and objetivo.metadata.tiempo_objetivo then
        local tiempoTranscurrido = os.time() - (objetivo.tiempo_inicio or os.time())
        return tiempoTranscurrido >= objetivo.metadata.tiempo_objetivo
    end

    return true
end

-- =====================================================================================
-- NOTIFICACIONES
-- =====================================================================================

--- Notificar objetivo completado
function Tracker.NotificarObjetivoCompletado(charId, misionId, objetivoIndex, objetivo)
    local progreso = Tracker.progresoActivo[misionId]
    local totalObjetivos = progreso and #progreso.objetivos or 1

    local mensaje = ('Objetivo %d/%d completado: %s'):format(
        objetivoIndex,
        totalObjetivos,
        objetivo.descripcion
    )

    -- Verificar si es el ultimo objetivo
    local todosCompletados = true
    if progreso then
        for _, obj in pairs(progreso.objetivos) do
            if not obj.completado then
                todosCompletados = false
                break
            end
        end
    end

    if todosCompletados then
        mensaje = 'Todos los objetivos completados!'
    end

    Tracker.EnviarNotificacion(charId, {
        tipo = 'objetivo_completado',
        titulo = 'Objetivo Completado',
        mensaje = mensaje,
        icono = 'fa-check-circle',
        duracion = 4000,
        sonido = Tracker.configNotificaciones.sonidoObjetivo,
        color = '#4CAF50',
    })

    -- Actualizar UI del cliente
    local source = Tracker.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:missions:tracker:objective', source, {
            mision_id = misionId,
            objetivo_index = objetivoIndex,
            completado = true,
            siguiente = progreso and progreso.objetivo_actual or nil,
            todos_completados = todosCompletados,
        })
    end

    -- Si todos estan completados, notificar al engine principal
    if todosCompletados and AIT.Engines.Missions then
        -- Poner en cola la finalizacion
        if progreso then
            table.insert(AIT.Engines.Missions.colaProgreso, {
                mision_id = misionId,
                progreso = Tracker.ConvertirProgresoParaGuardado(misionId),
                objetivos_completados = totalObjetivos,
                estado = 'completada',
            })
        end
    end
end

--- Notificar progreso parcial
function Tracker.NotificarProgresoParcial(charId, misionId, objetivoIndex, objetivo)
    local porcentaje = math.floor((objetivo.cantidad_actual / objetivo.cantidad_requerida) * 100)

    -- Solo notificar en ciertos umbrales
    local umbrales = { 25, 50, 75 }
    local notificar = false

    for _, umbral in ipairs(umbrales) do
        local cantidadUmbral = math.floor(objetivo.cantidad_requerida * (umbral / 100))
        local cantidadAnterior = objetivo.cantidad_actual - 1

        if objetivo.cantidad_actual >= cantidadUmbral and cantidadAnterior < cantidadUmbral then
            notificar = true
            break
        end
    end

    if notificar then
        Tracker.EnviarNotificacion(charId, {
            tipo = 'progreso_objetivo',
            titulo = 'Progreso',
            mensaje = ('%s: %d/%d (%d%%)'):format(
                objetivo.descripcion,
                objetivo.cantidad_actual,
                objetivo.cantidad_requerida,
                porcentaje
            ),
            icono = 'fa-tasks',
            duracion = 2500,
            sonido = Tracker.configNotificaciones.sonidoProgreso,
        })
    end

    -- Siempre actualizar UI
    local source = Tracker.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:missions:tracker:progress', source, {
            mision_id = misionId,
            objetivo_index = objetivoIndex,
            actual = objetivo.cantidad_actual,
            requerido = objetivo.cantidad_requerida,
            porcentaje = porcentaje,
        })
    end
end

--- Enviar notificacion al cliente
function Tracker.EnviarNotificacion(charId, notificacion)
    table.insert(Tracker.colaNotificaciones, {
        char_id = charId,
        notificacion = notificacion,
        timestamp = os.time(),
    })
end

-- =====================================================================================
-- THREADS DE PROCESAMIENTO
-- =====================================================================================

function Tracker.IniciarThreadActualizacion()
    CreateThread(function()
        while true do
            Wait(500) -- Actualizar cada 500ms

            for misionId, progreso in pairs(Tracker.progresoActivo) do
                if not progreso.pausado then
                    -- Verificar tiempo limite
                    local mision = AIT.Engines.Missions and AIT.Engines.Missions.ObtenerMision(misionId)
                    if mision and mision.tiempo_limite_epoch then
                        local tiempoRestante = mision.tiempo_limite_epoch - os.time()

                        if tiempoRestante <= 0 then
                            -- Tiempo agotado
                            if AIT.Engines.Missions then
                                AIT.Engines.Missions.Fallar(progreso.char_id, misionId, 'Tiempo agotado')
                            end
                        elseif tiempoRestante <= 60 and tiempoRestante % 15 == 0 then
                            -- Avisar ultimo minuto
                            Tracker.EnviarNotificacion(progreso.char_id, {
                                tipo = 'tiempo_limite',
                                titulo = 'Tiempo',
                                mensaje = ('%d segundos restantes!'):format(tiempoRestante),
                                icono = 'fa-clock',
                                duracion = 2000,
                                color = '#F44336',
                            })
                        elseif tiempoRestante <= 300 and tiempoRestante % 60 == 0 then
                            -- Avisar ultimos 5 minutos
                            local minutos = math.floor(tiempoRestante / 60)
                            Tracker.EnviarNotificacion(progreso.char_id, {
                                tipo = 'tiempo_limite',
                                titulo = 'Tiempo',
                                mensaje = ('%d minutos restantes'):format(minutos),
                                icono = 'fa-clock',
                                duracion = 2000,
                                color = '#FF9800',
                            })
                        end
                    end
                end
            end
        end
    end)
end

function Tracker.IniciarThreadNotificaciones()
    CreateThread(function()
        while true do
            Wait(100)

            while #Tracker.colaNotificaciones > 0 do
                local item = table.remove(Tracker.colaNotificaciones, 1)
                local source = Tracker.ObtenerSourceDeCharId(item.char_id)

                if source then
                    TriggerClientEvent('ait:missions:notification', source, item.notificacion)
                end
            end
        end
    end)
end

-- =====================================================================================
-- PERSISTENCIA
-- =====================================================================================

--- Guardar progreso en base de datos
function Tracker.GuardarProgreso(misionId)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then return end

    local progresoGuardado = Tracker.ConvertirProgresoParaGuardado(misionId)
    local objetivosCompletados = 0

    for _, obj in pairs(progreso.objetivos) do
        if obj.completado then
            objetivosCompletados = objetivosCompletados + 1
        end
    end

    MySQL.query([[
        UPDATE ait_misiones_activas
        SET progreso = ?, objetivos_completados = ?, estado = 'en_progreso'
        WHERE mision_id = ?
    ]], { json.encode(progresoGuardado), objetivosCompletados, misionId })
end

--- Convertir progreso a formato de guardado
function Tracker.ConvertirProgresoParaGuardado(misionId)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then return {} end

    local resultado = {}

    for i, obj in pairs(progreso.objetivos) do
        resultado[i] = {
            completado = obj.completado,
            cantidad_actual = obj.cantidad_actual,
            tiempo_inicio = obj.tiempo_inicio,
            tiempo_fin = obj.tiempo_fin,
        }
    end

    return resultado
end

--- Cargar progreso desde base de datos
function Tracker.CargarProgreso(misionId, charId)
    local mision = AIT.Engines.Missions and AIT.Engines.Missions.ObtenerMision(misionId)
    if not mision then return end

    local plantilla = AIT.Engines.Missions.ObtenerPlantilla(mision.plantilla_id)
    if not plantilla then return end

    -- Iniciar tracking con datos existentes
    Tracker.IniciarTracking(misionId, charId, plantilla.objetivos or {}, mision.checkpoints or {})

    -- Restaurar progreso guardado
    if mision.progreso then
        for i, prog in pairs(mision.progreso) do
            if Tracker.progresoActivo[misionId].objetivos[i] then
                Tracker.progresoActivo[misionId].objetivos[i].completado = prog.completado
                Tracker.progresoActivo[misionId].objetivos[i].cantidad_actual = prog.cantidad_actual or 0
                Tracker.progresoActivo[misionId].objetivos[i].tiempo_inicio = prog.tiempo_inicio
                Tracker.progresoActivo[misionId].objetivos[i].tiempo_fin = prog.tiempo_fin
            end
        end

        -- Recalcular objetivo actual
        for i, obj in ipairs(Tracker.progresoActivo[misionId].objetivos) do
            if not obj.completado then
                Tracker.progresoActivo[misionId].objetivo_actual = i
                break
            end
        end

        Tracker.RecalcularPorcentaje(misionId)
    end
end

-- =====================================================================================
-- EVENTOS
-- =====================================================================================

function Tracker.RegistrarEventos()
    -- Recibir actualizacion de posicion del cliente
    RegisterNetEvent('ait:missions:tracker:position', function(datos)
        local source = source
        if AIT.RateLimit and not AIT.RateLimit.check(tostring(source), 'tracker.position') then
            return
        end

        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid

        -- Verificar checkpoints activos
        if Tracker.checkpointsActivos[charId] then
            for misionId, checkpoints in pairs(Tracker.checkpointsActivos[charId]) do
                for i, checkpoint in pairs(checkpoints) do
                    if not checkpoint.alcanzado then
                        local dx = checkpoint.x - datos.x
                        local dy = checkpoint.y - datos.y

                        local distancia = math.sqrt(dx*dx + dy*dy)

                        if distancia <= checkpoint.radio then
                            Tracker.MarcarCheckpoint(misionId, i)

                            -- Actualizar progreso del objetivo asociado
                            local progreso = Tracker.progresoActivo[misionId]
                            if progreso then
                                for j, objetivo in pairs(progreso.objetivos) do
                                    if not objetivo.completado and objetivo.tipo == 'pasar_checkpoint' then
                                        if objetivo.orden == i or (not objetivo.orden and j == i) then
                                            Tracker.ActualizarProgreso(misionId, j, 1, { checkpoint = i })
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Recibir interaccion del cliente
    RegisterNetEvent('ait:missions:tracker:interact', function(misionId, objetivoIndex, datosInteraccion)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local progreso = Tracker.progresoActivo[misionId]

        if not progreso or progreso.char_id ~= charId then return end

        local objetivo = progreso.objetivos[objetivoIndex]
        if not objetivo or objetivo.completado then return end

        -- Verificar segun tipo de objetivo
        local tipoConfig = Tracker.TiposObjetivo[objetivo.tipo]
        if tipoConfig and tipoConfig.verificador then
            local verificador = Tracker[tipoConfig.verificador]
            if verificador then
                datosInteraccion.interaccion_completada = true
                local exito, resultado = verificador(charId, objetivo, datosInteraccion)

                if exito then
                    local cantidad = type(resultado) == 'number' and resultado or 1
                    Tracker.ActualizarProgreso(misionId, objetivoIndex, cantidad, datosInteraccion)
                end
            end
        end
    end)

    -- Recibir eliminacion de enemigo
    RegisterNetEvent('ait:missions:tracker:kill', function(misionId, datosEliminacion)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local progreso = Tracker.progresoActivo[misionId]

        if not progreso or progreso.char_id ~= charId then return end

        -- Buscar objetivo de eliminacion activo
        for i, objetivo in pairs(progreso.objetivos) do
            if objetivo.tipo == 'eliminar' and not objetivo.completado then
                Tracker.ActualizarProgreso(misionId, i, 1, datosEliminacion)
                break
            end
        end
    end)

    -- Recibir muerte del NPC de escolta
    RegisterNetEvent('ait:missions:tracker:escort_died', function(misionId)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local progreso = Tracker.progresoActivo[misionId]

        if not progreso or progreso.char_id ~= charId then return end

        -- Fallar la mision
        if AIT.Engines.Missions then
            AIT.Engines.Missions.Fallar(charId, misionId, 'El objetivo de escolta ha muerto')
        end
    end)

    -- Pausar/reanudar tracking
    RegisterNetEvent('ait:missions:tracker:pause', function(misionId, pausar)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local progreso = Tracker.progresoActivo[misionId]

        if progreso and progreso.char_id == charId then
            progreso.pausado = pausar
        end
    end)
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Tracker.ObtenerSourceDeCharId(charId)
    if AIT.QBCore then
        local players = AIT.QBCore.Functions.GetPlayers()
        for _, playerId in ipairs(players) do
            local player = AIT.QBCore.Functions.GetPlayer(playerId)
            if player and player.PlayerData and player.PlayerData.citizenid == charId then
                return playerId
            end
        end
    end
    return nil
end

--- Obtener resumen de progreso de una mision
---@param misionId number
---@return table|nil
function Tracker.ObtenerResumen(misionId)
    local progreso = Tracker.progresoActivo[misionId]
    if not progreso then return nil end

    local objetivosCompletados = 0
    local objetivosTotales = 0

    for _, obj in pairs(progreso.objetivos) do
        objetivosTotales = objetivosTotales + 1
        if obj.completado then
            objetivosCompletados = objetivosCompletados + 1
        end
    end

    local checkpointsAlcanzados = 0
    local checkpointsTotales = 0

    for _, cp in pairs(progreso.checkpoints) do
        checkpointsTotales = checkpointsTotales + 1
        if cp.alcanzado then
            checkpointsAlcanzados = checkpointsAlcanzados + 1
        end
    end

    return {
        mision_id = misionId,
        porcentaje = progreso.porcentaje_total,
        objetivos = {
            completados = objetivosCompletados,
            totales = objetivosTotales,
        },
        checkpoints = {
            alcanzados = checkpointsAlcanzados,
            totales = checkpointsTotales,
        },
        objetivo_actual = progreso.objetivo_actual,
        checkpoint_actual = progreso.checkpoint_actual,
        pausado = progreso.pausado,
    }
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

Tracker.Start = Tracker.IniciarTracking
Tracker.Stop = Tracker.DetenerTracking
Tracker.Update = Tracker.ActualizarProgreso
Tracker.Checkpoint = Tracker.MarcarCheckpoint
Tracker.GetSummary = Tracker.ObtenerResumen
Tracker.Load = Tracker.CargarProgreso
Tracker.Save = Tracker.GuardarProgreso

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.Missions.Tracker = Tracker

return Tracker
