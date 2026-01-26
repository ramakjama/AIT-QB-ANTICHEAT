-- =====================================================================================
-- ait-qb ENGINE DE JUSTICIA - SISTEMA DE BUSQUEDA
-- Sistema de busqueda policial avanzado con niveles, cooldown y escape
-- Namespace: AIT.Engines.Justice.Wanted
-- Optimizado para 2048 slots
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Justice = AIT.Engines.Justice or {}

local Wanted = {
    -- Cache de persecuciones activas
    persecuciones = {},
    -- Ultima ubicacion conocida de buscados
    ubicacionesConocidas = {},
    -- Policias en persecucion
    policiasEnPersecucion = {},
    -- Cooldowns de escape por jugador
    cooldownsEscape = {},
    -- Testigos por zona
    testigosPorZona = {},
    -- Configuracion de zonas
    zonas = {},
}

-- =====================================================================================
-- CONFIGURACION DE PERSECUCION
-- =====================================================================================

Wanted.ConfigPersecucion = {
    -- Tiempo minimo entre reportes de ubicacion
    intervaloReporte = 5000,
    -- Radio maximo de busqueda (metros)
    radioBusquedaMax = 2000,
    -- Tiempo para considerar que perdio a la policia
    tiempoEscape = 60,
    -- Tiempo de cooldown despues de escapar
    cooldownEscape = 300,
    -- Bonus de escape por nivel
    bonusEscapePorNivel = {
        [1] = 1.5,  -- 50% mas facil
        [2] = 1.2,
        [3] = 1.0,
        [4] = 0.7,
        [5] = 0.4,
        [6] = 0.1,  -- Casi imposible
    },
    -- Velocidad de decay por nivel (segundos por estrella)
    velocidadDecay = {
        [1] = 60,
        [2] = 120,
        [3] = 180,
        [4] = 300,
        [5] = 600,
        [6] = 1200,
    },
}

-- =====================================================================================
-- CONFIGURACION DE ZONAS DE BUSQUEDA
-- =====================================================================================

