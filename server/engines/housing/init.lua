-- =====================================================================================
-- ait-qb ENGINE DE VIVIENDAS
-- Sistema completo de propiedades: compra, venta, alquiler, acceso y almacenamiento
-- Namespace: AIT.Engines.Housing
-- Optimizado para 2048 slots con routing buckets
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}

local Viviendas = {
    -- Cache de propiedades activas
    cache = {},
    -- Propietarios online por propiedad
    propietariosOnline = {},
    -- Routing buckets activos
    routingBuckets = {},
    -- Siguiente bucket disponible
    siguienteBucket = 1000,
    -- Configuracion de tipos
    tipos = {},
    -- Cola de operaciones
    colaOperaciones = {},
}

-- =====================================================================================
-- CONFIGURACION DE TIPOS DE PROPIEDAD
-- =====================================================================================

Viviendas.TiposDefault = {
    apartamento_bajo = {
        nombre = 'Apartamento Economico',
        descripcion = 'Apartamento pequeno y accesible',
        precioBase = 50000,
        alquilerBase = 500,
        maxMuebles = 15,
        maxAlmacenamiento = 50,
        pesoMaximo = 100000,
        slots = 30,
        interior = 'low_end_apartment',
        icono = 'home',
        color = '#8BC34A',
    },
    apartamento_medio = {
        nombre = 'Apartamento Estandar',
        descripcion = 'Apartamento comodo de tamano medio',
        precioBase = 150000,
        alquilerBase = 1500,
        maxMuebles = 30,
        maxAlmacenamiento = 100,
        pesoMaximo = 200000,
        slots = 50,
        interior = 'medium_apartment',
        icono = 'home',
        color = '#03A9F4',
    },
    apartamento_lujo = {
        nombre = 'Apartamento de Lujo',
        descripcion = 'Apartamento exclusivo con todas las comodidades',
        precioBase = 500000,
        alquilerBase = 5000,
        maxMuebles = 50,
        maxAlmacenamiento = 200,
        pesoMaximo = 500000,
        slots = 100,
        interior = 'high_end_apartment',
        icono = 'home',
        color = '#9C27B0',
    },
    casa_pequena = {
        nombre = 'Casa Pequena',
        descripcion = 'Casa unifamiliar compacta',
        precioBase = 250000,
        alquilerBase = 2500,
        maxMuebles = 40,
        maxAlmacenamiento = 150,
        pesoMaximo = 300000,
        slots = 75,
        interior = 'small_house',
        icono = 'house',
        color = '#FF9800',
    },
    casa_mediana = {
        nombre = 'Casa Mediana',
        descripcion = 'Casa familiar con jardin',
        precioBase = 450000,
        alquilerBase = 4500,
        maxMuebles = 60,
        maxAlmacenamiento = 250,
        pesoMaximo = 500000,
        slots = 100,
        interior = 'medium_house',
        icono = 'house',
        color = '#E91E63',
    },
    mansion = {
        nombre = 'Mansion',
        descripcion = 'Residencia de lujo con amplios espacios',
        precioBase = 2000000,
        alquilerBase = 20000,
        maxMuebles = 100,
        maxAlmacenamiento = 500,
        pesoMaximo = 1000000,
        slots = 200,
        interior = 'mansion',
        icono = 'castle',
        color = '#FFD700',
    },
    garaje = {
        nombre = 'Garaje',
        descripcion = 'Espacio para almacenar vehiculos',
        precioBase = 75000,
        alquilerBase = 750,
        maxMuebles = 10,
        maxAlmacenamiento = 100,
        pesoMaximo = 500000,
        slots = 50,
        interior = 'garage',
        icono = 'warehouse',
        color = '#607D8B',
        esGaraje = true,
        capacidadVehiculos = 4,
    },
    almacen = {
        nombre = 'Almacen',
        descripcion = 'Nave industrial para almacenamiento',
        precioBase = 300000,
        alquilerBase = 3000,
        maxMuebles = 20,
        maxAlmacenamiento = 1000,
        pesoMaximo = 5000000,
        slots = 500,
        interior = 'warehouse',
        icono = 'warehouse',
        color = '#795548',
        esAlmacen = true,
    },
}

-- =====================================================================================
-- ESTADOS DE PROPIEDAD
-- =====================================================================================

