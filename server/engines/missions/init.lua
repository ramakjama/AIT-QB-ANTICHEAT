-- =====================================================================================
-- ait-qb ENGINE DE MISIONES
-- Sistema completo de misiones procedurales con dificultad dinamica
-- Namespace: AIT.Engines.Missions
-- Optimizado para 2048 slots
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Missions = AIT.Engines.Missions or {}

local Misiones = {
    -- Cache de misiones activas por jugador
    activas = {},
    -- Historico de misiones completadas (para cooldowns)
    historico = {},
    -- Pool de misiones disponibles por tipo
    poolMisiones = {},
    -- Cooldowns globales
    cooldowns = {},
    -- Configuracion de dificultad por nivel
    dificultad = {},
    -- Misiones diarias/semanales activas
    especiales = {
        diarias = {},
        semanales = {},
    },
    -- Cola de actualizaciones de progreso
    colaProgreso = {},
}

-- =====================================================================================
-- CONFIGURACION DE TIPOS DE MISION
-- =====================================================================================

Misiones.Tipos = {
    delivery = {
        nombre = 'Entrega',
        descripcion = 'Transportar paquetes o vehiculos a destinos',
        icono = 'fa-truck',
        color = '#4CAF50',
        tiempoBase = 600, -- 10 minutos
        recompensaBase = 500,
        xpBase = 50,
        cooldown = 300, -- 5 minutos
        maxActivas = 2,
        requiereVehiculo = true,
        categorias = { 'legal', 'neutral' },
    },
    collect = {
        nombre = 'Recoleccion',
        descripcion = 'Recoger items de multiples ubicaciones',
        icono = 'fa-box',
        color = '#2196F3',
        tiempoBase = 900, -- 15 minutos
        recompensaBase = 750,
        xpBase = 75,
        cooldown = 600, -- 10 minutos
        maxActivas = 1,
        requiereVehiculo = false,
        categorias = { 'legal', 'neutral', 'ilegal' },
    },
    hunt = {
        nombre = 'Caza',
        descripcion = 'Eliminar objetivos NPC o completar combates',
        icono = 'fa-crosshairs',
        color = '#F44336',
        tiempoBase = 1200, -- 20 minutos
        recompensaBase = 1500,
        xpBase = 150,
        cooldown = 900, -- 15 minutos
        maxActivas = 1,
        requiereVehiculo = false,
        requiereCombate = true,
        categorias = { 'neutral', 'ilegal' },
    },
    escort = {
        nombre = 'Escolta',
        descripcion = 'Proteger NPCs o vehiculos hasta destino',
        icono = 'fa-shield-alt',
        color = '#9C27B0',
        tiempoBase = 1500, -- 25 minutos
        recompensaBase = 2000,
        xpBase = 200,
        cooldown = 1200, -- 20 minutos
        maxActivas = 1,
        requiereVehiculo = true,
        requiereCombate = true,
        cooperativa = true,
        categorias = { 'legal', 'neutral' },
    },
    race = {
        nombre = 'Carrera',
        descripcion = 'Competiciones de velocidad',
        icono = 'fa-flag-checkered',
        color = '#FF9800',
        tiempoBase = 300, -- 5 minutos
        recompensaBase = 1000,
        xpBase = 100,
        cooldown = 600, -- 10 minutos
        maxActivas = 1,
        requiereVehiculo = true,
        categorias = { 'legal', 'neutral' },
    },
}

-- =====================================================================================
-- CONFIGURACION DE DIFICULTAD
-- =====================================================================================

Misiones.NivelesDificultad = {
    [1] = {
        nombre = 'Novato',
        multiplicadorRecompensa = 0.5,
        multiplicadorXP = 0.5,
        multiplicadorTiempo = 1.5,
        enemigosMax = 2,
        distanciaMax = 500,
        checkpointsMax = 3,
        nivelJugadorMin = 1,
        nivelJugadorMax = 10,
    },
    [2] = {
        nombre = 'Facil',
        multiplicadorRecompensa = 0.75,
        multiplicadorXP = 0.75,
        multiplicadorTiempo = 1.25,
        enemigosMax = 4,
        distanciaMax = 1000,
        checkpointsMax = 5,
        nivelJugadorMin = 5,
        nivelJugadorMax = 20,
    },
    [3] = {
        nombre = 'Normal',
        multiplicadorRecompensa = 1.0,
        multiplicadorXP = 1.0,
        multiplicadorTiempo = 1.0,
        enemigosMax = 6,
        distanciaMax = 2000,
        checkpointsMax = 7,
        nivelJugadorMin = 15,
        nivelJugadorMax = 40,
    },
    [4] = {
        nombre = 'Dificil',
        multiplicadorRecompensa = 1.5,
        multiplicadorXP = 1.5,
        multiplicadorTiempo = 0.8,
        enemigosMax = 10,
        distanciaMax = 4000,
        checkpointsMax = 10,
        nivelJugadorMin = 30,
        nivelJugadorMax = 60,
    },
    [5] = {
        nombre = 'Extremo',
        multiplicadorRecompensa = 2.5,
        multiplicadorXP = 2.5,
        multiplicadorTiempo = 0.6,
        enemigosMax = 15,
        distanciaMax = 8000,
        checkpointsMax = 15,
        nivelJugadorMin = 50,
        nivelJugadorMax = 100,
    },
    [6] = {
        nombre = 'Legendario',
        multiplicadorRecompensa = 5.0,
        multiplicadorXP = 5.0,
        multiplicadorTiempo = 0.5,
        enemigosMax = 25,
        distanciaMax = 15000,
        checkpointsMax = 20,
        nivelJugadorMin = 80,
        nivelJugadorMax = 999,
    },
}

-- =====================================================================================
-- ESTADOS DE MISION
-- =====================================================================================

