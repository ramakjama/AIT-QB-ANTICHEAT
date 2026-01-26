-- =====================================================================================
-- ait-qb ENGINE DE FACCIONES - SISTEMA DE SERVICIO (DUTY)
-- Gestion de estados on/off duty, uniformes y bonus
-- Namespace: AIT.Engines.Factions.Duties
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Factions = AIT.Engines.Factions or {}

local Duties = {
    -- Cache de estados de servicio
    estadosServicio = {},
    -- Configuracion de uniformes por faccion
    uniformes = {},
    -- Bonus activos
    bonusActivos = {},
    -- Intervalos de actualizacion
    intervaloTiempo = 60000, -- 1 minuto
}

-- =====================================================================================
-- CONFIGURACION DE UNIFORMES POR DEFECTO
-- =====================================================================================

Duties.UniformesDefault = {
    policia = {
        hombre = {
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 55, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 0,
            ['pants_1'] = 25, ['pants_2'] = 0,
            ['shoes_1'] = 25, ['shoes_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
            ['chain_1'] = 0, ['chain_2'] = 0,
            ['bags_1'] = 0, ['bags_2'] = 0,
        },
        mujer = {
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 48, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 0,
            ['pants_1'] = 34, ['pants_2'] = 0,
            ['shoes_1'] = 25, ['shoes_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
            ['chain_1'] = 0, ['chain_2'] = 0,
            ['bags_1'] = 0, ['bags_2'] = 0,
        }
    },
    ems = {
        hombre = {
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 250, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 92,
            ['pants_1'] = 96, ['pants_2'] = 0,
            ['shoes_1'] = 54, ['shoes_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
        },
        mujer = {
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 258, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 101,
            ['pants_1'] = 99, ['pants_2'] = 0,
            ['shoes_1'] = 54, ['shoes_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
        }
    },
    mecanico = {
        hombre = {
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 0, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 0,
            ['pants_1'] = 3, ['pants_2'] = 0,
            ['shoes_1'] = 1, ['shoes_2'] = 0,
        },
        mujer = {
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 0, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 0,
            ['pants_1'] = 3, ['pants_2'] = 0,
            ['shoes_1'] = 1, ['shoes_2'] = 0,
        }
    }
}

-- =====================================================================================
-- CONFIGURACION DE BONUS
-- =====================================================================================

Duties.BonusConfig = {
    tiempo_servicio = {
        -- Bonus por tiempo continuo en servicio
        [1] = { horas = 1, porcentaje = 5, nombre = 'Hora completa' },
        [2] = { horas = 2, porcentaje = 10, nombre = 'Veterano del dia' },
        [3] = { horas = 4, porcentaje = 15, nombre = 'Dedicacion' },
        [4] = { horas = 8, porcentaje = 25, nombre = 'Servicio ejemplar' },
    },
    horario_pico = {
        -- Bonus por trabajar en horarios con pocos empleados
        activo = true,
        porcentaje = 20,
        minJugadores = 10,
        maxEmpleadosActivos = 3,
    },
    nocturno = {
        -- Bonus por turno nocturno (22:00 - 06:00)
        activo = true,
        porcentaje = 15,
        horaInicio = 22,
        horaFin = 6,
    },
    fin_semana = {
        -- Bonus fin de semana
        activo = true,
        porcentaje = 10,
        dias = { 0, 6 }, -- Domingo y Sabado
    }
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Duties.Initialize()
    -- Crear tabla de estado de servicio
    Duties.CrearTablas()

    -- Cargar uniformes personalizados
    Duties.CargarUniformes()

    -- Registrar eventos
    Duties.RegistrarEventos()

    -- Iniciar thread de seguimiento de tiempo
    Duties.IniciarThreadTiempo()

    -- Registrar callbacks
    Duties.RegistrarCallbacks()

    if AIT.Log then
        AIT.Log.info('FACTIONS:DUTIES', 'Sistema de servicio inicializado')
    end

    return true
end

function Duties.CrearTablas()
    -- Tabla de estado de servicio actual
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_duty_status (
            char_id BIGINT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            en_servicio TINYINT(1) NOT NULL DEFAULT 0,
            inicio_servicio DATETIME NULL,
            ropa_guardada JSON NULL,
            metadata JSON NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_faccion (faccion_id),
            KEY idx_en_servicio (en_servicio)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de historial de servicios
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_duty_history (
            historial_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            faccion_id BIGINT NOT NULL,
            inicio DATETIME NOT NULL,
            fin DATETIME NULL,
            duracion_segundos BIGINT NULL,
            salario_ganado BIGINT NOT NULL DEFAULT 0,
            bonus_ganado BIGINT NOT NULL DEFAULT 0,
            bonus_detalle JSON NULL,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_faccion (faccion_id),
            KEY idx_inicio (inicio),
            KEY idx_fin (fin)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de uniformes personalizados
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faction_uniformes (
            uniforme_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            nombre VARCHAR(64) NOT NULL,
            rango_minimo INT NOT NULL DEFAULT 1,
            genero ENUM('hombre', 'mujer', 'unisex') NOT NULL DEFAULT 'unisex',
            componentes JSON NOT NULL,
            props JSON NULL,
            activo TINYINT(1) NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY idx_faccion_nombre (faccion_id, nombre),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Duties.CargarUniformes()
    Duties.uniformes = AIT.Utils.DeepCopy(Duties.UniformesDefault)

    -- Cargar uniformes personalizados de la BD
    local uniformesDb = MySQL.query.await([[
        SELECT * FROM ait_faction_uniformes WHERE activo = 1
    ]])

    for _, uniforme in ipairs(uniformesDb or {}) do
        local faccionId = uniforme.faccion_id
        if not Duties.uniformes[faccionId] then
            Duties.uniformes[faccionId] = {}
        end

        local genero = uniforme.genero
        if genero == 'unisex' then
            Duties.uniformes[faccionId].hombre = json.decode(uniforme.componentes)
            Duties.uniformes[faccionId].mujer = json.decode(uniforme.componentes)
        else
            Duties.uniformes[faccionId][genero] = json.decode(uniforme.componentes)
        end
    end
end

-- =====================================================================================
-- GESTION DE SERVICIO
-- =====================================================================================

--- Entrar en servicio
---@param source number
---@param charId number
---@return boolean, string
function Duties.EntrarServicio(source, charId)
    -- Verificar que pertenece a una faccion
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    -- Verificar si la faccion permite duty
    local tipoConfig = Facciones.tipos[membresia.tipo]
    if not tipoConfig then
        return false, 'Tipo de faccion no configurado'
    end

    local permiteDuty = false
    for _, perm in ipairs(tipoConfig.permisos or {}) do
        if perm == 'duty' then
            permiteDuty = true
            break
        end
    end

    if not permiteDuty then
        return false, 'Tu faccion no tiene sistema de servicio'
    end

    -- Verificar si ya esta en servicio
    local estadoActual = Duties.ObtenerEstado(charId)
    if estadoActual and estadoActual.en_servicio == 1 then
        return false, 'Ya estas en servicio'
    end

    -- Guardar ropa actual
    local ropaActual = nil
    if source > 0 then
        ropaActual = Duties.ObtenerRopaJugador(source)
    end

    -- Registrar entrada en servicio
    MySQL.query.await([[
        INSERT INTO ait_duty_status (char_id, faccion_id, en_servicio, inicio_servicio, ropa_guardada)
        VALUES (?, ?, 1, NOW(), ?)
        ON DUPLICATE KEY UPDATE
            en_servicio = 1,
            inicio_servicio = NOW(),
            ropa_guardada = VALUES(ropa_guardada)
    ]], { charId, membresia.faccion_id, ropaActual and json.encode(ropaActual) or nil })

    -- Guardar en cache
    Duties.estadosServicio[charId] = {
        faccion_id = membresia.faccion_id,
        en_servicio = true,
        inicio = os.time(),
        ropa_guardada = ropaActual,
    }

    -- Aplicar uniforme
    if source > 0 then
        Duties.AplicarUniforme(source, membresia.faccion_id, charId)
    end

    -- Registrar en historial
    MySQL.insert([[
        INSERT INTO ait_duty_history (char_id, faccion_id, inicio)
        VALUES (?, ?, NOW())
    ]], { charId, membresia.faccion_id })

    -- Log
    Facciones.RegistrarLog(membresia.faccion_id, 'DUTY_INICIO', charId, nil, {
        hora = os.date('%H:%M:%S')
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.duty.started', {
            char_id = charId,
            faccion_id = membresia.faccion_id,
            source = source
        })
    end

    -- Notificar al cliente
    if source > 0 then
        TriggerClientEvent('ait:factions:duty:update', source, {
            en_servicio = true,
            faccion = membresia.nombre_corto,
            inicio = os.time()
        })
    end

    return true, 'Has entrado en servicio'
end

--- Salir de servicio
---@param source number
---@param charId number
---@return boolean, string
function Duties.SalirServicio(source, charId)
    local estadoActual = Duties.ObtenerEstado(charId)
    if not estadoActual or estadoActual.en_servicio ~= 1 then
        return false, 'No estas en servicio'
    end

    local faccionId = estadoActual.faccion_id
    local inicioServicio = estadoActual.inicio_servicio

    -- Calcular duracion
    local duracion = Duties.CalcularDuracion(inicioServicio)
    local duracionSegundos = duracion.total_segundos

    -- Calcular bonus
    local bonus = Duties.CalcularBonus(charId, faccionId, duracionSegundos)

    -- Actualizar estado
    MySQL.query.await([[
        UPDATE ait_duty_status
        SET en_servicio = 0, inicio_servicio = NULL
        WHERE char_id = ?
    ]], { charId })

    -- Actualizar historial
    MySQL.query.await([[
        UPDATE ait_duty_history
        SET fin = NOW(),
            duracion_segundos = ?,
            bonus_ganado = ?,
            bonus_detalle = ?
        WHERE char_id = ? AND faccion_id = ? AND fin IS NULL
        ORDER BY inicio DESC
        LIMIT 1
    ]], { duracionSegundos, bonus.total, json.encode(bonus.detalle), charId, faccionId })

    -- Actualizar tiempo total del miembro
    MySQL.query([[
        UPDATE ait_faccion_miembros
        SET tiempo_servicio_total = tiempo_servicio_total + ?,
            ultimo_servicio = NOW(),
            bonus_acumulado = bonus_acumulado + ?
        WHERE char_id = ? AND faccion_id = ?
    ]], { duracionSegundos, bonus.total, charId, faccionId })

    -- Restaurar ropa
    if source > 0 and estadoActual.ropa_guardada then
        local ropa = type(estadoActual.ropa_guardada) == 'string'
            and json.decode(estadoActual.ropa_guardada)
            or estadoActual.ropa_guardada

        if ropa then
            Duties.RestaurarRopa(source, ropa)
        end
    end

    -- Pagar bonus si aplica
    if bonus.total > 0 and AIT.Engines.economy then
        local Facciones = AIT.Engines.Factions
        local faccion = Facciones and Facciones.Obtener(faccionId)

        if faccion and faccion.tesoreria >= bonus.total then
            Facciones.RetirarTesoreriaInterno(faccionId, bonus.total, 'Bonus de servicio')
            AIT.Engines.economy.AddMoney(source, charId, bonus.total, 'bank', 'job_payment',
                'Bonus por servicio')
        end
    end

    -- Limpiar cache
    Duties.estadosServicio[charId] = nil

    -- Log
    local Facciones = AIT.Engines.Factions
    if Facciones then
        Facciones.RegistrarLog(faccionId, 'DUTY_FIN', charId, nil, {
            duracion = duracion.formateado,
            bonus = bonus.total
        })
    end

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.duty.ended', {
            char_id = charId,
            faccion_id = faccionId,
            duracion = duracionSegundos,
            bonus = bonus.total
        })
    end

    -- Notificar al cliente
    if source > 0 then
        TriggerClientEvent('ait:factions:duty:update', source, {
            en_servicio = false,
            duracion = duracion.formateado,
            bonus = bonus.total
        })
    end

    return true, ('Servicio finalizado. Duracion: %s | Bonus: $%s'):format(
        duracion.formateado,
        Duties.FormatearNumero(bonus.total)
    )
end

--- Toggle de servicio
---@param source number
---@param charId number
---@return boolean, string
function Duties.ToggleServicio(source, charId)
    local estadoActual = Duties.ObtenerEstado(charId)

    if estadoActual and estadoActual.en_servicio == 1 then
        return Duties.SalirServicio(source, charId)
    else
        return Duties.EntrarServicio(source, charId)
    end
end

--- Obtener estado de servicio
---@param charId number
---@return table|nil
function Duties.ObtenerEstado(charId)
    -- Cache primero
    if Duties.estadosServicio[charId] then
        return Duties.estadosServicio[charId]
    end

    -- Base de datos
    local estado = MySQL.query.await([[
        SELECT * FROM ait_duty_status WHERE char_id = ?
    ]], { charId })

    if estado and estado[1] then
        return estado[1]
    end

    return nil
end

--- Verificar si esta en servicio
---@param charId number
---@return boolean
function Duties.EstaEnServicio(charId)
    local estado = Duties.ObtenerEstado(charId)
    return estado and estado.en_servicio == 1
end

--- Obtener todos los miembros en servicio de una faccion
---@param faccionId number
---@return table
function Duties.ObtenerEnServicio(faccionId)
    return MySQL.query.await([[
        SELECT d.*, c.nombre as char_nombre, c.apellido as char_apellido,
               r.nombre as rango_nombre, r.nivel as rango_nivel
        FROM ait_duty_status d
        JOIN ait_faccion_miembros m ON d.char_id = m.char_id AND d.faccion_id = m.faccion_id
        JOIN ait_faccion_rangos r ON m.rango_id = r.rango_id
        LEFT JOIN ait_characters c ON d.char_id = c.char_id
        WHERE d.faccion_id = ? AND d.en_servicio = 1
        ORDER BY d.inicio_servicio ASC
    ]], { faccionId }) or {}
end

--- Contar miembros en servicio
---@param faccionId number
---@return number
function Duties.ContarEnServicio(faccionId)
    local result = MySQL.query.await([[
        SELECT COUNT(*) as total FROM ait_duty_status
        WHERE faccion_id = ? AND en_servicio = 1
    ]], { faccionId })

    return result and result[1] and result[1].total or 0
end

-- =====================================================================================
-- UNIFORMES
-- =====================================================================================

--- Aplicar uniforme de faccion
---@param source number
---@param faccionId number
---@param charId number
function Duties.AplicarUniforme(source, faccionId, charId)
    local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local genero = Player.PlayerData.charinfo.gender == 0 and 'hombre' or 'mujer'

    -- Buscar uniforme de la faccion
    local uniforme = nil

    -- Por ID de faccion
    if Duties.uniformes[faccionId] then
        uniforme = Duties.uniformes[faccionId][genero]
    end

    -- Por tipo de faccion
    if not uniforme then
        local Facciones = AIT.Engines.Factions
        if Facciones then
            local faccion = Facciones.Obtener(faccionId)
            if faccion and Duties.uniformes[faccion.tipo] then
                uniforme = Duties.uniformes[faccion.tipo][genero]
            end
        end
    end

    if uniforme then
        TriggerClientEvent('ait:factions:duty:setClothes', source, uniforme)
    end
end

--- Restaurar ropa guardada
---@param source number
---@param ropa table
function Duties.RestaurarRopa(source, ropa)
    if ropa then
        TriggerClientEvent('ait:factions:duty:setClothes', source, ropa)
    end
end

--- Obtener ropa actual del jugador (se llama desde cliente)
---@param source number
---@return table|nil
function Duties.ObtenerRopaJugador(source)
    -- Esto se sincroniza con el cliente
    local promesa = promise.new()

    TriggerClientEvent('ait:factions:duty:getClothes', source)

    -- Timeout de 5 segundos
    SetTimeout(5000, function()
        if promesa then
            promesa:resolve(nil)
        end
    end)

    -- El cliente responde con ait:factions:duty:clothesData
    -- Esto es manejado en RegistrarEventos

    return Citizen.Await(promesa)
end

--- Guardar uniforme personalizado
---@param faccionId number
---@param datos table
---@return boolean, number|string
function Duties.GuardarUniforme(faccionId, datos)
    --[[
        datos = {
            nombre = 'Uniforme Patrulla',
            rango_minimo = 1,
            genero = 'unisex',
            componentes = { ... },
            props = { ... }
        }
    ]]

    local uniformeId = MySQL.insert.await([[
        INSERT INTO ait_faction_uniformes
        (faccion_id, nombre, rango_minimo, genero, componentes, props)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            rango_minimo = VALUES(rango_minimo),
            componentes = VALUES(componentes),
            props = VALUES(props)
    ]], {
        faccionId,
        datos.nombre,
        datos.rango_minimo or 1,
        datos.genero or 'unisex',
        json.encode(datos.componentes),
        datos.props and json.encode(datos.props) or nil
    })

    -- Recargar uniformes
    Duties.CargarUniformes()

    return true, uniformeId
end

-- =====================================================================================
-- CALCULO DE BONUS
-- =====================================================================================

--- Calcular bonus por servicio
---@param charId number
---@param faccionId number
---@param duracionSegundos number
---@return table
function Duties.CalcularBonus(charId, faccionId, duracionSegundos)
    local bonus = {
        total = 0,
        detalle = {}
    }

    local horasServicio = duracionSegundos / 3600

    -- Bonus por tiempo de servicio
    for _, config in ipairs(Duties.BonusConfig.tiempo_servicio) do
        if horasServicio >= config.horas then
            local Facciones = AIT.Engines.Factions
            local faccion = Facciones and Facciones.Obtener(faccionId)

            if faccion then
                local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
                if membresia then
                    local salarioBase = faccion.salario_base * (membresia.salario_mult or 1.0)
                    local bonusMonto = math.floor(salarioBase * (config.porcentaje / 100))

                    bonus.total = bonus.total + bonusMonto
                    table.insert(bonus.detalle, {
                        tipo = 'tiempo_servicio',
                        nombre = config.nombre,
                        porcentaje = config.porcentaje,
                        monto = bonusMonto
                    })
                end
            end
        end
    end

    -- Bonus horario pico (pocos empleados activos)
    if Duties.BonusConfig.horario_pico.activo then
        local jugadoresOnline = #GetPlayers()
        local empleadosActivos = Duties.ContarEnServicio(faccionId)

        if jugadoresOnline >= Duties.BonusConfig.horario_pico.minJugadores
            and empleadosActivos <= Duties.BonusConfig.horario_pico.maxEmpleadosActivos then

            local Facciones = AIT.Engines.Factions
            local faccion = Facciones and Facciones.Obtener(faccionId)

            if faccion then
                local bonusMonto = math.floor(faccion.salario_base * (Duties.BonusConfig.horario_pico.porcentaje / 100) * horasServicio)

                bonus.total = bonus.total + bonusMonto
                table.insert(bonus.detalle, {
                    tipo = 'horario_pico',
                    nombre = 'Bonus horario pico',
                    porcentaje = Duties.BonusConfig.horario_pico.porcentaje,
                    monto = bonusMonto
                })
            end
        end
    end

    -- Bonus nocturno
    if Duties.BonusConfig.nocturno.activo then
        local horaActual = tonumber(os.date('%H'))
        local esNocturno = horaActual >= Duties.BonusConfig.nocturno.horaInicio
            or horaActual < Duties.BonusConfig.nocturno.horaFin

        if esNocturno then
            local Facciones = AIT.Engines.Factions
            local faccion = Facciones and Facciones.Obtener(faccionId)

            if faccion then
                local bonusMonto = math.floor(faccion.salario_base * (Duties.BonusConfig.nocturno.porcentaje / 100) * horasServicio)

                bonus.total = bonus.total + bonusMonto
                table.insert(bonus.detalle, {
                    tipo = 'nocturno',
                    nombre = 'Bonus turno nocturno',
                    porcentaje = Duties.BonusConfig.nocturno.porcentaje,
                    monto = bonusMonto
                })
            end
        end
    end

    -- Bonus fin de semana
    if Duties.BonusConfig.fin_semana.activo then
        local diaActual = tonumber(os.date('%w'))
        local esFinDeSemana = false

        for _, dia in ipairs(Duties.BonusConfig.fin_semana.dias) do
            if diaActual == dia then
                esFinDeSemana = true
                break
            end
        end

        if esFinDeSemana then
            local Facciones = AIT.Engines.Factions
            local faccion = Facciones and Facciones.Obtener(faccionId)

            if faccion then
                local bonusMonto = math.floor(faccion.salario_base * (Duties.BonusConfig.fin_semana.porcentaje / 100) * horasServicio)

                bonus.total = bonus.total + bonusMonto
                table.insert(bonus.detalle, {
                    tipo = 'fin_semana',
                    nombre = 'Bonus fin de semana',
                    porcentaje = Duties.BonusConfig.fin_semana.porcentaje,
                    monto = bonusMonto
                })
            end
        end
    end

    return bonus
end

-- =====================================================================================
-- ESTADISTICAS
-- =====================================================================================

--- Obtener estadisticas de servicio de un miembro
---@param charId number
---@return table
function Duties.ObtenerEstadisticas(charId)
    local stats = MySQL.query.await([[
        SELECT
            COUNT(*) as total_servicios,
            COALESCE(SUM(duracion_segundos), 0) as tiempo_total,
            COALESCE(AVG(duracion_segundos), 0) as promedio_duracion,
            COALESCE(SUM(salario_ganado), 0) as salario_total,
            COALESCE(SUM(bonus_ganado), 0) as bonus_total,
            MAX(inicio) as ultimo_servicio
        FROM ait_duty_history
        WHERE char_id = ?
    ]], { charId })

    if stats and stats[1] then
        local data = stats[1]
        return {
            total_servicios = data.total_servicios or 0,
            tiempo_total = data.tiempo_total or 0,
            tiempo_formateado = Duties.FormatearDuracion(data.tiempo_total or 0),
            promedio_duracion = data.promedio_duracion or 0,
            salario_total = data.salario_total or 0,
            bonus_total = data.bonus_total or 0,
            ultimo_servicio = data.ultimo_servicio,
        }
    end

    return {
        total_servicios = 0,
        tiempo_total = 0,
        tiempo_formateado = '0h 0m',
        promedio_duracion = 0,
        salario_total = 0,
        bonus_total = 0,
        ultimo_servicio = nil,
    }
end

--- Obtener historial de servicios
---@param charId number
---@param limite number|nil
---@return table
function Duties.ObtenerHistorial(charId, limite)
    limite = limite or 20

    return MySQL.query.await([[
        SELECT h.*, f.nombre as faccion_nombre, f.nombre_corto
        FROM ait_duty_history h
        JOIN ait_facciones f ON h.faccion_id = f.faccion_id
        WHERE h.char_id = ?
        ORDER BY h.inicio DESC
        LIMIT ?
    ]], { charId, limite }) or {}
end

--- Obtener ranking de tiempo en servicio de una faccion
---@param faccionId number
---@param periodo string|nil 'dia', 'semana', 'mes', 'total'
---@param limite number|nil
---@return table
function Duties.ObtenerRanking(faccionId, periodo, limite)
    periodo = periodo or 'semana'
    limite = limite or 10

    local filtroFecha = ''
    if periodo == 'dia' then
        filtroFecha = 'AND h.inicio >= DATE_SUB(NOW(), INTERVAL 1 DAY)'
    elseif periodo == 'semana' then
        filtroFecha = 'AND h.inicio >= DATE_SUB(NOW(), INTERVAL 1 WEEK)'
    elseif periodo == 'mes' then
        filtroFecha = 'AND h.inicio >= DATE_SUB(NOW(), INTERVAL 1 MONTH)'
    end

    return MySQL.query.await([[
        SELECT
            h.char_id,
            c.nombre as char_nombre,
            c.apellido as char_apellido,
            r.nombre as rango_nombre,
            SUM(h.duracion_segundos) as tiempo_total,
            COUNT(*) as servicios,
            SUM(h.bonus_ganado) as bonus_total
        FROM ait_duty_history h
        JOIN ait_characters c ON h.char_id = c.char_id
        JOIN ait_faccion_miembros m ON h.char_id = m.char_id AND h.faccion_id = m.faccion_id
        JOIN ait_faccion_rangos r ON m.rango_id = r.rango_id
        WHERE h.faccion_id = ? AND h.fin IS NOT NULL
    ]] .. filtroFecha .. [[
        GROUP BY h.char_id
        ORDER BY tiempo_total DESC
        LIMIT ?
    ]], { faccionId, limite }) or {}
end

-- =====================================================================================
-- THREAD DE SEGUIMIENTO
-- =====================================================================================

function Duties.IniciarThreadTiempo()
    CreateThread(function()
        while true do
            Wait(Duties.intervaloTiempo)

            -- Actualizar tiempos de servicio activos
            for charId, estado in pairs(Duties.estadosServicio) do
                if estado.en_servicio then
                    local duracion = os.time() - estado.inicio

                    -- Notificar bonus por tiempo si aplica
                    local horasServicio = duracion / 3600

                    for _, config in ipairs(Duties.BonusConfig.tiempo_servicio) do
                        -- Notificar cuando se alcanza un hito
                        local horasAnteriores = (duracion - 60) / 3600
                        if horasServicio >= config.horas and horasAnteriores < config.horas then
                            -- Buscar source del jugador
                            local Facciones = AIT.Engines.Factions
                            if Facciones and Facciones.miembrosOnline[estado.faccion_id] then
                                local sourceId = Facciones.miembrosOnline[estado.faccion_id][charId]
                                if sourceId then
                                    TriggerClientEvent('ait:factions:duty:bonusNotify', sourceId, {
                                        tipo = config.nombre,
                                        porcentaje = config.porcentaje,
                                        horas = config.horas
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- =====================================================================================
-- EVENTOS
-- =====================================================================================

function Duties.RegistrarEventos()
    -- Toggle duty
    RegisterNetEvent('ait:factions:duty:toggle', function()
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, mensaje = Duties.ToggleServicio(source, charId)

        TriggerClientEvent('QBCore:Notify', source, mensaje, success and 'success' or 'error')
    end)

    -- Respuesta de ropa del cliente
    RegisterNetEvent('ait:factions:duty:clothesData', function(ropa)
        local source = source
        -- Almacenar temporalmente
        if Duties.pendingClothesRequests and Duties.pendingClothesRequests[source] then
            Duties.pendingClothesRequests[source]:resolve(ropa)
            Duties.pendingClothesRequests[source] = nil
        end
    end)

    -- Jugador desconectado - finalizar servicio automaticamente
    AddEventHandler('playerDropped', function(reason)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if Player then
            local charId = Player.PlayerData.citizenid
            if Duties.EstaEnServicio(charId) then
                -- Finalizar servicio sin restaurar ropa (desconectado)
                Duties.SalirServicio(0, charId)
            end
        end
    end)
end

function Duties.RegistrarCallbacks()
    -- Callback para obtener estado de servicio
    if AIT.QBCore then
        AIT.QBCore.Functions.CreateCallback('ait:factions:duty:getStatus', function(source, cb)
            local Player = AIT.QBCore.Functions.GetPlayer(source)
            if not Player then
                cb(nil)
                return
            end

            local charId = Player.PlayerData.citizenid
            local estado = Duties.ObtenerEstado(charId)

            if estado and estado.en_servicio == 1 then
                local duracion = Duties.CalcularDuracion(estado.inicio_servicio)
                cb({
                    en_servicio = true,
                    inicio = estado.inicio_servicio,
                    duracion = duracion,
                    faccion_id = estado.faccion_id
                })
            else
                cb({ en_servicio = false })
            end
        end)

        -- Callback para estadisticas
        AIT.QBCore.Functions.CreateCallback('ait:factions:duty:getStats', function(source, cb)
            local Player = AIT.QBCore.Functions.GetPlayer(source)
            if not Player then
                cb(nil)
                return
            end

            local charId = Player.PlayerData.citizenid
            cb(Duties.ObtenerEstadisticas(charId))
        end)
    end
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Duties.CalcularDuracion(inicio)
    local inicioTime
    if type(inicio) == 'string' then
        -- Parsear datetime de MySQL
        local pattern = '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
        local year, month, day, hour, min, sec = inicio:match(pattern)
        if year then
            inicioTime = os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = tonumber(sec)
            })
        else
            inicioTime = os.time()
        end
    else
        inicioTime = inicio
    end

    local ahora = os.time()
    local segundos = ahora - inicioTime

    return {
        total_segundos = segundos,
        horas = math.floor(segundos / 3600),
        minutos = math.floor((segundos % 3600) / 60),
        segundos = segundos % 60,
        formateado = Duties.FormatearDuracion(segundos)
    }
end

function Duties.FormatearDuracion(segundos)
    local horas = math.floor(segundos / 3600)
    local minutos = math.floor((segundos % 3600) / 60)

    if horas > 0 then
        return ('%dh %dm'):format(horas, minutos)
    else
        return ('%dm'):format(minutos)
    end
end

function Duties.FormatearNumero(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return formatted
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

Duties.GoOnDuty = Duties.EntrarServicio
Duties.GoOffDuty = Duties.SalirServicio
Duties.Toggle = Duties.ToggleServicio
Duties.IsOnDuty = Duties.EstaEnServicio
Duties.GetStatus = Duties.ObtenerEstado
Duties.GetOnDuty = Duties.ObtenerEnServicio
Duties.CountOnDuty = Duties.ContarEnServicio
Duties.GetStats = Duties.ObtenerEstadisticas
Duties.GetHistory = Duties.ObtenerHistorial
Duties.GetRanking = Duties.ObtenerRanking

-- =====================================================================================
-- REGISTRAR EN ENGINE
-- =====================================================================================

AIT.Engines.Factions.Duties = Duties

return Duties