Wanted.ZonasConfig = {
    ciudad = {
        nombre = 'Los Santos',
        multiplicadorBusqueda = 1.0,
        policiasBase = 10,
        tiempoRespuesta = 30,
        camarasVigilancia = true,
    },
    rural = {
        nombre = 'Zona Rural',
        multiplicadorBusqueda = 0.7,
        policiasBase = 3,
        tiempoRespuesta = 120,
        camarasVigilancia = false,
    },
    desierto = {
        nombre = 'Desierto',
        multiplicadorBusqueda = 0.5,
        policiasBase = 2,
        tiempoRespuesta = 180,
        camarasVigilancia = false,
    },
    montana = {
        nombre = 'Montanas',
        multiplicadorBusqueda = 0.4,
        policiasBase = 1,
        tiempoRespuesta = 240,
        camarasVigilancia = false,
    },
    agua = {
        nombre = 'Aguas',
        multiplicadorBusqueda = 0.3,
        policiasBase = 1,
        tiempoRespuesta = 300,
        camarasVigilancia = false,
        requiereBarco = true,
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Wanted.Initialize()
    -- Cargar zonas de busqueda
    Wanted.CargarZonas()

    -- Registrar eventos
    Wanted.RegistrarEventos()

    -- Iniciar thread de persecucion
    Wanted.IniciarThreadPersecucion()

    -- Iniciar thread de ubicaciones
    Wanted.IniciarThreadUbicaciones()

    -- Iniciar thread de testigos
    Wanted.IniciarThreadTestigos()

    if AIT.Log then
        AIT.Log.info('JUSTICE:WANTED', 'Sistema de busqueda inicializado')
    end

    return true
end

function Wanted.CargarZonas()
    -- Cargar zonas de la base de datos o config
    if AIT.Config and AIT.Config.justice and AIT.Config.justice.zonas then
        for zona, config in pairs(AIT.Config.justice.zonas) do
            Wanted.ZonasConfig[zona] = AIT.Utils.Merge(Wanted.ZonasConfig[zona] or {}, config)
        end
    end
end

-- =====================================================================================
-- GESTION DE PERSECUCIONES
-- =====================================================================================

--- Iniciar una persecucion
---@param charId number
---@param oficialId number
---@param ubicacion table|nil
---@return boolean, number|string
function Wanted.IniciarPersecucion(charId, oficialId, ubicacion)
    -- Verificar que el sospechoso esta buscado
    if not AIT.Engines.Justice.EstaBuscado(charId) then
        return false, 'El sospechoso no esta buscado'
    end

    local nivelWanted = AIT.Engines.Justice.ObtenerNivelWanted(charId)

    -- Verificar si ya hay una persecucion activa
    if Wanted.persecuciones[charId] then
        -- Anadir oficial a la persecucion existente
        Wanted.AnadirOficialPersecucion(charId, oficialId)
        return true, Wanted.persecuciones[charId].persecucion_id
    end

    -- Crear nueva persecucion
    local persecucionId = MySQL.insert.await([[
        INSERT INTO ait_justicia_persecuciones
        (char_id, nivel_inicial, ubicacion_inicial, iniciada_por, estado)
        VALUES (?, ?, ?, ?, 'activa')
    ]], {
        charId,
        nivelWanted,
        ubicacion and json.encode(ubicacion) or nil,
        oficialId,
    })

    Wanted.persecuciones[charId] = {
        persecucion_id = persecucionId,
        char_id = charId,
        nivel = nivelWanted,
        ubicacion_inicial = ubicacion,
        ubicacion_actual = ubicacion,
        tiempo_inicio = os.time(),
        ultimo_avistamiento = os.time(),
        oficiales = { [oficialId] = true },
        estado = 'activa',
        vehiculos_usados = {},
        danos_causados = 0,
        distancia_recorrida = 0,
    }

    -- Notificar al sospechoso
    Wanted.NotificarSospechoso(charId, 'persecucion_iniciada', {
        nivel = nivelWanted,
        oficiales = 1,
    })

    -- Notificar a la policia
    Wanted.NotificarPoliciasPersecucion(charId, 'nueva_persecucion', {
        char_id = charId,
        nivel = nivelWanted,
        ubicacion = ubicacion,
        iniciada_por = oficialId,
    })

    -- Log
    Wanted.RegistrarLogPersecucion(persecucionId, 'PERSECUCION_INICIADA', {
        nivel = nivelWanted,
        ubicacion = ubicacion,
        oficial = oficialId,
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.pursuit.started', {
            persecucion_id = persecucionId,
            char_id = charId,
            nivel = nivelWanted,
            oficial_id = oficialId,
        })
    end

    return true, persecucionId
end

--- Anadir oficial a una persecucion existente
---@param charId number
---@param oficialId number
function Wanted.AnadirOficialPersecucion(charId, oficialId)
    local persecucion = Wanted.persecuciones[charId]
    if not persecucion then return end

    if not persecucion.oficiales[oficialId] then
        persecucion.oficiales[oficialId] = true

        -- Notificar al sospechoso de mas unidades
        local numOficiales = 0
        for _ in pairs(persecucion.oficiales) do
            numOficiales = numOficiales + 1
        end

        Wanted.NotificarSospechoso(charId, 'unidades_adicionales', {
            total_oficiales = numOficiales,
        })

        -- Registrar
        Wanted.RegistrarLogPersecucion(persecucion.persecucion_id, 'OFICIAL_UNIDO', {
            oficial_id = oficialId,
            total = numOficiales,
        })
    end
end

--- Actualizar ubicacion de persecucion
---@param charId number
---@param ubicacion table
---@param velocidad number|nil
---@param enVehiculo boolean|nil
---@param vehiculoModelo string|nil
function Wanted.ActualizarUbicacionPersecucion(charId, ubicacion, velocidad, enVehiculo, vehiculoModelo)
    local persecucion = Wanted.persecuciones[charId]
    if not persecucion then return end

    -- Calcular distancia recorrida
    if persecucion.ubicacion_actual then
        local distancia = Wanted.CalcularDistancia(
            persecucion.ubicacion_actual,
            ubicacion
        )
        persecucion.distancia_recorrida = persecucion.distancia_recorrida + distancia
    end

    -- Actualizar ubicacion
    persecucion.ubicacion_actual = ubicacion
    persecucion.ultimo_avistamiento = os.time()

    -- Registrar vehiculo usado
    if enVehiculo and vehiculoModelo then
        persecucion.vehiculos_usados[vehiculoModelo] = true
    end

    -- Guardar ubicacion conocida
    Wanted.ubicacionesConocidas[charId] = {
        ubicacion = ubicacion,
        timestamp = os.time(),
        velocidad = velocidad,
        en_vehiculo = enVehiculo,
        vehiculo = vehiculoModelo,
    }

    -- Notificar a policias en persecucion
    Wanted.EnviarUbicacionAPolicias(charId, ubicacion, velocidad)
end

--- Finalizar una persecucion
---@param charId number
---@param resultado string
---@param opciones table|nil
---@return boolean
function Wanted.FinalizarPersecucion(charId, resultado, opciones)
    opciones = opciones or {}
    local persecucion = Wanted.persecuciones[charId]

    if not persecucion then
        return false
    end

    local ahora = os.time()
    local duracion = ahora - persecucion.tiempo_inicio

    -- Actualizar BD
    MySQL.query([[
        UPDATE ait_justicia_persecuciones
        SET estado = ?, duracion = ?, distancia = ?, vehiculos_usados = ?,
            danos_causados = ?, resultado = ?, finalizada_en = NOW()
        WHERE persecucion_id = ?
    ]], {
        'finalizada',
        duracion,
        persecucion.distancia_recorrida,
        json.encode(persecucion.vehiculos_usados),
        persecucion.danos_causados,
        resultado,
        persecucion.persecucion_id,
    })

    -- Notificar a todos los involucrados
    Wanted.NotificarSospechoso(charId, 'persecucion_finalizada', {
        resultado = resultado,
        duracion = duracion,
    })

    Wanted.NotificarPoliciasPersecucion(charId, 'persecucion_finalizada', {
        char_id = charId,
        resultado = resultado,
        duracion = duracion,
    })

    -- Si fue capturado, procesar arresto
    if resultado == 'capturado' and opciones.arrestadoPor then
        Wanted.ProcesarCaptura(charId, opciones.arrestadoPor, persecucion)
    end

    -- Si escapo, aplicar cooldown
    if resultado == 'escapado' then
        Wanted.AplicarCooldownEscape(charId)
    end

    -- Log
    Wanted.RegistrarLogPersecucion(persecucion.persecucion_id, 'PERSECUCION_FINALIZADA', {
        resultado = resultado,
        duracion = duracion,
        distancia = persecucion.distancia_recorrida,
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.pursuit.ended', {
            persecucion_id = persecucion.persecucion_id,
            char_id = charId,
            resultado = resultado,
            duracion = duracion,
        })
    end

    -- Limpiar cache
    Wanted.persecuciones[charId] = nil
    Wanted.ubicacionesConocidas[charId] = nil

    return true
end

--- Procesar la captura de un sospechoso
---@param charId number
---@param oficialId number
---@param persecucion table
function Wanted.ProcesarCaptura(charId, oficialId, persecucion)
    -- Obtener estado wanted completo
    local wanted = AIT.Engines.Justice.ObtenerWanted(charId)
    if not wanted then return end

    -- Calcular multas y tiempo de carcel
    local multaTotal = 0
    local tiempoCarcel = 0
    local delitosUnicos = {}

    for _, delito in ipairs(wanted.delitos) do
        if not delitosUnicos[delito.tipo] then
            delitosUnicos[delito.tipo] = true
            local tipoDelito = AIT.Engines.Justice.TiposDelito[delito.tipo]
            if tipoDelito then
                multaTotal = multaTotal + tipoDelito.multa
                tiempoCarcel = tiempoCarcel + tipoDelito.tiempoCarcel
            end
        end
    end

    -- Bonus/penalizacion por la persecucion
    if persecucion then
        -- Penalizacion por evasion
        multaTotal = multaTotal + 5000
        tiempoCarcel = tiempoCarcel + 5

        -- Penalizacion por danos
        if persecucion.danos_causados > 0 then
            multaTotal = multaTotal + persecucion.danos_causados
        end

        -- Penalizacion por distancia (fuga prolongada)
        if persecucion.distancia_recorrida > 5000 then
            tiempoCarcel = tiempoCarcel + 10
        end
    end

    -- Emitir multa
    if multaTotal > 0 then
        AIT.Engines.Justice.EmitirMulta(charId, 'multas_acumuladas', multaTotal, {
            descripcion = 'Multas por delitos cometidos',
            emitidaPor = oficialId,
        })
    end

    -- Enviar a carcel si aplica
    if tiempoCarcel > 0 then
        if AIT.Engines.Justice.Jail then
            AIT.Engines.Justice.Jail.Encarcelar(charId, tiempoCarcel, {
                arrestadoPor = oficialId,
                delitos = wanted.delitos,
            })
        end
    end

    -- Limpiar wanted
    AIT.Engines.Justice.LimpiarWanted(charId, 'Arrestado')

    -- Actualizar stats del oficial
    Wanted.ActualizarStatsOficial(oficialId, 'captura', {
        nivel_wanted = wanted.nivel,
        multa = multaTotal,
        tiempo_carcel = tiempoCarcel,
    })

    -- Notificar al sospechoso
    Wanted.NotificarSospechoso(charId, 'arrestado', {
        multa = multaTotal,
        tiempo_carcel = tiempoCarcel,
        oficial = oficialId,
    })
end

-- =====================================================================================
-- SISTEMA DE ESCAPE
-- =====================================================================================

--- Verificar si un sospechoso puede escapar
---@param charId number
---@return boolean, string
function Wanted.PuedeEscapar(charId)
    local persecucion = Wanted.persecuciones[charId]

    -- Si no hay persecucion activa, verificar decay normal
    if not persecucion then
        return Wanted.VerificarDecayNormal(charId)
    end

    -- Verificar cooldown de escape
    if Wanted.cooldownsEscape[charId] then
        local tiempoRestante = Wanted.cooldownsEscape[charId] - os.time()
        if tiempoRestante > 0 then
            return false, ('Cooldown de escape: %d segundos'):format(tiempoRestante)
        end
    end

    -- Verificar tiempo desde ultimo avistamiento
    local tiempoSinVer = os.time() - persecucion.ultimo_avistamiento
    local nivelWanted = AIT.Engines.Justice.ObtenerNivelWanted(charId)
    local nivelConfig = AIT.Engines.Justice.NivelesWanted[nivelWanted]

    if not nivelConfig.puedeEscapar then
        return false, 'Este nivel de busqueda no permite escape'
    end

    -- Calcular tiempo necesario para escapar
    local tiempoEscapeBase = Wanted.ConfigPersecucion.tiempoEscape
    local multiplicadorZona = Wanted.ObtenerMultiplicadorZona(persecucion.ubicacion_actual)
    local bonusNivel = Wanted.ConfigPersecucion.bonusEscapePorNivel[nivelWanted] or 1.0

    local tiempoNecesario = tiempoEscapeBase / (multiplicadorZona * bonusNivel)

    if tiempoSinVer >= tiempoNecesario then
        return true, 'Escape posible'
    end

    return false, ('Necesitas %d segundos mas sin ser visto'):format(math.ceil(tiempoNecesario - tiempoSinVer))
end

--- Verificar decay normal (sin persecucion activa)
---@param charId number
---@return boolean, string
function Wanted.VerificarDecayNormal(charId)
    local wanted = AIT.Engines.Justice.ObtenerWanted(charId)
    if not wanted then
        return true, 'No esta buscado'
    end

    local nivelConfig = AIT.Engines.Justice.NivelesWanted[wanted.nivel]
    if not nivelConfig.puedeEscapar then
        return false, 'Este nivel requiere arresto'
    end

    -- Verificar que no haya policias en la zona
    local ubicacion = Wanted.ubicacionesConocidas[charId]
    if ubicacion then
        local policiasEnZona = Wanted.ContarPoliciasEnRadio(ubicacion.ubicacion, nivelConfig.radioBusqueda)
        if policiasEnZona > 0 then
            return false, 'Hay policias en la zona'
        end
    end

    return true, 'Decay permitido'
end

--- Aplicar cooldown de escape
---@param charId number
function Wanted.AplicarCooldownEscape(charId)
    Wanted.cooldownsEscape[charId] = os.time() + Wanted.ConfigPersecucion.cooldownEscape

    -- Guardar en BD para persistencia
    MySQL.query([[
        INSERT INTO ait_justicia_cooldowns (char_id, tipo, expira_en)
        VALUES (?, 'escape', FROM_UNIXTIME(?))
        ON DUPLICATE KEY UPDATE expira_en = FROM_UNIXTIME(?)
    ]], { charId, Wanted.cooldownsEscape[charId], Wanted.cooldownsEscape[charId] })
end

--- Procesar escape exitoso
---@param charId number
---@param metodo string
function Wanted.ProcesarEscape(charId, metodo)
    local persecucion = Wanted.persecuciones[charId]

    -- Finalizar persecucion
    Wanted.FinalizarPersecucion(charId, 'escapado', {
        metodo = metodo,
    })

    -- Reducir nivel de wanted gradualmente
    local nivelActual = AIT.Engines.Justice.ObtenerNivelWanted(charId)
    if nivelActual > 0 then
        AIT.Engines.Justice.ReducirWanted(charId, 1, 'Escape exitoso')
    end

    -- Actualizar stats del jugador
    Wanted.ActualizarStatsJugador(charId, 'escape', {
        metodo = metodo,
    })

    -- Notificar
    Wanted.NotificarSospechoso(charId, 'escapado', {
        metodo = metodo,
        nuevo_nivel = math.max(0, nivelActual - 1),
    })

    -- Log
    AIT.Engines.Justice.RegistrarLog(charId, nil, 'ESCAPE_EXITOSO', nil, {
        metodo = metodo,
        nivel_anterior = nivelActual,
    })
end

-- =====================================================================================
-- SISTEMA DE AVISTAMIENTOS Y REPORTES
-- =====================================================================================

--- Reportar avistamiento de sospechoso
---@param charIdReportador number
---@param charIdSospechoso number
---@param ubicacion table
---@param opciones table|nil
---@return boolean
function Wanted.ReportarAvistamiento(charIdReportador, charIdSospechoso, ubicacion, opciones)
    opciones = opciones or {}

    -- Verificar que el sospechoso esta buscado
    if not AIT.Engines.Justice.EstaBuscado(charIdSospechoso) then
        return false
    end

    local nivelWanted = AIT.Engines.Justice.ObtenerNivelWanted(charIdSospechoso)

    -- Actualizar ubicacion conocida
    Wanted.ubicacionesConocidas[charIdSospechoso] = {
        ubicacion = ubicacion,
        timestamp = os.time(),
        reportado_por = charIdReportador,
        descripcion = opciones.descripcion,
        vehiculo = opciones.vehiculo,
        direccion = opciones.direccion,
    }

    -- Si hay persecucion activa, actualizar
    if Wanted.persecuciones[charIdSospechoso] then
        Wanted.persecuciones[charIdSospechoso].ultimo_avistamiento = os.time()
        Wanted.persecuciones[charIdSospechoso].ubicacion_actual = ubicacion
    end

    -- Notificar a policias
    local esPolicia = AIT.Engines.Justice.policiasOnline[charIdReportador]
    local tipoReporte = esPolicia and 'avistamiento_policia' or 'avistamiento_civil'

    Wanted.NotificarPoliciasZona(ubicacion, tipoReporte, {
        char_id = charIdSospechoso,
        nivel = nivelWanted,
        ubicacion = ubicacion,
        descripcion = opciones.descripcion,
        vehiculo = opciones.vehiculo,
    })

    -- Si es civil, dar recompensa por informacion
    if not esPolicia and nivelWanted >= 3 then
        local recompensa = nivelWanted * 100
        if AIT.Engines.economy then
            AIT.Engines.economy.AddMoney(nil, charIdReportador, recompensa, 'bank', 'reward',
                'Recompensa por informacion')
        end
    end

    -- Log
    Wanted.RegistrarLogAvistamiento(charIdSospechoso, charIdReportador, ubicacion, opciones)

    return true
end

--- Agregar testigo a una zona
---@param zona string
---@param charId number
---@param ubicacion table
function Wanted.AgregarTestigo(zona, charId, ubicacion)
    if not Wanted.testigosPorZona[zona] then
        Wanted.testigosPorZona[zona] = {}
    end

    Wanted.testigosPorZona[zona][charId] = {
        ubicacion = ubicacion,
        timestamp = os.time(),
    }
end

--- Verificar testigos de un delito
---@param ubicacion table
---@param radio number
---@return table
function Wanted.ObtenerTestigos(ubicacion, radio)
    radio = radio or 50
    local testigos = {}

    for zona, testigosZona in pairs(Wanted.testigosPorZona) do
        for charId, data in pairs(testigosZona) do
            local distancia = Wanted.CalcularDistancia(ubicacion, data.ubicacion)
            if distancia <= radio then
                table.insert(testigos, {
                    char_id = charId,
                    distancia = distancia,
                    zona = zona,
                })
            end
        end
    end

    return testigos
end

-- =====================================================================================
-- THREADS DE ACTUALIZACION
-- =====================================================================================

function Wanted.IniciarThreadPersecucion()
    CreateThread(function()
        while true do
            Wait(1000) -- Cada segundo

            local ahora = os.time()

            for charId, persecucion in pairs(Wanted.persecuciones) do
                -- Verificar tiempo sin avistamiento
                local tiempoSinVer = ahora - persecucion.ultimo_avistamiento

                -- Si ha pasado mucho tiempo, verificar escape
                if tiempoSinVer >= Wanted.ConfigPersecucion.tiempoEscape then
                    local puedeEscapar, _ = Wanted.PuedeEscapar(charId)
                    if puedeEscapar then
                        Wanted.ProcesarEscape(charId, 'tiempo_sin_avistamiento')
                    end
                end

                -- Notificar a policias del tiempo sin avistamiento
                if tiempoSinVer >= 30 and tiempoSinVer % 15 == 0 then
                    Wanted.NotificarPoliciasPersecucion(charId, 'sin_contacto_visual', {
                        char_id = charId,
                        tiempo_sin_ver = tiempoSinVer,
                        ultima_ubicacion = persecucion.ubicacion_actual,
                    })
                end
            end
        end
    end)
end

function Wanted.IniciarThreadUbicaciones()
    CreateThread(function()
        while true do
            Wait(5000) -- Cada 5 segundos

            local ahora = os.time()

            -- Limpiar ubicaciones antiguas (mas de 5 minutos)
            for charId, data in pairs(Wanted.ubicacionesConocidas) do
                if ahora - data.timestamp > 300 then
                    Wanted.ubicacionesConocidas[charId] = nil
                end
            end
        end
    end)
end

function Wanted.IniciarThreadTestigos()
    CreateThread(function()
        while true do
            Wait(30000) -- Cada 30 segundos

            local ahora = os.time()

            -- Limpiar testigos antiguos (mas de 2 minutos)
            for zona, testigos in pairs(Wanted.testigosPorZona) do
                for charId, data in pairs(testigos) do
                    if ahora - data.timestamp > 120 then
                        Wanted.testigosPorZona[zona][charId] = nil
                    end
                end

                -- Limpiar zona si esta vacia
                local count = 0
                for _ in pairs(Wanted.testigosPorZona[zona]) do count = count + 1 end
                if count == 0 then
                    Wanted.testigosPorZona[zona] = nil
                end
            end
        end
    end)
end

-- =====================================================================================
-- NOTIFICACIONES
-- =====================================================================================

--- Notificar al sospechoso
---@param charId number
---@param tipo string
---@param datos table
function Wanted.NotificarSospechoso(charId, tipo, datos)
    local source = AIT.Engines.Justice.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:justice:wanted:notify', source, {
            tipo = tipo,
            datos = datos,
        })
    end
