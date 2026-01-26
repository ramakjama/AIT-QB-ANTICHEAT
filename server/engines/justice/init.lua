-- =====================================================================================
-- ait-qb ENGINE DE JUSTICIA
-- Sistema completo de justicia: wanted level, multas, carcel, antecedentes penales
-- Namespace: AIT.Engines.Justice
-- Optimizado para 2048 slots
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Justice = AIT.Engines.Justice or {}

local Justicia = {
    -- Cache de jugadores buscados
    buscados = {},
    -- Cache de jugadores en carcel
    enCarcel = {},
    -- Antecedentes penales en memoria
    antecedentes = {},
    -- Cola de notificaciones a policia
    colaNotificaciones = {},
    -- Configuracion de delitos
    delitos = {},
    -- Oficiales de policia online
    policiasOnline = {},
}

-- =====================================================================================
-- CONFIGURACION DE NIVELES DE BUSQUEDA
-- =====================================================================================

Justicia.NivelesWanted = {
    [1] = {
        nombre = 'Infracciones Menores',
        descripcion = 'Multas de trafico, desorden publico leve',
        estrellas = 1,
        tiempoDecay = 300,         -- 5 minutos para bajar
        multaBase = 500,
        tiempoCarcelBase = 0,      -- Solo multa
        respuestaPolicialMax = 2,
        radioBusqueda = 100,
        puedeEscapar = true,
        notificarPolicia = false,
        color = '#FFEB3B',
    },
    [2] = {
        nombre = 'Delitos Menores',
        descripcion = 'Exceso de velocidad grave, resistencia pasiva',
        estrellas = 2,
        tiempoDecay = 600,         -- 10 minutos
        multaBase = 2500,
        tiempoCarcelBase = 5,      -- 5 minutos
        respuestaPolicialMax = 4,
        radioBusqueda = 200,
        puedeEscapar = true,
        notificarPolicia = true,
        color = '#FF9800',
    },
    [3] = {
        nombre = 'Delitos Moderados',
        descripcion = 'Robo menor, agresion, evasion policial',
        estrellas = 3,
        tiempoDecay = 900,         -- 15 minutos
        multaBase = 7500,
        tiempoCarcelBase = 15,     -- 15 minutos
        respuestaPolicialMax = 6,
        radioBusqueda = 400,
        puedeEscapar = true,
        notificarPolicia = true,
        color = '#FF5722',
    },
    [4] = {
        nombre = 'Delitos Graves',
        descripcion = 'Robo a mano armada, secuestro, trafico',
        estrellas = 4,
        tiempoDecay = 1800,        -- 30 minutos
        multaBase = 25000,
        tiempoCarcelBase = 45,     -- 45 minutos
        respuestaPolicialMax = 10,
        radioBusqueda = 800,
        puedeEscapar = false,      -- Requiere captura
        notificarPolicia = true,
        alertaGlobal = true,
        color = '#F44336',
    },
    [5] = {
        nombre = 'Delitos Muy Graves',
        descripcion = 'Asesinato, terrorismo, crimen organizado',
        estrellas = 5,
        tiempoDecay = 3600,        -- 60 minutos
        multaBase = 75000,
        tiempoCarcelBase = 120,    -- 2 horas
        respuestaPolicialMax = 20,
        radioBusqueda = 1500,
        puedeEscapar = false,
        notificarPolicia = true,
        alertaGlobal = true,
        fuerzaLetal = true,
        color = '#B71C1C',
    },
    [6] = {
        nombre = 'Terrorista',
        descripcion = 'Amenaza extrema para la seguridad publica',
        estrellas = 6,
        tiempoDecay = 7200,        -- 2 horas
        multaBase = 150000,
        tiempoCarcelBase = 300,    -- 5 horas (o ban temporal)
        respuestaPolicialMax = 50,
        radioBusqueda = 9999,      -- Todo el mapa
        puedeEscapar = false,
        notificarPolicia = true,
        alertaGlobal = true,
        fuerzaLetal = true,
        helicopteros = true,
        color = '#000000',
    },
}

-- =====================================================================================
-- CONFIGURACION DE TIPOS DE DELITO
-- =====================================================================================