Viviendas.Estados = {
    DISPONIBLE = 'disponible',
    VENDIDA = 'vendida',
    ALQUILADA = 'alquilada',
    RESERVADA = 'reservada',
    MANTENIMIENTO = 'mantenimiento',
    EMBARGADA = 'embargada',
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Viviendas.Initialize()
    -- Crear tablas de base de datos
    Viviendas.CrearTablas()

    -- Cargar tipos de propiedad
    Viviendas.CargarTipos()

    -- Cargar propiedades en cache
    Viviendas.CargarPropiedades()

    -- Registrar eventos
    Viviendas.RegistrarEventos()

    -- Registrar callbacks
    Viviendas.RegistrarCallbacks()

    -- Registrar comandos
    Viviendas.RegistrarComandos()

    -- Iniciar thread de mantenimiento
    Viviendas.IniciarThreadMantenimiento()

    -- Registrar tareas del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('housing_alquileres', {
            interval = 86400, -- Diario
            fn = Viviendas.ProcesarAlquileres
        })

        AIT.Scheduler.register('housing_impuestos', {
            interval = 604800, -- Semanal
            fn = Viviendas.ProcesarImpuestos
        })

        AIT.Scheduler.register('housing_mantenimiento', {
            interval = 3600, -- Cada hora
            fn = Viviendas.ProcesarMantenimiento
        })

        AIT.Scheduler.register('housing_cleanup', {
            interval = 86400,
            fn = Viviendas.LimpiarPropiedadesAbandonadas
        })
    end

    if AIT.Log then
        AIT.Log.info('HOUSING', 'Engine de Viviendas inicializado correctamente')
    end

    return true
end

-- =====================================================================================
-- CREACION DE TABLAS
-- =====================================================================================

function Viviendas.CrearTablas()
    -- Tabla principal de propiedades
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedades (
            propiedad_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            nombre VARCHAR(128) NOT NULL,
            descripcion TEXT NULL,
            tipo VARCHAR(32) NOT NULL DEFAULT 'apartamento_bajo',
            estado ENUM('disponible', 'vendida', 'alquilada', 'reservada', 'mantenimiento', 'embargada')
                NOT NULL DEFAULT 'disponible',
            propietario_char_id BIGINT NULL,
            inquilino_char_id BIGINT NULL,
            precio_compra BIGINT NOT NULL DEFAULT 0,
            precio_alquiler BIGINT NOT NULL DEFAULT 0,
            deposito_alquiler BIGINT NOT NULL DEFAULT 0,
            impuesto_semanal BIGINT NOT NULL DEFAULT 0,
            fecha_compra DATETIME NULL,
            fecha_alquiler_inicio DATETIME NULL,
            fecha_alquiler_fin DATETIME NULL,
            alquiler_pagado_hasta DATETIME NULL,
            entrada_coords JSON NOT NULL,
            interior_coords JSON NOT NULL,
            interior_id VARCHAR(64) NULL,
            routing_bucket INT NULL,
            max_muebles INT NOT NULL DEFAULT 30,
            max_almacenamiento INT NOT NULL DEFAULT 100,
            peso_maximo BIGINT NOT NULL DEFAULT 200000,
            slots_almacenamiento INT NOT NULL DEFAULT 50,
            tiene_garaje TINYINT(1) NOT NULL DEFAULT 0,
            capacidad_vehiculos INT NOT NULL DEFAULT 0,
            en_venta TINYINT(1) NOT NULL DEFAULT 0,
            precio_venta BIGINT NULL,
            bloqueada TINYINT(1) NOT NULL DEFAULT 0,
            motivo_bloqueo TEXT NULL,
            metadata JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_propietario (propietario_char_id),
            KEY idx_inquilino (inquilino_char_id),
            KEY idx_tipo (tipo),
            KEY idx_estado (estado),
            KEY idx_en_venta (en_venta)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de muebles (referencia a furniture.lua)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_muebles (
            mueble_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            catalogo_id VARCHAR(64) NOT NULL,
            posicion JSON NOT NULL,
            rotacion JSON NOT NULL,
            escala JSON NULL,
            colocado_por BIGINT NULL,
            fecha_colocacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            metadata JSON NULL,
            KEY idx_propiedad (propiedad_id),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de accesos (referencia a access.lua)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_accesos (
            acceso_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            tipo_acceso ENUM('propietario', 'inquilino', 'llave', 'temporal', 'servicio') NOT NULL,
            nivel_permiso INT NOT NULL DEFAULT 1,
            otorgado_por BIGINT NULL,
            fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_fin DATETIME NULL,
            activo TINYINT(1) NOT NULL DEFAULT 1,
            notas TEXT NULL,
            metadata JSON NULL,
            UNIQUE KEY idx_propiedad_char (propiedad_id, char_id),
            KEY idx_char (char_id),
            KEY idx_tipo (tipo_acceso),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de almacenamiento de propiedad
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_almacenamiento (
            almacen_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            stash_key VARCHAR(64) NOT NULL,
            tipo ENUM('principal', 'armario', 'caja_fuerte', 'nevera', 'garaje') NOT NULL DEFAULT 'principal',
            etiqueta VARCHAR(128) NOT NULL DEFAULT 'Almacen',
            max_slots INT NOT NULL DEFAULT 50,
            max_peso BIGINT NOT NULL DEFAULT 100000,
            requiere_codigo TINYINT(1) NOT NULL DEFAULT 0,
            codigo_hash VARCHAR(255) NULL,
            nivel_acceso_minimo INT NOT NULL DEFAULT 1,
            metadata JSON NULL,
            UNIQUE KEY idx_stash (stash_key),
            KEY idx_propiedad (propiedad_id),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de historial de visitas
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_visitas (
            visita_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            tipo_visita ENUM('entrada', 'salida', 'intrusion', 'invitado', 'servicio') NOT NULL,
            metodo_acceso VARCHAR(32) NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            ip VARCHAR(45) NULL,
            metadata JSON NULL,
            KEY idx_propiedad (propiedad_id),
            KEY idx_char (char_id),
            KEY idx_fecha (fecha),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de transacciones de propiedad
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_transacciones (
            tx_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            tipo ENUM('compra', 'venta', 'alquiler', 'deposito', 'impuesto', 'mantenimiento',
                      'mejora', 'reembolso', 'embargo') NOT NULL,
            monto BIGINT NOT NULL,
            char_id_desde BIGINT NULL,
            char_id_hacia BIGINT NULL,
            descripcion VARCHAR(255) NULL,
            referencia VARCHAR(64) NULL,
            metadata JSON NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_propiedad (propiedad_id),
            KEY idx_tipo (tipo),
            KEY idx_fecha (fecha),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de logs de propiedad
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_logs (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            accion VARCHAR(64) NOT NULL,
            actor_char_id BIGINT NULL,
            detalles JSON NULL,
            ip VARCHAR(45) NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_propiedad (propiedad_id),
            KEY idx_accion (accion),
            KEY idx_fecha (fecha),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de vehiculos en garaje
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_propiedad_vehiculos (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            propiedad_id BIGINT NOT NULL,
            vehiculo_id BIGINT NOT NULL,
            plaza INT NOT NULL DEFAULT 1,
            fecha_entrada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_propiedad (propiedad_id),
            KEY idx_vehiculo (vehiculo_id),
            UNIQUE KEY idx_propiedad_plaza (propiedad_id, plaza),
            FOREIGN KEY (propiedad_id) REFERENCES ait_propiedades(propiedad_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

-- =====================================================================================
-- CARGAR CONFIGURACION
-- =====================================================================================

function Viviendas.CargarTipos()
    Viviendas.tipos = {}

    -- Copiar tipos por defecto
    for tipo, config in pairs(Viviendas.TiposDefault) do
        Viviendas.tipos[tipo] = {}
        for k, v in pairs(config) do
            Viviendas.tipos[tipo][k] = v
        end
    end

    -- Cargar overrides de config si existen
    if AIT.Config and AIT.Config.housing and AIT.Config.housing.tipos then
        for tipo, config in pairs(AIT.Config.housing.tipos) do
            if Viviendas.tipos[tipo] then
                for k, v in pairs(config) do
                    Viviendas.tipos[tipo][k] = v
                end
            else
                Viviendas.tipos[tipo] = config
            end
        end
    end
end

function Viviendas.CargarPropiedades()
    local propiedades = MySQL.query.await([[
        SELECT p.*,
               c.nombre as propietario_nombre,
               c.apellido as propietario_apellido
        FROM ait_propiedades p
        LEFT JOIN ait_characters c ON p.propietario_char_id = c.char_id
        WHERE p.estado != 'embargada' OR p.estado IS NULL
    ]])

    Viviendas.cache = {}
    for _, propiedad in ipairs(propiedades or {}) do
        -- Parsear JSON
        propiedad.entrada_coords = propiedad.entrada_coords and json.decode(propiedad.entrada_coords) or nil
        propiedad.interior_coords = propiedad.interior_coords and json.decode(propiedad.interior_coords) or nil
        propiedad.metadata = propiedad.metadata and json.decode(propiedad.metadata) or {}

        -- Obtener tipo config
        propiedad.tipoConfig = Viviendas.tipos[propiedad.tipo] or Viviendas.tipos.apartamento_bajo

        Viviendas.cache[propiedad.propiedad_id] = propiedad
        Viviendas.propietariosOnline[propiedad.propiedad_id] = {}
    end

    if AIT.Log then
        AIT.Log.info('HOUSING', ('Cargadas %d propiedades'):format(#(propiedades or {})))
    end
end

-- =====================================================================================
-- GESTION DE PROPIEDADES
-- =====================================================================================

--- Crear una nueva propiedad
---@param params table Parametros de la propiedad
---@return boolean, number|string
function Viviendas.Crear(params)
    --[[
        params = {
            nombre = 'Apartamento Alta Vista #101',
            descripcion = 'Apartamento con vistas a la ciudad',
            tipo = 'apartamento_medio',
            entrada_coords = { x = 0, y = 0, z = 0, h = 0 },
            interior_coords = { x = 0, y = 0, z = 0, h = 0 },
            interior_id = 'medium_apartment_1',
            precio_compra = 150000,
            precio_alquiler = 1500,
        }
    ]]

    -- Validaciones
    if not params.nombre or #params.nombre < 3 then
        return false, 'El nombre debe tener al menos 3 caracteres'
    end

    if not params.entrada_coords then
        return false, 'Se requieren coordenadas de entrada'
    end

    if not params.interior_coords then
        return false, 'Se requieren coordenadas de interior'
    end

    local tipoConfig = Viviendas.tipos[params.tipo or 'apartamento_bajo']
    if not tipoConfig then
        return false, 'Tipo de propiedad no valido'
    end

    -- Valores por defecto del tipo
    local precioCompra = params.precio_compra or tipoConfig.precioBase
    local precioAlquiler = params.precio_alquiler or tipoConfig.alquilerBase
    local impuesto = math.floor(precioCompra * 0.001) -- 0.1% semanal

    -- Crear propiedad
    local propiedadId = MySQL.insert.await([[
        INSERT INTO ait_propiedades
        (nombre, descripcion, tipo, precio_compra, precio_alquiler, impuesto_semanal,
         entrada_coords, interior_coords, interior_id, max_muebles, max_almacenamiento,
         peso_maximo, slots_almacenamiento, tiene_garaje, capacidad_vehiculos, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        params.nombre,
        params.descripcion or '',
        params.tipo or 'apartamento_bajo',
        precioCompra,
        precioAlquiler,
        impuesto,
        json.encode(params.entrada_coords),
        json.encode(params.interior_coords),
        params.interior_id,
        tipoConfig.maxMuebles,
        tipoConfig.maxAlmacenamiento,
        tipoConfig.pesoMaximo,
        tipoConfig.slots,
        tipoConfig.esGaraje and 1 or 0,
        tipoConfig.capacidadVehiculos or 0,
        params.metadata and json.encode(params.metadata) or nil
    })

    if not propiedadId then
        return false, 'Error al crear la propiedad en la base de datos'
    end

    -- Crear almacenamiento principal
    local stashKey = 'property_' .. propiedadId .. '_main'
    MySQL.insert.await([[
        INSERT INTO ait_propiedad_almacenamiento
        (propiedad_id, stash_key, tipo, etiqueta, max_slots, max_peso)
        VALUES (?, ?, 'principal', 'Almacen Principal', ?, ?)
    ]], { propiedadId, stashKey, tipoConfig.slots, tipoConfig.pesoMaximo })

    -- Registrar en sistema de inventario si existe
    if AIT.Engines and AIT.Engines.inventory then
        -- El stash se creara automaticamente cuando se acceda
    end

    -- Recargar cache
    Viviendas.CargarPropiedadEnCache(propiedadId)

    -- Log
    Viviendas.RegistrarLog(propiedadId, 'PROPIEDAD_CREADA', nil, {
        nombre = params.nombre,
        tipo = params.tipo,
        precio = precioCompra
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('housing.property.created', {
            propiedad_id = propiedadId,
            nombre = params.nombre,
            tipo = params.tipo
        })
    end

    return true, propiedadId
end

--- Cargar una propiedad en cache
---@param propiedadId number
function Viviendas.CargarPropiedadEnCache(propiedadId)
    local propiedad = MySQL.query.await([[
        SELECT p.*,
               c.nombre as propietario_nombre,
               c.apellido as propietario_apellido
        FROM ait_propiedades p
        LEFT JOIN ait_characters c ON p.propietario_char_id = c.char_id
        WHERE p.propiedad_id = ?
    ]], { propiedadId })

    if propiedad and propiedad[1] then
        local p = propiedad[1]
        p.entrada_coords = p.entrada_coords and json.decode(p.entrada_coords) or nil
        p.interior_coords = p.interior_coords and json.decode(p.interior_coords) or nil
        p.metadata = p.metadata and json.decode(p.metadata) or {}
        p.tipoConfig = Viviendas.tipos[p.tipo] or Viviendas.tipos.apartamento_bajo

        Viviendas.cache[propiedadId] = p
        if not Viviendas.propietariosOnline[propiedadId] then
            Viviendas.propietariosOnline[propiedadId] = {}
        end
    end
end

--- Obtener informacion de una propiedad
---@param propiedadId number
---@return table|nil
function Viviendas.Obtener(propiedadId)
    if Viviendas.cache[propiedadId] then
        return Viviendas.cache[propiedadId]
    end

    Viviendas.CargarPropiedadEnCache(propiedadId)
    return Viviendas.cache[propiedadId]
end

--- Obtener propiedades de un personaje
---@param charId number
---@return table
function Viviendas.ObtenerPropiedadesDePersonaje(charId)
    local propiedades = MySQL.query.await([[
        SELECT p.* FROM ait_propiedades p
        WHERE p.propietario_char_id = ? OR p.inquilino_char_id = ?
        ORDER BY p.nombre ASC
    ]], { charId, charId })

    local resultado = {}
    for _, p in ipairs(propiedades or {}) do
        p.entrada_coords = p.entrada_coords and json.decode(p.entrada_coords) or nil
        p.interior_coords = p.interior_coords and json.decode(p.interior_coords) or nil
        p.metadata = p.metadata and json.decode(p.metadata) or {}
        p.tipoConfig = Viviendas.tipos[p.tipo]
        p.esPropietario = p.propietario_char_id == charId
        p.esInquilino = p.inquilino_char_id == charId
        table.insert(resultado, p)
    end

    return resultado
end

--- Listar propiedades disponibles
---@param filtros table|nil
---@return table
function Viviendas.ListarDisponibles(filtros)
    filtros = filtros or {}

    local query = 'SELECT * FROM ait_propiedades WHERE estado = ? '
    local params = { Viviendas.Estados.DISPONIBLE }

    if filtros.tipo then
        query = query .. 'AND tipo = ? '
        table.insert(params, filtros.tipo)
    end

    if filtros.precio_max then
        query = query .. 'AND precio_compra <= ? '
        table.insert(params, filtros.precio_max)
    end

    if filtros.precio_min then
        query = query .. 'AND precio_compra >= ? '
        table.insert(params, filtros.precio_min)
    end

    query = query .. 'ORDER BY precio_compra ASC'

    if filtros.limite then
        query = query .. ' LIMIT ?'
        table.insert(params, filtros.limite)
    end

    local propiedades = MySQL.query.await(query, params) or {}

    for i, p in ipairs(propiedades) do
        p.entrada_coords = p.entrada_coords and json.decode(p.entrada_coords) or nil
        p.tipoConfig = Viviendas.tipos[p.tipo]
        propiedades[i] = p
    end

    return propiedades
end

-- =====================================================================================
-- COMPRA Y VENTA
-- =====================================================================================

--- Comprar una propiedad
---@param charId number
---@param propiedadId number
---@param source number|nil
---@return boolean, string
function Viviendas.Comprar(charId, propiedadId, source)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    if propiedad.estado ~= Viviendas.Estados.DISPONIBLE then
        return false, 'Esta propiedad no esta disponible para la venta'
    end

    if propiedad.bloqueada then
        return false, 'Esta propiedad esta bloqueada: ' .. (propiedad.motivo_bloqueo or 'Sin motivo')
    end

    -- Verificar limite de propiedades
    local propiedadesActuales = Viviendas.ObtenerPropiedadesDePersonaje(charId)
    local maxPropiedades = AIT.Config and AIT.Config.housing and AIT.Config.housing.maxPropiedades or 3

    local propiedadesComoPropietario = 0
    for _, p in ipairs(propiedadesActuales) do
        if p.esPropietario then
            propiedadesComoPropietario = propiedadesComoPropietario + 1
        end
    end

    if propiedadesComoPropietario >= maxPropiedades then
        return false, ('Has alcanzado el limite de %d propiedades'):format(maxPropiedades)
    end

    -- Verificar fondos
    if AIT.Engines and AIT.Engines.economy then
        local balance = AIT.Engines.economy.GetBalance('char', charId, 'bank')
        if balance < propiedad.precio_compra then
            return false, 'Fondos insuficientes. Necesitas $' .. Viviendas.FormatearNumero(propiedad.precio_compra)
        end

        -- Cobrar
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, propiedad.precio_compra, 'bank', 'purchase',
            'Compra propiedad: ' .. propiedad.nombre)

        if not success then
            return false, 'Error al procesar el pago: ' .. tostring(err)
        end
    end

    -- Actualizar propiedad
    MySQL.query.await([[
        UPDATE ait_propiedades
        SET estado = ?, propietario_char_id = ?, fecha_compra = NOW(), en_venta = 0, precio_venta = NULL
        WHERE propiedad_id = ?
    ]], { Viviendas.Estados.VENDIDA, charId, propiedadId })

    -- Crear acceso de propietario
    MySQL.insert.await([[
        INSERT INTO ait_propiedad_accesos
        (propiedad_id, char_id, tipo_acceso, nivel_permiso)
        VALUES (?, ?, 'propietario', 10)
        ON DUPLICATE KEY UPDATE tipo_acceso = 'propietario', nivel_permiso = 10, activo = 1
    ]], { propiedadId, charId })

    -- Registrar transaccion
    Viviendas.RegistrarTransaccion(propiedadId, 'compra', propiedad.precio_compra, nil, charId,
        'Compra de propiedad')

    -- Recargar cache
    Viviendas.CargarPropiedadEnCache(propiedadId)

    -- Log
    Viviendas.RegistrarLog(propiedadId, 'PROPIEDAD_COMPRADA', charId, {
        precio = propiedad.precio_compra
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('housing.property.purchased', {
            propiedad_id = propiedadId,
            char_id = charId,
            precio = propiedad.precio_compra
        })
    end

    return true, 'Has comprado la propiedad: ' .. propiedad.nombre
end

--- Vender propiedad al mercado
---@param charId number
---@param propiedadId number
---@param precio number|nil
---@return boolean, string
function Viviendas.PonerEnVenta(charId, propiedadId, precio)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    if propiedad.propietario_char_id ~= charId then
        return false, 'No eres el propietario de esta propiedad'
    end

    if propiedad.inquilino_char_id then
        return false, 'No puedes vender una propiedad con inquilino activo'
    end

    -- Precio minimo 50% del valor original
    local precioMinimo = math.floor(propiedad.precio_compra * 0.5)
    precio = precio or propiedad.precio_compra

    if precio < precioMinimo then
        return false, ('El precio minimo de venta es $%s'):format(Viviendas.FormatearNumero(precioMinimo))
    end

    MySQL.query.await([[
        UPDATE ait_propiedades SET en_venta = 1, precio_venta = ? WHERE propiedad_id = ?
    ]], { precio, propiedadId })

    -- Recargar cache
    Viviendas.CargarPropiedadEnCache(propiedadId)

    -- Log
    Viviendas.RegistrarLog(propiedadId, 'PROPIEDAD_EN_VENTA', charId, { precio = precio })

    return true, ('Propiedad puesta en venta por $%s'):format(Viviendas.FormatearNumero(precio))
end

--- Comprar propiedad de otro jugador
---@param compradorCharId number
---@param propiedadId number
---@param source number|nil
---@return boolean, string
function Viviendas.ComprarDeJugador(compradorCharId, propiedadId, source)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    if not propiedad.en_venta or not propiedad.precio_venta then
        return false, 'Esta propiedad no esta en venta'
    end

    if propiedad.propietario_char_id == compradorCharId then
        return false, 'No puedes comprarte tu propia propiedad'
    end

    local vendedorCharId = propiedad.propietario_char_id
    local precio = propiedad.precio_venta

    -- Verificar fondos del comprador
    if AIT.Engines and AIT.Engines.economy then
        local balance = AIT.Engines.economy.GetBalance('char', compradorCharId, 'bank')
        if balance < precio then
            return false, 'Fondos insuficientes'
        end

        -- Cobrar al comprador
        local success, err = AIT.Engines.economy.RemoveMoney(source, compradorCharId, precio, 'bank', 'purchase',
            'Compra propiedad: ' .. propiedad.nombre)

        if not success then
            return false, 'Error al procesar el pago: ' .. tostring(err)
        end

        -- Pagar al vendedor (menos 5% de comision)
        local comision = math.floor(precio * 0.05)
        local pagoVendedor = precio - comision

        AIT.Engines.economy.AddMoney(nil, vendedorCharId, pagoVendedor, 'bank', 'trade',
            'Venta propiedad: ' .. propiedad.nombre)
    end

    -- Actualizar propiedad
    MySQL.query.await([[
        UPDATE ait_propiedades
        SET propietario_char_id = ?, fecha_compra = NOW(), en_venta = 0, precio_venta = NULL
        WHERE propiedad_id = ?
    ]], { compradorCharId, propiedadId })

    -- Actualizar accesos
    MySQL.query.await([[
        UPDATE ait_propiedad_accesos SET activo = 0 WHERE propiedad_id = ? AND tipo_acceso = 'propietario'
    ]], { propiedadId })

    MySQL.insert.await([[
        INSERT INTO ait_propiedad_accesos
        (propiedad_id, char_id, tipo_acceso, nivel_permiso)
        VALUES (?, ?, 'propietario', 10)
        ON DUPLICATE KEY UPDATE tipo_acceso = 'propietario', nivel_permiso = 10, activo = 1
    ]], { propiedadId, compradorCharId })

    -- Registrar transacciones
    Viviendas.RegistrarTransaccion(propiedadId, 'venta', precio, vendedorCharId, compradorCharId,
        'Venta entre jugadores')

    -- Recargar cache
    Viviendas.CargarPropiedadEnCache(propiedadId)

    -- Log
    Viviendas.RegistrarLog(propiedadId, 'PROPIEDAD_VENDIDA_JUGADOR', compradorCharId, {
        vendedor = vendedorCharId,
        precio = precio
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('housing.property.sold', {
            propiedad_id = propiedadId,
            vendedor_char_id = vendedorCharId,
            comprador_char_id = compradorCharId,
            precio = precio
        })
    end

    return true, 'Has comprado la propiedad: ' .. propiedad.nombre
end

-- =====================================================================================
-- ALQUILER
-- =====================================================================================

--- Alquilar una propiedad
---@param charId number
---@param propiedadId number
---@param duracionDias number
---@param source number|nil
---@return boolean, string
function Viviendas.Alquilar(charId, propiedadId, duracionDias, source)
    duracionDias = duracionDias or 7 -- Por defecto 1 semana

    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    if propiedad.estado ~= Viviendas.Estados.VENDIDA then
        return false, 'Esta propiedad no esta disponible para alquiler'
    end

    if propiedad.inquilino_char_id then
        return false, 'Esta propiedad ya tiene un inquilino'
    end

    if propiedad.propietario_char_id == charId then
        return false, 'No puedes alquilar tu propia propiedad'
    end

    -- Calcular costos
    local alquilerTotal = propiedad.precio_alquiler * duracionDias
    local deposito = propiedad.deposito_alquiler or (propiedad.precio_alquiler * 2)
    local costoTotal = alquilerTotal + deposito

    -- Verificar fondos
    if AIT.Engines and AIT.Engines.economy then
        local balance = AIT.Engines.economy.GetBalance('char', charId, 'bank')
        if balance < costoTotal then
            return false, ('Fondos insuficientes. Necesitas $%s (alquiler + deposito)'):format(
                Viviendas.FormatearNumero(costoTotal))
        end

        -- Cobrar
        local success, err = AIT.Engines.economy.RemoveMoney(source, charId, costoTotal, 'bank', 'purchase',
            'Alquiler propiedad: ' .. propiedad.nombre)

        if not success then
            return false, 'Error al procesar el pago'
        end

        -- Pagar al propietario (alquiler, el deposito se retiene)
        if propiedad.propietario_char_id then
            AIT.Engines.economy.AddMoney(nil, propiedad.propietario_char_id, alquilerTotal, 'bank', 'trade',
                'Alquiler recibido: ' .. propiedad.nombre)
        end
    end

    -- Actualizar propiedad
    local fechaFin = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duracionDias * 86400))
    MySQL.query.await([[
        UPDATE ait_propiedades
        SET estado = ?, inquilino_char_id = ?, deposito_alquiler = ?,
            fecha_alquiler_inicio = NOW(), fecha_alquiler_fin = ?, alquiler_pagado_hasta = ?
        WHERE propiedad_id = ?
    ]], { Viviendas.Estados.ALQUILADA, charId, deposito, fechaFin, fechaFin, propiedadId })

    -- Crear acceso de inquilino
    MySQL.insert.await([[
        INSERT INTO ait_propiedad_accesos
        (propiedad_id, char_id, tipo_acceso, nivel_permiso, fecha_fin)
        VALUES (?, ?, 'inquilino', 5, ?)
        ON DUPLICATE KEY UPDATE tipo_acceso = 'inquilino', nivel_permiso = 5, activo = 1, fecha_fin = ?
    ]], { propiedadId, charId, fechaFin, fechaFin })

    -- Registrar transaccion
    Viviendas.RegistrarTransaccion(propiedadId, 'alquiler', costoTotal, charId, propiedad.propietario_char_id,
        ('Alquiler por %d dias'):format(duracionDias))

    Viviendas.RegistrarTransaccion(propiedadId, 'deposito', deposito, charId, nil, 'Deposito de alquiler')

    -- Recargar cache
    Viviendas.CargarPropiedadEnCache(propiedadId)

    -- Log
    Viviendas.RegistrarLog(propiedadId, 'PROPIEDAD_ALQUILADA', charId, {
        duracion = duracionDias,
        alquiler = alquilerTotal,
        deposito = deposito
    })

    return true, ('Has alquilado la propiedad por %d dias'):format(duracionDias)
end

--- Finalizar alquiler
---@param propiedadId number
---@param devolucionDeposito boolean
---@return boolean, string
function Viviendas.FinalizarAlquiler(propiedadId, devolucionDeposito)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    if propiedad.estado ~= Viviendas.Estados.ALQUILADA then
        return false, 'Esta propiedad no esta alquilada'
    end

    local inquilinoCharId = propiedad.inquilino_char_id
    local deposito = propiedad.deposito_alquiler or 0

    -- Devolver deposito si corresponde
    if devolucionDeposito and deposito > 0 and inquilinoCharId and AIT.Engines and AIT.Engines.economy then
        AIT.Engines.economy.AddMoney(nil, inquilinoCharId, deposito, 'bank', 'transfer',
            'Devolucion deposito: ' .. propiedad.nombre)

        Viviendas.RegistrarTransaccion(propiedadId, 'reembolso', deposito, nil, inquilinoCharId,
            'Devolucion de deposito')
    end

    -- Actualizar propiedad
    MySQL.query.await([[
        UPDATE ait_propiedades
        SET estado = ?, inquilino_char_id = NULL, deposito_alquiler = 0,
            fecha_alquiler_inicio = NULL, fecha_alquiler_fin = NULL, alquiler_pagado_hasta = NULL
        WHERE propiedad_id = ?
    ]], { Viviendas.Estados.VENDIDA, propiedadId })

    -- Desactivar acceso de inquilino
    if inquilinoCharId then
        MySQL.query.await([[
            UPDATE ait_propiedad_accesos SET activo = 0 WHERE propiedad_id = ? AND char_id = ? AND tipo_acceso = 'inquilino'
        ]], { propiedadId, inquilinoCharId })
    end

    -- Recargar cache
    Viviendas.CargarPropiedadEnCache(propiedadId)

    -- Log
    Viviendas.RegistrarLog(propiedadId, 'ALQUILER_FINALIZADO', inquilinoCharId, {
        deposito_devuelto = devolucionDeposito and deposito or 0
    })

    return true, 'Alquiler finalizado'
end

-- =====================================================================================
-- ENTRADA Y SALIDA (ROUTING BUCKETS)
-- =====================================================================================

--- Obtener o crear routing bucket para una propiedad
---@param propiedadId number
---@return number
function Viviendas.ObtenerRoutingBucket(propiedadId)
    if Viviendas.routingBuckets[propiedadId] then
        return Viviendas.routingBuckets[propiedadId]
    end

    -- Asignar nuevo bucket
    local bucket = Viviendas.siguienteBucket
    Viviendas.siguienteBucket = Viviendas.siguienteBucket + 1

    -- Guardar en BD para persistencia
    MySQL.query.await([[
        UPDATE ait_propiedades SET routing_bucket = ? WHERE propiedad_id = ?
    ]], { bucket, propiedadId })

    Viviendas.routingBuckets[propiedadId] = bucket

    return bucket
end

--- Entrar a una propiedad
---@param source number
---@param charId number
---@param propiedadId number
---@return boolean, string
function Viviendas.Entrar(source, charId, propiedadId)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    -- Verificar acceso (usando modulo de access.lua)
    if AIT.Engines.Housing and AIT.Engines.Housing.Access then
        local tieneAcceso, nivelAcceso = AIT.Engines.Housing.Access.VerificarAcceso(charId, propiedadId)
        if not tieneAcceso then
            return false, 'No tienes acceso a esta propiedad'
        end
    else
        -- Verificacion basica
        local acceso = MySQL.query.await([[
            SELECT * FROM ait_propiedad_accesos
            WHERE propiedad_id = ? AND char_id = ? AND activo = 1
            AND (fecha_fin IS NULL OR fecha_fin > NOW())
        ]], { propiedadId, charId })

        if (not acceso or #acceso == 0) and
            propiedad.propietario_char_id ~= charId and
            propiedad.inquilino_char_id ~= charId then
            return false, 'No tienes acceso a esta propiedad'
        end
    end

    -- Obtener routing bucket
    local bucket = Viviendas.ObtenerRoutingBucket(propiedadId)

    -- Teletransportar al jugador
    local ped = GetPlayerPed(source)
    if ped and propiedad.interior_coords then
        -- Establecer routing bucket
        SetPlayerRoutingBucket(source, bucket)

        -- Teletransportar
        SetEntityCoords(ped,
            propiedad.interior_coords.x,
            propiedad.interior_coords.y,
            propiedad.interior_coords.z,
            false, false, false, false)

        if propiedad.interior_coords.h then
            SetEntityHeading(ped, propiedad.interior_coords.h)
        end
    end

    -- Registrar visita
    Viviendas.RegistrarVisita(propiedadId, charId, 'entrada', 'llave')

    -- Marcar como online en la propiedad
    if not Viviendas.propietariosOnline[propiedadId] then
        Viviendas.propietariosOnline[propiedadId] = {}
    end
    Viviendas.propietariosOnline[propiedadId][charId] = source

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('housing.player.entered', {
            propiedad_id = propiedadId,
            char_id = charId,
            source = source,
            bucket = bucket
        })
    end

    -- Enviar datos al cliente
    TriggerClientEvent('ait:housing:entered', source, {
        propiedad_id = propiedadId,
        nombre = propiedad.nombre,
        tipo = propiedad.tipo,
        es_propietario = propiedad.propietario_char_id == charId,
        es_inquilino = propiedad.inquilino_char_id == charId,
    })

    return true, 'Has entrado a ' .. propiedad.nombre
end

--- Salir de una propiedad
---@param source number
---@param charId number
---@param propiedadId number
---@return boolean, string
function Viviendas.Salir(source, charId, propiedadId)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    -- Restaurar routing bucket a 0 (mundo normal)
    SetPlayerRoutingBucket(source, 0)

    -- Teletransportar a la entrada
    local ped = GetPlayerPed(source)
    if ped and propiedad.entrada_coords then
        SetEntityCoords(ped,
            propiedad.entrada_coords.x,
            propiedad.entrada_coords.y,
            propiedad.entrada_coords.z,
            false, false, false, false)

        if propiedad.entrada_coords.h then
            SetEntityHeading(ped, propiedad.entrada_coords.h)
        end
    end

    -- Registrar visita
    Viviendas.RegistrarVisita(propiedadId, charId, 'salida', nil)

    -- Remover de online
    if Viviendas.propietariosOnline[propiedadId] then
        Viviendas.propietariosOnline[propiedadId][charId] = nil
    end

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('housing.player.exited', {
            propiedad_id = propiedadId,
            char_id = charId,
            source = source
        })
    end

    -- Notificar al cliente
    TriggerClientEvent('ait:housing:exited', source, {
        propiedad_id = propiedadId
    })

    return true, 'Has salido de ' .. propiedad.nombre
end

-- =====================================================================================
-- ALMACENAMIENTO
-- =====================================================================================

--- Obtener almacenamiento de una propiedad
---@param propiedadId number
---@param tipo string|nil
---@return table
function Viviendas.ObtenerAlmacenamiento(propiedadId, tipo)
    local query = 'SELECT * FROM ait_propiedad_almacenamiento WHERE propiedad_id = ?'
    local params = { propiedadId }

    if tipo then
        query = query .. ' AND tipo = ?'
        table.insert(params, tipo)
    end

    return MySQL.query.await(query, params) or {}
end

--- Crear almacenamiento adicional
---@param propiedadId number
---@param params table
---@return boolean, number|string
function Viviendas.CrearAlmacenamiento(propiedadId, params)
    local propiedad = Viviendas.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    local stashKey = 'property_' .. propiedadId .. '_' .. (params.tipo or 'extra') .. '_' .. os.time()

    local almacenId = MySQL.insert.await([[
        INSERT INTO ait_propiedad_almacenamiento
        (propiedad_id, stash_key, tipo, etiqueta, max_slots, max_peso, requiere_codigo, nivel_acceso_minimo)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        propiedadId,
        stashKey,
        params.tipo or 'armario',
        params.etiqueta or 'Almacen',
        params.max_slots or 25,
        params.max_peso or 50000,
        params.requiere_codigo and 1 or 0,
        params.nivel_acceso_minimo or 1
    })

    return true, almacenId
end

--- Acceder al almacenamiento
---@param source number
---@param charId number
---@param stashKey string
---@return boolean, string
function Viviendas.AccederAlmacenamiento(source, charId, stashKey)
    local almacen = MySQL.query.await([[
        SELECT a.*, p.propietario_char_id, p.inquilino_char_id
        FROM ait_propiedad_almacenamiento a
        JOIN ait_propiedades p ON a.propiedad_id = p.propiedad_id
        WHERE a.stash_key = ?
    ]], { stashKey })

    if not almacen or #almacen == 0 then
        return false, 'Almacen no encontrado'
    end

    almacen = almacen[1]

    -- Verificar acceso
    local tieneAcceso = false
    local nivelAcceso = 0

    if almacen.propietario_char_id == charId then
        tieneAcceso = true
        nivelAcceso = 10
    elseif almacen.inquilino_char_id == charId then
        tieneAcceso = true
        nivelAcceso = 5
    else
        local acceso = MySQL.query.await([[
            SELECT nivel_permiso FROM ait_propiedad_accesos
            WHERE propiedad_id = ? AND char_id = ? AND activo = 1
            AND (fecha_fin IS NULL OR fecha_fin > NOW())
        ]], { almacen.propiedad_id, charId })

        if acceso and acceso[1] then
            tieneAcceso = true
            nivelAcceso = acceso[1].nivel_permiso
        end
    end

    if not tieneAcceso then
        return false, 'No tienes acceso a este almacen'
    end

    if nivelAcceso < almacen.nivel_acceso_minimo then
        return false, 'Tu nivel de acceso es insuficiente'
    end

    -- Abrir stash usando el sistema de inventario
    if AIT.Engines and AIT.Engines.inventory then
        -- Trigger para abrir el stash en el cliente
        TriggerClientEvent('ait:inventory:openStash', source, {
            stash_key = stashKey,
            label = almacen.etiqueta,
            max_slots = almacen.max_slots,
            max_weight = almacen.max_peso
        })

        return true, 'Almacen abierto'
    end

    return false, 'Sistema de inventario no disponible'
end

-- =====================================================================================
-- PROCESAMIENTO PROGRAMADO
-- =====================================================================================

function Viviendas.ProcesarAlquileres()
    -- Buscar alquileres vencidos
    local vencidos = MySQL.query.await([[
        SELECT propiedad_id, inquilino_char_id, nombre
        FROM ait_propiedades
        WHERE estado = 'alquilada' AND fecha_alquiler_fin < NOW()
    ]])

    for _, alquiler in ipairs(vencidos or {}) do
        -- Finalizar alquiler sin devolucion de deposito (por vencimiento)
        Viviendas.FinalizarAlquiler(alquiler.propiedad_id, false)

        -- Notificar si el jugador esta online
        -- El deposito se pierde por no renovar a tiempo

        if AIT.Log then
            AIT.Log.info('HOUSING', ('Alquiler vencido: propiedad %d, inquilino %d'):format(
                alquiler.propiedad_id, alquiler.inquilino_char_id))
        end
    end

    -- Buscar alquileres proximos a vencer (24 horas)
    local proximosVencer = MySQL.query.await([[
        SELECT p.propiedad_id, p.inquilino_char_id, p.nombre, p.precio_alquiler,
               TIMESTAMPDIFF(HOUR, NOW(), p.fecha_alquiler_fin) as horas_restantes
        FROM ait_propiedades p
        WHERE p.estado = 'alquilada'
        AND p.fecha_alquiler_fin BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR)
    ]])

    for _, alquiler in ipairs(proximosVencer or {}) do
        -- Notificar al inquilino si esta online
        -- TODO: Implementar sistema de notificaciones
    end
end

function Viviendas.ProcesarImpuestos()
    -- Cobrar impuestos semanales a propietarios
    local propiedades = MySQL.query.await([[
        SELECT propiedad_id, propietario_char_id, nombre, impuesto_semanal
        FROM ait_propiedades
        WHERE estado = 'vendida' AND propietario_char_id IS NOT NULL AND impuesto_semanal > 0
    ]])

    for _, prop in ipairs(propiedades or {}) do
        if AIT.Engines and AIT.Engines.economy then
            local balance = AIT.Engines.economy.GetBalance('char', prop.propietario_char_id, 'bank')

            if balance >= prop.impuesto_semanal then
                AIT.Engines.economy.RemoveMoney(nil, prop.propietario_char_id, prop.impuesto_semanal, 'bank', 'tax',
                    'Impuesto propiedad: ' .. prop.nombre)

                Viviendas.RegistrarTransaccion(prop.propiedad_id, 'impuesto', prop.impuesto_semanal,
                    prop.propietario_char_id, nil, 'Impuesto semanal')
            else
                -- Marcar impuesto pendiente
                MySQL.query([[
                    UPDATE ait_propiedades
                    SET metadata = JSON_SET(COALESCE(metadata, '{}'), '$.impuesto_pendiente',
                        COALESCE(JSON_EXTRACT(metadata, '$.impuesto_pendiente'), 0) + ?)
                    WHERE propiedad_id = ?
                ]], { prop.impuesto_semanal, prop.propiedad_id })

                -- TODO: Notificar al propietario
            end
        end
    end
end

function Viviendas.ProcesarMantenimiento()
    -- Limpiar routing buckets de propiedades vacias
    for propiedadId, jugadores in pairs(Viviendas.propietariosOnline) do
        local hayJugadores = false
        for _ in pairs(jugadores) do
            hayJugadores = true
            break
        end

        if not hayJugadores and Viviendas.routingBuckets[propiedadId] then
            -- Liberar bucket si no hay nadie
            -- (En realidad no es necesario en FiveM, pero limpiamos la referencia)
            -- Viviendas.routingBuckets[propiedadId] = nil
        end
    end
end

function Viviendas.LimpiarPropiedadesAbandonadas()
    -- Embargar propiedades con impuestos pendientes por mas de 30 dias
    MySQL.query([[
        UPDATE ait_propiedades
        SET estado = 'embargada', motivo_bloqueo = 'Impuestos impagados por mas de 30 dias'
        WHERE estado = 'vendida'
        AND JSON_EXTRACT(metadata, '$.impuesto_pendiente') > impuesto_semanal * 4
        AND updated_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
    ]])
end

-- =====================================================================================
-- LOGS Y TRANSACCIONES
-- =====================================================================================

function Viviendas.RegistrarLog(propiedadId, accion, actorCharId, detalles)
    MySQL.insert([[
        INSERT INTO ait_propiedad_logs (propiedad_id, accion, actor_char_id, detalles)
        VALUES (?, ?, ?, ?)
    ]], {
        propiedadId,
        accion,
        actorCharId,
        detalles and json.encode(detalles) or nil
    })
end

function Viviendas.RegistrarTransaccion(propiedadId, tipo, monto, charIdDesde, charIdHacia, descripcion)
    MySQL.insert([[
        INSERT INTO ait_propiedad_transacciones
        (propiedad_id, tipo, monto, char_id_desde, char_id_hacia, descripcion)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { propiedadId, tipo, monto, charIdDesde, charIdHacia, descripcion })
end

function Viviendas.RegistrarVisita(propiedadId, charId, tipoVisita, metodoAcceso)
    MySQL.insert([[
        INSERT INTO ait_propiedad_visitas (propiedad_id, char_id, tipo_visita, metodo_acceso)
        VALUES (?, ?, ?, ?)
    ]], { propiedadId, charId, tipoVisita, metodoAcceso })
end

-- =====================================================================================
-- EVENTOS Y CALLBACKS
-- =====================================================================================

function Viviendas.RegistrarEventos()
    -- Jugador desconectado
    AddEventHandler('playerDropped', function(reason)
        local source = source

        -- Sacar de todas las propiedades
        for propiedadId, jugadores in pairs(Viviendas.propietariosOnline) do
            for charId, sid in pairs(jugadores) do
                if sid == source then
                    Viviendas.propietariosOnline[propiedadId][charId] = nil
                    break
                end
            end
        end
    end)
end

function Viviendas.RegistrarCallbacks()
    -- Callback para obtener propiedades del jugador
    if AIT.Callbacks then
        AIT.Callbacks.Register('housing:getPropiedades', function(source, cb)
            local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
            if not Player then
                cb({})
                return
            end

            local charId = Player.PlayerData.citizenid
            local propiedades = Viviendas.ObtenerPropiedadesDePersonaje(charId)
            cb(propiedades)
        end)

        AIT.Callbacks.Register('housing:getDisponibles', function(source, cb, filtros)
            local disponibles = Viviendas.ListarDisponibles(filtros or {})
            cb(disponibles)
        end)
    end
end

function Viviendas.RegistrarComandos()
    RegisterCommand('propiedad', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local propiedades = Viviendas.ObtenerPropiedadesDePersonaje(charId)

        if #propiedades == 0 then
            TriggerClientEvent('QBCore:Notify', source, 'No tienes ninguna propiedad', 'info')
            return
        end

        local mensaje = '=== Tus Propiedades ===\n'
        for _, p in ipairs(propiedades) do
            local rol = p.esPropietario and '[PROPIETARIO]' or '[INQUILINO]'
            mensaje = mensaje .. ('%s %s - %s\n'):format(rol, p.nombre, p.tipo)
        end

        TriggerClientEvent('chat:addMessage', source, { args = { 'Propiedades', mensaje } })
    end, false)

    -- Comando admin para crear propiedad
    RegisterCommand('crearpropiedad', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'housing.create') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        if #args < 2 then
            local msg = 'Uso: /crearpropiedad [nombre] [tipo]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        local nombre = args[1]
        local tipo = args[2]

        -- Obtener coordenadas del jugador
        local coords = { x = 0, y = 0, z = 0, h = 0 }
        if source > 0 then
            local ped = GetPlayerPed(source)
            local pedCoords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            coords = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z, h = heading }
        end

        local success, resultado = Viviendas.Crear({
            nombre = nombre,
            tipo = tipo,
            entrada_coords = coords,
            interior_coords = coords, -- Por defecto igual, se debe configurar
        })

        local msg = success and ('Propiedad creada con ID: %d'):format(resultado) or ('Error: %s'):format(resultado)
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
        else
            print(msg)
        end
    end, false)
end

-- =====================================================================================
-- THREAD DE MANTENIMIENTO
-- =====================================================================================

function Viviendas.IniciarThreadMantenimiento()
    CreateThread(function()
        while true do
            Wait(60000) -- Cada minuto

            -- Verificar jugadores en propiedades
            for propiedadId, jugadores in pairs(Viviendas.propietariosOnline) do
                for charId, sourceId in pairs(jugadores) do
                    -- Verificar si el jugador sigue conectado
                    local ped = GetPlayerPed(sourceId)
                    if not ped or ped == 0 then
                        Viviendas.propietariosOnline[propiedadId][charId] = nil
                    end
                end
            end
        end
    end)
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Viviendas.FormatearNumero(num)
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

-- Getters
Viviendas.Get = Viviendas.Obtener
Viviendas.GetPlayerProperties = Viviendas.ObtenerPropiedadesDePersonaje
Viviendas.GetAvailable = Viviendas.ListarDisponibles
Viviendas.GetStorage = Viviendas.ObtenerAlmacenamiento

-- Actions
Viviendas.Create = Viviendas.Crear
Viviendas.Buy = Viviendas.Comprar
Viviendas.Sell = Viviendas.PonerEnVenta
Viviendas.BuyFromPlayer = Viviendas.ComprarDeJugador
Viviendas.Rent = Viviendas.Alquilar
Viviendas.EndRent = Viviendas.FinalizarAlquiler
Viviendas.Enter = Viviendas.Entrar
Viviendas.Exit = Viviendas.Salir
Viviendas.AccessStorage = Viviendas.AccederAlmacenamiento

-- =====================================================================================
-- REGISTRAR ENGINE
-- =====================================================================================

AIT.Engines.Housing = Viviendas

return Viviendas