end

--- Notificar a policias en una persecucion especifica
---@param charId number
---@param tipo string
---@param datos table
function Wanted.NotificarPoliciasPersecucion(charId, tipo, datos)
    local persecucion = Wanted.persecuciones[charId]
    if not persecucion then
        -- Notificar a todos los policias
        for oficialCharId, sourceId in pairs(AIT.Engines.Justice.policiasOnline) do
            TriggerClientEvent('ait:justice:wanted:police', sourceId, {
                tipo = tipo,
                datos = datos,
            })
        end
        return
    end

    for oficialId, _ in pairs(persecucion.oficiales) do
        local sourceId = AIT.Engines.Justice.policiasOnline[oficialId]
        if sourceId then
            TriggerClientEvent('ait:justice:wanted:police', sourceId, {
                tipo = tipo,
                datos = datos,
            })
        end
    end
end

--- Notificar a policias en una zona
---@param ubicacion table
---@param tipo string
---@param datos table
function Wanted.NotificarPoliciasZona(ubicacion, tipo, datos)
    for oficialCharId, sourceId in pairs(AIT.Engines.Justice.policiasOnline) do
        TriggerClientEvent('ait:justice:wanted:zone', sourceId, {
            tipo = tipo,
            datos = datos,
        })
    end
end

--- Enviar ubicacion a policias en persecucion
---@param charId number
---@param ubicacion table
---@param velocidad number|nil
function Wanted.EnviarUbicacionAPolicias(charId, ubicacion, velocidad)
    local persecucion = Wanted.persecuciones[charId]
    if not persecucion then return end

    for oficialId, _ in pairs(persecucion.oficiales) do
        local sourceId = AIT.Engines.Justice.policiasOnline[oficialId]
        if sourceId then
            TriggerClientEvent('ait:justice:wanted:location', sourceId, {
                char_id = charId,
                ubicacion = ubicacion,
                velocidad = velocidad,
            })
        end
    end
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