Justicia.TiposDelito = {
    -- Delitos de trafico
    exceso_velocidad_leve = {
        nombre = 'Exceso de velocidad leve',
        categoria = 'trafico',
        nivelWanted = 1,
        multa = 250,
        tiempoCarcel = 0,
        puntos = 1,
        descripcion = 'Circular entre 20-40 km/h por encima del limite',
    },
    exceso_velocidad_grave = {
        nombre = 'Exceso de velocidad grave',
        categoria = 'trafico',
        nivelWanted = 2,
        multa = 1000,
        tiempoCarcel = 0,
        puntos = 3,
        descripcion = 'Circular mas de 40 km/h por encima del limite',
    },
    conduccion_temeraria = {
        nombre = 'Conduccion temeraria',
        categoria = 'trafico',
        nivelWanted = 2,
        multa = 2500,
        tiempoCarcel = 5,
        puntos = 4,
        descripcion = 'Poner en peligro la seguridad vial',
    },
    saltarse_semaforo = {
        nombre = 'Saltarse semaforo en rojo',
        categoria = 'trafico',
        nivelWanted = 1,
        multa = 500,
        tiempoCarcel = 0,
        puntos = 2,
        descripcion = 'Ignorar senales de trafico',
    },
    conducir_sin_licencia = {
        nombre = 'Conducir sin licencia',
        categoria = 'trafico',
        nivelWanted = 2,
        multa = 3500,
        tiempoCarcel = 10,
        puntos = 6,
        descripcion = 'Conducir sin permiso valido',
    },
    darse_a_la_fuga = {
        nombre = 'Darse a la fuga',
        categoria = 'trafico',
        nivelWanted = 3,
        multa = 5000,
        tiempoCarcel = 15,
        puntos = 5,
        descripcion = 'Huir de un accidente de trafico',
    },

    -- Delitos contra las personas
    amenazas = {
        nombre = 'Amenazas',
        categoria = 'personas',
        nivelWanted = 2,
        multa = 2000,
        tiempoCarcel = 10,
        puntos = 3,
        descripcion = 'Amenazar a otra persona',
    },
    agresion_leve = {
        nombre = 'Agresion leve',
        categoria = 'personas',
        nivelWanted = 2,
        multa = 3500,
        tiempoCarcel = 15,
        puntos = 4,
        descripcion = 'Causar lesiones menores',
    },
    agresion_grave = {
        nombre = 'Agresion grave',
        categoria = 'personas',
        nivelWanted = 3,
        multa = 10000,
        tiempoCarcel = 30,
        puntos = 6,
        descripcion = 'Causar lesiones graves',
    },
    intento_asesinato = {
        nombre = 'Intento de asesinato',
        categoria = 'personas',
        nivelWanted = 4,
        multa = 50000,
        tiempoCarcel = 60,
        puntos = 10,
        descripcion = 'Intentar acabar con la vida de alguien',
    },
    asesinato = {
        nombre = 'Asesinato',
        categoria = 'personas',
        nivelWanted = 5,
        multa = 100000,
        tiempoCarcel = 120,
        puntos = 15,
        descripcion = 'Acabar con la vida de alguien',
    },
    secuestro = {
        nombre = 'Secuestro',
        categoria = 'personas',
        nivelWanted = 4,
        multa = 35000,
        tiempoCarcel = 45,
        puntos = 8,
        descripcion = 'Privar de libertad a alguien',
    },

    -- Delitos contra la propiedad
    robo_menor = {
        nombre = 'Hurto',
        categoria = 'propiedad',
        nivelWanted = 2,
        multa = 1500,
        tiempoCarcel = 10,
        puntos = 3,
        descripcion = 'Sustraer objetos de poco valor',
    },
    robo_mayor = {
        nombre = 'Robo',
        categoria = 'propiedad',
        nivelWanted = 3,
        multa = 7500,
        tiempoCarcel = 25,
        puntos = 5,
        descripcion = 'Robo de objetos de valor',
    },
    robo_vehiculo = {
        nombre = 'Robo de vehiculo',
        categoria = 'propiedad',
        nivelWanted = 3,
        multa = 10000,
        tiempoCarcel = 30,
        puntos = 6,
        descripcion = 'Sustraer un vehiculo ajeno',
    },
    robo_mano_armada = {
        nombre = 'Robo a mano armada',
        categoria = 'propiedad',
        nivelWanted = 4,
        multa = 25000,
        tiempoCarcel = 45,
        puntos = 8,
        descripcion = 'Robo con uso de armas',
    },
    atraco_banco = {
        nombre = 'Atraco a banco',
        categoria = 'propiedad',
        nivelWanted = 5,
        multa = 75000,
        tiempoCarcel = 90,
        puntos = 12,
        descripcion = 'Robo a entidad bancaria',
    },
    vandalismo = {
        nombre = 'Vandalismo',
        categoria = 'propiedad',
        nivelWanted = 1,
        multa = 1000,
        tiempoCarcel = 5,
        puntos = 2,
        descripcion = 'Danos a propiedad publica o privada',
    },
    allanamiento = {
        nombre = 'Allanamiento de morada',
        categoria = 'propiedad',
        nivelWanted = 2,
        multa = 5000,
        tiempoCarcel = 20,
        puntos = 4,
        descripcion = 'Entrar en propiedad privada sin autorizacion',
    },

    -- Delitos contra la autoridad
    resistencia_arresto = {
        nombre = 'Resistencia al arresto',
        categoria = 'autoridad',
        nivelWanted = 3,
        multa = 5000,
        tiempoCarcel = 20,
        puntos = 5,
        descripcion = 'Resistirse a ser detenido',
    },
    evasion_policial = {
        nombre = 'Evasion policial',
        categoria = 'autoridad',
        nivelWanted = 3,
        multa = 7500,
        tiempoCarcel = 25,
        puntos = 6,
        descripcion = 'Huir de la policia',
    },
    agresion_oficial = {
        nombre = 'Agresion a oficial',
        categoria = 'autoridad',
        nivelWanted = 4,
        multa = 20000,
        tiempoCarcel = 40,
        puntos = 8,
        descripcion = 'Agredir a un oficial de policia',
    },
    soborno = {
        nombre = 'Soborno',
        categoria = 'autoridad',
        nivelWanted = 3,
        multa = 15000,
        tiempoCarcel = 30,
        puntos = 5,
        descripcion = 'Intentar sobornar a un oficial',
    },
    suplantacion_oficial = {
        nombre = 'Suplantacion de oficial',
        categoria = 'autoridad',
        nivelWanted = 3,
        multa = 12000,
        tiempoCarcel = 35,
        puntos = 6,
        descripcion = 'Hacerse pasar por policia',
    },
    fuga_carcel = {
        nombre = 'Fuga de prision',
        categoria = 'autoridad',
        nivelWanted = 4,
        multa = 30000,
        tiempoCarcel = 60,
        puntos = 10,
        descripcion = 'Escapar de custodia policial',
    },

    -- Delitos de drogas y armas
    posesion_drogas = {
        nombre = 'Posesion de drogas',
        categoria = 'drogas',
        nivelWanted = 2,
        multa = 5000,
        tiempoCarcel = 15,
        puntos = 4,
        descripcion = 'Poseer sustancias ilegales',
    },
    trafico_drogas = {
        nombre = 'Trafico de drogas',
        categoria = 'drogas',
        nivelWanted = 4,
        multa = 35000,
        tiempoCarcel = 60,
        puntos = 10,
        descripcion = 'Distribuir sustancias ilegales',
    },
    posesion_armas_ilegales = {
        nombre = 'Posesion de armas ilegales',
        categoria = 'armas',
        nivelWanted = 3,
        multa = 10000,
        tiempoCarcel = 25,
        puntos = 6,
        descripcion = 'Portar armas sin licencia',
    },
    trafico_armas = {
        nombre = 'Trafico de armas',
        categoria = 'armas',
        nivelWanted = 4,
        multa = 50000,
        tiempoCarcel = 75,
        puntos = 12,
        descripcion = 'Vender armas ilegalmente',
    },
    disparo_arma = {
        nombre = 'Disparo de arma de fuego',
        categoria = 'armas',
        nivelWanted = 3,
        multa = 7500,
        tiempoCarcel = 20,
        puntos = 5,
        descripcion = 'Disparar arma en zona publica',
    },

    -- Delitos especiales
    terrorismo = {
        nombre = 'Terrorismo',
        categoria = 'especial',
        nivelWanted = 6,
        multa = 250000,
        tiempoCarcel = 300,
        puntos = 20,
        descripcion = 'Actos terroristas contra la poblacion',
    },
    lavado_dinero = {
        nombre = 'Lavado de dinero',
        categoria = 'especial',
        nivelWanted = 4,
        multa = 100000,
        tiempoCarcel = 60,
        puntos = 10,
        descripcion = 'Blanquear dinero de origen ilegal',
    },
    crimen_organizado = {
        nombre = 'Crimen organizado',
        categoria = 'especial',
        nivelWanted = 5,
        multa = 150000,
        tiempoCarcel = 120,
        puntos = 15,
        descripcion = 'Liderar organizacion criminal',
    },
}

-- =====================================================================================
-- CONFIGURACION DE CATEGORIAS
-- =====================================================================================

