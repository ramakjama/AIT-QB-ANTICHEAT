-- =====================================================================================
-- ait-qb ENGINE DE JUSTICIA - SISTEMA DE CARCEL
-- Sistema de carcel completo con trabajos, reduccion de pena y escape
-- Namespace: AIT.Engines.Justice.Jail
-- Optimizado para 2048 slots
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Justice = AIT.Engines.Justice or {}

local Carcel = {
    -- Cache de presos activos
    presos = {},
    -- Celdas ocupadas
    celdasOcupadas = {},
    -- Trabajos en progreso
    trabajosActivos = {},
    -- Intentos de fuga en curso
    intentosFuga = {},
    -- Configuracion de trabajos
    trabajos = {},
    -- Coordenadas de la prision
    ubicaciones = {},
}

-- =====================================================================================
-- CONFIGURACION DE LA PRISION
-- =====================================================================================

Carcel.Config = {
    -- Tiempo minimo de condena (minutos)
    tiempoMinimo = 1,
    -- Tiempo maximo de condena (minutos)
    tiempoMaximo = 720, -- 12 horas
    -- Reduccion por buen comportamiento (%)
    reduccionBuenComportamiento = 15,
    -- Reduccion por trabajo (minutos por tarea)
    reduccionPorTrabajo = 2,
    -- Maximo de reduccion por trabajos (%)
    maxReduccionTrabajos = 50,
    -- Penalizacion por intento de fuga fallido (minutos)
    penalizacionFugaFallida = 30,
    -- Penalizacion por fuga exitosa al ser recapturado
    penalizacionRecaptura = 60,
    -- Cooldown entre intentos de fuga (minutos)
    cooldownFuga = 15,
    -- Probabilidad base de exito de fuga (%)
    probabilidadFugaBase = 5,
    -- Numero maximo de celdas
    maxCeldas = 50,
}

-- =====================================================================================
-- CONFIGURACION DE CELDAS
-- =====================================================================================

Carcel.Celdas = {
    -- Celdas individuales
    individual = {
        cantidad = 30,
        capacidad = 1,
        coords = {
            { x = 1691.0, y = 2565.0, z = 45.5 }, -- Ejemplo de coords
        },
        beneficios = {},
    },
    -- Celdas compartidas
    compartida = {
        cantidad = 15,
        capacidad = 2,
        coords = {},
        beneficios = { reduccion_tiempo = 5 }, -- 5% menos tiempo
    },
    -- Celda de aislamiento
    aislamiento = {
        cantidad = 5,
        capacidad = 1,
        coords = {},
        beneficios = {},
        penalizaciones = { sin_trabajos = true, sin_reduccion = true },
    },
}

-- =====================================================================================
-- CONFIGURACION DE TRABAJOS EN PRISION
-- =====================================================================================