--- Calcular distancia entre dos puntos
---@param punto1 table
---@param punto2 table
---@return number
function Wanted.CalcularDistancia(punto1, punto2)
    if not punto1 or not punto2 then return 0 end

    local dx = (punto1.x or 0) - (punto2.x or 0)
    local dy = (punto1.y or 0) - (punto2.y or 0)
    local dz = (punto1.z or 0) - (punto2.z or 0)

    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

--- Obtener multiplicador de zona
---@param ubicacion table|nil
---@return number
function Wanted.ObtenerMultiplicadorZona(ubicacion)
    -- Por defecto, zona ciudad
    local zona = Wanted.DeterminarZona(ubicacion)
    local config = Wanted.ZonasConfig[zona]

    return config and config.multiplicadorBusqueda or 1.0
end

--- Determinar zona basada en ubicacion
---@param ubicacion table|nil
---@return string
function Wanted.DeterminarZona(ubicacion)
    if not ubicacion then return 'ciudad' end

    -- Esta es una logica simplificada, en produccion se usarian polizonas
    local x = ubicacion.x or 0
    local y = ubicacion.y or 0

    -- Zona ciudad (centro)
    if x > -2000 and x < 2000 and y > -2000 and y < 2000 then
        return 'ciudad'
    end

    -- Desierto (noreste)
    if x > 1500 and y > 2000 then
        return 'desierto'
    end

    -- Montanas (norte)
    if y > 3000 then
        return 'montana'
    end

    return 'rural'
