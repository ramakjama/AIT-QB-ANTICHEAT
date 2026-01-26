-- =====================================================================================
-- ait-qb ENGINE DE COMPORTAMIENTOS DE IA
-- Sistema de estados, deteccion de jugadores y reacciones dinamicas
-- Namespace: AIT.Engines.AI.Behavior
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.AI = AIT.Engines.AI or {}

local Behavior = {
    -- Estados activos por NPC
    estadosActivos = {},
    -- Configuracion de deteccion
    configDeteccion = {
        rangoVision = 50.0,
        anguloVision = 120.0,
        rangoAuditivo = 30.0,
        frecuenciaChequeo = 1000,
    },
    -- Alertas activas por zona
    alertasZona = {},
}

-- =====================================================================================
-- DEFINICION DE ESTADOS
-- =====================================================================================

Behavior.Estados = {
    -- Estado inactivo/descansando
    idle = {
        nombre = 'Idle',
        descripcion = 'NPC en reposo',
        prioridad = 1,
        duracionMin = 5000,
        duracionMax = 30000,
        transicionesPermitidas = { 'patrol', 'wander', 'alert', 'combat', 'flee', 'follow', 'interact' },
        animaciones = {
            'WORLD_HUMAN_STAND_IMPATIENT',
            'WORLD_HUMAN_STAND_MOBILE',
            'WORLD_HUMAN_SMOKING',
            'WORLD_HUMAN_CLIPBOARD',
        },
    },

    -- Patrullando una ruta
    patrol = {
        nombre = 'Patrulla',
        descripcion = 'NPC siguiendo ruta de patrulla',
        prioridad = 2,
        velocidad = 1.0,
        esperaEnPunto = 3000,
        transicionesPermitidas = { 'idle', 'alert', 'combat', 'flee', 'investigate' },
    },

    -- Vagando aleatoriamente
    wander = {
        nombre = 'Vagando',
        descripcion = 'NPC caminando sin destino fijo',
        prioridad = 1,
        velocidad = 0.8,
        radioMaximo = 50.0,
        cambioDestino = 15000,
        transicionesPermitidas = { 'idle', 'alert', 'combat', 'flee' },
    },

    -- Alerta/sospechoso
    alert = {
        nombre = 'Alerta',
        descripcion = 'NPC sospecha de algo',
        prioridad = 3,
        duracion = 10000,
        velocidad = 1.2,
        transicionesPermitidas = { 'idle', 'patrol', 'combat', 'investigate', 'flee' },
        animaciones = {
            'WORLD_HUMAN_GUARD_STAND',
        },
    },

    -- Investigando
    investigate = {
        nombre = 'Investigando',
        descripcion = 'NPC investigando una ubicacion sospechosa',
        prioridad = 4,
        velocidad = 1.0,
        tiempoInvestigacion = 8000,
        transicionesPermitidas = { 'idle', 'alert', 'combat', 'patrol' },
    },

    -- En combate
    combat = {
        nombre = 'Combate',
        descripcion = 'NPC en estado de combate',
        prioridad = 5,
        velocidad = 1.5,
        rangoAtaque = 30.0,
        distanciaCobertura = 5.0,
        tiempoEntreTiros = 500,
        transicionesPermitidas = { 'flee', 'pursue', 'alert' },
    },

    -- Persiguiendo objetivo
    pursue = {
        nombre = 'Persecucion',
        descripcion = 'NPC persiguiendo un objetivo',
        prioridad = 5,
        velocidad = 2.0,
        distanciaMaxima = 100.0,
        tiempoMaximo = 60000,
        transicionesPermitidas = { 'combat', 'alert', 'idle' },
    },

    -- Huyendo
    flee = {
        nombre = 'Huida',
        descripcion = 'NPC huyendo del peligro',
        prioridad = 6,
        velocidad = 2.0,
        distanciaHuida = 100.0,
        transicionesPermitidas = { 'idle', 'cower' },
    },

    -- Acobardado
    cower = {
        nombre = 'Acobardado',
        descripcion = 'NPC paralizado de miedo',
        prioridad = 5,
        duracion = 15000,
        transicionesPermitidas = { 'flee', 'idle' },
        animaciones = {
            'WORLD_HUMAN_BUM_SLUMPED',
        },
    },

    -- Siguiendo a alguien
    follow = {
        nombre = 'Siguiendo',
        descripcion = 'NPC siguiendo a un objetivo',
        prioridad = 3,
        velocidad = 1.0,
        distanciaOptima = 3.0,
        distanciaMaxima = 20.0,
        transicionesPermitidas = { 'idle', 'combat', 'flee' },
    },

    -- Interactuando con jugador
    interact = {
        nombre = 'Interactuando',
        descripcion = 'NPC en interaccion con jugador',
        prioridad = 4,
        transicionesPermitidas = { 'idle' },
    },

    -- Guardia/vigilante
    guard = {
        nombre = 'Guardia',
        descripcion = 'NPC vigilando una posicion',
        prioridad = 2,
        rangoVigilancia = 20.0,
        transicionesPermitidas = { 'alert', 'combat', 'investigate', 'pursue' },
        animaciones = {
            'WORLD_HUMAN_GUARD_STAND',
            'WORLD_HUMAN_SECURITY_SHINE_TORCH',
        },
    },

    -- Tendero/vendedor
    shopkeeper = {
        nombre = 'Tendero',
        descripcion = 'NPC atendiendo una tienda',
        prioridad = 2,
        transicionesPermitidas = { 'interact', 'alert', 'cower', 'flee' },
        animaciones = {
            'WORLD_HUMAN_STAND_IMPATIENT',
            'WORLD_HUMAN_CLIPBOARD',
        },
    },

    -- Trabajando
    work = {
        nombre = 'Trabajando',
        descripcion = 'NPC realizando trabajo',
        prioridad = 2,
        transicionesPermitidas = { 'idle', 'alert', 'flee' },
    },

    -- Muerto
    dead = {
        nombre = 'Muerto',
        descripcion = 'NPC ha fallecido',
        prioridad = 10,
        transicionesPermitidas = {},
    },
}