Misiones.Estados = {
    PENDIENTE = 'pendiente',
    ACTIVA = 'activa',
    EN_PROGRESO = 'en_progreso',
    COMPLETADA = 'completada',
    FALLIDA = 'fallida',
    ABANDONADA = 'abandonada',
    EXPIRADA = 'expirada',
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Misiones.Initialize()
    -- Crear tablas de base de datos
    Misiones.CrearTablas()

    -- Cargar configuracion desde base de datos
    Misiones.CargarConfiguracion()

    -- Cargar misiones diarias/semanales
    Misiones.CargarMisionesEspeciales()

    -- Registrar eventos
    Misiones.RegistrarEventos()

    -- Registrar comandos
    Misiones.RegistrarComandos()

    -- Iniciar thread de progreso
    Misiones.IniciarThreadProgreso()

    -- Iniciar thread de expiracion
    Misiones.IniciarThreadExpiracion()

    -- Registrar tareas del scheduler
    if AIT.Scheduler then
        -- Generar misiones diarias a medianoche
        AIT.Scheduler.register('missions_daily_reset', {
            interval = 86400,
            fn = Misiones.GenerarMisionesDiarias
        })

        -- Generar misiones semanales cada lunes
        AIT.Scheduler.register('missions_weekly_reset', {
            interval = 604800, -- 7 dias
            fn = Misiones.GenerarMisionesSemanales
        })

        -- Limpiar misiones expiradas cada hora
        AIT.Scheduler.register('missions_cleanup', {
            interval = 3600,
            fn = Misiones.LimpiarMisionesExpiradas
        })

        -- Actualizar estadisticas cada 15 minutos
        AIT.Scheduler.register('missions_stats', {
            interval = 900,
            fn = Misiones.ActualizarEstadisticas
        })
    end

    if AIT.Log then
        AIT.Log.info('MISSIONS', 'Engine de Misiones inicializado correctamente')
    end

    return true
end

-- =====================================================================================
-- CREACION DE TABLAS
-- =====================================================================================

function Misiones.CrearTablas()
    -- Tabla principal de misiones (plantillas)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_plantillas (
            plantilla_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            codigo VARCHAR(64) NOT NULL UNIQUE,
            tipo VARCHAR(32) NOT NULL,
            nombre VARCHAR(128) NOT NULL,
            descripcion TEXT NULL,
            categoria VARCHAR(32) NOT NULL DEFAULT 'neutral',
            dificultad_min INT NOT NULL DEFAULT 1,
            dificultad_max INT NOT NULL DEFAULT 6,
            nivel_requerido INT NOT NULL DEFAULT 1,
            faccion_requerida BIGINT NULL,
            licencia_requerida VARCHAR(64) NULL,
            recompensa_base INT NOT NULL DEFAULT 500,
            xp_base INT NOT NULL DEFAULT 50,
            rep_base INT NOT NULL DEFAULT 10,
            tiempo_limite INT NOT NULL DEFAULT 600,
            cooldown INT NOT NULL DEFAULT 300,
            objetivos JSON NOT NULL,
            ubicaciones JSON NULL,
            npcs JSON NULL,
            items_requeridos JSON NULL,
            items_recompensa JSON NULL,
            vehiculos JSON NULL,
            metadata JSON NULL,
            activa TINYINT(1) NOT NULL DEFAULT 1,
            diaria TINYINT(1) NOT NULL DEFAULT 0,
            semanal TINYINT(1) NOT NULL DEFAULT 0,
            repetible TINYINT(1) NOT NULL DEFAULT 1,
            cooperativa TINYINT(1) NOT NULL DEFAULT 0,
            max_participantes INT NOT NULL DEFAULT 1,
            peso INT NOT NULL DEFAULT 100,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_tipo (tipo),
            KEY idx_categoria (categoria),
            KEY idx_activa (activa),
            KEY idx_dificultad (dificultad_min, dificultad_max)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de misiones activas de jugadores
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_activas (
            mision_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            plantilla_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            estado VARCHAR(32) NOT NULL DEFAULT 'pendiente',
            dificultad INT NOT NULL DEFAULT 3,
            progreso JSON NOT NULL,
            objetivos_completados INT NOT NULL DEFAULT 0,
            objetivos_totales INT NOT NULL DEFAULT 1,
            checkpoints JSON NULL,
            ubicacion_actual JSON NULL,
            npcs_spawneados JSON NULL,
            vehiculos_spawneados JSON NULL,
            recompensa_final INT NOT NULL DEFAULT 0,
            xp_final INT NOT NULL DEFAULT 0,
            rep_final INT NOT NULL DEFAULT 0,
            tiempo_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            tiempo_limite DATETIME NOT NULL,
            tiempo_fin DATETIME NULL,
            tiempo_pausado INT NOT NULL DEFAULT 0,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_estado (estado),
            KEY idx_plantilla (plantilla_id),
            KEY idx_tiempo_limite (tiempo_limite),
            FOREIGN KEY (plantilla_id) REFERENCES ait_misiones_plantillas(plantilla_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de participantes (para misiones cooperativas)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_participantes (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            mision_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            rol VARCHAR(32) NOT NULL DEFAULT 'participante',
            contribucion DECIMAL(5,2) NOT NULL DEFAULT 0.00,
            fecha_union DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            activo TINYINT(1) NOT NULL DEFAULT 1,
            UNIQUE KEY idx_mision_char (mision_id, char_id),
            KEY idx_char (char_id),
            FOREIGN KEY (mision_id) REFERENCES ait_misiones_activas(mision_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de historico de misiones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_historico (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            mision_id BIGINT NOT NULL,
            plantilla_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            resultado VARCHAR(32) NOT NULL,
            dificultad INT NOT NULL,
            recompensa_obtenida INT NOT NULL DEFAULT 0,
            xp_obtenida INT NOT NULL DEFAULT 0,
            rep_obtenida INT NOT NULL DEFAULT 0,
            tiempo_total INT NOT NULL DEFAULT 0,
            objetivos_completados INT NOT NULL DEFAULT 0,
            objetivos_totales INT NOT NULL DEFAULT 1,
            fecha_inicio DATETIME NOT NULL,
            fecha_fin DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_plantilla (plantilla_id),
            KEY idx_resultado (resultado),
            KEY idx_fecha (fecha_fin)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de cooldowns
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_cooldowns (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            plantilla_id BIGINT NULL,
            tipo_cooldown VARCHAR(32) NOT NULL,
            expira_en DATETIME NOT NULL,
            metadata JSON NULL,
            UNIQUE KEY idx_char_tipo (char_id, tipo_cooldown, plantilla_id),
            KEY idx_expira (expira_en)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de misiones diarias/semanales
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_especiales (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            plantilla_id BIGINT NOT NULL,
            tipo VARCHAR(16) NOT NULL,
            fecha_inicio DATETIME NOT NULL,
            fecha_fin DATETIME NOT NULL,
            bonus_recompensa DECIMAL(4,2) NOT NULL DEFAULT 1.50,
            bonus_xp DECIMAL(4,2) NOT NULL DEFAULT 2.00,
            completada_por INT NOT NULL DEFAULT 0,
            limite_completados INT NULL,
            activa TINYINT(1) NOT NULL DEFAULT 1,
            metadata JSON NULL,
            KEY idx_tipo (tipo),
            KEY idx_fecha (fecha_inicio, fecha_fin),
            KEY idx_activa (activa),
            FOREIGN KEY (plantilla_id) REFERENCES ait_misiones_plantillas(plantilla_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de progreso de misiones especiales por jugador
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_especiales_progreso (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            especial_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            completada TINYINT(1) NOT NULL DEFAULT 0,
            fecha_completado DATETIME NULL,
            UNIQUE KEY idx_especial_char (especial_id, char_id),
            KEY idx_char (char_id),
            FOREIGN KEY (especial_id) REFERENCES ait_misiones_especiales(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estadisticas de misiones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_stats (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL UNIQUE,
            misiones_completadas INT NOT NULL DEFAULT 0,
            misiones_fallidas INT NOT NULL DEFAULT 0,
            misiones_abandonadas INT NOT NULL DEFAULT 0,
            recompensa_total BIGINT NOT NULL DEFAULT 0,
            xp_total BIGINT NOT NULL DEFAULT 0,
            rep_total BIGINT NOT NULL DEFAULT 0,
            tiempo_total_segundos BIGINT NOT NULL DEFAULT 0,
            racha_actual INT NOT NULL DEFAULT 0,
            racha_maxima INT NOT NULL DEFAULT 0,
            diarias_completadas INT NOT NULL DEFAULT 0,
            semanales_completadas INT NOT NULL DEFAULT 0,
            por_tipo JSON NULL,
            por_dificultad JSON NULL,
            logros JSON NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_completadas (misiones_completadas),
            KEY idx_racha (racha_actual)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de logs de misiones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_misiones_logs (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            mision_id BIGINT NULL,
            char_id BIGINT NULL,
            accion VARCHAR(64) NOT NULL,
            detalles JSON NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_mision (mision_id),
            KEY idx_char (char_id),
            KEY idx_accion (accion),
            KEY idx_fecha (fecha)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

-- =====================================================================================
-- CARGAR CONFIGURACION
-- =====================================================================================

function Misiones.CargarConfiguracion()
    -- Cargar overrides de config si existen
    if AIT.Config and AIT.Config.missions then
        if AIT.Config.missions.tipos then
            for tipo, config in pairs(AIT.Config.missions.tipos) do
                if Misiones.Tipos[tipo] then
                    Misiones.Tipos[tipo] = AIT.Utils.Merge(Misiones.Tipos[tipo], config)
                end
            end
        end

        if AIT.Config.missions.dificultad then
            for nivel, config in pairs(AIT.Config.missions.dificultad) do
                if Misiones.NivelesDificultad[nivel] then
                    Misiones.NivelesDificultad[nivel] = AIT.Utils.Merge(Misiones.NivelesDificultad[nivel], config)
                end
            end
        end
    end

    -- Cargar plantillas en cache
    Misiones.CargarPlantillas()
end

function Misiones.CargarPlantillas()
    local plantillas = MySQL.query.await([[
        SELECT * FROM ait_misiones_plantillas WHERE activa = 1
    ]])

    Misiones.poolMisiones = {}
    for tipo, _ in pairs(Misiones.Tipos) do
        Misiones.poolMisiones[tipo] = {}
    end

    for _, plantilla in ipairs(plantillas or {}) do
        plantilla.objetivos = plantilla.objetivos and json.decode(plantilla.objetivos) or {}
        plantilla.ubicaciones = plantilla.ubicaciones and json.decode(plantilla.ubicaciones) or {}
        plantilla.npcs = plantilla.npcs and json.decode(plantilla.npcs) or {}
        plantilla.items_requeridos = plantilla.items_requeridos and json.decode(plantilla.items_requeridos) or {}
        plantilla.items_recompensa = plantilla.items_recompensa and json.decode(plantilla.items_recompensa) or {}
        plantilla.vehiculos = plantilla.vehiculos and json.decode(plantilla.vehiculos) or {}
        plantilla.metadata = plantilla.metadata and json.decode(plantilla.metadata) or {}

        if Misiones.poolMisiones[plantilla.tipo] then
            table.insert(Misiones.poolMisiones[plantilla.tipo], plantilla)
        end
    end

    if AIT.Log then
        local total = 0
        for _, pool in pairs(Misiones.poolMisiones) do
            total = total + #pool
        end
        AIT.Log.info('MISSIONS', ('Cargadas %d plantillas de misiones'):format(total))
    end
end

function Misiones.CargarMisionesEspeciales()
    local ahora = os.date('%Y-%m-%d %H:%M:%S')

    -- Cargar diarias activas
    local diarias = MySQL.query.await([[
        SELECT e.*, p.codigo, p.nombre, p.tipo, p.descripcion
        FROM ait_misiones_especiales e
        JOIN ait_misiones_plantillas p ON e.plantilla_id = p.plantilla_id
        WHERE e.tipo = 'diaria' AND e.activa = 1
        AND e.fecha_inicio <= ? AND e.fecha_fin > ?
    ]], { ahora, ahora })

    Misiones.especiales.diarias = diarias or {}

    -- Cargar semanales activas
    local semanales = MySQL.query.await([[
        SELECT e.*, p.codigo, p.nombre, p.tipo, p.descripcion
        FROM ait_misiones_especiales e
        JOIN ait_misiones_plantillas p ON e.plantilla_id = p.plantilla_id
        WHERE e.tipo = 'semanal' AND e.activa = 1
        AND e.fecha_inicio <= ? AND e.fecha_fin > ?
    ]], { ahora, ahora })

    Misiones.especiales.semanales = semanales or {}

    if AIT.Log then
        AIT.Log.info('MISSIONS', ('Misiones especiales: %d diarias, %d semanales'):format(
            #Misiones.especiales.diarias, #Misiones.especiales.semanales
        ))
    end
end

-- =====================================================================================
-- GESTION DE MISIONES
-- =====================================================================================

--- Obtener misiones disponibles para un jugador
---@param charId number
---@param filtros table|nil
---@return table
function Misiones.ObtenerDisponibles(charId, filtros)
    filtros = filtros or {}

    -- Obtener datos del jugador
    local nivelJugador = Misiones.ObtenerNivelJugador(charId)
    local faccionId = nil
    local licencias = {}

    if AIT.Engines.Factions then
        local faccion = AIT.Engines.Factions.ObtenerFaccionDePersonaje(charId)
        if faccion then
            faccionId = faccion.faccion_id
        end
    end

    -- Obtener cooldowns activos
    local cooldowns = Misiones.ObtenerCooldowns(charId)

    -- Obtener misiones activas
    local activas = Misiones.ObtenerActivas(charId)
    local tiposActivos = {}
    for _, mision in ipairs(activas) do
        tiposActivos[mision.tipo] = (tiposActivos[mision.tipo] or 0) + 1
    end

    local disponibles = {}

    for tipo, pool in pairs(Misiones.poolMisiones) do
        -- Verificar limite de activas por tipo
        local tipoConfig = Misiones.Tipos[tipo]
        local activasDeEsteTipo = tiposActivos[tipo] or 0

        if activasDeEsteTipo < tipoConfig.maxActivas then
            for _, plantilla in ipairs(pool) do
                local valida = true
                local razon = nil

                -- Filtro por tipo
                if filtros.tipo and plantilla.tipo ~= filtros.tipo then
                    valida = false
                end

                -- Filtro por categoria
                if filtros.categoria and plantilla.categoria ~= filtros.categoria then
                    valida = false
                end

                -- Verificar nivel
                if valida and plantilla.nivel_requerido > nivelJugador then
                    valida = false
                    razon = 'Nivel insuficiente'
                end

                -- Verificar faccion
                if valida and plantilla.faccion_requerida and plantilla.faccion_requerida ~= faccionId then
                    valida = false
                    razon = 'Faccion incorrecta'
                end

                -- Verificar cooldown
                if valida and cooldowns[plantilla.plantilla_id] then
                    valida = false
                    razon = 'En cooldown'
                end

                -- Verificar si ya esta activa
                if valida then
                    for _, activa in ipairs(activas) do
                        if activa.plantilla_id == plantilla.plantilla_id then
                            valida = false
                            razon = 'Ya activa'
                            break
                        end
                    end
                end

                if valida then
                    -- Calcular dificultad recomendada
                    local dificultadRecomendada = Misiones.CalcularDificultadRecomendada(nivelJugador, plantilla)

                    -- Calcular recompensas estimadas
                    local recompensas = Misiones.CalcularRecompensas(plantilla, dificultadRecomendada)

                    table.insert(disponibles, {
                        plantilla_id = plantilla.plantilla_id,
                        codigo = plantilla.codigo,
                        tipo = plantilla.tipo,
                        nombre = plantilla.nombre,
                        descripcion = plantilla.descripcion,
                        categoria = plantilla.categoria,
                        dificultad_recomendada = dificultadRecomendada,
                        dificultad_min = plantilla.dificultad_min,
                        dificultad_max = plantilla.dificultad_max,
                        recompensa_estimada = recompensas.dinero,
                        xp_estimada = recompensas.xp,
                        tiempo_limite = plantilla.tiempo_limite,
                        cooperativa = plantilla.cooperativa == 1,
                        repetible = plantilla.repetible == 1,
                    })
                end
            end
        end
    end

    -- Ordenar por recompensa
    table.sort(disponibles, function(a, b)
        return a.recompensa_estimada > b.recompensa_estimada
    end)

    return disponibles
end

--- Iniciar una mision
---@param charId number
---@param plantillaId number
---@param dificultad number|nil
---@return boolean, number|string
function Misiones.Iniciar(charId, plantillaId, dificultad)
    -- Verificar que la plantilla existe
    local plantilla = Misiones.ObtenerPlantilla(plantillaId)
    if not plantilla then
        return false, 'Mision no encontrada'
    end

    -- Verificar si ya tiene esta mision activa
    local activas = Misiones.ObtenerActivas(charId)
    for _, activa in ipairs(activas) do
        if activa.plantilla_id == plantillaId then
            return false, 'Ya tienes esta mision activa'
        end
    end

    -- Verificar limite de misiones activas por tipo
    local tipoConfig = Misiones.Tipos[plantilla.tipo]
    local activasDelTipo = 0
    for _, activa in ipairs(activas) do
        if activa.tipo == plantilla.tipo then
            activasDelTipo = activasDelTipo + 1
        end
    end

    if activasDelTipo >= tipoConfig.maxActivas then
        return false, 'Has alcanzado el limite de misiones de este tipo'
    end

    -- Verificar cooldown
    local cooldowns = Misiones.ObtenerCooldowns(charId)
    if cooldowns[plantillaId] then
        local tiempoRestante = math.ceil((cooldowns[plantillaId] - os.time()) / 60)
        return false, ('Mision en cooldown. Disponible en %d minutos'):format(tiempoRestante)
    end

    -- Verificar nivel del jugador
    local nivelJugador = Misiones.ObtenerNivelJugador(charId)
    if nivelJugador < plantilla.nivel_requerido then
        return false, ('Requieres nivel %d para esta mision'):format(plantilla.nivel_requerido)
    end

    -- Calcular dificultad
    if not dificultad then
        dificultad = Misiones.CalcularDificultadRecomendada(nivelJugador, plantilla)
    end

    -- Validar rango de dificultad
    dificultad = math.max(plantilla.dificultad_min, math.min(plantilla.dificultad_max, dificultad))

    -- Verificar items requeridos
    if plantilla.items_requeridos and #plantilla.items_requeridos > 0 then
        if AIT.Engines.Inventory then
            for _, item in ipairs(plantilla.items_requeridos) do
                local cantidad = AIT.Engines.Inventory.GetItemCount(charId, item.nombre)
                if cantidad < item.cantidad then
                    return false, ('Necesitas %dx %s'):format(item.cantidad, item.nombre)
                end
            end
        end
    end

    -- Generar mision procedural
    local misionGenerada = nil
    if AIT.Engines.Missions.Generator then
        misionGenerada = AIT.Engines.Missions.Generator.Generar(plantilla, dificultad)
    else
        misionGenerada = Misiones.GenerarMisionBasica(plantilla, dificultad)
    end

    -- Calcular recompensas finales
    local recompensas = Misiones.CalcularRecompensas(plantilla, dificultad)

    -- Calcular tiempo limite
    local nivelDificultad = Misiones.NivelesDificultad[dificultad] or Misiones.NivelesDificultad[3]
    local tiempoLimite = math.floor(plantilla.tiempo_limite * nivelDificultad.multiplicadorTiempo)
    local fechaLimite = os.date('%Y-%m-%d %H:%M:%S', os.time() + tiempoLimite)

    -- Insertar en base de datos
    local misionId = MySQL.insert.await([[
        INSERT INTO ait_misiones_activas
        (plantilla_id, char_id, estado, dificultad, progreso, objetivos_totales,
         recompensa_final, xp_final, rep_final, tiempo_limite, checkpoints, metadata)
        VALUES (?, ?, 'activa', ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        plantillaId,
        charId,
        dificultad,
        json.encode(misionGenerada.progreso or {}),
        misionGenerada.objetivos_totales or 1,
        recompensas.dinero,
        recompensas.xp,
        recompensas.rep,
        fechaLimite,
        json.encode(misionGenerada.checkpoints or {}),
        json.encode(misionGenerada.metadata or {})
    })

    if not misionId then
        return false, 'Error al crear la mision'
    end

    -- Agregar a cache
    if not Misiones.activas[charId] then
        Misiones.activas[charId] = {}
    end
    Misiones.activas[charId][misionId] = {
        mision_id = misionId,
        plantilla_id = plantillaId,
        tipo = plantilla.tipo,
        nombre = plantilla.nombre,
        dificultad = dificultad,
        estado = Misiones.Estados.ACTIVA,
        progreso = misionGenerada.progreso or {},
        checkpoints = misionGenerada.checkpoints or {},
        recompensa_final = recompensas.dinero,
        xp_final = recompensas.xp,
        tiempo_limite = os.time() + tiempoLimite,
    }

    -- Quitar items requeridos
    if plantilla.items_requeridos and #plantilla.items_requeridos > 0 then
        if AIT.Engines.Inventory then
            for _, item in ipairs(plantilla.items_requeridos) do
                AIT.Engines.Inventory.RemoveItem(charId, item.nombre, item.cantidad)
            end
        end
    end

    -- Log
    Misiones.RegistrarLog(misionId, charId, 'MISION_INICIADA', {
        plantilla = plantilla.codigo,
        dificultad = dificultad,
        recompensa = recompensas.dinero
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('missions.started', {
            mision_id = misionId,
            char_id = charId,
            plantilla_id = plantillaId,
            tipo = plantilla.tipo,
            dificultad = dificultad
        })
    end

    -- Notificar al cliente
    Misiones.EnviarActualizacionCliente(charId, misionId, 'iniciada', {
        mision = Misiones.activas[charId][misionId],
        objetivos = misionGenerada.objetivos or {},
        checkpoints = misionGenerada.checkpoints or {},
    })

    return true, misionId
end

--- Completar una mision
---@param charId number
---@param misionId number
---@param forzar boolean|nil
---@return boolean, string
function Misiones.Completar(charId, misionId, forzar)
    local mision = Misiones.ObtenerMision(misionId)
    if not mision then
        return false, 'Mision no encontrada'
    end

    if mision.char_id ~= charId then
        return false, 'Esta mision no te pertenece'
    end

    if mision.estado ~= Misiones.Estados.ACTIVA and mision.estado ~= Misiones.Estados.EN_PROGRESO then
        return false, 'Esta mision no esta activa'
    end

    -- Verificar que todos los objetivos esten completados
    if not forzar then
        if mision.objetivos_completados < mision.objetivos_totales then
            return false, ('Faltan %d objetivos por completar'):format(
                mision.objetivos_totales - mision.objetivos_completados
            )
        end
    end

    local ahora = os.date('%Y-%m-%d %H:%M:%S')
    local tiempoTotal = os.time() - (mision.tiempo_inicio_epoch or os.time())

    -- Actualizar estado
    MySQL.query.await([[
        UPDATE ait_misiones_activas
        SET estado = 'completada', tiempo_fin = ?
        WHERE mision_id = ?
    ]], { ahora, misionId })

    -- Registrar en historico
    MySQL.insert.await([[
        INSERT INTO ait_misiones_historico
        (mision_id, plantilla_id, char_id, resultado, dificultad, recompensa_obtenida,
         xp_obtenida, rep_obtenida, tiempo_total, objetivos_completados, objetivos_totales,
         fecha_inicio, metadata)
        VALUES (?, ?, ?, 'completada', ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        misionId,
        mision.plantilla_id,
        charId,
        mision.dificultad,
        mision.recompensa_final,
        mision.xp_final,
        mision.rep_final or 0,
        tiempoTotal,
        mision.objetivos_completados,
        mision.objetivos_totales,
        mision.tiempo_inicio,
        mision.metadata and json.encode(mision.metadata) or nil
    })

    -- Entregar recompensas
    if AIT.Engines.economy then
        AIT.Engines.economy.AddMoney(nil, charId, mision.recompensa_final, 'bank', 'mission_reward',
            ('Recompensa mision: %s'):format(mision.nombre or 'Mision'))
    end

    -- Entregar XP (si hay sistema de niveles)
    if AIT.Engines.Levels then
        AIT.Engines.Levels.AddXP(charId, mision.xp_final, 'mission')
    end

    -- Entregar items de recompensa
    local plantilla = Misiones.ObtenerPlantilla(mision.plantilla_id)
    if plantilla and plantilla.items_recompensa and #plantilla.items_recompensa > 0 then
        if AIT.Engines.Inventory then
            for _, item in ipairs(plantilla.items_recompensa) do
                AIT.Engines.Inventory.AddItem(charId, item.nombre, item.cantidad)
            end
        end
    end

    -- Establecer cooldown
    if plantilla then
        Misiones.EstablecerCooldown(charId, mision.plantilla_id, plantilla.cooldown)
    end

    -- Actualizar estadisticas
    Misiones.ActualizarEstadisticasJugador(charId, 'completada', mision)

    -- Limpiar cache
    if Misiones.activas[charId] then
        Misiones.activas[charId][misionId] = nil
    end

    -- Log
    Misiones.RegistrarLog(misionId, charId, 'MISION_COMPLETADA', {
        recompensa = mision.recompensa_final,
        xp = mision.xp_final,
        tiempo = tiempoTotal
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('missions.completed', {
            mision_id = misionId,
            char_id = charId,
            plantilla_id = mision.plantilla_id,
            recompensa = mision.recompensa_final,
            xp = mision.xp_final
        })
    end

    -- Notificar al cliente
    Misiones.EnviarActualizacionCliente(charId, misionId, 'completada', {
        recompensa = mision.recompensa_final,
        xp = mision.xp_final,
    })

    return true, ('Mision completada! Recompensa: $%s'):format(Misiones.FormatearNumero(mision.recompensa_final))
end

--- Fallar una mision
---@param charId number
---@param misionId number
---@param motivo string|nil
---@return boolean, string
function Misiones.Fallar(charId, misionId, motivo)
    local mision = Misiones.ObtenerMision(misionId)
    if not mision then
        return false, 'Mision no encontrada'
    end

    if mision.char_id ~= charId then
        return false, 'Esta mision no te pertenece'
    end

    local ahora = os.date('%Y-%m-%d %H:%M:%S')
    local tiempoTotal = os.time() - (mision.tiempo_inicio_epoch or os.time())

    -- Actualizar estado
    MySQL.query.await([[
        UPDATE ait_misiones_activas
        SET estado = 'fallida', tiempo_fin = ?
        WHERE mision_id = ?
    ]], { ahora, misionId })

    -- Registrar en historico
    MySQL.insert.await([[
        INSERT INTO ait_misiones_historico
        (mision_id, plantilla_id, char_id, resultado, dificultad, recompensa_obtenida,
         xp_obtenida, rep_obtenida, tiempo_total, objetivos_completados, objetivos_totales,
         fecha_inicio, metadata)
        VALUES (?, ?, ?, 'fallida', ?, 0, 0, 0, ?, ?, ?, ?, ?)
    ]], {
        misionId,
        mision.plantilla_id,
        charId,
        mision.dificultad,
        tiempoTotal,
        mision.objetivos_completados,
        mision.objetivos_totales,
        mision.tiempo_inicio,
        json.encode({ motivo = motivo })
    })

    -- Aplicar penalizacion de cooldown (doble)
    local plantilla = Misiones.ObtenerPlantilla(mision.plantilla_id)
    if plantilla then
        Misiones.EstablecerCooldown(charId, mision.plantilla_id, plantilla.cooldown * 2)
    end

    -- Actualizar estadisticas
    Misiones.ActualizarEstadisticasJugador(charId, 'fallida', mision)

    -- Limpiar cache
    if Misiones.activas[charId] then
        Misiones.activas[charId][misionId] = nil
    end

    -- Log
    Misiones.RegistrarLog(misionId, charId, 'MISION_FALLIDA', {
        motivo = motivo or 'Desconocido',
        tiempo = tiempoTotal
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('missions.failed', {
            mision_id = misionId,
            char_id = charId,
            plantilla_id = mision.plantilla_id,
            motivo = motivo
        })
    end

    -- Notificar al cliente
    Misiones.EnviarActualizacionCliente(charId, misionId, 'fallida', {
        motivo = motivo or 'Mision fallida',
    })

    return true, 'Mision fallida'
end

--- Abandonar una mision
---@param charId number
---@param misionId number
---@return boolean, string
function Misiones.Abandonar(charId, misionId)
    local mision = Misiones.ObtenerMision(misionId)
    if not mision then
        return false, 'Mision no encontrada'
    end

    if mision.char_id ~= charId then
        return false, 'Esta mision no te pertenece'
    end

    local ahora = os.date('%Y-%m-%d %H:%M:%S')

    -- Actualizar estado
    MySQL.query.await([[
        UPDATE ait_misiones_activas
        SET estado = 'abandonada', tiempo_fin = ?
        WHERE mision_id = ?
    ]], { ahora, misionId })

    -- Registrar en historico
    MySQL.insert.await([[
        INSERT INTO ait_misiones_historico
        (mision_id, plantilla_id, char_id, resultado, dificultad, tiempo_total,
         objetivos_completados, objetivos_totales, fecha_inicio)
        VALUES (?, ?, ?, 'abandonada', ?, 0, ?, ?, ?)
    ]], {
        misionId,
        mision.plantilla_id,
        charId,
        mision.dificultad,
        mision.objetivos_completados,
        mision.objetivos_totales,
        mision.tiempo_inicio
    })

    -- Aplicar penalizacion de cooldown (1.5x)
    local plantilla = Misiones.ObtenerPlantilla(mision.plantilla_id)
    if plantilla then
        Misiones.EstablecerCooldown(charId, mision.plantilla_id, math.floor(plantilla.cooldown * 1.5))
    end

    -- Actualizar estadisticas
    Misiones.ActualizarEstadisticasJugador(charId, 'abandonada', mision)

    -- Limpiar cache
    if Misiones.activas[charId] then
        Misiones.activas[charId][misionId] = nil
    end

    -- Limpiar NPCs y vehiculos spawneados
    Misiones.LimpiarEntidadesMision(misionId)

    -- Log
    Misiones.RegistrarLog(misionId, charId, 'MISION_ABANDONADA', {})

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('missions.abandoned', {
            mision_id = misionId,
            char_id = charId,
            plantilla_id = mision.plantilla_id
        })
    end

    -- Notificar al cliente
    Misiones.EnviarActualizacionCliente(charId, misionId, 'abandonada', {})

    return true, 'Mision abandonada'
end

-- =====================================================================================
-- CONSULTAS Y OBTENCION DE DATOS
-- =====================================================================================

--- Obtener una plantilla por ID
---@param plantillaId number
---@return table|nil
function Misiones.ObtenerPlantilla(plantillaId)
    for _, pool in pairs(Misiones.poolMisiones) do
        for _, plantilla in ipairs(pool) do
            if plantilla.plantilla_id == plantillaId then
                return plantilla
            end
        end
    end

    -- Buscar en BD si no esta en cache
    local result = MySQL.query.await([[
        SELECT * FROM ait_misiones_plantillas WHERE plantilla_id = ?
    ]], { plantillaId })

    if result and result[1] then
        local p = result[1]
        p.objetivos = p.objetivos and json.decode(p.objetivos) or {}
        p.ubicaciones = p.ubicaciones and json.decode(p.ubicaciones) or {}
        p.npcs = p.npcs and json.decode(p.npcs) or {}
        p.items_requeridos = p.items_requeridos and json.decode(p.items_requeridos) or {}
        p.items_recompensa = p.items_recompensa and json.decode(p.items_recompensa) or {}
        p.vehiculos = p.vehiculos and json.decode(p.vehiculos) or {}
        p.metadata = p.metadata and json.decode(p.metadata) or {}
        return p
    end

    return nil
end

--- Obtener una mision activa por ID
---@param misionId number
---@return table|nil
function Misiones.ObtenerMision(misionId)
    -- Buscar en cache
    for charId, misiones in pairs(Misiones.activas) do
        if misiones[misionId] then
            return misiones[misionId]
        end
    end

    -- Buscar en BD
    local result = MySQL.query.await([[
        SELECT m.*, p.tipo, p.nombre, p.codigo
        FROM ait_misiones_activas m
        JOIN ait_misiones_plantillas p ON m.plantilla_id = p.plantilla_id
        WHERE m.mision_id = ?
    ]], { misionId })

    if result and result[1] then
        local m = result[1]
        m.progreso = m.progreso and json.decode(m.progreso) or {}
        m.checkpoints = m.checkpoints and json.decode(m.checkpoints) or {}
        m.metadata = m.metadata and json.decode(m.metadata) or {}
        m.tiempo_inicio_epoch = Misiones.ParseFecha(m.tiempo_inicio)
        return m
    end

    return nil
end

--- Obtener misiones activas de un jugador
---@param charId number
---@return table
function Misiones.ObtenerActivas(charId)
    -- Cache primero
    if Misiones.activas[charId] then
        local lista = {}
        for _, mision in pairs(Misiones.activas[charId]) do
            table.insert(lista, mision)
        end
        return lista
    end

    -- Base de datos
    local result = MySQL.query.await([[
        SELECT m.*, p.tipo, p.nombre, p.codigo
        FROM ait_misiones_activas m
        JOIN ait_misiones_plantillas p ON m.plantilla_id = p.plantilla_id
        WHERE m.char_id = ? AND m.estado IN ('activa', 'en_progreso')
    ]], { charId })

    local misiones = {}
    Misiones.activas[charId] = {}

    for _, m in ipairs(result or {}) do
        m.progreso = m.progreso and json.decode(m.progreso) or {}
        m.checkpoints = m.checkpoints and json.decode(m.checkpoints) or {}
        m.metadata = m.metadata and json.decode(m.metadata) or {}
        m.tiempo_limite_epoch = Misiones.ParseFecha(m.tiempo_limite)
        m.tiempo_inicio_epoch = Misiones.ParseFecha(m.tiempo_inicio)

        Misiones.activas[charId][m.mision_id] = m
        table.insert(misiones, m)
    end

    return misiones
end

--- Obtener historial de misiones de un jugador
---@param charId number
---@param limite number|nil
---@return table
function Misiones.ObtenerHistorial(charId, limite)
    limite = limite or 50

    local result = MySQL.query.await([[
        SELECT h.*, p.nombre, p.tipo, p.codigo
        FROM ait_misiones_historico h
        JOIN ait_misiones_plantillas p ON h.plantilla_id = p.plantilla_id
        WHERE h.char_id = ?
        ORDER BY h.fecha_fin DESC
        LIMIT ?
    ]], { charId, limite })

    return result or {}
end

--- Obtener estadisticas de un jugador
---@param charId number
---@return table
function Misiones.ObtenerEstadisticas(charId)
    local result = MySQL.query.await([[
        SELECT * FROM ait_misiones_stats WHERE char_id = ?
    ]], { charId })

    if result and result[1] then
        local stats = result[1]
        stats.por_tipo = stats.por_tipo and json.decode(stats.por_tipo) or {}
        stats.por_dificultad = stats.por_dificultad and json.decode(stats.por_dificultad) or {}
        stats.logros = stats.logros and json.decode(stats.logros) or {}
        return stats
    end

    return {
        misiones_completadas = 0,
        misiones_fallidas = 0,
        misiones_abandonadas = 0,
        recompensa_total = 0,
        xp_total = 0,
        racha_actual = 0,
        racha_maxima = 0,
        por_tipo = {},
        por_dificultad = {},
        logros = {},
    }
end

--- Obtener cooldowns activos de un jugador
---@param charId number
---@return table
function Misiones.ObtenerCooldowns(charId)
    local ahora = os.date('%Y-%m-%d %H:%M:%S')

    local result = MySQL.query.await([[
        SELECT plantilla_id, UNIX_TIMESTAMP(expira_en) as expira_epoch
        FROM ait_misiones_cooldowns
        WHERE char_id = ? AND expira_en > ?
    ]], { charId, ahora })

    local cooldowns = {}
    for _, cd in ipairs(result or {}) do
        if cd.plantilla_id then
            cooldowns[cd.plantilla_id] = cd.expira_epoch
        end
    end

    return cooldowns
end

-- =====================================================================================
-- FUNCIONES DE CALCULO
-- =====================================================================================

--- Calcular la dificultad recomendada para un jugador
---@param nivelJugador number
---@param plantilla table
---@return number
function Misiones.CalcularDificultadRecomendada(nivelJugador, plantilla)
    local dificultadRecomendada = 1

    for nivel, config in pairs(Misiones.NivelesDificultad) do
        if nivelJugador >= config.nivelJugadorMin and nivelJugador <= config.nivelJugadorMax then
            dificultadRecomendada = nivel
            break
        end
    end

    -- Ajustar al rango de la plantilla
    dificultadRecomendada = math.max(plantilla.dificultad_min, dificultadRecomendada)
    dificultadRecomendada = math.min(plantilla.dificultad_max, dificultadRecomendada)

    return dificultadRecomendada
end

--- Calcular recompensas para una mision
---@param plantilla table
---@param dificultad number
---@return table
function Misiones.CalcularRecompensas(plantilla, dificultad)
    local nivelDificultad = Misiones.NivelesDificultad[dificultad] or Misiones.NivelesDificultad[3]

    local dinero = math.floor(plantilla.recompensa_base * nivelDificultad.multiplicadorRecompensa)
    local xp = math.floor(plantilla.xp_base * nivelDificultad.multiplicadorXP)
    local rep = math.floor((plantilla.rep_base or 10) * nivelDificultad.multiplicadorRecompensa)

    return {
        dinero = dinero,
        xp = xp,
        rep = rep,
    }
end

--- Obtener nivel del jugador
---@param charId number
---@return number
function Misiones.ObtenerNivelJugador(charId)
    if AIT.Engines.Levels then
        return AIT.Engines.Levels.GetLevel(charId)
    end

    -- Estimar por misiones completadas
    local stats = Misiones.ObtenerEstadisticas(charId)
    return math.min(100, 1 + math.floor(stats.misiones_completadas / 5))
end

-- =====================================================================================
-- COOLDOWNS
-- =====================================================================================

--- Establecer cooldown para una mision
---@param charId number
---@param plantillaId number
---@param segundos number
function Misiones.EstablecerCooldown(charId, plantillaId, segundos)
    local expira = os.date('%Y-%m-%d %H:%M:%S', os.time() + segundos)

    MySQL.query([[
        INSERT INTO ait_misiones_cooldowns (char_id, plantilla_id, tipo_cooldown, expira_en)
        VALUES (?, ?, 'mision', ?)
        ON DUPLICATE KEY UPDATE expira_en = ?
    ]], { charId, plantillaId, expira, expira })
end

--- Verificar si un jugador tiene cooldown
---@param charId number
---@param plantillaId number
---@return boolean, number|nil
function Misiones.TieneCooldown(charId, plantillaId)
    local cooldowns = Misiones.ObtenerCooldowns(charId)
    if cooldowns[plantillaId] then
        return true, cooldowns[plantillaId] - os.time()
    end
    return false, nil
end

-- =====================================================================================
-- MISIONES ESPECIALES (DIARIAS/SEMANALES)
-- =====================================================================================

function Misiones.GenerarMisionesDiarias()
    local ahora = os.time()
    local inicioHoy = os.date('%Y-%m-%d 00:00:00')
    local finHoy = os.date('%Y-%m-%d 23:59:59')

    -- Desactivar diarias anteriores
    MySQL.query([[
        UPDATE ait_misiones_especiales SET activa = 0
        WHERE tipo = 'diaria' AND fecha_fin < ?
    ]], { inicioHoy })

    -- Seleccionar 3 misiones aleatorias de diferentes tipos
    local tipos = { 'delivery', 'collect', 'hunt' }
    local plantillasElegidas = {}

    for _, tipo in ipairs(tipos) do
        local pool = Misiones.poolMisiones[tipo]
        if pool and #pool > 0 then
            local plantilla = pool[math.random(1, #pool)]
            table.insert(plantillasElegidas, plantilla)
        end
    end

    -- Insertar nuevas diarias
    for _, plantilla in ipairs(plantillasElegidas) do
        MySQL.insert([[
            INSERT INTO ait_misiones_especiales
            (plantilla_id, tipo, fecha_inicio, fecha_fin, bonus_recompensa, bonus_xp)
            VALUES (?, 'diaria', ?, ?, 1.5, 2.0)
        ]], { plantilla.plantilla_id, inicioHoy, finHoy })
    end

    -- Recargar cache
    Misiones.CargarMisionesEspeciales()

    if AIT.Log then
        AIT.Log.info('MISSIONS', ('Generadas %d misiones diarias'):format(#plantillasElegidas))
    end
end

function Misiones.GenerarMisionesSemanales()
    local ahora = os.time()
    -- Calcular inicio de semana (lunes)
    local diasDesdeLogic = tonumber(os.date('%w', ahora))
    if diasDesdeLogic == 0 then diasDesdeLogic = 7 end
    local inicioSemana = os.date('%Y-%m-%d 00:00:00', ahora - ((diasDesdeLogic - 1) * 86400))
    local finSemana = os.date('%Y-%m-%d 23:59:59', ahora + ((7 - diasDesdeLogic) * 86400))

    -- Desactivar semanales anteriores
    MySQL.query([[
        UPDATE ait_misiones_especiales SET activa = 0
        WHERE tipo = 'semanal' AND fecha_fin < ?
    ]], { inicioSemana })

    -- Seleccionar 2 misiones de dificultad alta
    local plantillasElegidas = {}

    for tipo, pool in pairs(Misiones.poolMisiones) do
        for _, plantilla in ipairs(pool) do
            if plantilla.dificultad_max >= 4 and #plantillasElegidas < 2 then
                table.insert(plantillasElegidas, plantilla)
            end
        end
    end

    -- Insertar nuevas semanales
    for _, plantilla in ipairs(plantillasElegidas) do
        MySQL.insert([[
            INSERT INTO ait_misiones_especiales
            (plantilla_id, tipo, fecha_inicio, fecha_fin, bonus_recompensa, bonus_xp)
            VALUES (?, 'semanal', ?, ?, 2.5, 3.0)
        ]], { plantilla.plantilla_id, inicioSemana, finSemana })
    end

    -- Recargar cache
    Misiones.CargarMisionesEspeciales()

    if AIT.Log then
        AIT.Log.info('MISSIONS', ('Generadas %d misiones semanales'):format(#plantillasElegidas))
    end
end

--- Obtener misiones especiales disponibles para un jugador
---@param charId number
---@return table
function Misiones.ObtenerMisionesEspeciales(charId)
    local especiales = {
        diarias = {},
        semanales = {},
    }

    -- Obtener progreso del jugador
    local progresoResult = MySQL.query.await([[
        SELECT especial_id, completada FROM ait_misiones_especiales_progreso
        WHERE char_id = ?
    ]], { charId })

    local progreso = {}
    for _, p in ipairs(progresoResult or {}) do
        progreso[p.especial_id] = p.completada == 1
    end

    -- Diarias
    for _, diaria in ipairs(Misiones.especiales.diarias) do
        table.insert(especiales.diarias, {
            id = diaria.id,
            plantilla_id = diaria.plantilla_id,
            codigo = diaria.codigo,
            nombre = diaria.nombre,
            tipo = diaria.tipo,
            descripcion = diaria.descripcion,
            bonus_recompensa = diaria.bonus_recompensa,
            bonus_xp = diaria.bonus_xp,
            completada = progreso[diaria.id] or false,
        })
    end

    -- Semanales
    for _, semanal in ipairs(Misiones.especiales.semanales) do
        table.insert(especiales.semanales, {
            id = semanal.id,
            plantilla_id = semanal.plantilla_id,
            codigo = semanal.codigo,
            nombre = semanal.nombre,
            tipo = semanal.tipo,
            descripcion = semanal.descripcion,
            bonus_recompensa = semanal.bonus_recompensa,
            bonus_xp = semanal.bonus_xp,
            completada = progreso[semanal.id] or false,
        })
    end

    return especiales
end

-- =====================================================================================
-- ACTUALIZACION DE ESTADISTICAS
-- =====================================================================================

function Misiones.ActualizarEstadisticasJugador(charId, resultado, mision)
    -- Asegurar que existe el registro
    MySQL.query.await([[
        INSERT IGNORE INTO ait_misiones_stats (char_id) VALUES (?)
    ]], { charId })

    local updates = {}
    local params = {}

    if resultado == 'completada' then
        table.insert(updates, 'misiones_completadas = misiones_completadas + 1')
        table.insert(updates, 'recompensa_total = recompensa_total + ?')
        table.insert(params, mision.recompensa_final or 0)
        table.insert(updates, 'xp_total = xp_total + ?')
        table.insert(params, mision.xp_final or 0)
        table.insert(updates, 'racha_actual = racha_actual + 1')
        table.insert(updates, 'racha_maxima = GREATEST(racha_maxima, racha_actual + 1)')
    elseif resultado == 'fallida' then
        table.insert(updates, 'misiones_fallidas = misiones_fallidas + 1')
        table.insert(updates, 'racha_actual = 0')
    elseif resultado == 'abandonada' then
        table.insert(updates, 'misiones_abandonadas = misiones_abandonadas + 1')
        table.insert(updates, 'racha_actual = 0')
    end

    if #updates > 0 then
        local query = 'UPDATE ait_misiones_stats SET ' .. table.concat(updates, ', ') .. ' WHERE char_id = ?'
        table.insert(params, charId)
        MySQL.query(query, params)
    end
end

function Misiones.ActualizarEstadisticas()
    -- Calcular estadisticas globales del servidor
    local stats = MySQL.query.await([[
        SELECT
            COUNT(*) as total,
            SUM(CASE WHEN resultado = 'completada' THEN 1 ELSE 0 END) as completadas,
            SUM(CASE WHEN resultado = 'fallida' THEN 1 ELSE 0 END) as fallidas,
            SUM(recompensa_obtenida) as recompensas_totales,
            AVG(tiempo_total) as tiempo_promedio
        FROM ait_misiones_historico
        WHERE fecha_fin >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ]])[1] or {}

    if AIT.State then
        AIT.State.set('missions.stats', {
            ultimas24h = {
                total = stats.total or 0,
                completadas = stats.completadas or 0,
                fallidas = stats.fallidas or 0,
                recompensas = stats.recompensas_totales or 0,
                tiempoPromedio = stats.tiempo_promedio or 0,
            }
        })
    end
end

-- =====================================================================================
-- THREADS DE PROCESAMIENTO
-- =====================================================================================

function Misiones.IniciarThreadProgreso()
    CreateThread(function()
        while true do
            Wait(1000)

            while #Misiones.colaProgreso > 0 do
                local actualizacion = table.remove(Misiones.colaProgreso, 1)
                Misiones.ProcesarActualizacionProgreso(actualizacion)
            end
        end
    end)
end

function Misiones.IniciarThreadExpiracion()
    CreateThread(function()
        while true do
            Wait(30000) -- Cada 30 segundos

            local ahora = os.time()

            for charId, misiones in pairs(Misiones.activas) do
                for misionId, mision in pairs(misiones) do
                    if mision.tiempo_limite and ahora > mision.tiempo_limite then
                        -- Expirar mision
                        Misiones.Fallar(charId, misionId, 'Tiempo agotado')
                    end
                end
            end
        end
    end)
end

function Misiones.ProcesarActualizacionProgreso(actualizacion)
    local mision = Misiones.ObtenerMision(actualizacion.mision_id)
    if not mision then return end

    -- Actualizar progreso en BD
    MySQL.query([[
        UPDATE ait_misiones_activas
        SET progreso = ?, objetivos_completados = ?, estado = ?
        WHERE mision_id = ?
    ]], {
        json.encode(actualizacion.progreso),
        actualizacion.objetivos_completados,
        actualizacion.estado or 'en_progreso',
        actualizacion.mision_id
    })

    -- Actualizar cache
    if Misiones.activas[mision.char_id] and Misiones.activas[mision.char_id][actualizacion.mision_id] then
        Misiones.activas[mision.char_id][actualizacion.mision_id].progreso = actualizacion.progreso
        Misiones.activas[mision.char_id][actualizacion.mision_id].objetivos_completados = actualizacion.objetivos_completados
    end
end

function Misiones.LimpiarMisionesExpiradas()
    local ahora = os.date('%Y-%m-%d %H:%M:%S')

    -- Obtener misiones expiradas
    local expiradas = MySQL.query.await([[
        SELECT mision_id, char_id FROM ait_misiones_activas
        WHERE estado IN ('activa', 'en_progreso') AND tiempo_limite < ?
    ]], { ahora })

    for _, mision in ipairs(expiradas or {}) do
        Misiones.Fallar(mision.char_id, mision.mision_id, 'Tiempo agotado')
    end

    -- Limpiar cooldowns expirados
    MySQL.query([[
        DELETE FROM ait_misiones_cooldowns WHERE expira_en < ?
    ]], { ahora })

    if AIT.Log and #(expiradas or {}) > 0 then
        AIT.Log.info('MISSIONS', ('Limpiadas %d misiones expiradas'):format(#expiradas))
    end
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Misiones.GenerarMisionBasica(plantilla, dificultad)
    local nivelDificultad = Misiones.NivelesDificultad[dificultad] or Misiones.NivelesDificultad[3]

    return {
        objetivos_totales = math.min(#plantilla.objetivos, nivelDificultad.checkpointsMax),
        progreso = {},
        checkpoints = {},
        metadata = {
            dificultad = dificultad,
            generado_en = os.time(),
        },
    }
end

function Misiones.LimpiarEntidadesMision(misionId)
    local mision = Misiones.ObtenerMision(misionId)
    if not mision then return end

    -- Los NPCs y vehiculos se limpian desde el cliente
    -- Aqui solo notificamos
    if mision.char_id then
        Misiones.EnviarActualizacionCliente(mision.char_id, misionId, 'limpiar_entidades', {})
    end
end

function Misiones.EnviarActualizacionCliente(charId, misionId, tipo, datos)
    -- Obtener source del jugador
    local source = Misiones.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:missions:update', source, {
            tipo = tipo,
            mision_id = misionId,
            datos = datos,
        })
    end
end

function Misiones.ObtenerSourceDeCharId(charId)
    -- Buscar en jugadores conectados
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

function Misiones.RegistrarLog(misionId, charId, accion, detalles)
    MySQL.insert([[
        INSERT INTO ait_misiones_logs (mision_id, char_id, accion, detalles)
        VALUES (?, ?, ?, ?)
    ]], { misionId, charId, accion, detalles and json.encode(detalles) or nil })
end

function Misiones.FormatearNumero(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return formatted
end

function Misiones.ParseFecha(fechaStr)
    if not fechaStr then return os.time() end
    local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
    local year, month, day, hour, min, sec = fechaStr:match(pattern)
    if year then
        return os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec)
        })
    end
    return os.time()
end

-- =====================================================================================
-- EVENTOS DEL SERVIDOR
-- =====================================================================================

function Misiones.RegistrarEventos()
    -- Jugador conectado
    RegisterNetEvent('ait:player:loaded', function(source, playerData, charData)
        if charData and charData.char_id then
            -- Cargar misiones activas del jugador
            local activas = Misiones.ObtenerActivas(charData.char_id)

            if #activas > 0 then
                TriggerClientEvent('ait:missions:load', source, activas)
            end

            -- Enviar misiones especiales
            local especiales = Misiones.ObtenerMisionesEspeciales(charData.char_id)
            TriggerClientEvent('ait:missions:specials', source, especiales)
        end
    end)

    -- Jugador desconectado
    AddEventHandler('playerDropped', function(reason)
        local source = source
        -- Limpiar cache
        for charId, misiones in pairs(Misiones.activas) do
            local sourceDeChar = Misiones.ObtenerSourceDeCharId(charId)
            if sourceDeChar == source then
                -- Pausar misiones activas
                for misionId, _ in pairs(misiones) do
                    MySQL.query([[
                        UPDATE ait_misiones_activas
                        SET tiempo_pausado = tiempo_pausado + ?
                        WHERE mision_id = ?
                    ]], { 0, misionId }) -- Se puede agregar tiempo pausado real
                end
                break
            end
        end
    end)

    -- Actualizar progreso desde cliente
    RegisterNetEvent('ait:missions:progress', function(misionId, progreso, objetivosCompletados)
        local source = source
        if AIT.RateLimit and not AIT.RateLimit.check(tostring(source), 'mission.progress') then
            return
        end

        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid

        -- Verificar que la mision pertenece al jugador
        local mision = Misiones.ObtenerMision(misionId)
        if not mision or mision.char_id ~= charId then return end

        table.insert(Misiones.colaProgreso, {
            mision_id = misionId,
            progreso = progreso,
            objetivos_completados = objetivosCompletados,
            estado = Misiones.Estados.EN_PROGRESO,
        })

        -- Verificar si se completo
        if objetivosCompletados >= mision.objetivos_totales then
            Misiones.Completar(charId, misionId)
        end
    end)

    -- Solicitar completar mision
    RegisterNetEvent('ait:missions:complete', function(misionId)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Misiones.Completar(charId, misionId)

        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)

    -- Solicitar abandonar mision
    RegisterNetEvent('ait:missions:abandon', function(misionId)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Misiones.Abandonar(charId, misionId)

        TriggerClientEvent('QBCore:Notify', source, msg, success and 'info' or 'error')
    end)

    -- Solicitar iniciar mision
    RegisterNetEvent('ait:missions:start', function(plantillaId, dificultad)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, resultado = Misiones.Iniciar(charId, plantillaId, dificultad)

        if success then
            TriggerClientEvent('QBCore:Notify', source, 'Mision iniciada', 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, resultado, 'error')
        end
    end)

    -- Solicitar misiones disponibles
    RegisterNetEvent('ait:missions:getAvailable', function(filtros)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local disponibles = Misiones.ObtenerDisponibles(charId, filtros)

        TriggerClientEvent('ait:missions:available', source, disponibles)
    end)
end

-- =====================================================================================
-- COMANDOS
-- =====================================================================================

function Misiones.RegistrarComandos()
    -- Ver misiones activas
    RegisterCommand('misiones', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local activas = Misiones.ObtenerActivas(charId)

        if #activas == 0 then
            TriggerClientEvent('QBCore:Notify', source, 'No tienes misiones activas', 'info')
            return
        end

        local mensaje = '=== MISIONES ACTIVAS ==='
        for _, mision in ipairs(activas) do
            local tiempoRestante = math.max(0, (mision.tiempo_limite_epoch or 0) - os.time())
            local minutos = math.floor(tiempoRestante / 60)

            mensaje = mensaje .. ('\n[%s] %s - %d/%d objetivos - %d min'):format(
                mision.tipo:upper(),
                mision.nombre,
                mision.objetivos_completados,
                mision.objetivos_totales,
                minutos
            )
        end

        TriggerClientEvent('chat:addMessage', source, { args = { 'Misiones', mensaje } })
    end, false)

    -- Ver estadisticas
    RegisterCommand('misionstats', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local stats = Misiones.ObtenerEstadisticas(charId)

        local mensaje = ([[
=== ESTADISTICAS ===
Completadas: %d
Fallidas: %d
Abandonadas: %d
Recompensa total: $%s
XP total: %s
Racha actual: %d
Racha maxima: %d
        ]]):format(
            stats.misiones_completadas,
            stats.misiones_fallidas,
            stats.misiones_abandonadas,
            Misiones.FormatearNumero(stats.recompensa_total),
            Misiones.FormatearNumero(stats.xp_total),
            stats.racha_actual,
            stats.racha_maxima
        )

        TriggerClientEvent('chat:addMessage', source, { args = { 'Misiones', mensaje } })
    end, false)

    -- Admin: Completar mision
    RegisterCommand('adminmissioncomplete', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'mission.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local misionId = tonumber(args[1])
        if not misionId then
            local msg = 'Uso: /adminmissioncomplete [mision_id]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        local mision = Misiones.ObtenerMision(misionId)
        if not mision then
            local msg = 'Mision no encontrada'
            if source > 0 then
                TriggerClientEvent('QBCore:Notify', source, msg, 'error')
            else
                print(msg)
            end
            return
        end

        local success, resultado = Misiones.Completar(mision.char_id, misionId, true)
        local msg = success and 'Mision completada forzadamente' or ('Error: %s'):format(resultado)

        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
        else
            print(msg)
        end
    end, false)

    -- Admin: Recargar plantillas
    RegisterCommand('adminmissionreload', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'mission.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        Misiones.CargarPlantillas()
        Misiones.CargarMisionesEspeciales()

        local msg = 'Plantillas de misiones recargadas'
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, msg, 'success')
        else
            print(msg)
        end
    end, false)
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Getters
Misiones.GetAvailable = Misiones.ObtenerDisponibles
Misiones.GetActive = Misiones.ObtenerActivas
Misiones.GetMission = Misiones.ObtenerMision
Misiones.GetHistory = Misiones.ObtenerHistorial
Misiones.GetStats = Misiones.ObtenerEstadisticas
Misiones.GetSpecials = Misiones.ObtenerMisionesEspeciales
Misiones.GetCooldowns = Misiones.ObtenerCooldowns

-- Actions
Misiones.Start = Misiones.Iniciar
Misiones.Complete = Misiones.Completar
Misiones.Fail = Misiones.Fallar
Misiones.Abandon = Misiones.Abandonar

-- Utils
Misiones.CalculateRewards = Misiones.CalcularRecompensas
Misiones.HasCooldown = Misiones.TieneCooldown

-- =====================================================================================
-- REGISTRAR ENGINE
-- =====================================================================================

AIT.Engines.Missions = Misiones

return Misiones