end

--- Contar policias en un radio
---@param ubicacion table
---@param radio number
---@return number
function Wanted.ContarPoliciasEnRadio(ubicacion, radio)
    local count = 0

    for oficialId, sourceId in pairs(AIT.Engines.Justice.policiasOnline) do
        -- Obtener ubicacion del policia (esto normalmente vendria del cliente)
        local ubicacionPolicia = Wanted.ObtenerUbicacionPolicia(oficialId)
        if ubicacionPolicia then
            local distancia = Wanted.CalcularDistancia(ubicacion, ubicacionPolicia)
            if distancia <= radio then
                count = count + 1
            end
        end
    end

    return count
end

--- Obtener ubicacion de un policia
---@param charId number
---@return table|nil
function Wanted.ObtenerUbicacionPolicia(charId)
    -- Esta informacion normalmente se sincronizaria desde el cliente
    return Wanted.ubicacionesConocidas[charId] and Wanted.ubicacionesConocidas[charId].ubicacion
end

--- Actualizar stats del oficial
---@param oficialId number
---@param tipo string
---@param datos table
function Wanted.ActualizarStatsOficial(oficialId, tipo, datos)
    if tipo == 'captura' then
        MySQL.query([[
            INSERT INTO ait_justicia_stats_oficiales (char_id, sospechosos_capturados, persecuciones_exitosas)
            VALUES (?, 1, 1)
            ON DUPLICATE KEY UPDATE
                sospechosos_capturados = sospechosos_capturados + 1,
                persecuciones_exitosas = persecuciones_exitosas + 1
        ]], { oficialId })
    end