-- =====================================================================================
-- CONFIGURACION DE DETECCION
-- =====================================================================================

Behavior.TiposDeteccion = {
    visual = {
        nombre = 'Visual',
        rango = 50.0,
        angulo = 120.0,
        requiereLOS = true,
        factorLuz = true,
        factorMovimiento = 1.5,
    },
    auditivo = {
        nombre = 'Auditivo',
        rango = 30.0,
        atraviesaParedes = true,
        factorRuido = 1.0,
    },
    proximidad = {
        nombre = 'Proximidad',
        rango = 5.0,
        siempreDetecta = true,
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Behavior.Initialize()
    if AIT.Log then
        AIT.Log.info('AI:BEHAVIOR', 'Sistema de comportamientos inicializado')
    end

    return true
end

-- =====================================================================================
-- PROCESAMIENTO PRINCIPAL
-- =====================================================================================

--- Procesa el comportamiento de un NPC
---@param npc table
function Behavior.Procesar(npc)
    if not npc or npc.estado == 'muerto' or npc.congelado then
        return
    end

    -- Obtener o crear estado activo
    local estadoActivo = Behavior.estadosActivos[npc.identificador]
    if not estadoActivo then
        estadoActivo = Behavior.CrearEstadoActivo(npc)
        Behavior.estadosActivos[npc.identificador] = estadoActivo
    end

    -- Actualizar deteccion
    local amenazasDetectadas = Behavior.ActualizarDeteccion(npc)

    -- Evaluar transiciones de estado
    local nuevoEstado = Behavior.EvaluarTransicion(npc, estadoActivo, amenazasDetectadas)

    if nuevoEstado and nuevoEstado ~= npc.comportamiento then
        Behavior.CambiarEstado(npc, nuevoEstado, amenazasDetectadas)
    end

    -- Ejecutar logica del estado actual
    Behavior.EjecutarEstado(npc, estadoActivo, amenazasDetectadas)
end

--- Crea el estado activo inicial para un NPC
---@param npc table
---@return table
function Behavior.CrearEstadoActivo(npc)
    return {
        estado = npc.comportamiento or 'idle',
        inicioEstado = os.time(),
        duracionEstado = 0,
        objetivo = nil,
        objetivoTipo = nil,
        ultimaPosicion = npc.posicion,
        ultimaDeteccion = 0,
        amenazasConocidas = {},
        alertas = {},
        puntoRutaActual = npc.puntoRutaActual or 0,
        destinoActual = nil,
        esperando = false,
        tiempoEspera = 0,
    }
end

-- =====================================================================================
-- SISTEMA DE DETECCION
-- =====================================================================================

--- Actualiza la deteccion de amenazas para un NPC
---@param npc table
---@return table amenazas
function Behavior.ActualizarDeteccion(npc)
    local amenazas = {}
    local jugadores = GetPlayers()

    for _, playerId in ipairs(jugadores) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            local distancia = #(npc.posicion - playerCoords)

            -- Deteccion por proximidad
            if distancia <= Behavior.TiposDeteccion.proximidad.rango then
                table.insert(amenazas, {
                    tipo = 'proximidad',
                    playerId = playerId,
                    entityId = ped,
                    distancia = distancia,
                    posicion = playerCoords,
                    nivel = 1.0,
                })
            -- Deteccion visual
            elseif distancia <= Behavior.TiposDeteccion.visual.rango then
                if Behavior.TieneLineaVision(npc, playerCoords) then
                    local nivelDeteccion = Behavior.CalcularNivelDeteccionVisual(npc, playerId, distancia)
                    if nivelDeteccion > 0.3 then
                        table.insert(amenazas, {
                            tipo = 'visual',
                            playerId = playerId,
                            entityId = ped,
                            distancia = distancia,
                            posicion = playerCoords,
                            nivel = nivelDeteccion,
                        })
                    end
                end
            end

            -- Deteccion auditiva (disparos, vehiculos, etc.)
            if distancia <= Behavior.TiposDeteccion.auditivo.rango then
                local nivelRuido = Behavior.ObtenerNivelRuidoJugador(playerId)
                if nivelRuido > 0.5 then
                    table.insert(amenazas, {
                        tipo = 'auditivo',
                        playerId = playerId,
                        entityId = ped,
                        distancia = distancia,
                        posicion = playerCoords,
                        nivel = nivelRuido,
                    })
                end
            end
        end
    end

    -- Ordenar por nivel de amenaza
    table.sort(amenazas, function(a, b)
        return a.nivel > b.nivel
    end)

    return amenazas
end

--- Verifica si hay linea de vision
---@param npc table
---@param objetivo vector3
---@return boolean
function Behavior.TieneLineaVision(npc, objetivo)
    -- Verificar angulo de vision
    local direccionNPC = math.rad(npc.rotacion)
    local direccionObjetivo = math.atan2(objetivo.y - npc.posicion.y, objetivo.x - npc.posicion.x)
    local diferencia = math.abs(direccionNPC - direccionObjetivo)

    if diferencia > math.rad(Behavior.TiposDeteccion.visual.angulo / 2) then
        return false
    end

    -- Aqui se haria raycast en el cliente para verificar obstaculos
    -- Por ahora asumimos que hay LOS si esta en el angulo
    return true
end

--- Calcula el nivel de deteccion visual
---@param npc table
---@param playerId number
---@param distancia number
---@return number 0-1
function Behavior.CalcularNivelDeteccionVisual(npc, playerId, distancia)
    local nivel = 1.0

    -- Factor de distancia (mas lejos = menos deteccion)
    local factorDistancia = 1.0 - (distancia / Behavior.TiposDeteccion.visual.rango)
    nivel = nivel * factorDistancia

    -- Factor de movimiento del jugador (corriendo = mas visible)
    local ped = GetPlayerPed(playerId)
    if ped then
        local velocidad = GetEntitySpeed(ped)
        if velocidad > 5.0 then
            nivel = nivel * Behavior.TiposDeteccion.visual.factorMovimiento
        end
    end

    -- Factor de alerta del NPC (ya alerta = mas facil detectar)
    if npc.comportamiento == 'alert' or npc.comportamiento == 'guard' then
        nivel = nivel * 1.5
    end

    return math.min(1.0, nivel)
end

--- Obtiene el nivel de ruido de un jugador
---@param playerId number
---@return number 0-1
function Behavior.ObtenerNivelRuidoJugador(playerId)
    local ped = GetPlayerPed(playerId)
    if not ped then return 0 end

    local nivel = 0

    -- En vehiculo
    local vehiculo = GetVehiclePedIsIn(ped, false)
    if vehiculo and vehiculo ~= 0 then
        local velocidad = GetEntitySpeed(vehiculo)
        nivel = math.min(1.0, velocidad / 30.0)
    end

    -- Disparando (se detectaria via evento)
    -- Por ahora nivel base

    return nivel
end

-- =====================================================================================
-- TRANSICIONES DE ESTADO
-- =====================================================================================

--- Evalua si el NPC debe cambiar de estado
---@param npc table
---@param estadoActivo table
---@param amenazas table
---@return string|nil nuevoEstado
function Behavior.EvaluarTransicion(npc, estadoActivo, amenazas)
    local estadoConfig = Behavior.Estados[npc.comportamiento]
    if not estadoConfig then return nil end

    -- Verificar si hay amenazas
    if #amenazas > 0 then
        local amenazaPrincipal = amenazas[1]

        -- NPC hostil detecta jugador -> combate
        if npc.hostil and amenazaPrincipal.nivel > 0.5 then
            if Behavior.PuedeTransicionar(npc.comportamiento, 'combat') then
                return 'combat'
            end
        end

        -- NPC no hostil detecta amenaza cercana -> huir o alerta
        if not npc.hostil then
            if amenazaPrincipal.nivel > 0.8 and amenazaPrincipal.distancia < 10.0 then
                -- Amenaza muy cercana
                if npc.tipo == 'civil' then
                    if Behavior.PuedeTransicionar(npc.comportamiento, 'flee') then
                        return 'flee'
                    end
                elseif npc.tipo == 'policia' then
                    if Behavior.PuedeTransicionar(npc.comportamiento, 'alert') then
                        return 'alert'
                    end
                end
            elseif amenazaPrincipal.nivel > 0.5 then
                -- Amenaza detectada
                if Behavior.PuedeTransicionar(npc.comportamiento, 'alert') then
                    return 'alert'
                end
            end
        end
    end

    -- Verificar duracion del estado
    local tiempoEnEstado = os.time() - estadoActivo.inicioEstado

    if estadoConfig.duracion and tiempoEnEstado * 1000 >= estadoConfig.duracion then
        -- Estado con duracion limitada - volver a idle
        if Behavior.PuedeTransicionar(npc.comportamiento, 'idle') then
            return 'idle'
        end
    end

    if estadoConfig.duracionMax and tiempoEnEstado * 1000 >= estadoConfig.duracionMax then
        -- Transicion a siguiente estado logico
        if npc.comportamiento == 'idle' then
            if npc.rutaId and #npc.puntosRuta > 0 then
                return 'patrol'
            elseif Behavior.PuedeTransicionar('idle', 'wander') then
                return 'wander'
            end
        end
    end

    -- Estado de alerta sin amenazas -> volver a normal
    if npc.comportamiento == 'alert' and #amenazas == 0 then
        if tiempoEnEstado > 10 then
            return 'idle'
        end
    end

    -- Huida completada
    if npc.comportamiento == 'flee' then
        if #amenazas == 0 or (amenazas[1] and amenazas[1].distancia > 50.0) then
            return 'idle'
        end
    end

    return nil
end

--- Verifica si una transicion es valida
---@param estadoActual string
---@param estadoNuevo string
---@return boolean
function Behavior.PuedeTransicionar(estadoActual, estadoNuevo)
    local config = Behavior.Estados[estadoActual]
    if not config then return false end

    for _, permitido in ipairs(config.transicionesPermitidas) do
        if permitido == estadoNuevo then
            return true
        end
    end

    return false
end

--- Cambia el estado del NPC
---@param npc table
---@param nuevoEstado string
---@param contexto table|nil
function Behavior.CambiarEstado(npc, nuevoEstado, contexto)
    local estadoAnterior = npc.comportamiento
    local estadoConfig = Behavior.Estados[nuevoEstado]

    if not estadoConfig then
        if AIT.Log then
            AIT.Log.warn('AI:BEHAVIOR', ('Estado invalido: %s'):format(nuevoEstado))
        end
        return
    end

    -- Actualizar NPC
    npc.comportamiento = nuevoEstado
    npc.estado = nuevoEstado

    -- Actualizar estado activo
    local estadoActivo = Behavior.estadosActivos[npc.identificador]
    if estadoActivo then
        estadoActivo.estado = nuevoEstado
        estadoActivo.inicioEstado = os.time()
        estadoActivo.duracionEstado = 0

        -- Guardar objetivo si hay amenaza
        if contexto and #contexto > 0 then
            estadoActivo.objetivo = contexto[1].entityId
            estadoActivo.objetivoTipo = 'player'
            estadoActivo.objetivoPosicion = contexto[1].posicion
        end
    end

    -- Notificar al cliente
    TriggerClientEvent('ait:ai:estado', -1, npc.identificador, {
        estado = nuevoEstado,
        objetivo = estadoActivo and estadoActivo.objetivo,
        velocidad = estadoConfig.velocidad or 1.0,
        animacion = estadoConfig.animaciones and estadoConfig.animaciones[math.random(#estadoConfig.animaciones)],
    })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('ai.npc.state.changed', {
            identificador = npc.identificador,
            estadoAnterior = estadoAnterior,
            estadoNuevo = nuevoEstado,
        })
    end

    if AIT.Log then
        AIT.Log.debug('AI:BEHAVIOR', ('NPC %s: %s -> %s'):format(npc.identificador, estadoAnterior, nuevoEstado))
    end
end

-- =====================================================================================
-- EJECUCION DE ESTADOS
-- =====================================================================================

--- Ejecuta la logica del estado actual
---@param npc table
---@param estadoActivo table
---@param amenazas table
function Behavior.EjecutarEstado(npc, estadoActivo, amenazas)
    local handler = Behavior.Handlers[npc.comportamiento]
    if handler then
        handler(npc, estadoActivo, amenazas)
    end
end

-- Handlers de cada estado
Behavior.Handlers = {}

--- Handler estado IDLE
function Behavior.Handlers.idle(npc, estadoActivo, amenazas)
    -- En idle, el NPC simplemente espera
    -- Puede ejecutar animaciones aleatorias
    if not estadoActivo.animacionActiva then
        local config = Behavior.Estados.idle
        if config.animaciones and #config.animaciones > 0 then
            local animacion = config.animaciones[math.random(#config.animaciones)]
            TriggerClientEvent('ait:ai:escenario', -1, npc.identificador, animacion)
            estadoActivo.animacionActiva = true
        end
    end
end

--- Handler estado PATROL
function Behavior.Handlers.patrol(npc, estadoActivo, amenazas)
    if not npc.puntosRuta or #npc.puntosRuta == 0 then
        -- Sin ruta, cambiar a wander o idle
        Behavior.CambiarEstado(npc, 'wander')
        return
    end

    -- Verificar si estamos esperando en un punto
    if estadoActivo.esperando then
        if os.time() - estadoActivo.tiempoEspera >= (Behavior.Estados.patrol.esperaEnPunto / 1000) then
            estadoActivo.esperando = false
            estadoActivo.puntoRutaActual = estadoActivo.puntoRutaActual + 1

            -- Ciclar ruta
            if estadoActivo.puntoRutaActual > #npc.puntosRuta then
                estadoActivo.puntoRutaActual = 1
            end
        end
        return
    end

    -- Obtener punto actual
    local puntoActual = npc.puntosRuta[estadoActivo.puntoRutaActual]
    if not puntoActual then
        estadoActivo.puntoRutaActual = 1
        puntoActual = npc.puntosRuta[1]
    end

    -- Verificar si llegamos al punto
    local distancia = #(npc.posicion - puntoActual.posicion)
    if distancia < 2.0 then
        estadoActivo.esperando = true
        estadoActivo.tiempoEspera = os.time()

        -- Ejecutar accion del punto si tiene
        if puntoActual.escenario then
            TriggerClientEvent('ait:ai:escenario', -1, npc.identificador, puntoActual.escenario)
        end
    else
        -- Mover hacia el punto
        TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
            destino = puntoActual.posicion,
            velocidad = Behavior.Estados.patrol.velocidad,
        })
    end
end

--- Handler estado WANDER
function Behavior.Handlers.wander(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.wander

    -- Verificar si necesita nuevo destino
    if not estadoActivo.destinoActual or os.time() - (estadoActivo.ultimoCambioDestino or 0) > config.cambioDestino / 1000 then
        -- Generar destino aleatorio dentro del radio
        local angulo = math.random() * math.pi * 2
        local distancia = math.random() * config.radioMaximo
        local nuevoDestino = vector3(
            npc.posicion.x + math.cos(angulo) * distancia,
            npc.posicion.y + math.sin(angulo) * distancia,
            npc.posicion.z
        )

        estadoActivo.destinoActual = nuevoDestino
        estadoActivo.ultimoCambioDestino = os.time()

        TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
            destino = nuevoDestino,
            velocidad = config.velocidad,
        })
    end
end

--- Handler estado ALERT
function Behavior.Handlers.alert(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.alert

    -- Mirar hacia la ultima posicion conocida de amenaza
    if estadoActivo.objetivoPosicion then
        TriggerClientEvent('ait:ai:mirar', -1, npc.identificador, estadoActivo.objetivoPosicion)
    end

    -- Si la amenaza sigue cerca, investigar
    if #amenazas > 0 and amenazas[1].distancia < 30.0 then
        if Behavior.PuedeTransicionar('alert', 'investigate') then
            Behavior.CambiarEstado(npc, 'investigate', amenazas)
        end
    end
end

--- Handler estado INVESTIGATE
function Behavior.Handlers.investigate(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.investigate

    -- Mover hacia la posicion sospechosa
    if estadoActivo.objetivoPosicion then
        local distancia = #(npc.posicion - estadoActivo.objetivoPosicion)

        if distancia > 2.0 then
            TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
                destino = estadoActivo.objetivoPosicion,
                velocidad = config.velocidad,
            })
        else
            -- Llegamos, mirar alrededor
            if not estadoActivo.investigando then
                estadoActivo.investigando = true
                estadoActivo.inicioInvestigacion = os.time()
                TriggerClientEvent('ait:ai:investigar', -1, npc.identificador)
            elseif os.time() - estadoActivo.inicioInvestigacion > config.tiempoInvestigacion / 1000 then
                -- Terminar investigacion
                estadoActivo.investigando = false
                Behavior.CambiarEstado(npc, 'alert')
            end
        end
    else
        -- Sin posicion objetivo, volver a alert
        Behavior.CambiarEstado(npc, 'alert')
    end
end

--- Handler estado COMBAT
function Behavior.Handlers.combat(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.combat

    if #amenazas == 0 then
        -- Sin objetivos, volver a alerta
        Behavior.CambiarEstado(npc, 'alert')
        return
    end

    local objetivo = amenazas[1]
    estadoActivo.objetivo = objetivo.entityId
    estadoActivo.objetivoPosicion = objetivo.posicion

    if objetivo.distancia > config.rangoAtaque then
        -- Perseguir
        if Behavior.PuedeTransicionar('combat', 'pursue') then
            Behavior.CambiarEstado(npc, 'pursue', amenazas)
        else
            -- Acercarse
            TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
                destino = objetivo.posicion,
                velocidad = config.velocidad,
            })
        end
    else
        -- Atacar
        TriggerClientEvent('ait:ai:atacar', -1, npc.identificador, {
            objetivo = objetivo.entityId,
            posicion = objetivo.posicion,
        })
    end
end

--- Handler estado PURSUE
function Behavior.Handlers.pursue(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.pursue

    if #amenazas == 0 then
        -- Perdimos al objetivo
        Behavior.CambiarEstado(npc, 'alert')
        return
    end

    local objetivo = amenazas[1]

    -- Verificar distancia maxima
    if objetivo.distancia > config.distanciaMaxima then
        Behavior.CambiarEstado(npc, 'alert')
        return
    end

    -- Verificar tiempo maximo de persecucion
    local tiempoPersecucion = os.time() - estadoActivo.inicioEstado
    if tiempoPersecucion * 1000 > config.tiempoMaximo then
        Behavior.CambiarEstado(npc, 'alert')
        return
    end

    -- Perseguir
    TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
        destino = objetivo.posicion,
        velocidad = config.velocidad,
        correr = true,
    })

    -- Si esta cerca, entrar en combate
    if objetivo.distancia < Behavior.Estados.combat.rangoAtaque then
        Behavior.CambiarEstado(npc, 'combat', amenazas)
    end
end

--- Handler estado FLEE
function Behavior.Handlers.flee(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.flee

    -- Calcular direccion de huida (opuesta a la amenaza)
    if #amenazas > 0 then
        local amenaza = amenazas[1]
        local direccion = npc.posicion - amenaza.posicion
        local distancia = config.distanciaHuida

        local destino = npc.posicion + (direccion:normalized() * distancia)

        TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
            destino = destino,
            velocidad = config.velocidad,
            correr = true,
            huir = true,
        })
    else
        -- Sin amenaza, detenerse
        Behavior.CambiarEstado(npc, 'idle')
    end
