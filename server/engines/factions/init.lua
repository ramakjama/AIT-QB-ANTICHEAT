-- =====================================================================================
-- ait-qb ENGINE DE FACCIONES
-- Sistema completo de facciones/trabajos con rangos, permisos y tesoreria
-- Namespace: AIT.Engines.Factions
-- Optimizado para 2048 slots
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}

local Facciones = {
    -- Cache de facciones activas
    cache = {},
    -- Miembros online por faccion
    miembrosOnline = {},
    -- Configuracion de tipos
    tipos = {},
    -- Cola de notificaciones
    colaNotificaciones = {},
}

-- =====================================================================================
-- CONFIGURACION DE TIPOS DE FACCION
-- =====================================================================================

Facciones.TiposDefault = {
    trabajo = {
        nombre = 'Trabajo',
        descripcion = 'Empleo legal con salario',
        permisos = { 'duty', 'uniforme', 'vehiculo_trabajo' },
        maxMiembros = 50,
        requiereAprobacion = false,
        salarioBase = 500,
        color = '#4CAF50',
    },
    gobierno = {
        nombre = 'Gobierno',
        descripcion = 'Faccion gubernamental oficial',
        permisos = { 'duty', 'uniforme', 'vehiculo_trabajo', 'multas', 'arrestos', 'requisar' },
        maxMiembros = 100,
        requiereAprobacion = true,
        salarioBase = 750,
        color = '#2196F3',
    },
    emergencias = {
        nombre = 'Emergencias',
        descripcion = 'Servicios de emergencia',
        permisos = { 'duty', 'uniforme', 'vehiculo_emergencia', 'sirenas', 'curar', 'reanimar' },
        maxMiembros = 80,
        requiereAprobacion = true,
        salarioBase = 700,
        color = '#F44336',
    },
    criminal = {
        nombre = 'Criminal',
        descripcion = 'Organizacion criminal',
        permisos = { 'territorio', 'drogas', 'armas', 'lavado' },
        maxMiembros = 30,
        requiereAprobacion = true,
        salarioBase = 0,
        color = '#9C27B0',
    },
    empresa = {
        nombre = 'Empresa',
        descripcion = 'Negocio privado',
        permisos = { 'duty', 'uniforme', 'inventario_empresa', 'contratar' },
        maxMiembros = 25,
        requiereAprobacion = false,
        salarioBase = 400,
        color = '#FF9800',
    },
    comunidad = {
        nombre = 'Comunidad',
        descripcion = 'Grupo comunitario sin animo de lucro',
        permisos = { 'eventos', 'chat_faccion' },
        maxMiembros = 100,
        requiereAprobacion = false,
        salarioBase = 0,
        color = '#00BCD4',
    },
}

-- =====================================================================================
-- CONFIGURACION DE RANGOS POR DEFECTO
-- =====================================================================================