end

--- Actualizar stats del jugador
---@param charId number
---@param tipo string
---@param datos table
function Wanted.ActualizarStatsJugador(charId, tipo, datos)
    if tipo == 'escape' then
        MySQL.query([[
            INSERT INTO ait_justicia_stats (char_id, fugas_exitosas)
            VALUES (?, 1)
            ON DUPLICATE KEY UPDATE fugas_exitosas = fugas_exitosas + 1
        ]], { charId })
    end
end

--- Registrar log de persecucion
---@param persecucionId number
---@param accion string
---@param detalles table|nil
function Wanted.RegistrarLogPersecucion(persecucionId, accion, detalles)
    MySQL.insert([[
        INSERT INTO ait_justicia_logs (accion, detalles)
        VALUES (?, ?)
    ]], { accion, detalles and json.encode(detalles) or nil })
end

--- Registrar log de avistamiento
---@param charIdSospechoso number
---@param charIdReportador number
---@param ubicacion table
---@param opciones table|nil
function Wanted.RegistrarLogAvistamiento(charIdSospechoso, charIdReportador, ubicacion, opciones)
    MySQL.insert([[
        INSERT INTO ait_justicia_logs (char_id, oficial_id, accion, ubicacion, detalles)
        VALUES (?, ?, 'AVISTAMIENTO', ?, ?)
    ]], {
        charIdSospechoso,
        charIdReportador,
        json.encode(ubicacion),
        opciones and json.encode(opciones) or nil
    })