end

--- Handler estado COWER
function Behavior.Handlers.cower(npc, estadoActivo, amenazas)
    -- El NPC esta paralizado de miedo
    if not estadoActivo.animacionCower then
        TriggerClientEvent('ait:ai:escenario', -1, npc.identificador, 'WORLD_HUMAN_BUM_SLUMPED')
        estadoActivo.animacionCower = true
    end
end

--- Handler estado FOLLOW
function Behavior.Handlers.follow(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.follow

    if not estadoActivo.objetivo then
        Behavior.CambiarEstado(npc, 'idle')
        return
    end

    -- Obtener posicion del objetivo
    local ped = estadoActivo.objetivo
    if not DoesEntityExist(ped) then
        Behavior.CambiarEstado(npc, 'idle')
        return
    end

    local objetivoPos = GetEntityCoords(ped)
    local distancia = #(npc.posicion - objetivoPos)

    if distancia > config.distanciaMaxima then
        -- Muy lejos, dejar de seguir
        Behavior.CambiarEstado(npc, 'idle')
    elseif distancia > config.distanciaOptima then
        -- Acercarse
        TriggerClientEvent('ait:ai:mover', -1, npc.identificador, {
            destino = objetivoPos,
            velocidad = config.velocidad,
        })
    end
    -- Si esta a distancia optima, quedarse quieto
end

--- Handler estado GUARD
function Behavior.Handlers.guard(npc, estadoActivo, amenazas)
    local config = Behavior.Estados.guard

    -- Verificar amenazas en rango de vigilancia
    for _, amenaza in ipairs(amenazas) do
        if amenaza.distancia < config.rangoVigilancia then
            Behavior.CambiarEstado(npc, 'alert', { amenaza })
            return
        end
    end

    -- Mantener posicion y animacion de guardia
    if not estadoActivo.animacionGuardia then
        local animacion = config.animaciones[math.random(#config.animaciones)]
        TriggerClientEvent('ait:ai:escenario', -1, npc.identificador, animacion)
        estadoActivo.animacionGuardia = true
    end
end

--- Handler estado SHOPKEEPER
function Behavior.Handlers.shopkeeper(npc, estadoActivo, amenazas)
    -- Verificar si hay clientes cerca (jugadores)
    for _, amenaza in ipairs(amenazas) do
        if amenaza.distancia < 3.0 and amenaza.tipo == 'proximidad' then
            -- Mirar al jugador
            TriggerClientEvent('ait:ai:mirar', -1, npc.identificador, amenaza.posicion)
            return
        end
    end

    -- Animacion de espera
    if not estadoActivo.animacionTienda then
        local config = Behavior.Estados.shopkeeper
        local animacion = config.animaciones[math.random(#config.animaciones)]
        TriggerClientEvent('ait:ai:escenario', -1, npc.identificador, animacion)
        estadoActivo.animacionTienda = true
    end
end

--- Handler estado INTERACT
function Behavior.Handlers.interact(npc, estadoActivo, amenazas)
    -- En interaccion, el NPC esta bloqueado
    -- Solo se sale via FinalizarInteraccion
end

--- Handler estado WORK
function Behavior.Handlers.work(npc, estadoActivo, amenazas)
    -- Ejecutar escenario de trabajo si tiene
    if npc.escenario and not estadoActivo.trabajando then
        TriggerClientEvent('ait:ai:escenario', -1, npc.identificador, npc.escenario)
        estadoActivo.trabajando = true
    end
end

--- Handler estado DEAD
function Behavior.Handlers.dead(npc, estadoActivo, amenazas)
    -- NPC muerto, no hacer nada
end

-- =====================================================================================
-- REACCIONES
-- =====================================================================================

--- Reaccion al recibir danio
---@param npc table
---@param atacanteNetId number
function Behavior.ReaccionarDanio(npc, atacanteNetId)
    -- Guardar atacante como objetivo
    local estadoActivo = Behavior.estadosActivos[npc.identificador]
    if estadoActivo then
        estadoActivo.objetivo = atacanteNetId
        estadoActivo.objetivoTipo = 'attacker'
    end

    -- Determinar reaccion segun tipo de NPC
    if npc.hostil or npc.armado then
        -- Contraatacar
        if Behavior.PuedeTransicionar(npc.comportamiento, 'combat') then
            Behavior.CambiarEstado(npc, 'combat')
        end
    else
        -- Huir
        if Behavior.PuedeTransicionar(npc.comportamiento, 'flee') then
            Behavior.CambiarEstado(npc, 'flee')
        elseif Behavior.PuedeTransicionar(npc.comportamiento, 'cower') then
            Behavior.CambiarEstado(npc, 'cower')
        end
    end

    -- Alertar NPCs cercanos
    Behavior.AlertarNPCsCercanos(npc.posicion, 30.0, atacanteNetId)
end

--- Alerta NPCs cercanos de una amenaza
---@param posicion vector3
---@param radio number
---@param amenazaId number|nil
function Behavior.AlertarNPCsCercanos(posicion, radio, amenazaId)
    local AI = AIT.Engines.AI

    for identificador, npc in pairs(AI.npcsActivos) do
        if npc.estado == 'spawned' then
            local distancia = #(npc.posicion - posicion)
            if distancia <= radio then
                local estadoActivo = Behavior.estadosActivos[identificador]
                if estadoActivo then
                    -- Guardar alerta
                    table.insert(estadoActivo.alertas, {
                        posicion = posicion,
                        amenaza = amenazaId,
                        tiempo = os.time(),
                    })

                    -- Transicionar a alerta si es posible
                    if Behavior.PuedeTransicionar(npc.comportamiento, 'alert') then
                        estadoActivo.objetivoPosicion = posicion
                        Behavior.CambiarEstado(npc, 'alert')
                    end
                end
            end
        end
    end
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

--- Fuerza un cambio de estado en un NPC
---@param identificador string
---@param nuevoEstado string
---@param objetivo number|nil
---@return boolean
function Behavior.ForzarEstado(identificador, nuevoEstado, objetivo)
    local AI = AIT.Engines.AI
    local npc = AI.Obtener(identificador)

    if not npc then
        return false
    end

    local estadoActivo = Behavior.estadosActivos[identificador]
    if estadoActivo and objetivo then
        estadoActivo.objetivo = objetivo
    end

    Behavior.CambiarEstado(npc, nuevoEstado)
    return true
end

--- Hace que un NPC siga a un jugador
---@param identificador string
---@param targetSource number
---@return boolean
function Behavior.SeguirJugador(identificador, targetSource)
    local AI = AIT.Engines.AI
    local npc = AI.Obtener(identificador)

    if not npc then
        return false
    end

    local ped = GetPlayerPed(targetSource)
    if not ped then
        return false
    end

    local estadoActivo = Behavior.estadosActivos[identificador]
    if estadoActivo then
        estadoActivo.objetivo = ped
        estadoActivo.objetivoTipo = 'follow'
    end

    Behavior.CambiarEstado(npc, 'follow')
    return true
end

--- Limpia el estado de un NPC
---@param identificador string
function Behavior.LimpiarEstado(identificador)
    Behavior.estadosActivos[identificador] = nil
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

Behavior.Process = Behavior.Procesar
Behavior.ChangeState = Behavior.CambiarEstado
Behavior.ForceState = Behavior.ForzarEstado
Behavior.FollowPlayer = Behavior.SeguirJugador
Behavior.ReactToDamage = Behavior.ReaccionarDanio
Behavior.AlertNearby = Behavior.AlertarNPCsCercanos
Behavior.CleanState = Behavior.LimpiarEstado

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.AI.Behavior = Behavior

return Behavior