Facciones.RangosDefault = {
    { nivel = 1, nombre = 'Novato',     salarioMult = 0.8,  permisos = {} },
    { nivel = 2, nombre = 'Miembro',    salarioMult = 1.0,  permisos = { 'chat_faccion' } },
    { nivel = 3, nombre = 'Veterano',   salarioMult = 1.2,  permisos = { 'chat_faccion', 'invitar' } },
    { nivel = 4, nombre = 'Supervisor', salarioMult = 1.5,  permisos = { 'chat_faccion', 'invitar', 'expulsar', 'promover' } },
    { nivel = 5, nombre = 'Jefe',       salarioMult = 2.0,  permisos = { '*' } },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Facciones.Initialize()
    -- Crear tablas de base de datos
    Facciones.CrearTablas()

    -- Cargar tipos de faccion
    Facciones.CargarTipos()

    -- Cargar facciones en cache
    Facciones.CargarFacciones()

    -- Registrar eventos
    Facciones.RegistrarEventos()

    -- Registrar comandos
    Facciones.RegistrarComandos()

    -- Iniciar thread de notificaciones
    Facciones.IniciarThreadNotificaciones()

    -- Registrar tareas del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('factions_salarios', {
            interval = 3600, -- Cada hora
            fn = Facciones.ProcesarSalarios
        })

        AIT.Scheduler.register('factions_impuestos', {
            interval = 86400, -- Diario
            fn = Facciones.ProcesarImpuestosFacciones
        })

        AIT.Scheduler.register('factions_cleanup', {
            interval = 86400,
            fn = Facciones.LimpiarFaccionesInactivas
        })
    end

    if AIT.Log then
        AIT.Log.info('FACTIONS', 'Engine de Facciones inicializado correctamente')
    end

    return true
end

-- =====================================================================================
-- CREACION DE TABLAS
-- =====================================================================================

function Facciones.CrearTablas()
    -- Tabla principal de facciones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_facciones (
            faccion_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            nombre VARCHAR(64) NOT NULL UNIQUE,
            nombre_corto VARCHAR(16) NOT NULL,
            descripcion TEXT NULL,
            tipo VARCHAR(32) NOT NULL DEFAULT 'trabajo',
            lider_char_id BIGINT NULL,
            tesoreria BIGINT NOT NULL DEFAULT 0,
            limite_tesoreria BIGINT NOT NULL DEFAULT 10000000,
            salario_base INT NOT NULL DEFAULT 500,
            color VARCHAR(16) DEFAULT '#FFFFFF',
            logo_url VARCHAR(255) NULL,
            sede_coords JSON NULL,
            activa TINYINT(1) NOT NULL DEFAULT 1,
            publica TINYINT(1) NOT NULL DEFAULT 0,
            requiere_aprobacion TINYINT(1) NOT NULL DEFAULT 1,
            max_miembros INT NOT NULL DEFAULT 50,
            metadata JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_tipo (tipo),
            KEY idx_activa (activa),
            KEY idx_lider (lider_char_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de rangos de faccion
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_rangos (
            rango_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            nivel INT NOT NULL,
            nombre VARCHAR(64) NOT NULL,
            salario_mult DECIMAL(4,2) NOT NULL DEFAULT 1.00,
            permisos JSON NULL,
            color VARCHAR(16) DEFAULT '#FFFFFF',
            puede_reclutar TINYINT(1) NOT NULL DEFAULT 0,
            puede_expulsar TINYINT(1) NOT NULL DEFAULT 0,
            puede_promover TINYINT(1) NOT NULL DEFAULT 0,
            puede_tesoreria TINYINT(1) NOT NULL DEFAULT 0,
            puede_editar TINYINT(1) NOT NULL DEFAULT 0,
            metadata JSON NULL,
            UNIQUE KEY idx_faccion_nivel (faccion_id, nivel),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de miembros
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_miembros (
            miembro_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            rango_id BIGINT NOT NULL,
            fecha_ingreso DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            ultimo_servicio DATETIME NULL,
            tiempo_servicio_total BIGINT NOT NULL DEFAULT 0,
            salario_acumulado BIGINT NOT NULL DEFAULT 0,
            bonus_acumulado BIGINT NOT NULL DEFAULT 0,
            amonestaciones INT NOT NULL DEFAULT 0,
            notas TEXT NULL,
            metadata JSON NULL,
            UNIQUE KEY idx_char_faccion (char_id, faccion_id),
            KEY idx_faccion (faccion_id),
            KEY idx_rango (rango_id),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE,
            FOREIGN KEY (rango_id) REFERENCES ait_faccion_rangos(rango_id) ON DELETE RESTRICT
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de solicitudes de ingreso
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_solicitudes (
            solicitud_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            mensaje TEXT NULL,
            estado ENUM('pendiente', 'aprobada', 'rechazada', 'cancelada') NOT NULL DEFAULT 'pendiente',
            revisada_por BIGINT NULL,
            fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_revision DATETIME NULL,
            motivo_rechazo TEXT NULL,
            UNIQUE KEY idx_pendiente (faccion_id, char_id, estado),
            KEY idx_estado (estado),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de invitaciones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_invitaciones (
            invitacion_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            invitado_por BIGINT NOT NULL,
            mensaje TEXT NULL,
            estado ENUM('pendiente', 'aceptada', 'rechazada', 'expirada') NOT NULL DEFAULT 'pendiente',
            fecha_invitacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_expiracion DATETIME NOT NULL,
            fecha_respuesta DATETIME NULL,
            UNIQUE KEY idx_pendiente (faccion_id, char_id, estado),
            KEY idx_char (char_id),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de transacciones de tesoreria
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_tesoreria (
            tx_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            tipo ENUM('deposito', 'retiro', 'salario', 'compra', 'venta', 'impuesto', 'multa', 'bonus', 'otro') NOT NULL,
            monto BIGINT NOT NULL,
            balance_anterior BIGINT NOT NULL,
            balance_nuevo BIGINT NOT NULL,
            char_id BIGINT NULL,
            descripcion VARCHAR(255) NULL,
            referencia VARCHAR(64) NULL,
            metadata JSON NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_faccion (faccion_id),
            KEY idx_tipo (tipo),
            KEY idx_fecha (fecha),
            KEY idx_char (char_id),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de logs de faccion
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_logs (
            log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            accion VARCHAR(64) NOT NULL,
            actor_char_id BIGINT NULL,
            objetivo_char_id BIGINT NULL,
            detalles JSON NULL,
            ip VARCHAR(45) NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_faccion (faccion_id),
            KEY idx_accion (accion),
            KEY idx_fecha (fecha),
            KEY idx_actor (actor_char_id),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de notificaciones de faccion
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_notificaciones (
            notif_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            faccion_id BIGINT NOT NULL,
            tipo VARCHAR(32) NOT NULL,
            titulo VARCHAR(128) NOT NULL,
            mensaje TEXT NOT NULL,
            prioridad ENUM('baja', 'normal', 'alta', 'urgente') NOT NULL DEFAULT 'normal',
            rango_minimo INT NULL,
            creada_por BIGINT NULL,
            fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            fecha_expiracion DATETIME NULL,
            metadata JSON NULL,
            KEY idx_faccion (faccion_id),
            KEY idx_fecha (fecha_creacion),
            FOREIGN KEY (faccion_id) REFERENCES ait_facciones(faccion_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de notificaciones leidas
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_faccion_notif_leidas (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            notif_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            fecha_lectura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY idx_notif_char (notif_id, char_id),
            FOREIGN KEY (notif_id) REFERENCES ait_faccion_notificaciones(notif_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

-- =====================================================================================
-- CARGAR CONFIGURACION
-- =====================================================================================

function Facciones.CargarTipos()
    Facciones.tipos = AIT.Utils.DeepCopy(Facciones.TiposDefault)

    -- Cargar overrides de config si existen
    if AIT.Config and AIT.Config.factions and AIT.Config.factions.tipos then
        for tipo, config in pairs(AIT.Config.factions.tipos) do
            if Facciones.tipos[tipo] then
                Facciones.tipos[tipo] = AIT.Utils.Merge(Facciones.tipos[tipo], config)
            else
                Facciones.tipos[tipo] = config
            end
        end
    end
end

function Facciones.CargarFacciones()
    local facciones = MySQL.query.await([[
        SELECT f.*,
               COUNT(DISTINCT m.char_id) as total_miembros
        FROM ait_facciones f
        LEFT JOIN ait_faccion_miembros m ON f.faccion_id = m.faccion_id
        WHERE f.activa = 1
        GROUP BY f.faccion_id
    ]])

    Facciones.cache = {}
    for _, faccion in ipairs(facciones or {}) do
        -- Cargar rangos
        local rangos = MySQL.query.await([[
            SELECT * FROM ait_faccion_rangos
            WHERE faccion_id = ?
            ORDER BY nivel ASC
        ]], { faccion.faccion_id })

        faccion.rangos = {}
        for _, rango in ipairs(rangos or {}) do
            rango.permisos = rango.permisos and json.decode(rango.permisos) or {}
            faccion.rangos[rango.nivel] = rango
        end

        -- Parsear metadata
        faccion.metadata = faccion.metadata and json.decode(faccion.metadata) or {}
        faccion.sede_coords = faccion.sede_coords and json.decode(faccion.sede_coords) or nil

        Facciones.cache[faccion.faccion_id] = faccion
        Facciones.miembrosOnline[faccion.faccion_id] = {}
    end

    if AIT.Log then
        AIT.Log.info('FACTIONS', ('Cargadas %d facciones activas'):format(#(facciones or {})))
    end
end

-- =====================================================================================
-- GESTION DE FACCIONES
-- =====================================================================================

--- Crear una nueva faccion
---@param params table Parametros de la faccion
---@return boolean, number|string
function Facciones.Crear(params)
    --[[
        params = {
            nombre = 'Policia de Los Santos',
            nombre_corto = 'LSPD',
            descripcion = 'Departamento de policia',
            tipo = 'gobierno',
            lider_char_id = 123,
            color = '#0000FF',
            publica = true,
        }
    ]]

    -- Validaciones
    if not params.nombre or #params.nombre < 3 then
        return false, 'El nombre debe tener al menos 3 caracteres'
    end

    if not params.nombre_corto or #params.nombre_corto < 2 or #params.nombre_corto > 16 then
        return false, 'El nombre corto debe tener entre 2 y 16 caracteres'
    end

    local tipoConfig = Facciones.tipos[params.tipo or 'trabajo']
    if not tipoConfig then
        return false, 'Tipo de faccion no valido'
    end

    -- Verificar nombre unico
    local existe = MySQL.query.await(
        'SELECT faccion_id FROM ait_facciones WHERE nombre = ? OR nombre_corto = ?',
        { params.nombre, params.nombre_corto }
    )

    if existe and #existe > 0 then
        return false, 'Ya existe una faccion con ese nombre'
    end

    -- Crear faccion
    local faccionId = MySQL.insert.await([[
        INSERT INTO ait_facciones
        (nombre, nombre_corto, descripcion, tipo, lider_char_id, salario_base,
         color, publica, requiere_aprobacion, max_miembros, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        params.nombre,
        params.nombre_corto,
        params.descripcion or '',
        params.tipo or 'trabajo',
        params.lider_char_id,
        tipoConfig.salarioBase or 500,
        params.color or tipoConfig.color or '#FFFFFF',
        params.publica and 1 or 0,
        tipoConfig.requiereAprobacion and 1 or 0,
        tipoConfig.maxMiembros or 50,
        params.metadata and json.encode(params.metadata) or nil
    })

    if not faccionId then
        return false, 'Error al crear la faccion en la base de datos'
    end

    -- Crear rangos por defecto
    local rangosCreados = {}
    for _, rango in ipairs(Facciones.RangosDefault) do
        local rangoId = MySQL.insert.await([[
            INSERT INTO ait_faccion_rangos
            (faccion_id, nivel, nombre, salario_mult, permisos, puede_reclutar,
             puede_expulsar, puede_promover, puede_tesoreria, puede_editar)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            faccionId,
            rango.nivel,
            rango.nombre,
            rango.salarioMult,
            json.encode(rango.permisos),
            rango.nivel >= 3 and 1 or 0, -- Puede reclutar desde nivel 3
            rango.nivel >= 4 and 1 or 0, -- Puede expulsar desde nivel 4
            rango.nivel >= 4 and 1 or 0, -- Puede promover desde nivel 4
            rango.nivel >= 5 and 1 or 0, -- Solo jefes tesoreria
            rango.nivel >= 5 and 1 or 0, -- Solo jefes editar
        })
        rangosCreados[rango.nivel] = rangoId
    end

    -- Añadir lider como miembro si se especifico
    if params.lider_char_id then
        local rangoJefeId = rangosCreados[5]
        if rangoJefeId then
            MySQL.insert.await([[
                INSERT INTO ait_faccion_miembros (faccion_id, char_id, rango_id)
                VALUES (?, ?, ?)
            ]], { faccionId, params.lider_char_id, rangoJefeId })
        end
    end

    -- Recargar cache
    Facciones.CargarFacciones()

    -- Log
    Facciones.RegistrarLog(faccionId, 'FACCION_CREADA', params.lider_char_id, nil, {
        nombre = params.nombre,
        tipo = params.tipo
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.created', {
            faccion_id = faccionId,
            nombre = params.nombre,
            tipo = params.tipo
        })
    end

    return true, faccionId
end

--- Obtener informacion de una faccion
---@param faccionId number
---@return table|nil
function Facciones.Obtener(faccionId)
    -- Cache primero
    if Facciones.cache[faccionId] then
        return Facciones.cache[faccionId]
    end

    -- Base de datos
    local faccion = MySQL.query.await([[
        SELECT * FROM ait_facciones WHERE faccion_id = ?
    ]], { faccionId })

    if faccion and faccion[1] then
        return faccion[1]
    end

    return nil
end

--- Obtener faccion por nombre
---@param nombre string
---@return table|nil
function Facciones.ObtenerPorNombre(nombre)
    for _, faccion in pairs(Facciones.cache) do
        if faccion.nombre == nombre or faccion.nombre_corto == nombre then
            return faccion
        end
    end

    local faccion = MySQL.query.await([[
        SELECT * FROM ait_facciones WHERE nombre = ? OR nombre_corto = ?
    ]], { nombre, nombre })

    if faccion and faccion[1] then
        return faccion[1]
    end

    return nil
end

--- Listar todas las facciones
---@param filtros table|nil Filtros opcionales
---@return table
function Facciones.Listar(filtros)
    filtros = filtros or {}

    local query = 'SELECT f.*, COUNT(DISTINCT m.char_id) as total_miembros FROM ait_facciones f '
    query = query .. 'LEFT JOIN ait_faccion_miembros m ON f.faccion_id = m.faccion_id WHERE 1=1 '
    local params = {}

    if filtros.tipo then
        query = query .. 'AND f.tipo = ? '
        table.insert(params, filtros.tipo)
    end

    if filtros.activa ~= nil then
        query = query .. 'AND f.activa = ? '
        table.insert(params, filtros.activa and 1 or 0)
    end

    if filtros.publica ~= nil then
        query = query .. 'AND f.publica = ? '
        table.insert(params, filtros.publica and 1 or 0)
    end

    query = query .. 'GROUP BY f.faccion_id ORDER BY f.nombre ASC'

    return MySQL.query.await(query, params) or {}
end

--- Eliminar una faccion (soft delete)
---@param faccionId number
---@param motivostring
---@return boolean
function Facciones.Eliminar(faccionId, motivo)
    local faccion = Facciones.Obtener(faccionId)
    if not faccion then
        return false, 'Faccion no encontrada'
    end

    MySQL.query.await([[
        UPDATE ait_facciones SET activa = 0, metadata = JSON_SET(COALESCE(metadata, '{}'), '$.motivo_baja', ?)
        WHERE faccion_id = ?
    ]], { motivo or 'Eliminada por administracion', faccionId })

    -- Limpiar cache
    Facciones.cache[faccionId] = nil
    Facciones.miembrosOnline[faccionId] = nil

    -- Log
    Facciones.RegistrarLog(faccionId, 'FACCION_ELIMINADA', nil, nil, { motivo = motivo })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.deleted', {
            faccion_id = faccionId,
            nombre = faccion.nombre
        })
    end

    return true
end

-- =====================================================================================
-- GESTION DE MIEMBROS
-- =====================================================================================

--- Obtener la faccion de un personaje
---@param charId number
---@return table|nil
function Facciones.ObtenerFaccionDePersonaje(charId)
    local miembro = MySQL.query.await([[
        SELECT m.*, f.*, r.nombre as rango_nombre, r.nivel as rango_nivel,
               r.permisos as rango_permisos, r.puede_reclutar, r.puede_expulsar,
               r.puede_promover, r.puede_tesoreria, r.puede_editar
        FROM ait_faccion_miembros m
        JOIN ait_facciones f ON m.faccion_id = f.faccion_id
        JOIN ait_faccion_rangos r ON m.rango_id = r.rango_id
        WHERE m.char_id = ? AND f.activa = 1
        LIMIT 1
    ]], { charId })

    if miembro and miembro[1] then
        local data = miembro[1]
        data.rango_permisos = data.rango_permisos and json.decode(data.rango_permisos) or {}
        return data
    end

    return nil
end

--- Verificar si un personaje pertenece a una faccion
---@param charId number
---@param faccionId number|nil
---@return boolean
function Facciones.EsMiembro(charId, faccionId)
    local query = 'SELECT 1 FROM ait_faccion_miembros m JOIN ait_facciones f ON m.faccion_id = f.faccion_id '
    query = query .. 'WHERE m.char_id = ? AND f.activa = 1 '
    local params = { charId }

    if faccionId then
        query = query .. 'AND m.faccion_id = ? '
        table.insert(params, faccionId)
    end

    query = query .. 'LIMIT 1'

    local result = MySQL.query.await(query, params)
    return result and #result > 0
end

--- Unirse a una faccion
---@param charId number
---@param faccionId number
---@param rangoNivel number|nil
---@return boolean, string
function Facciones.Unirse(charId, faccionId, rangoNivel)
    -- Verificar que no este en otra faccion
    if Facciones.EsMiembro(charId, nil) then
        return false, 'Ya perteneces a una faccion'
    end

    local faccion = Facciones.Obtener(faccionId)
    if not faccion then
        return false, 'Faccion no encontrada'
    end

    if not faccion.activa then
        return false, 'Esta faccion no esta activa'
    end

    -- Verificar limite de miembros
    if faccion.total_miembros >= faccion.max_miembros then
        return false, 'La faccion ha alcanzado el limite de miembros'
    end

    -- Obtener rango inicial
    rangoNivel = rangoNivel or 1
    local rango = faccion.rangos and faccion.rangos[rangoNivel]

    if not rango then
        -- Buscar rango en BD
        local rangoDb = MySQL.query.await([[
            SELECT * FROM ait_faccion_rangos WHERE faccion_id = ? AND nivel = ?
        ]], { faccionId, rangoNivel })

        if not rangoDb or #rangoDb == 0 then
            return false, 'Rango no encontrado'
        end
        rango = rangoDb[1]
    end

    -- Insertar miembro
    MySQL.insert.await([[
        INSERT INTO ait_faccion_miembros (faccion_id, char_id, rango_id)
        VALUES (?, ?, ?)
    ]], { faccionId, charId, rango.rango_id })

    -- Actualizar cache
    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].total_miembros = (Facciones.cache[faccionId].total_miembros or 0) + 1
    end

    -- Log
    Facciones.RegistrarLog(faccionId, 'MIEMBRO_UNIDO', charId, nil, { rango = rango.nombre })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.member.joined', {
            faccion_id = faccionId,
            char_id = charId,
            rango_id = rango.rango_id
        })
    end

    -- Notificar a la faccion
    Facciones.NotificarFaccion(faccionId, {
        tipo = 'nuevo_miembro',
        titulo = 'Nuevo miembro',
        mensaje = ('Un nuevo miembro se ha unido a la faccion con el rango de %s'):format(rango.nombre),
        prioridad = 'normal'
    })

    return true, 'Te has unido a la faccion correctamente'
end

--- Salir de una faccion
---@param charId number
---@param motivo string|nil
---@return boolean, string
function Facciones.Salir(charId, motivo)
    local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    local faccionId = membresia.faccion_id

    -- Verificar si es el lider
    if membresia.lider_char_id == charId then
        return false, 'El lider no puede abandonar la faccion. Transfiere el liderazgo primero.'
    end

    -- Eliminar membresia
    MySQL.query.await([[
        DELETE FROM ait_faccion_miembros WHERE char_id = ? AND faccion_id = ?
    ]], { charId, faccionId })

    -- Actualizar cache
    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].total_miembros = math.max(0, (Facciones.cache[faccionId].total_miembros or 1) - 1)
    end

    -- Remover de online si estaba
    if Facciones.miembrosOnline[faccionId] then
        Facciones.miembrosOnline[faccionId][charId] = nil
    end

    -- Log
    Facciones.RegistrarLog(faccionId, 'MIEMBRO_SALIO', charId, nil, { motivo = motivo or 'Voluntario' })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.member.left', {
            faccion_id = faccionId,
            char_id = charId,
            motivo = motivo
        })
    end

    return true, 'Has abandonado la faccion'
end

--- Obtener miembros de una faccion
---@param faccionId number
---@param opciones table|nil
---@return table
function Facciones.ObtenerMiembros(faccionId, opciones)
    opciones = opciones or {}

    local query = [[
        SELECT m.*, r.nombre as rango_nombre, r.nivel as rango_nivel, r.color as rango_color,
               c.nombre as char_nombre, c.apellido as char_apellido
        FROM ait_faccion_miembros m
        JOIN ait_faccion_rangos r ON m.rango_id = r.rango_id
        LEFT JOIN ait_characters c ON m.char_id = c.char_id
        WHERE m.faccion_id = ?
    ]]
    local params = { faccionId }

    if opciones.rango_minimo then
        query = query .. ' AND r.nivel >= ?'
        table.insert(params, opciones.rango_minimo)
    end

    query = query .. ' ORDER BY r.nivel DESC, m.fecha_ingreso ASC'

    if opciones.limite then
        query = query .. ' LIMIT ?'
        table.insert(params, opciones.limite)
    end

    return MySQL.query.await(query, params) or {}
end

-- =====================================================================================
-- TESORERIA
-- =====================================================================================

--- Depositar en tesoreria
---@param faccionId number
---@param monto number
---@param charId number|nil
---@param descripcion string|nil
---@return boolean, string
function Facciones.DepositarTesoreria(faccionId, monto, charId, descripcion)
    if monto <= 0 then
        return false, 'El monto debe ser mayor a 0'
    end

    local faccion = Facciones.Obtener(faccionId)
    if not faccion then
        return false, 'Faccion no encontrada'
    end

    local nuevoBalance = faccion.tesoreria + monto
    if nuevoBalance > faccion.limite_tesoreria then
        return false, 'Se excederia el limite de tesoreria'
    end

    -- Actualizar tesoreria
    MySQL.query.await([[
        UPDATE ait_facciones SET tesoreria = tesoreria + ? WHERE faccion_id = ?
    ]], { monto, faccionId })

    -- Registrar transaccion
    MySQL.insert.await([[
        INSERT INTO ait_faccion_tesoreria
        (faccion_id, tipo, monto, balance_anterior, balance_nuevo, char_id, descripcion)
        VALUES (?, 'deposito', ?, ?, ?, ?, ?)
    ]], { faccionId, monto, faccion.tesoreria, nuevoBalance, charId, descripcion or 'Deposito' })

    -- Actualizar cache
    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].tesoreria = nuevoBalance
    end

    -- Log
    Facciones.RegistrarLog(faccionId, 'TESORERIA_DEPOSITO', charId, nil, {
        monto = monto,
        balance_nuevo = nuevoBalance
    })

    return true, ('Depositados $%s en la tesoreria'):format(Facciones.FormatearNumero(monto))
end

--- Retirar de tesoreria
---@param faccionId number
---@param monto number
---@param charId number
---@param descripcion string|nil
---@return boolean, string
function Facciones.RetirarTesoreria(faccionId, monto, charId, descripcion)
    if monto <= 0 then
        return false, 'El monto debe ser mayor a 0'
    end

    -- Verificar permisos
    local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
    if not membresia or membresia.faccion_id ~= faccionId then
        return false, 'No perteneces a esta faccion'
    end

    if not membresia.puede_tesoreria then
        return false, 'No tienes permiso para acceder a la tesoreria'
    end

    local faccion = Facciones.Obtener(faccionId)
    if not faccion then
        return false, 'Faccion no encontrada'
    end

    if faccion.tesoreria < monto then
        return false, 'Fondos insuficientes en la tesoreria'
    end

    local nuevoBalance = faccion.tesoreria - monto

    -- Actualizar tesoreria
    MySQL.query.await([[
        UPDATE ait_facciones SET tesoreria = tesoreria - ? WHERE faccion_id = ?
    ]], { monto, faccionId })

    -- Registrar transaccion
    MySQL.insert.await([[
        INSERT INTO ait_faccion_tesoreria
        (faccion_id, tipo, monto, balance_anterior, balance_nuevo, char_id, descripcion)
        VALUES (?, 'retiro', ?, ?, ?, ?, ?)
    ]], { faccionId, -monto, faccion.tesoreria, nuevoBalance, charId, descripcion or 'Retiro' })

    -- Actualizar cache
    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].tesoreria = nuevoBalance
    end

    -- Log
    Facciones.RegistrarLog(faccionId, 'TESORERIA_RETIRO', charId, nil, {
        monto = monto,
        balance_nuevo = nuevoBalance
    })

    return true, ('Retirados $%s de la tesoreria'):format(Facciones.FormatearNumero(monto))
end

--- Obtener balance de tesoreria
---@param faccionId number
---@return number
function Facciones.ObtenerTesoreria(faccionId)
    local faccion = Facciones.Obtener(faccionId)
    return faccion and faccion.tesoreria or 0
end

--- Obtener historial de tesoreria
---@param faccionId number
---@param limite number|nil
---@return table
function Facciones.ObtenerHistorialTesoreria(faccionId, limite)
    limite = limite or 50

    return MySQL.query.await([[
        SELECT t.*, c.nombre as char_nombre, c.apellido as char_apellido
        FROM ait_faccion_tesoreria t
        LEFT JOIN ait_characters c ON t.char_id = c.char_id
        WHERE t.faccion_id = ?
        ORDER BY t.fecha DESC
        LIMIT ?
    ]], { faccionId, limite }) or {}
end

-- =====================================================================================
-- RANGOS Y PERMISOS
-- =====================================================================================

--- Verificar si un miembro tiene un permiso especifico
---@param charId number
---@param permiso string
---@return boolean
function Facciones.TienePermiso(charId, permiso)
    local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
    if not membresia then
        return false
    end

    -- Jefe tiene todos los permisos
    if membresia.rango_nivel >= 5 then
        return true
    end

    -- Verificar permisos especificos del rango
    local permisos = membresia.rango_permisos or {}

    for _, p in ipairs(permisos) do
        if p == '*' or p == permiso then
            return true
        end
    end

    -- Verificar permisos del tipo de faccion
    local tipoConfig = Facciones.tipos[membresia.tipo]
    if tipoConfig and tipoConfig.permisos then
        for _, p in ipairs(tipoConfig.permisos) do
            if p == permiso then
                return true
            end
        end
    end

    return false
end

--- Obtener rango de un miembro
---@param charId number
---@return table|nil
function Facciones.ObtenerRango(charId)
    local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
    if not membresia then
        return nil
    end

    return {
        id = membresia.rango_id,
        nivel = membresia.rango_nivel,
        nombre = membresia.rango_nombre,
        permisos = membresia.rango_permisos,
        puede_reclutar = membresia.puede_reclutar == 1,
        puede_expulsar = membresia.puede_expulsar == 1,
        puede_promover = membresia.puede_promover == 1,
        puede_tesoreria = membresia.puede_tesoreria == 1,
        puede_editar = membresia.puede_editar == 1,
    }
end

-- =====================================================================================
-- NOTIFICACIONES
-- =====================================================================================

--- Crear notificacion para la faccion
---@param faccionId number
---@param datos table
---@return boolean, number|string
function Facciones.NotificarFaccion(faccionId, datos)
    --[[
        datos = {
            tipo = 'anuncio',
            titulo = 'Titulo',
            mensaje = 'Contenido',
            prioridad = 'normal', -- baja, normal, alta, urgente
            rango_minimo = nil, -- Solo rangos >= este nivel
            creada_por = nil, -- char_id
            duracion = nil, -- segundos hasta expirar
        }
    ]]

    local fechaExpiracion = nil
    if datos.duracion then
        fechaExpiracion = os.date('%Y-%m-%d %H:%M:%S', os.time() + datos.duracion)
    end

    local notifId = MySQL.insert.await([[
        INSERT INTO ait_faccion_notificaciones
        (faccion_id, tipo, titulo, mensaje, prioridad, rango_minimo, creada_por, fecha_expiracion)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        faccionId,
        datos.tipo or 'general',
        datos.titulo,
        datos.mensaje,
        datos.prioridad or 'normal',
        datos.rango_minimo,
        datos.creada_por,
        fechaExpiracion
    })

    -- Añadir a cola para envio inmediato a conectados
    table.insert(Facciones.colaNotificaciones, {
        faccion_id = faccionId,
        notif_id = notifId,
        tipo = datos.tipo,
        titulo = datos.titulo,
        mensaje = datos.mensaje,
        prioridad = datos.prioridad,
        rango_minimo = datos.rango_minimo,
    })

    return true, notifId
end

--- Obtener notificaciones pendientes de un miembro
---@param charId number
---@return table
function Facciones.ObtenerNotificaciones(charId)
    local membresia = Facciones.ObtenerFaccionDePersonaje(charId)
    if not membresia then
        return {}
    end

    return MySQL.query.await([[
        SELECT n.* FROM ait_faccion_notificaciones n
        LEFT JOIN ait_faccion_notif_leidas l ON n.notif_id = l.notif_id AND l.char_id = ?
        WHERE n.faccion_id = ?
        AND l.id IS NULL
        AND (n.fecha_expiracion IS NULL OR n.fecha_expiracion > NOW())
        AND (n.rango_minimo IS NULL OR n.rango_minimo <= ?)
        ORDER BY
            FIELD(n.prioridad, 'urgente', 'alta', 'normal', 'baja'),
            n.fecha_creacion DESC
        LIMIT 50
    ]], { charId, membresia.faccion_id, membresia.rango_nivel }) or {}
end

--- Marcar notificacion como leida
---@param charId number
---@param notifId number
---@return boolean
function Facciones.MarcarNotificacionLeida(charId, notifId)
    MySQL.insert.await([[
        INSERT IGNORE INTO ait_faccion_notif_leidas (notif_id, char_id)
        VALUES (?, ?)
    ]], { notifId, charId })

    return true
end

--- Thread de procesamiento de notificaciones
function Facciones.IniciarThreadNotificaciones()
    CreateThread(function()
        while true do
            Wait(1000) -- Cada segundo

            while #Facciones.colaNotificaciones > 0 do
                local notif = table.remove(Facciones.colaNotificaciones, 1)

                -- Enviar a miembros online de la faccion
                local miembrosOnline = Facciones.miembrosOnline[notif.faccion_id] or {}

                for charId, sourceId in pairs(miembrosOnline) do
                    -- Verificar rango minimo si aplica
                    local enviar = true
                    if notif.rango_minimo then
                        local rango = Facciones.ObtenerRango(charId)
                        if not rango or rango.nivel < notif.rango_minimo then
                            enviar = false
                        end
                    end

                    if enviar then
                        TriggerClientEvent('ait:factions:notification', sourceId, {
                            tipo = notif.tipo,
                            titulo = notif.titulo,
                            mensaje = notif.mensaje,
                            prioridad = notif.prioridad,
                        })
                    end
                end
            end
        end
    end)
end

-- =====================================================================================
-- LOGS
-- =====================================================================================

--- Registrar accion en el log de faccion
---@param faccionId number
---@param accion string
---@param actorCharId number|nil
---@param objetivoCharId number|nil
---@param detalles table|nil
function Facciones.RegistrarLog(faccionId, accion, actorCharId, objetivoCharId, detalles)
    MySQL.insert([[
        INSERT INTO ait_faccion_logs (faccion_id, accion, actor_char_id, objetivo_char_id, detalles)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        faccionId,
        accion,
        actorCharId,
        objetivoCharId,
        detalles and json.encode(detalles) or nil
    })
end

--- Obtener logs de faccion
---@param faccionId number
---@param opciones table|nil
---@return table
function Facciones.ObtenerLogs(faccionId, opciones)
    opciones = opciones or {}

    local query = [[
        SELECT l.*,
               ca.nombre as actor_nombre, ca.apellido as actor_apellido,
               co.nombre as objetivo_nombre, co.apellido as objetivo_apellido
        FROM ait_faccion_logs l
        LEFT JOIN ait_characters ca ON l.actor_char_id = ca.char_id
        LEFT JOIN ait_characters co ON l.objetivo_char_id = co.char_id
        WHERE l.faccion_id = ?
    ]]
    local params = { faccionId }

    if opciones.accion then
        query = query .. ' AND l.accion = ?'
        table.insert(params, opciones.accion)
    end

    if opciones.desde then
        query = query .. ' AND l.fecha >= ?'
        table.insert(params, opciones.desde)
    end

    query = query .. ' ORDER BY l.fecha DESC LIMIT ?'
    table.insert(params, opciones.limite or 100)

    return MySQL.query.await(query, params) or {}
end

-- =====================================================================================
-- SALARIOS (SCHEDULER)
-- =====================================================================================

function Facciones.ProcesarSalarios()
    -- Obtener todos los miembros en servicio
    local miembrosEnServicio = MySQL.query.await([[
        SELECT m.*, f.salario_base, r.salario_mult
        FROM ait_faccion_miembros m
        JOIN ait_facciones f ON m.faccion_id = f.faccion_id
        JOIN ait_faccion_rangos r ON m.rango_id = r.rango_id
        WHERE f.activa = 1
        AND m.char_id IN (
            SELECT char_id FROM ait_duty_status WHERE en_servicio = 1
        )
    ]])

    for _, miembro in ipairs(miembrosEnServicio or {}) do
        local salario = math.floor(miembro.salario_base * (miembro.salario_mult or 1.0))
        local faccion = Facciones.Obtener(miembro.faccion_id)

        if faccion and faccion.tesoreria >= salario then
            -- Pagar desde tesoreria
            local success, _ = Facciones.RetirarTesoreriaInterno(miembro.faccion_id, salario, 'Salario hora')

            if success and AIT.Engines.economy then
                -- Pagar al jugador
                AIT.Engines.economy.AddMoney(nil, miembro.char_id, salario, 'bank', 'job_payment',
                    ('Salario por hora - %s'):format(faccion.nombre))

                -- Actualizar acumulado
                MySQL.query([[
                    UPDATE ait_faccion_miembros
                    SET salario_acumulado = salario_acumulado + ?
                    WHERE miembro_id = ?
                ]], { salario, miembro.miembro_id })
            end
        end
    end

    if AIT.Log then
        AIT.Log.debug('FACTIONS', ('Procesados salarios para %d miembros'):format(#(miembrosEnServicio or {})))
    end
end

function Facciones.RetirarTesoreriaInterno(faccionId, monto, descripcion)
    local faccion = Facciones.Obtener(faccionId)
    if not faccion or faccion.tesoreria < monto then
        return false
    end

    local nuevoBalance = faccion.tesoreria - monto

    MySQL.query.await([[
        UPDATE ait_facciones SET tesoreria = tesoreria - ? WHERE faccion_id = ?
    ]], { monto, faccionId })

    MySQL.insert([[
        INSERT INTO ait_faccion_tesoreria
        (faccion_id, tipo, monto, balance_anterior, balance_nuevo, descripcion)
        VALUES (?, 'salario', ?, ?, ?, ?)
    ]], { faccionId, -monto, faccion.tesoreria, nuevoBalance, descripcion })

    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].tesoreria = nuevoBalance
    end

    return true
end

function Facciones.ProcesarImpuestosFacciones()
    -- Impuesto diario a facciones con tesoreria alta
    local facciones = MySQL.query.await([[
        SELECT * FROM ait_facciones WHERE activa = 1 AND tesoreria > 1000000
    ]])

    for _, faccion in ipairs(facciones or {}) do
        local impuesto = math.floor(faccion.tesoreria * 0.001) -- 0.1% diario
        if impuesto > 0 then
            Facciones.RetirarTesoreriaInterno(faccion.faccion_id, impuesto, 'Impuesto diario')

            Facciones.RegistrarLog(faccion.faccion_id, 'IMPUESTO_APLICADO', nil, nil, {
                monto = impuesto,
                porcentaje = 0.1
            })
        end
    end
end

function Facciones.LimpiarFaccionesInactivas()
    -- Marcar como inactivas facciones sin miembros por mas de 30 dias
    MySQL.query([[
        UPDATE ait_facciones f
        SET f.activa = 0,
            f.metadata = JSON_SET(COALESCE(f.metadata, '{}'), '$.motivo_baja', 'Inactividad automatica')
        WHERE f.activa = 1
        AND f.faccion_id NOT IN (
            SELECT DISTINCT faccion_id FROM ait_faccion_miembros
        )
        AND f.created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
    ]])
end

-- =====================================================================================
-- EVENTOS DEL SERVIDOR
-- =====================================================================================

function Facciones.RegistrarEventos()
    -- Jugador conectado
    RegisterNetEvent('ait:player:loaded', function(source, playerData, charData)
        if charData and charData.char_id then
            local membresia = Facciones.ObtenerFaccionDePersonaje(charData.char_id)
            if membresia then
                -- Añadir a online
                if not Facciones.miembrosOnline[membresia.faccion_id] then
                    Facciones.miembrosOnline[membresia.faccion_id] = {}
                end
                Facciones.miembrosOnline[membresia.faccion_id][charData.char_id] = source

                -- Enviar datos de faccion al cliente
                TriggerClientEvent('ait:factions:data', source, {
                    faccion_id = membresia.faccion_id,
                    nombre = membresia.nombre,
                    nombre_corto = membresia.nombre_corto,
                    tipo = membresia.tipo,
                    rango = {
                        nivel = membresia.rango_nivel,
                        nombre = membresia.rango_nombre,
                    },
                    tesoreria = membresia.tesoreria,
                })

                -- Enviar notificaciones pendientes
                local notificaciones = Facciones.ObtenerNotificaciones(charData.char_id)
                if #notificaciones > 0 then
                    TriggerClientEvent('ait:factions:notifications', source, notificaciones)
                end
            end
        end
    end)

    -- Jugador desconectado
    AddEventHandler('playerDropped', function(reason)
        local source = source
        -- Buscar y remover de miembros online
        for faccionId, miembros in pairs(Facciones.miembrosOnline) do
            for charId, sid in pairs(miembros) do
                if sid == source then
                    Facciones.miembrosOnline[faccionId][charId] = nil
                    break
                end
            end
        end
    end)
end

-- =====================================================================================
-- COMANDOS
-- =====================================================================================

function Facciones.RegistrarComandos()
    -- Comando para ver info de faccion
    RegisterCommand('faccion', function(source, args, rawCommand)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local membresia = Facciones.ObtenerFaccionDePersonaje(charId)

        if not membresia then
            TriggerClientEvent('QBCore:Notify', source, 'No perteneces a ninguna faccion', 'error')
            return
        end

        local mensaje = ([[
            === %s [%s] ===
            Tipo: %s
            Tu rango: %s (Nivel %d)
            Miembros: %d/%d
            Tesoreria: $%s
        ]]):format(
            membresia.nombre,
            membresia.nombre_corto,
            membresia.tipo,
            membresia.rango_nombre,
            membresia.rango_nivel,
            membresia.total_miembros or 0,
            membresia.max_miembros,
            Facciones.FormatearNumero(membresia.tesoreria)
        )

        TriggerClientEvent('chat:addMessage', source, { args = { 'Faccion', mensaje } })
    end, false)

    -- Comando admin para crear faccion
    RegisterCommand('crearfaccion', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'faction.create') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        if #args < 3 then
            local msg = 'Uso: /crearfaccion [nombre] [nombre_corto] [tipo]'
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
            else
                print(msg)
            end
            return
        end

        local nombre = args[1]
        local nombreCorto = args[2]
        local tipo = args[3]

        local success, resultado = Facciones.Crear({
            nombre = nombre,
            nombre_corto = nombreCorto,
            tipo = tipo,
            publica = true
        })

        local msg = success and ('Faccion creada con ID: %d'):format(resultado) or ('Error: %s'):format(resultado)
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
        else
            print(msg)
        end
    end, false)
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Facciones.FormatearNumero(num)
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
Facciones.Get = Facciones.Obtener
Facciones.GetByName = Facciones.ObtenerPorNombre
Facciones.GetPlayerFaction = Facciones.ObtenerFaccionDePersonaje
Facciones.GetMembers = Facciones.ObtenerMiembros
Facciones.GetRank = Facciones.ObtenerRango
Facciones.GetTreasury = Facciones.ObtenerTesoreria
Facciones.IsMember = Facciones.EsMiembro
Facciones.HasPermission = Facciones.TienePermiso

-- Actions
Facciones.Create = Facciones.Crear
Facciones.Delete = Facciones.Eliminar
Facciones.Join = Facciones.Unirse
Facciones.Leave = Facciones.Salir
Facciones.Deposit = Facciones.DepositarTesoreria
Facciones.Withdraw = Facciones.RetirarTesoreria
Facciones.Notify = Facciones.NotificarFaccion
Facciones.Log = Facciones.RegistrarLog

-- =====================================================================================
-- REGISTRAR ENGINE
-- =====================================================================================

AIT.Engines.Factions = Facciones

return Facciones