end

-- =====================================================================================
-- EVENTOS
-- =====================================================================================

function Wanted.RegistrarEventos()
    -- Actualizar ubicacion desde cliente
    RegisterNetEvent('ait:justice:wanted:updateLocation', function(ubicacion, velocidad, enVehiculo, vehiculoModelo)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid

        -- Solo procesar si esta buscado
        if AIT.Engines.Justice.EstaBuscado(charId) then
            Wanted.ActualizarUbicacionPersecucion(charId, ubicacion, velocidad, enVehiculo, vehiculoModelo)
        end
    end)

    -- Policia inicia persecucion
    RegisterNetEvent('ait:justice:wanted:startPursuit', function(targetId, ubicacion)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local oficialId = Player.PlayerData.citizenid

        -- Verificar que es policia
        if not AIT.Engines.Justice.policiasOnline[oficialId] then
            return
        end

        Wanted.IniciarPersecucion(targetId, oficialId, ubicacion)
    end)

    -- Policia se une a persecucion
    RegisterNetEvent('ait:justice:wanted:joinPursuit', function(targetId)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local oficialId = Player.PlayerData.citizenid

        if AIT.Engines.Justice.policiasOnline[oficialId] then
            Wanted.AnadirOficialPersecucion(targetId, oficialId)
        end
    end)

    -- Reportar avistamiento
    RegisterNetEvent('ait:justice:wanted:report', function(targetId, ubicacion, descripcion)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        Wanted.ReportarAvistamiento(charId, targetId, ubicacion, {
            descripcion = descripcion,
        })
    end)

    -- Verificar escape desde cliente
    RegisterNetEvent('ait:justice:wanted:checkEscape', function()
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local puedeEscapar, mensaje = Wanted.PuedeEscapar(charId)

        TriggerClientEvent('ait:justice:wanted:escapeResult', source, puedeEscapar, mensaje)

        if puedeEscapar and not Wanted.persecuciones[charId] then
            -- Decay natural
            AIT.Engines.Justice.ReducirWanted(charId, 1, 'Perdio a la policia')
        end
    end)

    -- Captura de sospechoso
    RegisterNetEvent('ait:justice:wanted:capture', function(targetId)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local oficialId = Player.PlayerData.citizenid

        if AIT.Engines.Justice.policiasOnline[oficialId] then
            Wanted.FinalizarPersecucion(targetId, 'capturado', {
                arrestadoPor = oficialId,
            })
        end
    end)
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Persecuciones
Wanted.StartPursuit = Wanted.IniciarPersecucion
Wanted.EndPursuit = Wanted.FinalizarPersecucion
Wanted.UpdateLocation = Wanted.ActualizarUbicacionPersecucion
Wanted.GetPursuit = function(charId) return Wanted.persecuciones[charId] end
Wanted.GetAllPursuits = function() return Wanted.persecuciones end