Carcel.TrabajosPrision = {
    limpieza = {
        nombre = 'Limpieza',
        descripcion = 'Limpiar las instalaciones de la prision',
        duracion = 120, -- segundos
        reduccion = 1, -- minutos reducidos
        xp = 5,
        repetible = true,
        cooldown = 180, -- segundos
        requisitos = {},
        ubicacion = { x = 1750.0, y = 2500.0, z = 45.5 },
        icono = 'fa-broom',
    },
    cocina = {
        nombre = 'Cocina',
        descripcion = 'Ayudar en la cocina de la prision',
        duracion = 180,
        reduccion = 2,
        xp = 10,
        repetible = true,
        cooldown = 300,
        requisitos = { comportamiento_minimo = 70 },
        ubicacion = { x = 1760.0, y = 2510.0, z = 45.5 },
        icono = 'fa-utensils',
    },
    lavanderia = {
        nombre = 'Lavanderia',
        descripcion = 'Lavar y doblar ropa',
        duracion = 150,
        reduccion = 1.5,
        xp = 8,
        repetible = true,
        cooldown = 240,
        requisitos = {},
        ubicacion = { x = 1770.0, y = 2520.0, z = 45.5 },
        icono = 'fa-tshirt',
    },
    taller = {
        nombre = 'Taller Mecanico',
        descripcion = 'Trabajar en el taller de reparacion',
        duracion = 240,
        reduccion = 3,
        xp = 15,
        repetible = true,
        cooldown = 600,
        requisitos = { comportamiento_minimo = 80 },
        ubicacion = { x = 1780.0, y = 2530.0, z = 45.5 },
        icono = 'fa-wrench',
    },
    biblioteca = {
        nombre = 'Biblioteca',
        descripcion = 'Organizar y mantener la biblioteca',
        duracion = 200,
        reduccion = 2,
        xp = 12,
        repetible = true,
        cooldown = 360,
        requisitos = { comportamiento_minimo = 60 },
        ubicacion = { x = 1790.0, y = 2540.0, z = 45.5 },
        icono = 'fa-book',
    },
    electricidad = {
        nombre = 'Mantenimiento Electrico',
        descripcion = 'Reparar instalaciones electricas',
        duracion = 300,
        reduccion = 4,
        xp = 20,
        repetible = true,
        cooldown = 900,
        requisitos = { comportamiento_minimo = 90 },
        ubicacion = { x = 1800.0, y = 2550.0, z = 45.5 },
        icono = 'fa-bolt',
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Carcel.Initialize()
    -- Crear tablas adicionales
    Carcel.CrearTablas()

    -- Cargar presos activos
    Carcel.CargarPresosActivos()

    -- Cargar celdas ocupadas
    Carcel.CargarCeldasOcupadas()

    -- Registrar eventos
    Carcel.RegistrarEventos()

    -- Registrar comandos
    Carcel.RegistrarComandos()

    -- Iniciar thread de tiempo de condena
    Carcel.IniciarThreadCondena()

    -- Iniciar thread de trabajos
    Carcel.IniciarThreadTrabajos()

    if AIT.Log then
        AIT.Log.info('JUSTICE:JAIL', 'Sistema de carcel inicializado')
    end

    return true
end

function Carcel.CrearTablas()
    -- Tabla de trabajos de presos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_carcel_trabajos (
            trabajo_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            carcel_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            tipo_trabajo VARCHAR(64) NOT NULL,
            tiempo_reducido INT NOT NULL DEFAULT 0,
            xp_ganada INT NOT NULL DEFAULT 0,
            completado TINYINT(1) NOT NULL DEFAULT 0,
            fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_fin DATETIME NULL,
            KEY idx_carcel (carcel_id),
            KEY idx_char (char_id),
            KEY idx_fecha (fecha_inicio),
            FOREIGN KEY (carcel_id) REFERENCES ait_justicia_carcel(carcel_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de intentos de fuga
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_fugas (
            fuga_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            carcel_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            metodo VARCHAR(64) NOT NULL,
            exitoso TINYINT(1) NOT NULL DEFAULT 0,
            complices JSON NULL,
            penalizacion INT NOT NULL DEFAULT 0,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            recapturado TINYINT(1) NOT NULL DEFAULT 0,
            fecha_recaptura DATETIME NULL,
            recapturado_por BIGINT NULL,
            metadata JSON NULL,
            KEY idx_carcel (carcel_id),
            KEY idx_char (char_id),
            KEY idx_fecha (fecha),
            FOREIGN KEY (carcel_id) REFERENCES ait_justicia_carcel(carcel_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de comportamiento
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_comportamiento (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            carcel_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            tipo VARCHAR(64) NOT NULL,
            puntos INT NOT NULL,
            descripcion TEXT NULL,
            registrado_por BIGINT NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_carcel (carcel_id),
            KEY idx_char (char_id),
            FOREIGN KEY (carcel_id) REFERENCES ait_justicia_carcel(carcel_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

function Carcel.CargarPresosActivos()
    local presos = MySQL.query.await([[
        SELECT c.*, ch.nombre, ch.apellido
        FROM ait_justicia_carcel c
        LEFT JOIN ait_characters ch ON c.char_id = ch.char_id
        WHERE c.estado = 'cumpliendo'
    ]])

    Carcel.presos = {}
    for _, preso in ipairs(presos or {}) do
        preso.trabajo_realizado = preso.trabajo_realizado and json.decode(preso.trabajo_realizado) or {}
        preso.metadata = preso.metadata and json.decode(preso.metadata) or {}

        Carcel.presos[preso.char_id] = preso

        -- Actualizar referencia en Justice principal
        if AIT.Engines.Justice.enCarcel then
            AIT.Engines.Justice.enCarcel[preso.char_id] = preso
        end
    end

    if AIT.Log then
        AIT.Log.info('JUSTICE:JAIL', ('Cargados %d presos activos'):format(#(presos or {})))
    end
end

function Carcel.CargarCeldasOcupadas()
    Carcel.celdasOcupadas = {}

    for charId, preso in pairs(Carcel.presos) do
        if preso.celda then
            Carcel.celdasOcupadas[preso.celda] = charId
        end
    end
end

-- =====================================================================================
-- GESTION DE ENCARCELAMIENTO
-- =====================================================================================

--- Encarcelar a un jugador
---@param charId number
---@param tiempoMinutos number
---@param opciones table|nil
---@return boolean, number|string
function Carcel.Encarcelar(charId, tiempoMinutos, opciones)
    opciones = opciones or {}

    -- Validar tiempo
    tiempoMinutos = math.max(Carcel.Config.tiempoMinimo, math.min(Carcel.Config.tiempoMaximo, tiempoMinutos))

    -- Verificar si ya esta en carcel
    if Carcel.presos[charId] then
        -- Anadir tiempo a condena existente
        return Carcel.ExtenderCondena(charId, tiempoMinutos, opciones.motivo or 'Nuevos cargos')
    end

    -- Asignar celda
    local celda = Carcel.AsignarCelda(opciones.tipoCelda)
    if not celda then
        return false, 'No hay celdas disponibles'
    end

    -- Calcular fecha de liberacion estimada
    local fechaLiberacion = os.date('%Y-%m-%d %H:%M:%S', os.time() + (tiempoMinutos * 60))

    -- Crear registro de antecedente si no existe
    local antecedenteId = opciones.antecedenteId
    if not antecedenteId and opciones.delitos then
        -- El antecedente ya deberia existir del sistema de wanted
    end

    -- Insertar en carcel
    local carcelId = MySQL.insert.await([[
        INSERT INTO ait_justicia_carcel
        (char_id, antecedente_id, tiempo_total, celda, fecha_liberacion_estimada, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        charId,
        antecedenteId,
        tiempoMinutos,
        celda,
        fechaLiberacion,
        opciones.metadata and json.encode(opciones.metadata) or nil,
    })

    if not carcelId then
        return false, 'Error al crear registro de carcel'
    end

    -- Actualizar cache
    Carcel.presos[charId] = {
        carcel_id = carcelId,
        char_id = charId,
        antecedente_id = antecedenteId,
        tiempo_total = tiempoMinutos,
        tiempo_cumplido = 0,
        tiempo_reducido = 0,
        celda = celda,
        comportamiento = 100,
        intentos_fuga = 0,
        estado = 'cumpliendo',
        fecha_ingreso = os.date('%Y-%m-%d %H:%M:%S'),
        fecha_liberacion_estimada = fechaLiberacion,
        trabajo_realizado = {},
    }

    Carcel.celdasOcupadas[celda] = charId

    -- Actualizar referencia en Justice principal
    if AIT.Engines.Justice.enCarcel then
        AIT.Engines.Justice.enCarcel[charId] = Carcel.presos[charId]
    end

    -- Teletransportar al jugador a la carcel
    Carcel.TeletransportarACarcel(charId, celda)

    -- Quitar items prohibidos
    Carcel.RequisarItems(charId)

    -- Log
    Carcel.RegistrarLog(charId, opciones.arrestadoPor, 'ENCARCELADO', {
        tiempo = tiempoMinutos,
        celda = celda,
        delitos = opciones.delitos,
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.jail.imprisoned', {
            char_id = charId,
            carcel_id = carcelId,
            tiempo = tiempoMinutos,
            celda = celda,
        })
    end

    -- Notificar al jugador
    Carcel.NotificarPreso(charId, 'encarcelado', {
        tiempo = tiempoMinutos,
        celda = celda,
    })

    return true, carcelId
end

--- Extender condena de un preso
---@param charId number
---@param tiempoAdicional number
---@param motivo string|nil
---@return boolean, string
function Carcel.ExtenderCondena(charId, tiempoAdicional, motivo)
    local preso = Carcel.presos[charId]
    if not preso then
        return false, 'El jugador no esta en carcel'
    end

    local nuevoTiempoTotal = math.min(
        Carcel.Config.tiempoMaximo,
        preso.tiempo_total + tiempoAdicional
    )

    local tiempoRestante = nuevoTiempoTotal - preso.tiempo_cumplido - preso.tiempo_reducido
    local nuevaFechaLiberacion = os.date('%Y-%m-%d %H:%M:%S', os.time() + (tiempoRestante * 60))

    MySQL.query([[
        UPDATE ait_justicia_carcel
        SET tiempo_total = ?, fecha_liberacion_estimada = ?, notas = CONCAT(COALESCE(notas, ''), '\n', ?)
        WHERE carcel_id = ?
    ]], {
        nuevoTiempoTotal,
        nuevaFechaLiberacion,
        ('[%s] +%d min: %s'):format(os.date('%Y-%m-%d %H:%M'), tiempoAdicional, motivo or 'Extension'),
        preso.carcel_id
    })

    preso.tiempo_total = nuevoTiempoTotal
    preso.fecha_liberacion_estimada = nuevaFechaLiberacion

    -- Log
    Carcel.RegistrarLog(charId, nil, 'CONDENA_EXTENDIDA', {
        tiempo_adicional = tiempoAdicional,
        tiempo_total = nuevoTiempoTotal,
        motivo = motivo,
    })

    -- Notificar
    Carcel.NotificarPreso(charId, 'condena_extendida', {
        tiempo_adicional = tiempoAdicional,
        tiempo_restante = tiempoRestante,
        motivo = motivo,
    })

    return true, ('Condena extendida en %d minutos'):format(tiempoAdicional)
end

--- Liberar a un preso
---@param charId number
---@param opciones table|nil
---@return boolean, string
function Carcel.Liberar(charId, opciones)
    opciones = opciones or {}

    local preso = Carcel.presos[charId]
    if not preso then
        return false, 'El jugador no esta en carcel'
    end

    local ahora = os.date('%Y-%m-%d %H:%M:%S')

    -- Actualizar BD
    MySQL.query([[
        UPDATE ait_justicia_carcel
        SET estado = 'liberado', fecha_liberacion = ?, liberado_por = ?
        WHERE carcel_id = ?
    ]], { ahora, opciones.liberadoPor, preso.carcel_id })

    -- Liberar celda
    if preso.celda then
        Carcel.celdasOcupadas[preso.celda] = nil
    end

    -- Limpiar cache
    Carcel.presos[charId] = nil
    if AIT.Engines.Justice.enCarcel then
        AIT.Engines.Justice.enCarcel[charId] = nil
    end

    -- Teletransportar fuera de la carcel
    Carcel.TeletransportarFueraCarcel(charId)

    -- Devolver items requisados (si aplica)
    if not opciones.sinItems then
        Carcel.DevolverItems(charId)
    end

    -- Log
    Carcel.RegistrarLog(charId, opciones.liberadoPor, 'LIBERADO', {
        tiempo_cumplido = preso.tiempo_cumplido,
        tiempo_reducido = preso.tiempo_reducido,
        comportamiento_final = preso.comportamiento,
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.jail.released', {
            char_id = charId,
            carcel_id = preso.carcel_id,
            tiempo_cumplido = preso.tiempo_cumplido,
        })
    end

    -- Notificar
    Carcel.NotificarPreso(charId, 'liberado', {
        tiempo_cumplido = preso.tiempo_cumplido,
    })

    return true, 'Liberado de la carcel'
end

-- =====================================================================================
-- SISTEMA DE TRABAJOS EN PRISION
-- =====================================================================================

--- Iniciar un trabajo en prision
---@param charId number
---@param tipoTrabajo string
---@return boolean, string
function Carcel.IniciarTrabajo(charId, tipoTrabajo)
    local preso = Carcel.presos[charId]
    if not preso then
        return false, 'No estas en la carcel'
    end

    -- Verificar que no este en aislamiento
    if preso.celda and preso.celda:find('aislamiento') then
        return false, 'No puedes trabajar estando en aislamiento'
    end

    local trabajo = Carcel.TrabajosPrision[tipoTrabajo]
    if not trabajo then
        return false, 'Trabajo no disponible'
    end

    -- Verificar requisitos
    if trabajo.requisitos.comportamiento_minimo then
        if preso.comportamiento < trabajo.requisitos.comportamiento_minimo then
            return false, ('Necesitas %d%% de comportamiento'):format(trabajo.requisitos.comportamiento_minimo)
        end
    end

    -- Verificar cooldown
    if Carcel.trabajosActivos[charId] then
        return false, 'Ya estas realizando un trabajo'
    end

    local cooldownKey = charId .. ':' .. tipoTrabajo
    if Carcel.cooldownsTrabajos and Carcel.cooldownsTrabajos[cooldownKey] then
        local tiempoRestante = Carcel.cooldownsTrabajos[cooldownKey] - os.time()
        if tiempoRestante > 0 then
            return false, ('Disponible en %d segundos'):format(tiempoRestante)
        end
    end

    -- Verificar limite de reduccion
    local maxReduccion = math.floor(preso.tiempo_total * (Carcel.Config.maxReduccionTrabajos / 100))
    if preso.tiempo_reducido >= maxReduccion then
        return false, 'Has alcanzado el limite de reduccion por trabajos'
    end

    -- Iniciar trabajo
    local trabajoId = MySQL.insert.await([[
        INSERT INTO ait_justicia_carcel_trabajos
        (carcel_id, char_id, tipo_trabajo, tiempo_reducido, xp_ganada)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        preso.carcel_id,
        charId,
        tipoTrabajo,
        trabajo.reduccion,
        trabajo.xp,
    })

    Carcel.trabajosActivos[charId] = {
        trabajo_id = trabajoId,
        tipo = tipoTrabajo,
        config = trabajo,
        inicio = os.time(),
        fin_esperado = os.time() + trabajo.duracion,
    }

    -- Log
    Carcel.RegistrarLog(charId, nil, 'TRABAJO_INICIADO', {
        tipo = tipoTrabajo,
        duracion = trabajo.duracion,
    })

    -- Notificar
    Carcel.NotificarPreso(charId, 'trabajo_iniciado', {
        tipo = tipoTrabajo,
        nombre = trabajo.nombre,
        duracion = trabajo.duracion,
        reduccion = trabajo.reduccion,
    })

    return true, ('Trabajo iniciado: %s (%d segundos)'):format(trabajo.nombre, trabajo.duracion)
end

--- Completar un trabajo en prision
---@param charId number
---@return boolean, string
function Carcel.CompletarTrabajo(charId)
    local trabajoActivo = Carcel.trabajosActivos[charId]
    if not trabajoActivo then
        return false, 'No hay trabajo activo'
    end

    local preso = Carcel.presos[charId]
    if not preso then
        Carcel.trabajosActivos[charId] = nil
        return false, 'No estas en la carcel'
    end

    local ahora = os.time()

    -- Verificar que haya pasado el tiempo
    if ahora < trabajoActivo.fin_esperado then
        local restante = trabajoActivo.fin_esperado - ahora
        return false, ('Faltan %d segundos'):format(restante)
    end

    local trabajo = trabajoActivo.config

    -- Aplicar reduccion de tiempo
    local reduccionReal = math.min(
        trabajo.reduccion,
        preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido - 1 -- Dejar al menos 1 minuto
    )

    preso.tiempo_reducido = preso.tiempo_reducido + reduccionReal

    -- Actualizar trabajo completado
    if not preso.trabajo_realizado then
        preso.trabajo_realizado = {}
    end
    preso.trabajo_realizado[trabajoActivo.tipo] = (preso.trabajo_realizado[trabajoActivo.tipo] or 0) + 1

    -- Actualizar BD
    MySQL.query([[
        UPDATE ait_justicia_carcel
        SET tiempo_reducido = ?, trabajo_realizado = ?
        WHERE carcel_id = ?
    ]], { preso.tiempo_reducido, json.encode(preso.trabajo_realizado), preso.carcel_id })

    MySQL.query([[
        UPDATE ait_justicia_carcel_trabajos
        SET completado = 1, fecha_fin = NOW()
        WHERE trabajo_id = ?
    ]], { trabajoActivo.trabajo_id })

    -- Aplicar cooldown
    if not Carcel.cooldownsTrabajos then
        Carcel.cooldownsTrabajos = {}
    end
    local cooldownKey = charId .. ':' .. trabajoActivo.tipo
    Carcel.cooldownsTrabajos[cooldownKey] = os.time() + trabajo.cooldown

    -- Limpiar trabajo activo
    Carcel.trabajosActivos[charId] = nil

    -- Mejorar comportamiento
    Carcel.ModificarComportamiento(charId, 2, 'Trabajo completado')

    -- Dar XP si hay sistema
    if trabajo.xp > 0 and AIT.Engines.Levels then
        AIT.Engines.Levels.AddXP(charId, trabajo.xp, 'prison_work')
    end

    -- Log
    Carcel.RegistrarLog(charId, nil, 'TRABAJO_COMPLETADO', {
        tipo = trabajoActivo.tipo,
        reduccion = reduccionReal,
    })

    -- Notificar
    Carcel.NotificarPreso(charId, 'trabajo_completado', {
        tipo = trabajoActivo.tipo,
        nombre = trabajo.nombre,
        reduccion = reduccionReal,
        tiempo_restante = preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido,
    })

    -- Verificar si puede ser liberado
    Carcel.VerificarLiberacion(charId)

    return true, ('Trabajo completado! Reduccion: %d minutos'):format(reduccionReal)
end

--- Obtener trabajos disponibles para un preso
---@param charId number
---@return table
function Carcel.ObtenerTrabajosDisponibles(charId)
    local preso = Carcel.presos[charId]
    if not preso then return {} end

    local disponibles = {}
    local ahora = os.time()

    for tipo, trabajo in pairs(Carcel.TrabajosPrision) do
        local disponible = true
        local razon = nil

        -- Verificar cooldown
        local cooldownKey = charId .. ':' .. tipo
        if Carcel.cooldownsTrabajos and Carcel.cooldownsTrabajos[cooldownKey] then
            local restante = Carcel.cooldownsTrabajos[cooldownKey] - ahora
            if restante > 0 then
                disponible = false
                razon = ('Cooldown: %d seg'):format(restante)
            end
        end

        -- Verificar requisitos
        if disponible and trabajo.requisitos.comportamiento_minimo then
            if preso.comportamiento < trabajo.requisitos.comportamiento_minimo then
                disponible = false
                razon = ('Requiere %d%% comportamiento'):format(trabajo.requisitos.comportamiento_minimo)
            end
        end

        -- Verificar si ya esta trabajando
        if disponible and Carcel.trabajosActivos[charId] then
            disponible = false
            razon = 'Ya estas trabajando'
        end

        table.insert(disponibles, {
            tipo = tipo,
            nombre = trabajo.nombre,
            descripcion = trabajo.descripcion,
            duracion = trabajo.duracion,
            reduccion = trabajo.reduccion,
            xp = trabajo.xp,
            disponible = disponible,
            razon = razon,
            icono = trabajo.icono,
        })
    end

    return disponibles
end

-- =====================================================================================
-- SISTEMA DE COMPORTAMIENTO
-- =====================================================================================

--- Modificar puntos de comportamiento
---@param charId number
---@param puntos number
---@param motivo string
---@param registradoPor number|nil
function Carcel.ModificarComportamiento(charId, puntos, motivo, registradoPor)
    local preso = Carcel.presos[charId]
    if not preso then return end

    local nuevoComportamiento = math.max(0, math.min(100, preso.comportamiento + puntos))
    preso.comportamiento = nuevoComportamiento

    MySQL.query([[
        UPDATE ait_justicia_carcel SET comportamiento = ? WHERE carcel_id = ?
    ]], { nuevoComportamiento, preso.carcel_id })

    MySQL.insert([[
        INSERT INTO ait_justicia_comportamiento
        (carcel_id, char_id, tipo, puntos, descripcion, registrado_por)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        preso.carcel_id,
        charId,
        puntos > 0 and 'positivo' or 'negativo',
        puntos,
        motivo,
        registradoPor,
    })

    -- Notificar
    Carcel.NotificarPreso(charId, 'comportamiento', {
        cambio = puntos,
        actual = nuevoComportamiento,
        motivo = motivo,
    })

    -- Verificar penalizaciones por mal comportamiento
    if nuevoComportamiento <= 20 then
        Carcel.AplicarPenalizacionComportamiento(charId)
    end
end

--- Aplicar penalizacion por mal comportamiento
---@param charId number
function Carcel.AplicarPenalizacionComportamiento(charId)
    local preso = Carcel.presos[charId]
    if not preso then return end

    -- Trasladar a aislamiento
    local celdaAislamiento = Carcel.AsignarCelda('aislamiento')
    if celdaAislamiento then
        -- Liberar celda actual
        if preso.celda then
            Carcel.celdasOcupadas[preso.celda] = nil
        end

        preso.celda = celdaAislamiento
        Carcel.celdasOcupadas[celdaAislamiento] = charId

        MySQL.query([[
            UPDATE ait_justicia_carcel SET celda = ? WHERE carcel_id = ?
        ]], { celdaAislamiento, preso.carcel_id })

        Carcel.TeletransportarACarcel(charId, celdaAislamiento)

        Carcel.NotificarPreso(charId, 'aislamiento', {
            motivo = 'Mal comportamiento',
        })
    end
end

-- =====================================================================================
-- SISTEMA DE ESCAPE
-- =====================================================================================

--- Intentar escapar de la carcel
---@param charId number
---@param metodo string
---@return boolean, string
function Carcel.IntentarFuga(charId, metodo)
    local preso = Carcel.presos[charId]
    if not preso then
        return false, 'No estas en la carcel'
    end

    -- Verificar cooldown de fuga
    if Carcel.intentosFuga[charId] then
        local tiempoRestante = Carcel.intentosFuga[charId] - os.time()
        if tiempoRestante > 0 then
            return false, ('Cooldown de fuga: %d segundos'):format(tiempoRestante)
        end
    end

    -- Verificar si esta en aislamiento
    if preso.celda and preso.celda:find('aislamiento') then
        return false, 'No puedes escapar desde aislamiento'
    end

    -- Calcular probabilidad de exito
    local probabilidad = Carcel.CalcularProbabilidadFuga(charId, metodo)

    -- Aplicar cooldown
    Carcel.intentosFuga[charId] = os.time() + (Carcel.Config.cooldownFuga * 60)

    -- Tirar dado
    local exito = math.random(100) <= probabilidad

    -- Registrar intento
    MySQL.insert([[
        INSERT INTO ait_justicia_fugas
        (carcel_id, char_id, metodo, exitoso, penalizacion)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        preso.carcel_id,
        charId,
        metodo,
        exito and 1 or 0,
        exito and 0 or Carcel.Config.penalizacionFugaFallida,
    })

    preso.intentos_fuga = preso.intentos_fuga + 1

    MySQL.query([[
        UPDATE ait_justicia_carcel SET intentos_fuga = ? WHERE carcel_id = ?
    ]], { preso.intentos_fuga, preso.carcel_id })

    if exito then
        return Carcel.ProcesarFugaExitosa(charId, metodo)
    else
        return Carcel.ProcesarFugaFallida(charId, metodo)
    end
end

--- Calcular probabilidad de fuga
---@param charId number
---@param metodo string
---@return number
function Carcel.CalcularProbabilidadFuga(charId, metodo)
    local preso = Carcel.presos[charId]
    if not preso then return 0 end

    local probabilidad = Carcel.Config.probabilidadFugaBase

    -- Bonus por buen comportamiento
    if preso.comportamiento >= 80 then
        probabilidad = probabilidad + 5
    end

    -- Penalizacion por intentos previos
    probabilidad = probabilidad - (preso.intentos_fuga * 2)

    -- Bonus/penalizacion por metodo
    local metodosBonus = {
        tunel = 10,        -- Requiere tiempo
        distraccion = 5,   -- Requiere complices
        soborno = 15,      -- Requiere dinero
        fuerza = -5,       -- Violento, mas vigilado
        vehiculo = 8,      -- Vehiculo de escape preparado
    }
    probabilidad = probabilidad + (metodosBonus[metodo] or 0)

    -- Bonus por hora del dia (noche es mas facil)
    local hora = tonumber(os.date('%H'))
    if hora >= 22 or hora <= 5 then
        probabilidad = probabilidad + 10
    end

    return math.max(1, math.min(50, probabilidad)) -- Min 1%, max 50%
end

--- Procesar fuga exitosa
---@param charId number
---@param metodo string
---@return boolean, string
function Carcel.ProcesarFugaExitosa(charId, metodo)
    local preso = Carcel.presos[charId]

    -- Actualizar estado
    MySQL.query([[
        UPDATE ait_justicia_carcel SET estado = 'fugado' WHERE carcel_id = ?
    ]], { preso.carcel_id })

    -- Liberar celda
    if preso.celda then
        Carcel.celdasOcupadas[preso.celda] = nil
    end

    -- Limpiar cache
    Carcel.presos[charId] = nil
    if AIT.Engines.Justice.enCarcel then
        AIT.Engines.Justice.enCarcel[charId] = nil
    end

    -- Teletransportar a ubicacion de escape
    Carcel.TeletransportarEscape(charId, metodo)

    -- Anadir wanted por fuga
    AIT.Engines.Justice.AnadirWanted(charId, 'fuga_carcel')

    -- Actualizar stats
    MySQL.query([[
        INSERT INTO ait_justicia_stats (char_id, fugas_exitosas)
        VALUES (?, 1)
        ON DUPLICATE KEY UPDATE fugas_exitosas = fugas_exitosas + 1
    ]], { charId })

    -- Log
    Carcel.RegistrarLog(charId, nil, 'FUGA_EXITOSA', {
        metodo = metodo,
        tiempo_restante = preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido,
    })

    -- Alertar a policia
    if AIT.Engines.Justice.AlertaGlobal then
        AIT.Engines.Justice.AlertaGlobal({
            tipo = 'fuga_prision',
            titulo = '!!! FUGA DE PRISION !!!',
            mensaje = 'Un preso ha escapado de la carcel',
            prioridad = 'urgente',
        })
    end

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.jail.escaped', {
            char_id = charId,
            metodo = metodo,
        })
    end

    return true, 'Has escapado de la carcel!'
end

--- Procesar fuga fallida
---@param charId number
---@param metodo string
---@return boolean, string
function Carcel.ProcesarFugaFallida(charId, metodo)
    local preso = Carcel.presos[charId]

    -- Aplicar penalizacion de tiempo
    preso.tiempo_total = preso.tiempo_total + Carcel.Config.penalizacionFugaFallida

    -- Reducir comportamiento
    Carcel.ModificarComportamiento(charId, -30, 'Intento de fuga fallido')

    -- Actualizar BD
    MySQL.query([[
        UPDATE ait_justicia_carcel SET tiempo_total = ? WHERE carcel_id = ?
    ]], { preso.tiempo_total, preso.carcel_id })

    -- Log
    Carcel.RegistrarLog(charId, nil, 'FUGA_FALLIDA', {
        metodo = metodo,
        penalizacion = Carcel.Config.penalizacionFugaFallida,
    })

    -- Notificar
    Carcel.NotificarPreso(charId, 'fuga_fallida', {
        penalizacion = Carcel.Config.penalizacionFugaFallida,
        tiempo_total = preso.tiempo_total,
    })

    -- Actualizar stats
    MySQL.query([[
        INSERT INTO ait_justicia_stats (char_id, fugas_fallidas)
        VALUES (?, 1)
        ON DUPLICATE KEY UPDATE fugas_fallidas = fugas_fallidas + 1
    ]], { charId })

    return false, ('Fuga fallida! +%d minutos de condena'):format(Carcel.Config.penalizacionFugaFallida)
end

--- Recapturar a un fugitivo
---@param charId number
---@param oficialId number
---@return boolean, string
function Carcel.Recapturar(charId, oficialId)
    -- Verificar que tiene wanted por fuga
    if not AIT.Engines.Justice.EstaBuscado(charId) then
        return false, 'El jugador no es un fugitivo'
    end

    -- Buscar su condena anterior
    local condenaAnterior = MySQL.query.await([[
        SELECT * FROM ait_justicia_carcel
        WHERE char_id = ? AND estado = 'fugado'
        ORDER BY fecha_ingreso DESC
        LIMIT 1
    ]], { charId })

    if not condenaAnterior or #condenaAnterior == 0 then
        return false, 'No se encontro condena previa'
    end

    condenaAnterior = condenaAnterior[1]

    -- Calcular tiempo restante + penalizacion
    local tiempoRestante = condenaAnterior.tiempo_total - condenaAnterior.tiempo_cumplido - condenaAnterior.tiempo_reducido
    local tiempoNuevo = tiempoRestante + Carcel.Config.penalizacionRecaptura

    -- Actualizar registro de fuga
    MySQL.query([[
        UPDATE ait_justicia_fugas
        SET recapturado = 1, fecha_recaptura = NOW(), recapturado_por = ?
        WHERE char_id = ? AND exitoso = 1 AND recapturado = 0
        ORDER BY fecha DESC
        LIMIT 1
    ]], { oficialId, charId })

    -- Limpiar wanted
    AIT.Engines.Justice.LimpiarWanted(charId, 'Recapturado')

    -- Encarcelar de nuevo
    return Carcel.Encarcelar(charId, tiempoNuevo, {
        arrestadoPor = oficialId,
        motivo = 'Recaptura tras fuga',
        antecedenteId = condenaAnterior.antecedente_id,
    })
end

-- =====================================================================================
-- THREADS DE PROCESAMIENTO
-- =====================================================================================

function Carcel.IniciarThreadCondena()
    CreateThread(function()
        while true do
            Wait(60000) -- Cada minuto

            for charId, preso in pairs(Carcel.presos) do
                if preso.estado == 'cumpliendo' then
                    -- Incrementar tiempo cumplido
                    preso.tiempo_cumplido = preso.tiempo_cumplido + 1

                    MySQL.query([[
                        UPDATE ait_justicia_carcel SET tiempo_cumplido = ? WHERE carcel_id = ?
                    ]], { preso.tiempo_cumplido, preso.carcel_id })

                    -- Verificar si debe ser liberado
                    Carcel.VerificarLiberacion(charId)

                    -- Notificar tiempo restante cada 5 minutos
                    if preso.tiempo_cumplido % 5 == 0 then
                        local restante = preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido
                        Carcel.NotificarPreso(charId, 'tiempo_restante', {
                            minutos = restante,
                        })
                    end
                end
            end
        end
    end)
end

function Carcel.IniciarThreadTrabajos()
    CreateThread(function()
        while true do
            Wait(1000) -- Cada segundo

            local ahora = os.time()

            for charId, trabajo in pairs(Carcel.trabajosActivos) do
                if ahora >= trabajo.fin_esperado then
                    -- Notificar que puede completar
                    Carcel.NotificarPreso(charId, 'trabajo_listo', {
                        tipo = trabajo.tipo,
                        nombre = trabajo.config.nombre,
                    })
                end
            end
        end
    end)
end

--- Verificar si un preso debe ser liberado
---@param charId number
function Carcel.VerificarLiberacion(charId)
    local preso = Carcel.presos[charId]
    if not preso then return end

    local tiempoRestante = preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido

    -- Aplicar reduccion por buen comportamiento
    if preso.comportamiento >= 80 then
        local reduccionComportamiento = math.floor(tiempoRestante * (Carcel.Config.reduccionBuenComportamiento / 100))
        tiempoRestante = tiempoRestante - reduccionComportamiento
    end

    if tiempoRestante <= 0 then
        Carcel.Liberar(charId, { motivo = 'Condena cumplida' })
    end
end

-- =====================================================================================
-- GESTION DE CELDAS
-- =====================================================================================

--- Asignar una celda disponible
---@param tipoCelda string|nil
---@return string|nil
function Carcel.AsignarCelda(tipoCelda)
    tipoCelda = tipoCelda or 'individual'

    local configCelda = Carcel.Celdas[tipoCelda]
    if not configCelda then
        configCelda = Carcel.Celdas.individual
        tipoCelda = 'individual'
    end

    -- Buscar celda disponible
    for i = 1, configCelda.cantidad do
        local celdaId = ('%s_%d'):format(tipoCelda, i)
        if not Carcel.celdasOcupadas[celdaId] then
            return celdaId
        end
    end

    -- Si no hay del tipo solicitado, buscar cualquiera
    if tipoCelda ~= 'individual' then
        return Carcel.AsignarCelda('individual')
    end

    return nil
end

--- Obtener informacion de una celda
---@param celdaId string
---@return table
function Carcel.ObtenerInfoCelda(celdaId)
    local tipo = celdaId:match('(.+)_%d+')
    local config = Carcel.Celdas[tipo] or Carcel.Celdas.individual

    return {
        id = celdaId,
        tipo = tipo,
        ocupada = Carcel.celdasOcupadas[celdaId] ~= nil,
        ocupante = Carcel.celdasOcupadas[celdaId],
        beneficios = config.beneficios,
        penalizaciones = config.penalizaciones,
    }
end

-- =====================================================================================
-- TELETRANSPORTE
-- =====================================================================================

--- Teletransportar a la carcel
---@param charId number
---@param celda string
function Carcel.TeletransportarACarcel(charId, celda)
    local source = AIT.Engines.Justice.ObtenerSourceDeCharId(charId)
    if source then
        -- Obtener coords de la celda
        local tipo = celda:match('(.+)_%d+')
        local config = Carcel.Celdas[tipo] or Carcel.Celdas.individual
        local coords = config.coords and config.coords[1] or { x = 1691.0, y = 2565.0, z = 45.5 }

        TriggerClientEvent('ait:justice:jail:teleport', source, {
            coords = coords,
            celda = celda,
        })
    end
end

--- Teletransportar fuera de la carcel
---@param charId number
function Carcel.TeletransportarFueraCarcel(charId)
    local source = AIT.Engines.Justice.ObtenerSourceDeCharId(charId)
    if source then
        -- Coords de salida de la prision
        local coordsSalida = { x = 1849.0, y = 2586.0, z = 45.7 }

        TriggerClientEvent('ait:justice:jail:teleport', source, {
            coords = coordsSalida,
            liberado = true,
        })
    end
end

--- Teletransportar a ubicacion de escape
---@param charId number
---@param metodo string
function Carcel.TeletransportarEscape(charId, metodo)
    local source = AIT.Engines.Justice.ObtenerSourceDeCharId(charId)
    if source then
        -- Ubicaciones de escape segun metodo
        local ubicacionesEscape = {
            tunel = { x = 1700.0, y = 2600.0, z = 45.0 },
            vehiculo = { x = 1850.0, y = 2550.0, z = 45.0 },
            default = { x = 1750.0, y = 2550.0, z = 45.0 },
        }

        local coords = ubicacionesEscape[metodo] or ubicacionesEscape.default

        TriggerClientEvent('ait:justice:jail:escape', source, {
            coords = coords,
            metodo = metodo,
        })
    end
end

-- =====================================================================================
-- GESTION DE ITEMS
-- =====================================================================================

--- Requisar items prohibidos
---@param charId number
function Carcel.RequisarItems(charId)
    if not AIT.Engines.Inventory then return end

    -- Items prohibidos en prision
    local itemsProhibidos = {
        'weapon_pistol', 'weapon_smg', 'weapon_rifle', 'weapon_knife',
        'phone', 'lockpick', 'radio', 'weapon_*',
    }

    local itemsRequisados = {}

    -- Obtener inventario
    local inventario = AIT.Engines.Inventory.GetPlayerInventory(charId)
    if not inventario then return end

    for _, item in ipairs(inventario) do
        local esProhibido = false
        for _, prohibido in ipairs(itemsProhibidos) do
            if prohibido:find('%*') then
                -- Patron con wildcard
                local patron = prohibido:gsub('%*', '.*')
                if item.name:match(patron) then
                    esProhibido = true
                    break
                end
            elseif item.name == prohibido then
                esProhibido = true
                break
            end
        end

        if esProhibido then
            AIT.Engines.Inventory.RemoveItem(charId, item.name, item.amount)
            table.insert(itemsRequisados, { name = item.name, amount = item.amount })
        end
    end

    -- Guardar items requisados para devolucion posterior
    if #itemsRequisados > 0 then
        MySQL.query([[
            UPDATE ait_justicia_carcel
            SET metadata = JSON_SET(COALESCE(metadata, '{}'), '$.items_requisados', ?)
            WHERE char_id = ? AND estado = 'cumpliendo'
        ]], { json.encode(itemsRequisados), charId })
    end
end

--- Devolver items requisados
---@param charId number
function Carcel.DevolverItems(charId)
    if not AIT.Engines.Inventory then return end

    -- Obtener items requisados
    local result = MySQL.query.await([[
        SELECT JSON_EXTRACT(metadata, '$.items_requisados') as items
        FROM ait_justicia_carcel
        WHERE char_id = ? AND estado = 'liberado'
        ORDER BY fecha_liberacion DESC
        LIMIT 1
    ]], { charId })

    if result and result[1] and result[1].items then
        local items = json.decode(result[1].items)
        for _, item in ipairs(items or {}) do
            AIT.Engines.Inventory.AddItem(charId, item.name, item.amount)
        end
    end
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

--- Obtener estado de un preso
---@param charId number
---@return table|nil
function Carcel.ObtenerEstadoPreso(charId)
    local preso = Carcel.presos[charId]
    if not preso then return nil end

    local tiempoRestante = preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido

    return {
        carcel_id = preso.carcel_id,
        tiempo_total = preso.tiempo_total,
        tiempo_cumplido = preso.tiempo_cumplido,
        tiempo_reducido = preso.tiempo_reducido,
        tiempo_restante = tiempoRestante,
        celda = preso.celda,
        comportamiento = preso.comportamiento,
        intentos_fuga = preso.intentos_fuga,
        trabajos_realizados = preso.trabajo_realizado,
        estado = preso.estado,
    }
end

--- Verificar si un jugador esta en carcel
---@param charId number
---@return boolean
function Carcel.EstaEnCarcel(charId)
    return Carcel.presos[charId] ~= nil
end

--- Obtener lista de todos los presos
---@return table
function Carcel.ObtenerTodosPresos()
    local lista = {}
    for charId, preso in pairs(Carcel.presos) do
        table.insert(lista, Carcel.ObtenerEstadoPreso(charId))
    end
    return lista
end

--- Notificar a un preso
---@param charId number
---@param tipo string
---@param datos table
function Carcel.NotificarPreso(charId, tipo, datos)
    local source = AIT.Engines.Justice.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:justice:jail:notify', source, {
            tipo = tipo,
            datos = datos,
        })
    end
end

--- Registrar log de carcel
---@param charId number
---@param oficialId number|nil
---@param accion string
---@param detalles table|nil
function Carcel.RegistrarLog(charId, oficialId, accion, detalles)
    AIT.Engines.Justice.RegistrarLog(charId, oficialId, accion, nil, detalles, nil)
end

-- =====================================================================================
-- EVENTOS
-- =====================================================================================

function Carcel.RegistrarEventos()
    -- Jugador conectado - verificar si esta en carcel
    RegisterNetEvent('ait:player:loaded', function(source, playerData, charData)
        if charData and charData.char_id then
            local charId = charData.char_id
            local preso = Carcel.presos[charId]

            if preso then
                -- Teletransportar de vuelta a la carcel
                Wait(2000)
                Carcel.TeletransportarACarcel(charId, preso.celda)

                -- Enviar estado actual
                TriggerClientEvent('ait:justice:jail:status', source, Carcel.ObtenerEstadoPreso(charId))
            end
        end
    end)

    -- Solicitar estado de carcel
    RegisterNetEvent('ait:justice:jail:getStatus', function()
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local estado = Carcel.ObtenerEstadoPreso(charId)

        TriggerClientEvent('ait:justice:jail:status', source, estado)
    end)

    -- Solicitar trabajos disponibles
    RegisterNetEvent('ait:justice:jail:getJobs', function()
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local trabajos = Carcel.ObtenerTrabajosDisponibles(charId)

        TriggerClientEvent('ait:justice:jail:jobs', source, trabajos)
    end)

    -- Iniciar trabajo
    RegisterNetEvent('ait:justice:jail:startJob', function(tipoTrabajo)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Carcel.IniciarTrabajo(charId, tipoTrabajo)

        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)

    -- Completar trabajo
    RegisterNetEvent('ait:justice:jail:completeJob', function()
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Carcel.CompletarTrabajo(charId)

        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)

    -- Intentar fuga
    RegisterNetEvent('ait:justice:jail:escape', function(metodo)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Carcel.IntentarFuga(charId, metodo or 'fuerza')

        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)
end

-- =====================================================================================
-- COMANDOS
-- =====================================================================================

function Carcel.RegistrarComandos()
    -- Ver estado de carcel propio
    RegisterCommand('carcel', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local estado = Carcel.ObtenerEstadoPreso(charId)

        if not estado then
            TriggerClientEvent('QBCore:Notify', source, 'No estas en la carcel', 'info')
            return
        end

        local mensaje = ([[
=== ESTADO EN CARCEL ===
Tiempo total: %d minutos
Tiempo cumplido: %d minutos
Tiempo reducido: %d minutos
Tiempo restante: %d minutos
Celda: %s
Comportamiento: %d%%
        ]]):format(
            estado.tiempo_total,
            estado.tiempo_cumplido,
            estado.tiempo_reducido,
            estado.tiempo_restante,
            estado.celda or 'N/A',
            estado.comportamiento
        )

        TriggerClientEvent('chat:addMessage', source, { args = { 'Carcel', mensaje } })
    end, false)

    -- Ver trabajos disponibles
    RegisterCommand('trabajos', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid

        if not Carcel.EstaEnCarcel(charId) then
            TriggerClientEvent('QBCore:Notify', source, 'No estas en la carcel', 'error')
            return
        end

        local trabajos = Carcel.ObtenerTrabajosDisponibles(charId)
        local mensaje = '=== TRABAJOS DISPONIBLES ==='

        for _, trabajo in ipairs(trabajos) do
            local estado = trabajo.disponible and '[Disponible]' or ('[No disponible: ' .. (trabajo.razon or '') .. ']')
            mensaje = mensaje .. ('\n%s - %s (%d seg, -%d min) %s'):format(
                trabajo.nombre,
                trabajo.descripcion,
                trabajo.duracion,
                trabajo.reduccion,
                estado
            )
        end

        TriggerClientEvent('chat:addMessage', source, { args = { 'Carcel', mensaje } })
    end, false)

    -- Admin: Encarcelar
    RegisterCommand('adminencarcelar', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'justice.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local targetId = tonumber(args[1])
        local tiempo = tonumber(args[2])

        if not targetId or not tiempo then
            local msg = 'Uso: /adminencarcelar [char_id] [minutos]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        local success, resultado = Carcel.Encarcelar(targetId, tiempo, {
            motivo = 'Encarcelamiento administrativo'
        })

        local msg = success and ('Encarcelado por %d minutos'):format(tiempo) or ('Error: %s'):format(resultado)
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
        else
            print(msg)
        end
    end, false)

    -- Admin: Liberar
    RegisterCommand('adminliberar', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'justice.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local targetId = tonumber(args[1])

        if not targetId then
            local msg = 'Uso: /adminliberar [char_id]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        local success, resultado = Carcel.Liberar(targetId, {
            liberadoPor = source > 0 and AIT.QBCore.Functions.GetPlayer(source).PlayerData.citizenid or nil,
            motivo = 'Liberacion administrativa'
        })

        local msg = success and 'Liberado exitosamente' or ('Error: %s'):format(resultado)
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
        else
            print(msg)
        end
    end, false)

    -- Admin: Ver presos
    RegisterCommand('adminpresos', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'justice.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local presos = Carcel.ObtenerTodosPresos()
        local mensaje = ('=== PRESOS ACTIVOS (%d) ==='):format(#presos)

        for _, preso in ipairs(presos) do
            mensaje = mensaje .. ('\nID: %d | Restante: %d min | Celda: %s | Comp: %d%%'):format(
                preso.carcel_id,
                preso.tiempo_restante,
                preso.celda or 'N/A',
                preso.comportamiento
            )
        end

        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', mensaje } })
        else
            print(mensaje)
        end
    end, false)
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Encarcelamiento
Carcel.Imprison = Carcel.Encarcelar
Carcel.ExtendSentence = Carcel.ExtenderCondena
Carcel.Release = Carcel.Liberar
Carcel.IsInJail = Carcel.EstaEnCarcel
Carcel.GetStatus = Carcel.ObtenerEstadoPreso
Carcel.GetAllPrisoners = Carcel.ObtenerTodosPresos

-- Trabajos
Carcel.StartJob = Carcel.IniciarTrabajo
Carcel.CompleteJob = Carcel.CompletarTrabajo
Carcel.GetAvailableJobs = Carcel.ObtenerTrabajosDisponibles

-- Comportamiento
Carcel.ModifyBehavior = Carcel.ModificarComportamiento

-- Escape
Carcel.AttemptEscape = Carcel.IntentarFuga
Carcel.Recapture = Carcel.Recapturar

-- Celdas
Carcel.GetCellInfo = Carcel.ObtenerInfoCelda

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.Justice.Jail = Carcel

return Carcel