Justicia.Categorias = {
    trafico = { nombre = 'Trafico', icono = 'fa-car', color = '#4CAF50' },
    personas = { nombre = 'Personas', icono = 'fa-user', color = '#F44336' },
    propiedad = { nombre = 'Propiedad', icono = 'fa-home', color = '#FF9800' },
    autoridad = { nombre = 'Autoridad', icono = 'fa-shield-alt', color = '#2196F3' },
    drogas = { nombre = 'Drogas', icono = 'fa-pills', color = '#9C27B0' },
    armas = { nombre = 'Armas', icono = 'fa-crosshairs', color = '#795548' },
    especial = { nombre = 'Especial', icono = 'fa-skull', color = '#000000' },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Justicia.Initialize()
    -- Crear tablas de base de datos
    Justicia.CrearTablas()

    -- Cargar configuracion
    Justicia.CargarConfiguracion()

    -- Cargar buscados activos
    Justicia.CargarBuscados()

    -- Cargar presos activos
    Justicia.CargarPresosActivos()

    -- Registrar eventos
    Justicia.RegistrarEventos()

    -- Registrar comandos
    Justicia.RegistrarComandos()

    -- Iniciar thread de decay de wanted
    Justicia.IniciarThreadDecay()

    -- Iniciar thread de notificaciones
    Justicia.IniciarThreadNotificaciones()

    -- Registrar tareas del scheduler
    if AIT.Scheduler then
        -- Limpiar wanted expirados cada 5 minutos
        AIT.Scheduler.register('justice_wanted_cleanup', {
            interval = 300,
            fn = Justicia.LimpiarWantedExpirados
        })

        -- Procesar tiempos de carcel cada minuto
        AIT.Scheduler.register('justice_jail_tick', {
            interval = 60,
            fn = Justicia.ProcesarTiemposCarcel
        })

        -- Limpiar antecedentes muy antiguos diariamente
        AIT.Scheduler.register('justice_records_cleanup', {
            interval = 86400,
            fn = Justicia.LimpiarAntecedentesAntiguos
        })

        -- Estadisticas cada hora
        AIT.Scheduler.register('justice_stats', {
            interval = 3600,
            fn = Justicia.ActualizarEstadisticas
        })
    end

    if AIT.Log then
        AIT.Log.info('JUSTICE', 'Engine de Justicia inicializado correctamente')
    end

    return true
end

-- =====================================================================================
-- CREACION DE TABLAS
-- =====================================================================================

function Justicia.CrearTablas()
    -- Tabla de estado wanted actual
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_wanted (
            wanted_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            nivel INT NOT NULL DEFAULT 1,
            delitos JSON NOT NULL,
            ultima_ubicacion JSON NULL,
            tiempo_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            tiempo_ultimo_delito DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            tiempo_decay DATETIME NULL,
            visto_por JSON NULL,
            activo TINYINT(1) NOT NULL DEFAULT 1,
            metadata JSON NULL,
            UNIQUE KEY idx_char_activo (char_id, activo),
            KEY idx_nivel (nivel),
            KEY idx_activo (activo),
            KEY idx_tiempo (tiempo_ultimo_delito)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de antecedentes penales
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_antecedentes (
            antecedente_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            tipo_delito VARCHAR(64) NOT NULL,
            descripcion TEXT NULL,
            multa_impuesta BIGINT NOT NULL DEFAULT 0,
            multa_pagada BIGINT NOT NULL DEFAULT 0,
            tiempo_carcel INT NOT NULL DEFAULT 0,
            tiempo_cumplido INT NOT NULL DEFAULT 0,
            puntos INT NOT NULL DEFAULT 0,
            arrestado_por BIGINT NULL,
            ubicacion_arresto JSON NULL,
            evidencias JSON NULL,
            estado ENUM('pendiente', 'cumplida', 'indultada', 'apelada', 'prescrita') NOT NULL DEFAULT 'pendiente',
            fecha_delito DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_arresto DATETIME NULL,
            fecha_sentencia DATETIME NULL,
            fecha_cumplimiento DATETIME NULL,
            notas TEXT NULL,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_tipo (tipo_delito),
            KEY idx_estado (estado),
            KEY idx_fecha (fecha_delito),
            KEY idx_arrestado_por (arrestado_por)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de multas
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_multas (
            multa_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            antecedente_id BIGINT NULL,
            tipo VARCHAR(64) NOT NULL,
            descripcion VARCHAR(255) NOT NULL,
            monto BIGINT NOT NULL,
            monto_pagado BIGINT NOT NULL DEFAULT 0,
            descuento DECIMAL(5,2) NOT NULL DEFAULT 0,
            recargo DECIMAL(5,2) NOT NULL DEFAULT 0,
            emitida_por BIGINT NULL,
            estado ENUM('pendiente', 'pagada', 'parcial', 'anulada', 'prescrita') NOT NULL DEFAULT 'pendiente',
            fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_vencimiento DATETIME NULL,
            fecha_pago DATETIME NULL,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_estado (estado),
            KEY idx_fecha (fecha_emision),
            KEY idx_antecedente (antecedente_id),
            FOREIGN KEY (antecedente_id) REFERENCES ait_justicia_antecedentes(antecedente_id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estado de carcel
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_carcel (
            carcel_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            antecedente_id BIGINT NULL,
            tiempo_total INT NOT NULL,
            tiempo_cumplido INT NOT NULL DEFAULT 0,
            tiempo_reducido INT NOT NULL DEFAULT 0,
            trabajo_realizado JSON NULL,
            celda VARCHAR(32) NULL,
            comportamiento INT NOT NULL DEFAULT 100,
            intentos_fuga INT NOT NULL DEFAULT 0,
            estado ENUM('cumpliendo', 'liberado', 'fugado', 'trasladado') NOT NULL DEFAULT 'cumpliendo',
            fecha_ingreso DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_liberacion_estimada DATETIME NULL,
            fecha_liberacion DATETIME NULL,
            liberado_por BIGINT NULL,
            notas TEXT NULL,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_estado (estado),
            KEY idx_fecha (fecha_ingreso),
            FOREIGN KEY (antecedente_id) REFERENCES ait_justicia_antecedentes(antecedente_id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de puntos de licencia
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_puntos_licencia (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            puntos_actuales INT NOT NULL DEFAULT 12,
            puntos_maximos INT NOT NULL DEFAULT 12,
            licencia_suspendida TINYINT(1) NOT NULL DEFAULT 0,
            fecha_suspension DATETIME NULL,
            fecha_recuperacion DATETIME NULL,
            historial JSON NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY idx_char (char_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de ordenes de arresto
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_ordenes_arresto (
            orden_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL,
            tipo_delito VARCHAR(64) NOT NULL,
            descripcion TEXT NOT NULL,
            nivel_prioridad INT NOT NULL DEFAULT 3,
            recompensa BIGINT NOT NULL DEFAULT 0,
            emitida_por BIGINT NOT NULL,
            autorizada_por BIGINT NULL,
            estado ENUM('activa', 'ejecutada', 'cancelada', 'expirada') NOT NULL DEFAULT 'activa',
            fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_expiracion DATETIME NULL,
            fecha_ejecucion DATETIME NULL,
            ejecutada_por BIGINT NULL,
            metadata JSON NULL,
            KEY idx_char (char_id),
            KEY idx_estado (estado),
            KEY idx_prioridad (nivel_prioridad),
            KEY idx_fecha (fecha_emision)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de logs de justicia
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_logs (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NULL,
            oficial_id BIGINT NULL,
            accion VARCHAR(64) NOT NULL,
            tipo_delito VARCHAR(64) NULL,
            detalles JSON NULL,
            ubicacion JSON NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_char (char_id),
            KEY idx_oficial (oficial_id),
            KEY idx_accion (accion),
            KEY idx_fecha (fecha)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estadisticas de justicia
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_stats (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL UNIQUE,
            total_arrestos INT NOT NULL DEFAULT 0,
            total_multas_recibidas BIGINT NOT NULL DEFAULT 0,
            total_multas_pagadas BIGINT NOT NULL DEFAULT 0,
            tiempo_carcel_total INT NOT NULL DEFAULT 0,
            fugas_exitosas INT NOT NULL DEFAULT 0,
            fugas_fallidas INT NOT NULL DEFAULT 0,
            delitos_por_categoria JSON NULL,
            nivel_wanted_maximo INT NOT NULL DEFAULT 0,
            puntos_perdidos_total INT NOT NULL DEFAULT 0,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estadisticas de oficiales
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_justicia_stats_oficiales (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            char_id BIGINT NOT NULL UNIQUE,
            total_arrestos INT NOT NULL DEFAULT 0,
            total_multas_emitidas BIGINT NOT NULL DEFAULT 0,
            total_multas_monto BIGINT NOT NULL DEFAULT 0,
            sospechosos_capturados INT NOT NULL DEFAULT 0,
            persecuciones_exitosas INT NOT NULL DEFAULT 0,
            tiempo_servicio_total INT NOT NULL DEFAULT 0,
            arrestos_por_categoria JSON NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

-- =====================================================================================
-- CARGAR CONFIGURACION
-- =====================================================================================

function Justicia.CargarConfiguracion()
    -- Cargar overrides de config si existen
    if AIT.Config and AIT.Config.justice then
        if AIT.Config.justice.niveles then
            for nivel, config in pairs(AIT.Config.justice.niveles) do
                if Justicia.NivelesWanted[nivel] then
                    Justicia.NivelesWanted[nivel] = AIT.Utils.Merge(Justicia.NivelesWanted[nivel], config)
                end
            end
        end

        if AIT.Config.justice.delitos then
            for delito, config in pairs(AIT.Config.justice.delitos) do
                if Justicia.TiposDelito[delito] then
                    Justicia.TiposDelito[delito] = AIT.Utils.Merge(Justicia.TiposDelito[delito], config)
                end
            end
        end
    end
end

function Justicia.CargarBuscados()
    local buscados = MySQL.query.await([[
        SELECT w.*, c.nombre, c.apellido
        FROM ait_justicia_wanted w
        LEFT JOIN ait_characters c ON w.char_id = c.char_id
        WHERE w.activo = 1
    ]])

    Justicia.buscados = {}
    for _, buscado in ipairs(buscados or {}) do
        buscado.delitos = buscado.delitos and json.decode(buscado.delitos) or {}
        buscado.ultima_ubicacion = buscado.ultima_ubicacion and json.decode(buscado.ultima_ubicacion) or nil
        buscado.visto_por = buscado.visto_por and json.decode(buscado.visto_por) or {}
        buscado.metadata = buscado.metadata and json.decode(buscado.metadata) or {}

        Justicia.buscados[buscado.char_id] = buscado
    end

    if AIT.Log then
        AIT.Log.info('JUSTICE', ('Cargados %d sospechosos buscados'):format(#(buscados or {})))
    end
end

function Justicia.CargarPresosActivos()
    local presos = MySQL.query.await([[
        SELECT c.*, ch.nombre, ch.apellido
        FROM ait_justicia_carcel c
        LEFT JOIN ait_characters ch ON c.char_id = ch.char_id
        WHERE c.estado = 'cumpliendo'
    ]])

    Justicia.enCarcel = {}
    for _, preso in ipairs(presos or {}) do
        preso.trabajo_realizado = preso.trabajo_realizado and json.decode(preso.trabajo_realizado) or {}
        preso.metadata = preso.metadata and json.decode(preso.metadata) or {}

        Justicia.enCarcel[preso.char_id] = preso
    end

    if AIT.Log then
        AIT.Log.info('JUSTICE', ('Cargados %d presos activos'):format(#(presos or {})))
    end
end

-- =====================================================================================
-- GESTION DE WANTED (BUSQUEDA)
-- =====================================================================================

--- Anadir nivel de busqueda a un jugador
---@param charId number
---@param tipoDelito string
---@param opciones table|nil
---@return boolean, string
function Justicia.AnadirWanted(charId, tipoDelito, opciones)
    opciones = opciones or {}

    local delito = Justicia.TiposDelito[tipoDelito]
    if not delito then
        return false, 'Tipo de delito no valido'
    end

    local ahora = os.date('%Y-%m-%d %H:%M:%S')
    local buscadoActual = Justicia.buscados[charId]

    if buscadoActual then
        -- Aumentar nivel si es mayor
        local nuevoNivel = math.max(buscadoActual.nivel, delito.nivelWanted)
        nuevoNivel = math.min(6, nuevoNivel + (opciones.incremento or 0))

        -- Anadir delito a la lista
        table.insert(buscadoActual.delitos, {
            tipo = tipoDelito,
            nombre = delito.nombre,
            timestamp = os.time(),
            ubicacion = opciones.ubicacion,
            testigos = opciones.testigos,
        })

        -- Actualizar BD
        MySQL.query([[
            UPDATE ait_justicia_wanted
            SET nivel = ?, delitos = ?, tiempo_ultimo_delito = ?, ultima_ubicacion = ?
            WHERE wanted_id = ?
        ]], {
            nuevoNivel,
            json.encode(buscadoActual.delitos),
            ahora,
            opciones.ubicacion and json.encode(opciones.ubicacion) or nil,
            buscadoActual.wanted_id
        })

        buscadoActual.nivel = nuevoNivel
        buscadoActual.tiempo_ultimo_delito = ahora
        buscadoActual.ultima_ubicacion = opciones.ubicacion

    else
        -- Crear nuevo registro de busqueda
        local delitos = {{
            tipo = tipoDelito,
            nombre = delito.nombre,
            timestamp = os.time(),
            ubicacion = opciones.ubicacion,
            testigos = opciones.testigos,
        }}

        local wantedId = MySQL.insert.await([[
            INSERT INTO ait_justicia_wanted
            (char_id, nivel, delitos, ultima_ubicacion, tiempo_decay)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            charId,
            delito.nivelWanted,
            json.encode(delitos),
            opciones.ubicacion and json.encode(opciones.ubicacion) or nil,
            os.date('%Y-%m-%d %H:%M:%S', os.time() + (Justicia.NivelesWanted[delito.nivelWanted].tiempoDecay or 300))
        })

        Justicia.buscados[charId] = {
            wanted_id = wantedId,
            char_id = charId,
            nivel = delito.nivelWanted,
            delitos = delitos,
            ultima_ubicacion = opciones.ubicacion,
            tiempo_inicio = ahora,
            tiempo_ultimo_delito = ahora,
            activo = true,
        }
    end

    -- Registrar antecedente
    Justicia.RegistrarAntecedente(charId, tipoDelito, opciones)

    -- Notificar a policia si es necesario
    local nivelConfig = Justicia.NivelesWanted[Justicia.buscados[charId].nivel]
    if nivelConfig.notificarPolicia then
        Justicia.NotificarPolicia(charId, tipoDelito, Justicia.buscados[charId].nivel, opciones.ubicacion)
    end

    -- Log
    Justicia.RegistrarLog(charId, nil, 'WANTED_ANADIDO', tipoDelito, {
        nivel = Justicia.buscados[charId].nivel,
        delito = delito.nombre
    }, opciones.ubicacion)

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.wanted.added', {
            char_id = charId,
            nivel = Justicia.buscados[charId].nivel,
            tipo_delito = tipoDelito,
            delito_nombre = delito.nombre,
        })
    end

    -- Notificar al cliente
    Justicia.EnviarActualizacionCliente(charId, 'wanted', {
        nivel = Justicia.buscados[charId].nivel,
        delitos = Justicia.buscados[charId].delitos,
    })

    return true, ('Nivel de busqueda: %d estrellas'):format(Justicia.buscados[charId].nivel)
end

--- Reducir o limpiar nivel de busqueda
---@param charId number
---@param cantidad number|nil
---@param motivo string|nil
---@return boolean
function Justicia.ReducirWanted(charId, cantidad, motivo)
    local buscado = Justicia.buscados[charId]
    if not buscado then
        return false
    end

    cantidad = cantidad or 1
    local nuevoNivel = math.max(0, buscado.nivel - cantidad)

    if nuevoNivel <= 0 then
        return Justicia.LimpiarWanted(charId, motivo or 'Decay natural')
    end

    MySQL.query([[
        UPDATE ait_justicia_wanted SET nivel = ? WHERE wanted_id = ?
    ]], { nuevoNivel, buscado.wanted_id })

    buscado.nivel = nuevoNivel

    -- Log
    Justicia.RegistrarLog(charId, nil, 'WANTED_REDUCIDO', nil, {
        nivel_anterior = buscado.nivel + cantidad,
        nivel_nuevo = nuevoNivel,
        motivo = motivo
    })

    -- Notificar al cliente
    Justicia.EnviarActualizacionCliente(charId, 'wanted', {
        nivel = nuevoNivel,
    })

    return true
end

--- Limpiar completamente el nivel de busqueda
---@param charId number
---@param motivo string|nil
---@return boolean
function Justicia.LimpiarWanted(charId, motivo)
    local buscado = Justicia.buscados[charId]
    if not buscado then
        return true -- Ya no esta buscado
    end

    MySQL.query([[
        UPDATE ait_justicia_wanted SET activo = 0 WHERE wanted_id = ?
    ]], { buscado.wanted_id })

    Justicia.buscados[charId] = nil

    -- Log
    Justicia.RegistrarLog(charId, nil, 'WANTED_LIMPIADO', nil, {
        nivel_anterior = buscado.nivel,
        motivo = motivo or 'Limpieza manual'
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.wanted.cleared', {
            char_id = charId,
            motivo = motivo,
        })
    end

    -- Notificar al cliente
    Justicia.EnviarActualizacionCliente(charId, 'wanted', {
        nivel = 0,
        limpiado = true,
    })

    return true
end

--- Obtener estado de busqueda de un jugador
---@param charId number
---@return table|nil
function Justicia.ObtenerWanted(charId)
    return Justicia.buscados[charId]
end

--- Obtener nivel de busqueda
---@param charId number
---@return number
function Justicia.ObtenerNivelWanted(charId)
    local buscado = Justicia.buscados[charId]
    return buscado and buscado.nivel or 0
end

--- Verificar si un jugador esta buscado
---@param charId number
---@param nivelMinimo number|nil
---@return boolean
function Justicia.EstaBuscado(charId, nivelMinimo)
    local buscado = Justicia.buscados[charId]
    if not buscado then return false end

    nivelMinimo = nivelMinimo or 1
    return buscado.nivel >= nivelMinimo
end

--- Obtener lista de todos los buscados
---@param filtros table|nil
---@return table
function Justicia.ObtenerTodosBuscados(filtros)
    filtros = filtros or {}
    local lista = {}

    for charId, buscado in pairs(Justicia.buscados) do
        local incluir = true

        if filtros.nivelMinimo and buscado.nivel < filtros.nivelMinimo then
            incluir = false
        end

        if filtros.nivelMaximo and buscado.nivel > filtros.nivelMaximo then
            incluir = false
        end

        if incluir then
            table.insert(lista, buscado)
        end
    end

    -- Ordenar por nivel (mayor primero)
    table.sort(lista, function(a, b)
        return a.nivel > b.nivel
    end)

    return lista
end

-- =====================================================================================
-- GESTION DE ANTECEDENTES
-- =====================================================================================

--- Registrar antecedente penal
---@param charId number
---@param tipoDelito string
---@param opciones table|nil
---@return number|nil antecedenteId
function Justicia.RegistrarAntecedente(charId, tipoDelito, opciones)
    opciones = opciones or {}

    local delito = Justicia.TiposDelito[tipoDelito]
    if not delito then return nil end

    local antecedenteId = MySQL.insert.await([[
        INSERT INTO ait_justicia_antecedentes
        (char_id, tipo_delito, descripcion, multa_impuesta, tiempo_carcel, puntos,
         arrestado_por, ubicacion_arresto, evidencias, estado)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendiente')
    ]], {
        charId,
        tipoDelito,
        opciones.descripcion or delito.descripcion,
        delito.multa,
        delito.tiempoCarcel,
        delito.puntos,
        opciones.arrestadoPor,
        opciones.ubicacion and json.encode(opciones.ubicacion) or nil,
        opciones.evidencias and json.encode(opciones.evidencias) or nil,
    })

    -- Actualizar puntos de licencia si aplica
    if delito.puntos > 0 and delito.categoria == 'trafico' then
        Justicia.RestarPuntosLicencia(charId, delito.puntos)
    end

    return antecedenteId
end

--- Obtener antecedentes de un jugador
---@param charId number
---@param limite number|nil
---@return table
function Justicia.ObtenerAntecedentes(charId, limite)
    limite = limite or 50

    local antecedentes = MySQL.query.await([[
        SELECT a.*, o.nombre as oficial_nombre, o.apellido as oficial_apellido
        FROM ait_justicia_antecedentes a
        LEFT JOIN ait_characters o ON a.arrestado_por = o.char_id
        WHERE a.char_id = ?
        ORDER BY a.fecha_delito DESC
        LIMIT ?
    ]], { charId, limite })

    for _, ant in ipairs(antecedentes or {}) do
        ant.ubicacion_arresto = ant.ubicacion_arresto and json.decode(ant.ubicacion_arresto) or nil
        ant.evidencias = ant.evidencias and json.decode(ant.evidencias) or nil
    end

    return antecedentes or {}
end

--- Obtener resumen de antecedentes
---@param charId number
---@return table
function Justicia.ObtenerResumenAntecedentes(charId)
    local resumen = MySQL.query.await([[
        SELECT
            COUNT(*) as total_delitos,
            SUM(CASE WHEN estado = 'cumplida' THEN 1 ELSE 0 END) as cumplidas,
            SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) as pendientes,
            SUM(multa_impuesta) as total_multas,
            SUM(multa_pagada) as multas_pagadas,
            SUM(tiempo_carcel) as tiempo_carcel_total,
            SUM(tiempo_cumplido) as tiempo_cumplido,
            SUM(puntos) as puntos_perdidos
        FROM ait_justicia_antecedentes
        WHERE char_id = ?
    ]], { charId })

    return resumen and resumen[1] or {
        total_delitos = 0,
        cumplidas = 0,
        pendientes = 0,
        total_multas = 0,
        multas_pagadas = 0,
        tiempo_carcel_total = 0,
        tiempo_cumplido = 0,
        puntos_perdidos = 0,
    }
end

-- =====================================================================================
-- GESTION DE MULTAS
-- =====================================================================================

--- Emitir una multa
---@param charId number
---@param tipo string
---@param monto number
---@param opciones table|nil
---@return boolean, number|string
function Justicia.EmitirMulta(charId, tipo, monto, opciones)
    opciones = opciones or {}

    -- Calcular fecha de vencimiento (30 dias)
    local fechaVencimiento = os.date('%Y-%m-%d %H:%M:%S', os.time() + (30 * 86400))

    local multaId = MySQL.insert.await([[
        INSERT INTO ait_justicia_multas
        (char_id, antecedente_id, tipo, descripcion, monto, emitida_por, fecha_vencimiento)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        charId,
        opciones.antecedenteId,
        tipo,
        opciones.descripcion or 'Multa',
        monto,
        opciones.emitidaPor,
        fechaVencimiento,
    })

    if not multaId then
        return false, 'Error al crear la multa'
    end

    -- Actualizar estadisticas
    Justicia.ActualizarStatsMulta(charId, monto, opciones.emitidaPor)

    -- Log
    Justicia.RegistrarLog(charId, opciones.emitidaPor, 'MULTA_EMITIDA', tipo, {
        monto = monto,
        multa_id = multaId,
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.fine.issued', {
            char_id = charId,
            multa_id = multaId,
            monto = monto,
            tipo = tipo,
        })
    end

    -- Notificar al cliente
    Justicia.EnviarActualizacionCliente(charId, 'multa', {
        multa_id = multaId,
        monto = monto,
        tipo = tipo,
        descripcion = opciones.descripcion,
    })

    return true, multaId
end

--- Pagar una multa
---@param charId number
---@param multaId number
---@param montoPago number|nil
---@return boolean, string
function Justicia.PagarMulta(charId, multaId, montoPago)
    local multa = MySQL.query.await([[
        SELECT * FROM ait_justicia_multas WHERE multa_id = ? AND char_id = ?
    ]], { multaId, charId })

    if not multa or #multa == 0 then
        return false, 'Multa no encontrada'
    end

    multa = multa[1]

    if multa.estado == 'pagada' then
        return false, 'Esta multa ya ha sido pagada'
    end

    local montoPendiente = multa.monto - multa.monto_pagado
    montoPago = montoPago or montoPendiente

    if montoPago > montoPendiente then
        montoPago = montoPendiente
    end

    -- Verificar fondos
    if AIT.Engines.economy then
        local balance = AIT.Engines.economy.GetBalance('char', charId, 'bank')
        if balance < montoPago then
            return false, 'Fondos insuficientes'
        end

        -- Cobrar
        local success = AIT.Engines.economy.RemoveMoney(nil, charId, montoPago, 'bank', 'fine', 'Pago de multa')
        if not success then
            return false, 'Error al procesar el pago'
        end
    end

    -- Actualizar multa
    local nuevoMontoPagado = multa.monto_pagado + montoPago
    local nuevoEstado = nuevoMontoPagado >= multa.monto and 'pagada' or 'parcial'

    MySQL.query([[
        UPDATE ait_justicia_multas
        SET monto_pagado = ?, estado = ?, fecha_pago = ?
        WHERE multa_id = ?
    ]], {
        nuevoMontoPagado,
        nuevoEstado,
        nuevoEstado == 'pagada' and os.date('%Y-%m-%d %H:%M:%S') or nil,
        multaId
    })

    -- Log
    Justicia.RegistrarLog(charId, nil, 'MULTA_PAGADA', nil, {
        multa_id = multaId,
        monto_pagado = montoPago,
        estado = nuevoEstado,
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('justice.fine.paid', {
            char_id = charId,
            multa_id = multaId,
            monto_pagado = montoPago,
            estado = nuevoEstado,
        })
    end

    return true, ('Pagados $%s. %s'):format(
        Justicia.FormatearNumero(montoPago),
        nuevoEstado == 'pagada' and 'Multa saldada.' or ('Pendiente: $%s'):format(Justicia.FormatearNumero(montoPendiente - montoPago))
    )
end

--- Obtener multas pendientes de un jugador
---@param charId number
---@return table
function Justicia.ObtenerMultasPendientes(charId)
    return MySQL.query.await([[
        SELECT * FROM ait_justicia_multas
        WHERE char_id = ? AND estado IN ('pendiente', 'parcial')
        ORDER BY fecha_emision ASC
    ]], { charId }) or {}
end

--- Obtener total de multas pendientes
---@param charId number
---@return number
function Justicia.ObtenerTotalMultasPendientes(charId)
    local result = MySQL.query.await([[
        SELECT SUM(monto - monto_pagado) as total
        FROM ait_justicia_multas
        WHERE char_id = ? AND estado IN ('pendiente', 'parcial')
    ]], { charId })

    return result and result[1] and result[1].total or 0
end

-- =====================================================================================
-- GESTION DE PUNTOS DE LICENCIA
-- =====================================================================================

--- Restar puntos de licencia
---@param charId number
---@param puntos number
---@return boolean, number
function Justicia.RestarPuntosLicencia(charId, puntos)
    -- Asegurar registro existe
    MySQL.query.await([[
        INSERT IGNORE INTO ait_justicia_puntos_licencia (char_id) VALUES (?)
    ]], { charId })

    -- Obtener puntos actuales
    local result = MySQL.query.await([[
        SELECT * FROM ait_justicia_puntos_licencia WHERE char_id = ?
    ]], { charId })

    local registro = result and result[1]
    if not registro then return false, 0 end

    local nuevosPuntos = math.max(0, registro.puntos_actuales - puntos)
    local suspendida = nuevosPuntos <= 0

    local fechaSuspension = nil
    local fechaRecuperacion = nil

    if suspendida and not registro.licencia_suspendida then
        fechaSuspension = os.date('%Y-%m-%d %H:%M:%S')
        fechaRecuperacion = os.date('%Y-%m-%d %H:%M:%S', os.time() + (30 * 86400)) -- 30 dias
    end

    MySQL.query([[
        UPDATE ait_justicia_puntos_licencia
        SET puntos_actuales = ?, licencia_suspendida = ?,
            fecha_suspension = COALESCE(?, fecha_suspension),
            fecha_recuperacion = COALESCE(?, fecha_recuperacion)
        WHERE char_id = ?
    ]], { nuevosPuntos, suspendida and 1 or 0, fechaSuspension, fechaRecuperacion, charId })

    -- Notificar al cliente
    Justicia.EnviarActualizacionCliente(charId, 'puntos_licencia', {
        puntos = nuevosPuntos,
        suspendida = suspendida,
    })

    return true, nuevosPuntos
end

--- Obtener puntos de licencia
---@param charId number
---@return table
function Justicia.ObtenerPuntosLicencia(charId)
    local result = MySQL.query.await([[
        SELECT * FROM ait_justicia_puntos_licencia WHERE char_id = ?
    ]], { charId })

    return result and result[1] or {
        puntos_actuales = 12,
        puntos_maximos = 12,
        licencia_suspendida = false,
    }
end

-- =====================================================================================
-- NOTIFICACIONES A POLICIA
-- =====================================================================================

--- Notificar a la policia de un delito
---@param charId number
---@param tipoDelito string
---@param nivelWanted number
---@param ubicacion table|nil
function Justicia.NotificarPolicia(charId, tipoDelito, nivelWanted, ubicacion)
    local delito = Justicia.TiposDelito[tipoDelito]
    if not delito then return end

    local nivelConfig = Justicia.NivelesWanted[nivelWanted]
    if not nivelConfig then return end

    -- Obtener nombre del sospechoso si es conocido
    local nombreSospechoso = 'Sospechoso desconocido'
    if AIT.QBCore then
        -- Buscar si hay testigos o si el sospechoso es conocido
        local charData = MySQL.query.await([[
            SELECT nombre, apellido FROM ait_characters WHERE char_id = ?
        ]], { charId })

        if charData and charData[1] then
            nombreSospechoso = charData[1].nombre .. ' ' .. charData[1].apellido
        end
    end

    local notificacion = {
        tipo = 'delito',
        prioridad = nivelWanted >= 4 and 'urgente' or (nivelWanted >= 3 and 'alta' or 'normal'),
        titulo = ('%s - %d Estrellas'):format(delito.nombre, nivelWanted),
        mensaje = ('Sospechoso: %s. %s'):format(nombreSospechoso, delito.descripcion),
        char_id = charId,
        nivel_wanted = nivelWanted,
        ubicacion = ubicacion,
        timestamp = os.time(),
    }

    table.insert(Justicia.colaNotificaciones, notificacion)

    -- Si es alerta global, notificar a todos los policias
    if nivelConfig.alertaGlobal then
        Justicia.AlertaGlobal(notificacion)
    end
end

--- Enviar alerta global a todos los policias
---@param notificacion table
function Justicia.AlertaGlobal(notificacion)
    for charId, sourceId in pairs(Justicia.policiasOnline) do
        TriggerClientEvent('ait:justice:alert', sourceId, {
            tipo = 'alerta_global',
            prioridad = 'urgente',
            titulo = '!!! ALERTA MAXIMA !!!',
            mensaje = notificacion.mensaje,
            ubicacion = notificacion.ubicacion,
            nivel_wanted = notificacion.nivel_wanted,
        })

        -- Sonido de alerta
        TriggerClientEvent('ait:justice:playSound', sourceId, 'alert_critical')
    end
end

--- Iniciar thread de notificaciones
function Justicia.IniciarThreadNotificaciones()
    CreateThread(function()
        while true do
            Wait(1000)

            while #Justicia.colaNotificaciones > 0 do
                local notif = table.remove(Justicia.colaNotificaciones, 1)

                -- Enviar a policias cercanos o a todos segun prioridad
                for charId, sourceId in pairs(Justicia.policiasOnline) do
                    TriggerClientEvent('ait:justice:notification', sourceId, notif)
                end
            end
        end
    end)
end

-- =====================================================================================
-- THREAD DE DECAY DE WANTED
-- =====================================================================================

function Justicia.IniciarThreadDecay()
    CreateThread(function()
        while true do
            Wait(30000) -- Cada 30 segundos

            local ahora = os.time()

            for charId, buscado in pairs(Justicia.buscados) do
                if buscado.tiempo_decay then
                    local tiempoDecay = Justicia.ParseFecha(buscado.tiempo_decay)

                    if ahora >= tiempoDecay then
                        -- Verificar si puede escapar (decay natural)
                        local nivelConfig = Justicia.NivelesWanted[buscado.nivel]

                        if nivelConfig and nivelConfig.puedeEscapar then
                            -- Verificar que no haya policias cerca (esto lo deberia verificar el cliente)
                            local sourceId = Justicia.ObtenerSourceDeCharId(charId)

                            if sourceId then
                                -- Solicitar verificacion al cliente
                                TriggerClientEvent('ait:justice:checkEscape', sourceId, buscado.nivel)
                            else
                                -- Si no esta conectado, reducir nivel
                                Justicia.ReducirWanted(charId, 1, 'Decay por desconexion')
                            end
                        end

                        -- Actualizar tiempo de decay para el siguiente nivel
                        local nuevoTiempoDecay = os.date('%Y-%m-%d %H:%M:%S', ahora + (nivelConfig.tiempoDecay or 300))

                        MySQL.query([[
                            UPDATE ait_justicia_wanted SET tiempo_decay = ? WHERE wanted_id = ?
                        ]], { nuevoTiempoDecay, buscado.wanted_id })

                        buscado.tiempo_decay = nuevoTiempoDecay
                    end
                end
            end
        end
    end)
end

-- =====================================================================================
-- FUNCIONES DE LIMPIEZA
-- =====================================================================================

function Justicia.LimpiarWantedExpirados()
    -- Limpiar wanted con decay muy antiguo sin actividad reciente
    local limite = os.date('%Y-%m-%d %H:%M:%S', os.time() - 7200) -- 2 horas

    local expirados = MySQL.query.await([[
        SELECT wanted_id, char_id FROM ait_justicia_wanted
        WHERE activo = 1 AND tiempo_ultimo_delito < ?
        AND nivel <= 2
    ]], { limite })

    for _, exp in ipairs(expirados or {}) do
        Justicia.LimpiarWanted(exp.char_id, 'Expiracion automatica')
    end

    if AIT.Log and #(expirados or {}) > 0 then
        AIT.Log.info('JUSTICE', ('Limpiados %d wanted expirados'):format(#expirados))
    end
end

function Justicia.LimpiarAntecedentesAntiguos()
    -- Marcar como prescritos los antecedentes de mas de 1 ano sin cumplir
    MySQL.query([[
        UPDATE ait_justicia_antecedentes
        SET estado = 'prescrita'
        WHERE estado = 'pendiente'
        AND fecha_delito < DATE_SUB(NOW(), INTERVAL 365 DAY)
    ]])
end

-- =====================================================================================
-- ESTADISTICAS
-- =====================================================================================

function Justicia.ActualizarStatsMulta(charId, monto, oficialId)
    -- Stats del multado
    MySQL.query([[
        INSERT INTO ait_justicia_stats (char_id, total_multas_recibidas)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE total_multas_recibidas = total_multas_recibidas + ?
    ]], { charId, monto, monto })

    -- Stats del oficial
    if oficialId then
        MySQL.query([[
            INSERT INTO ait_justicia_stats_oficiales (char_id, total_multas_emitidas, total_multas_monto)
            VALUES (?, 1, ?)
            ON DUPLICATE KEY UPDATE
                total_multas_emitidas = total_multas_emitidas + 1,
                total_multas_monto = total_multas_monto + ?
        ]], { oficialId, monto, monto })
    end
end

function Justicia.ActualizarEstadisticas()
    -- Calcular estadisticas globales
    local stats = MySQL.query.await([[
        SELECT
            COUNT(DISTINCT w.char_id) as buscados_actuales,
            (SELECT COUNT(*) FROM ait_justicia_carcel WHERE estado = 'cumpliendo') as presos_actuales,
            (SELECT SUM(monto - monto_pagado) FROM ait_justicia_multas WHERE estado IN ('pendiente', 'parcial')) as multas_pendientes_total,
            (SELECT COUNT(*) FROM ait_justicia_antecedentes WHERE DATE(fecha_delito) = CURDATE()) as delitos_hoy
        FROM ait_justicia_wanted w
        WHERE w.activo = 1
    ]])[1] or {}

    if AIT.State then
        AIT.State.set('justice.stats', stats)
    end
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Justicia.EnviarActualizacionCliente(charId, tipo, datos)
    local source = Justicia.ObtenerSourceDeCharId(charId)
    if source then
        TriggerClientEvent('ait:justice:update', source, {
            tipo = tipo,
            datos = datos,
        })
    end
end

function Justicia.ObtenerSourceDeCharId(charId)
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

function Justicia.RegistrarLog(charId, oficialId, accion, tipoDelito, detalles, ubicacion)
    MySQL.insert([[
        INSERT INTO ait_justicia_logs (char_id, oficial_id, accion, tipo_delito, detalles, ubicacion)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        charId,
        oficialId,
        accion,
        tipoDelito,
        detalles and json.encode(detalles) or nil,
        ubicacion and json.encode(ubicacion) or nil
    })
end

function Justicia.FormatearNumero(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return formatted
end

function Justicia.ParseFecha(fechaStr)
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

function Justicia.RegistrarEventos()
    -- Jugador conectado
    RegisterNetEvent('ait:player:loaded', function(source, playerData, charData)
        if charData and charData.char_id then
            local charId = charData.char_id

            -- Verificar si es policia
            if AIT.Engines.Factions then
                local faccion = AIT.Engines.Factions.ObtenerFaccionDePersonaje(charId)
                if faccion and faccion.tipo == 'gobierno' then
                    Justicia.policiasOnline[charId] = source
                end
            end

            -- Enviar estado de wanted
            local buscado = Justicia.buscados[charId]
            if buscado then
                TriggerClientEvent('ait:justice:wanted', source, {
                    nivel = buscado.nivel,
                    delitos = buscado.delitos,
                })
            end

            -- Enviar estado de carcel
            local preso = Justicia.enCarcel[charId]
            if preso then
                TriggerClientEvent('ait:justice:jail', source, {
                    tiempo_restante = preso.tiempo_total - preso.tiempo_cumplido - preso.tiempo_reducido,
                    celda = preso.celda,
                })
            end

            -- Enviar multas pendientes
            local multas = Justicia.ObtenerMultasPendientes(charId)
            if #multas > 0 then
                TriggerClientEvent('ait:justice:fines', source, multas)
            end

            -- Enviar puntos de licencia
            local puntos = Justicia.ObtenerPuntosLicencia(charId)
            TriggerClientEvent('ait:justice:licensePoints', source, puntos)
        end
    end)

    -- Jugador desconectado
    AddEventHandler('playerDropped', function(reason)
        local source = source
        -- Remover de policias online
        for charId, sid in pairs(Justicia.policiasOnline) do
            if sid == source then
                Justicia.policiasOnline[charId] = nil
                break
            end
        end
    end)

    -- Respuesta de verificacion de escape
    RegisterNetEvent('ait:justice:escapeResponse', function(puedeEscapar)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid

        if puedeEscapar then
            Justicia.ReducirWanted(charId, 1, 'Escape exitoso')
        end
    end)
end

-- =====================================================================================
-- COMANDOS
-- =====================================================================================

function Justicia.RegistrarComandos()
    -- Ver estado de busqueda propio
    RegisterCommand('wanted', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local nivel = Justicia.ObtenerNivelWanted(charId)

        if nivel == 0 then
            TriggerClientEvent('QBCore:Notify', source, 'No tienes nivel de busqueda', 'success')
        else
            local nivelConfig = Justicia.NivelesWanted[nivel]
            TriggerClientEvent('QBCore:Notify', source,
                ('Nivel de busqueda: %d estrellas - %s'):format(nivel, nivelConfig.nombre), 'error')
        end
    end, false)

    -- Ver antecedentes propios
    RegisterCommand('antecedentes', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local resumen = Justicia.ObtenerResumenAntecedentes(charId)

        local mensaje = ([[
=== ANTECEDENTES PENALES ===
Total delitos: %d
Pendientes: %d
Cumplidas: %d
Multas totales: $%s
Multas pagadas: $%s
Tiempo carcel total: %d minutos
        ]]):format(
            resumen.total_delitos,
            resumen.pendientes,
            resumen.cumplidas,
            Justicia.FormatearNumero(resumen.total_multas or 0),
            Justicia.FormatearNumero(resumen.multas_pagadas or 0),
            resumen.tiempo_carcel_total or 0
        )

        TriggerClientEvent('chat:addMessage', source, { args = { 'Justicia', mensaje } })
    end, false)

    -- Comando policia: buscar antecedentes
    RegisterCommand('buscarpersona', function(source, args, rawCommand)
        -- Verificar que es policia
        if source > 0 then
            local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
            if not Player then return end

            local charId = Player.PlayerData.citizenid
            if not Justicia.policiasOnline[charId] then
                TriggerClientEvent('QBCore:Notify', source, 'No tienes acceso a esta funcion', 'error')
                return
            end
        end

        local targetId = tonumber(args[1])
        if not targetId then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', 'Uso: /buscarpersona [char_id]' } })
            return
        end

        local antecedentes = Justicia.ObtenerAntecedentes(targetId, 10)
        local resumen = Justicia.ObtenerResumenAntecedentes(targetId)
        local wanted = Justicia.ObtenerWanted(targetId)

        local mensaje = ('\n=== REGISTRO CRIMINAL ===\nDelitos: %d | Pendientes: %d\nMultas pendientes: $%s\nNivel busqueda: %s'):format(
            resumen.total_delitos,
            resumen.pendientes,
            Justicia.FormatearNumero(Justicia.ObtenerTotalMultasPendientes(targetId)),
            wanted and (wanted.nivel .. ' estrellas') or 'Ninguno'
        )

        TriggerClientEvent('chat:addMessage', source, { args = { 'MDT', mensaje } })
    end, false)

    -- Comando admin: anadir wanted
    RegisterCommand('adminwanted', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'justice.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local targetId = tonumber(args[1])
        local tipoDelito = args[2]

        if not targetId or not tipoDelito then
            local msg = 'Uso: /adminwanted [char_id] [tipo_delito]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        local success, resultado = Justicia.AnadirWanted(targetId, tipoDelito)
        local msg = success and resultado or ('Error: %s'):format(resultado)

        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
        else
            print(msg)
        end
    end, false)

    -- Comando admin: limpiar wanted
    RegisterCommand('adminclearwanted', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'justice.admin') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local targetId = tonumber(args[1])

        if not targetId then
            local msg = 'Uso: /adminclearwanted [char_id]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        Justicia.LimpiarWanted(targetId, 'Limpieza administrativa')

        local msg = 'Wanted limpiado'
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

-- Wanted
Justicia.AddWanted = Justicia.AnadirWanted
Justicia.ReduceWanted = Justicia.ReducirWanted
Justicia.ClearWanted = Justicia.LimpiarWanted
Justicia.GetWanted = Justicia.ObtenerWanted
Justicia.GetWantedLevel = Justicia.ObtenerNivelWanted
Justicia.IsWanted = Justicia.EstaBuscado
Justicia.GetAllWanted = Justicia.ObtenerTodosBuscados

-- Antecedentes
Justicia.AddRecord = Justicia.RegistrarAntecedente
Justicia.GetRecords = Justicia.ObtenerAntecedentes
Justicia.GetRecordsSummary = Justicia.ObtenerResumenAntecedentes

-- Multas
Justicia.IssueFine = Justicia.EmitirMulta
Justicia.PayFine = Justicia.PagarMulta
Justicia.GetPendingFines = Justicia.ObtenerMultasPendientes
Justicia.GetTotalPendingFines = Justicia.ObtenerTotalMultasPendientes

-- Licencia
Justicia.DeductLicensePoints = Justicia.RestarPuntosLicencia
Justicia.GetLicensePoints = Justicia.ObtenerPuntosLicencia

-- Policia
Justicia.NotifyPolice = Justicia.NotificarPolicia
Justicia.GlobalAlert = Justicia.AlertaGlobal

-- =====================================================================================
-- REGISTRAR ENGINE
-- =====================================================================================

AIT.Engines.Justice = Justicia

return Justicia