-- Escape
Wanted.CanEscape = Wanted.PuedeEscapar
Wanted.ProcessEscape = Wanted.ProcesarEscape

-- Reportes
Wanted.ReportSighting = Wanted.ReportarAvistamiento
Wanted.GetWitnesses = Wanted.ObtenerTestigos
Wanted.GetKnownLocation = function(charId) return Wanted.ubicacionesConocidas[charId] end

-- Zonas
Wanted.GetZone = Wanted.DeterminarZona
Wanted.GetZoneMultiplier = Wanted.ObtenerMultiplicadorZona

-- =====================================================================================
-- CREAR TABLAS ADICIONALES
-- =====================================================================================

CreateThread(function()
    Wait(1000) -- Esperar a que MySQL este listo

    -- Tabla de persecuciones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_persecuciones (
            persecucion_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            nivel_inicial INT NOT NULL,
            ubicacion_inicial JSON NULL,
            iniciada_por BIGINT NOT NULL,
            duracion INT NOT NULL DEFAULT 0,
            distancia DECIMAL(10,2) NOT NULL DEFAULT 0,
            vehiculos_usados JSON NULL,
            danos_causados BIGINT NOT NULL DEFAULT 0,
            resultado VARCHAR(32) NULL,
            estado VARCHAR(32) NOT NULL DEFAULT 'activa',
            iniciada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            finalizada_en DATETIME NULL,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_estado (estado),
            KEY idx_fecha (iniciada_en)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de cooldowns
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_cooldowns (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            tipo VARCHAR(32) NOT NULL,
            expira_en DATETIME NOT NULL,
            UNIQUE KEY idx_char_tipo (char_id, tipo),
            KEY idx_expira (expira_en)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end)

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.Justice.Wanted = Wanted

return Wanted
