-- =====================================================================================
-- ait-qb ENGINE DE IA/NPCs
-- Sistema completo de NPCs con spawn, despawn, persistencia, comportamientos y rutas
-- Namespace: AIT.Engines.AI
-- Optimizado para 2048 slots con spawning dinamico
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.AI = AIT.Engines.AI or {}

local AI = {
    -- Pool de NPCs activos
    npcsActivos = {},
    -- NPCs persistentes (guardados en BD)
    npcsPersistentes = {},
    -- Contador de IDs
    ultimoId = 0,
    -- Configuracion de pools por zona
    poolsZona = {},
    -- Cache de modelos cargados
    modelosCache = {},
    -- Cola de spawn pendiente
    colaSpawn = {},
    -- Limite global de NPCs
    limiteGlobal = 500,
    -- NPCs por jugador cercano
    npcsPorJugador = 15,
    -- Distancia de activacion
    distanciaActivacion = 100.0,
    -- Distancia de despawn
    distanciaDespawn = 150.0,
    -- Estado del sistema
    inicializado = false,
    procesando = false,
}

-- =====================================================================================
-- CONFIGURACION DE TIPOS DE NPC
-- =====================================================================================

AI.TiposNPC = {
    civil = {
        nombre = 'Civil',
        descripcion = 'NPC civil comun',
        comportamientoDefault = 'idle',
        velocidadBase = 1.0,
        saludBase = 100,
        armado = false,
        hostil = false,
        interactuable = true,
        persistente = false,
        despawnDistancia = 150.0,
        prioridad = 1,
    },
    vendedor = {
        nombre = 'Vendedor',
        descripcion = 'NPC de tienda o negocio',
        comportamientoDefault = 'shopkeeper',
        velocidadBase = 0.0,
        saludBase = 200,
        armado = false,
        hostil = false,
        interactuable = true,
        persistente = true,
        despawnDistancia = 200.0,
        prioridad = 3,
    },
    policia = {
        nombre = 'Policia',
        descripcion = 'NPC de fuerzas del orden',
        comportamientoDefault = 'patrol',
        velocidadBase = 1.0,
        saludBase = 150,
        armado = true,
        hostil = false,
        interactuable = true,
        persistente = false,
        despawnDistancia = 200.0,
        prioridad = 2,
    },
    enemigo = {
        nombre = 'Enemigo',
        descripcion = 'NPC hostil',
        comportamientoDefault = 'guard',
        velocidadBase = 1.2,
        saludBase = 120,
        armado = true,
        hostil = true,
        interactuable = false,
        persistente = false,
        despawnDistancia = 100.0,
        prioridad = 2,
    },
    mision = {
        nombre = 'NPC de Mision',
        descripcion = 'NPC relacionado con misiones',
        comportamientoDefault = 'idle',
        velocidadBase = 1.0,
        saludBase = 500,
        armado = false,
        hostil = false,
        interactuable = true,
        persistente = true,
        despawnDistancia = 300.0,
        prioridad = 4,
    },
    escolta = {
        nombre = 'Escolta',
        descripcion = 'NPC que sigue al jugador',
        comportamientoDefault = 'follow',
        velocidadBase = 1.1,
        saludBase = 150,
        armado = true,
        hostil = false,
        interactuable = true,
        persistente = false,
        despawnDistancia = 50.0,
        prioridad = 3,
    },
    animal = {
        nombre = 'Animal',
        descripcion = 'NPC animal',
        comportamientoDefault = 'wander',
        velocidadBase = 0.8,
        saludBase = 50,
        armado = false,
        hostil = false,
        interactuable = false,
        persistente = false,
        despawnDistancia = 100.0,
        prioridad = 1,
    },
}

-- =====================================================================================
-- CONFIGURACION DE RELACIONES
-- =====================================================================================

AI.Relaciones = {
    -- Grupos de relacion
    grupos = {
        civiles = 0,
        policia = 1,
        pandillas = 2,
        ejercito = 3,
        animales = 4,
        jugadores = 5,
    },
    -- Matriz de relaciones (0 = neutral, 1 = amigo, -1 = enemigo)
    matriz = {
        [0] = { [0] = 0, [1] = 1, [2] = -1, [3] = 1, [4] = 0, [5] = 0 },  -- civiles
        [1] = { [0] = 1, [1] = 1, [2] = -1, [3] = 1, [4] = 0, [5] = 0 },  -- policia
        [2] = { [0] = -1, [1] = -1, [2] = 0, [3] = -1, [4] = 0, [5] = -1 }, -- pandillas
        [3] = { [0] = 1, [1] = 1, [2] = -1, [3] = 1, [4] = 0, [5] = 0 },  -- ejercito
        [4] = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },   -- animales
        [5] = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1 },   -- jugadores
    },
}

-- =====================================================================================
-- MODELOS POR DEFECTO
-- =====================================================================================

AI.ModelosDefault = {
    civil_masculino = {
        'a_m_m_bevhills_01', 'a_m_m_bevhills_02', 'a_m_m_business_01',
        'a_m_m_eastsa_01', 'a_m_m_farmer_01', 'a_m_m_malibu_01',
        'a_m_m_mexcntry_01', 'a_m_m_salton_01', 'a_m_m_socenlat_01',
        'a_m_m_tourist_01', 'a_m_y_bevhills_01', 'a_m_y_business_01',
    },
    civil_femenino = {
        'a_f_m_bevhills_01', 'a_f_m_bevhills_02', 'a_f_m_business_01',
        'a_f_m_eastsa_01', 'a_f_m_fatcult_01', 'a_f_m_ktown_01',
        'a_f_m_salton_01', 'a_f_m_tourist_01', 'a_f_y_beach_01',
        'a_f_y_bevhills_01', 'a_f_y_business_01', 'a_f_y_eastsa_01',
    },
    policia = {
        's_m_y_cop_01', 's_f_y_cop_01', 's_m_y_sheriff_01',
        's_m_y_hwaycop_01',
    },
    vendedor = {
        's_m_m_ammucountry', 's_m_y_shop_mask', 's_f_y_shop_low',
        's_m_m_cntrybar_01', 's_f_m_shop_high',
    },
    pandillero = {
        'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'g_m_y_famca_01',
        'g_m_y_famdnf_01', 'g_m_y_lost_01', 'g_m_y_mexgoon_01',
    },
    seguridad = {
        's_m_m_security_01', 's_m_y_security_01', 's_m_m_bouncer_01',
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function AI.Initialize()
    if AI.inicializado then
        return true
    end

    -- Crear tablas de base de datos
    AI.CrearTablas()

    -- Cargar NPCs persistentes
    AI.CargarNPCsPersistentes()

    -- Cargar configuracion de zonas
    AI.CargarConfiguracionZonas()

    -- Registrar eventos
    AI.RegistrarEventos()

    -- Registrar comandos
    AI.RegistrarComandos()

    -- Iniciar threads de gestion
    AI.IniciarThreadPrincipal()
    AI.IniciarThreadSpawn()
    AI.IniciarThreadDespawn()
    AI.IniciarThreadPersistencia()

    -- Registrar tareas del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('ai_cleanup', {
            interval = 300, -- Cada 5 minutos
            fn = AI.LimpiarNPCsHuerfanos
        })

        AIT.Scheduler.register('ai_balance', {
            interval = 60, -- Cada minuto
            fn = AI.BalancearPoblacion
        })

        AIT.Scheduler.register('ai_persistencia', {
            interval = 120, -- Cada 2 minutos
            fn = AI.GuardarEstadoNPCs
        })
    end

    AI.inicializado = true

    if AIT.Log then
        AIT.Log.info('AI', 'Engine de IA/NPCs inicializado correctamente')
    end

    return true
end

-- =====================================================================================
-- CREACION DE TABLAS
-- =====================================================================================

function AI.CrearTablas()
    -- Tabla principal de NPCs persistentes
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npcs (
            npc_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            identificador VARCHAR(64) NOT NULL UNIQUE,
            nombre VARCHAR(128) NOT NULL,
            tipo VARCHAR(32) NOT NULL DEFAULT 'civil',
            modelo VARCHAR(64) NOT NULL,
            posicion_x FLOAT NOT NULL,
            posicion_y FLOAT NOT NULL,
            posicion_z FLOAT NOT NULL,
            rotacion FLOAT NOT NULL DEFAULT 0.0,
            dimension INT NOT NULL DEFAULT 0,
            zona_id INT NULL,
            salud_actual INT NOT NULL DEFAULT 100,
            salud_maxima INT NOT NULL DEFAULT 100,
            armadura INT NOT NULL DEFAULT 0,
            arma_actual VARCHAR(64) NULL,
            comportamiento VARCHAR(32) NOT NULL DEFAULT 'idle',
            ruta_id BIGINT NULL,
            punto_ruta_actual INT NOT NULL DEFAULT 0,
            estado VARCHAR(32) NOT NULL DEFAULT 'idle',
            objetivo_entity INT NULL,
            objetivo_coords JSON NULL,
            escenario VARCHAR(64) NULL,
            animacion JSON NULL,
            dialogo_id BIGINT NULL,
            faccion_id BIGINT NULL,
            propietario_char_id BIGINT NULL,
            metadata JSON NULL,
            activo TINYINT(1) NOT NULL DEFAULT 1,
            invencible TINYINT(1) NOT NULL DEFAULT 0,
            congelado TINYINT(1) NOT NULL DEFAULT 0,
            ultimo_spawn DATETIME NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_tipo (tipo),
            KEY idx_zona (zona_id),
            KEY idx_activo (activo),
            KEY idx_comportamiento (comportamiento),
            KEY idx_faccion (faccion_id),
            KEY idx_propietario (propietario_char_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de rutas de patrulla
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npc_rutas (
            ruta_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            nombre VARCHAR(128) NOT NULL,
            descripcion TEXT NULL,
            tipo ENUM('patrol', 'circuit', 'random', 'follow') NOT NULL DEFAULT 'patrol',
            zona_id INT NULL,
            velocidad FLOAT NOT NULL DEFAULT 1.0,
            tiempo_espera INT NOT NULL DEFAULT 5000,
            repetir TINYINT(1) NOT NULL DEFAULT 1,
            invertir TINYINT(1) NOT NULL DEFAULT 0,
            activa TINYINT(1) NOT NULL DEFAULT 1,
            metadata JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_zona (zona_id),
            KEY idx_activa (activa)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de puntos de ruta
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npc_ruta_puntos (
            punto_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            ruta_id BIGINT NOT NULL,
            orden INT NOT NULL,
            posicion_x FLOAT NOT NULL,
            posicion_y FLOAT NOT NULL,
            posicion_z FLOAT NOT NULL,
            rotacion FLOAT NULL,
            tiempo_espera INT NULL,
            accion VARCHAR(64) NULL,
            animacion VARCHAR(64) NULL,
            escenario VARCHAR(64) NULL,
            metadata JSON NULL,
            UNIQUE KEY idx_ruta_orden (ruta_id, orden),
            FOREIGN KEY (ruta_id) REFERENCES ait_npc_rutas(ruta_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de zonas de spawn
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npc_zonas (
            zona_id INT AUTO_INCREMENT PRIMARY KEY,
            nombre VARCHAR(128) NOT NULL,
            tipo VARCHAR(32) NOT NULL DEFAULT 'general',
            centro_x FLOAT NOT NULL,
            centro_y FLOAT NOT NULL,
            centro_z FLOAT NOT NULL,
            radio FLOAT NOT NULL DEFAULT 100.0,
            densidad_max INT NOT NULL DEFAULT 10,
            densidad_min INT NOT NULL DEFAULT 2,
            tipos_npc JSON NULL,
            modelos JSON NULL,
            comportamientos JSON NULL,
            horario_activo JSON NULL,
            activa TINYINT(1) NOT NULL DEFAULT 1,
            prioridad INT NOT NULL DEFAULT 1,
            metadata JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_activa (activa),
            KEY idx_tipo (tipo)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de dialogos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npc_dialogos (
            dialogo_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            npc_id BIGINT NULL,
            tipo VARCHAR(32) NOT NULL DEFAULT 'general',
            titulo VARCHAR(128) NOT NULL,
            contenido TEXT NOT NULL,
            opciones JSON NULL,
            condiciones JSON NULL,
            recompensas JSON NULL,
            siguiente_dialogo_id BIGINT NULL,
            activo TINYINT(1) NOT NULL DEFAULT 1,
            metadata JSON NULL,
            KEY idx_npc (npc_id),
            KEY idx_tipo (tipo)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de interacciones
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npc_interacciones (
            interaccion_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            npc_id BIGINT NOT NULL,
            char_id BIGINT NOT NULL,
            tipo VARCHAR(32) NOT NULL,
            resultado VARCHAR(32) NULL,
            datos JSON NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_npc (npc_id),
            KEY idx_char (char_id),
            KEY idx_fecha (fecha),
            FOREIGN KEY (npc_id) REFERENCES ait_npcs(npc_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Tabla de estado de NPCs (snapshot)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_npc_estado (
            estado_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            npc_id BIGINT NOT NULL,
            posicion JSON NOT NULL,
            salud INT NOT NULL,
            armadura INT NOT NULL,
            estado VARCHAR(32) NOT NULL,
            comportamiento VARCHAR(32) NOT NULL,
            objetivo JSON NULL,
            metadata JSON NULL,
            fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_npc (npc_id),
            KEY idx_fecha (fecha),
            FOREIGN KEY (npc_id) REFERENCES ait_npcs(npc_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

-- =====================================================================================
-- CARGAR DATOS
-- =====================================================================================

function AI.CargarNPCsPersistentes()
    local npcs = MySQL.query.await([[
        SELECT n.*, r.nombre as ruta_nombre, r.tipo as ruta_tipo
        FROM ait_npcs n
        LEFT JOIN ait_npc_rutas r ON n.ruta_id = r.ruta_id
        WHERE n.activo = 1
    ]])

    AI.npcsPersistentes = {}

    for _, npc in ipairs(npcs or {}) do
        -- Parsear JSON
        npc.metadata = npc.metadata and json.decode(npc.metadata) or {}
        npc.objetivo_coords = npc.objetivo_coords and json.decode(npc.objetivo_coords) or nil
        npc.animacion = npc.animacion and json.decode(npc.animacion) or nil

        AI.npcsPersistentes[npc.identificador] = npc
    end

    if AIT.Log then
        AIT.Log.info('AI', ('Cargados %d NPCs persistentes'):format(#(npcs or {})))
    end
end

function AI.CargarConfiguracionZonas()
    local zonas = MySQL.query.await([[
        SELECT * FROM ait_npc_zonas WHERE activa = 1 ORDER BY prioridad DESC
    ]])

    AI.poolsZona = {}

    for _, zona in ipairs(zonas or {}) do
        zona.tipos_npc = zona.tipos_npc and json.decode(zona.tipos_npc) or { 'civil' }
        zona.modelos = zona.modelos and json.decode(zona.modelos) or nil
        zona.comportamientos = zona.comportamientos and json.decode(zona.comportamientos) or nil
        zona.horario_activo = zona.horario_activo and json.decode(zona.horario_activo) or nil
        zona.metadata = zona.metadata and json.decode(zona.metadata) or {}

        AI.poolsZona[zona.zona_id] = zona
    end

    if AIT.Log then
        AIT.Log.info('AI', ('Cargadas %d zonas de spawn'):format(#(zonas or {})))
    end
end

-- =====================================================================================
-- GESTION DE NPCs
-- =====================================================================================

--- Genera un ID unico para el NPC
---@return number
function AI.GenerarId()
    AI.ultimoId = AI.ultimoId + 1
    return AI.ultimoId
end

--- Crea un nuevo NPC en memoria
---@param params table Parametros del NPC
---@return table|nil, string
function AI.Crear(params)
    --[[
        params = {
            identificador = 'npc_vendedor_001',  -- Opcional, se genera si no se da
            nombre = 'Juan el Vendedor',
            tipo = 'vendedor',
            modelo = 's_m_m_ammucountry',
            posicion = vector3(x, y, z),
            rotacion = 180.0,
            dimension = 0,
            zona_id = 1,
            comportamiento = 'shopkeeper',
            ruta_id = nil,
            salud = 200,
            armadura = 0,
            arma = nil,
            invencible = true,
            persistente = true,
            metadata = {}
        }
    ]]

    -- Validar posicion
    if not params.posicion then
        return nil, 'Posicion requerida'
    end

    -- Obtener configuracion del tipo
    local tipoConfig = AI.TiposNPC[params.tipo or 'civil']
    if not tipoConfig then
        return nil, 'Tipo de NPC no valido'
    end

    -- Generar identificador si no se proporciona
    local identificador = params.identificador or ('npc_%s_%d_%d'):format(
        params.tipo or 'civil',
        os.time(),
        AI.GenerarId()
    )

    -- Verificar limite global
    local totalActivos = 0
    for _ in pairs(AI.npcsActivos) do
        totalActivos = totalActivos + 1
    end

    if totalActivos >= AI.limiteGlobal then
        return nil, 'Limite global de NPCs alcanzado'
    end

    -- Seleccionar modelo
    local modelo = params.modelo
    if not modelo then
        local modelosGrupo = AI.ModelosDefault[params.tipo] or AI.ModelosDefault.civil_masculino
        modelo = modelosGrupo[math.random(#modelosGrupo)]
    end

    -- Crear objeto NPC
    local npc = {
        id = AI.GenerarId(),
        identificador = identificador,
        nombre = params.nombre or ('NPC %d'):format(AI.ultimoId),
        tipo = params.tipo or 'civil',
        modelo = modelo,
        posicion = params.posicion,
        rotacion = params.rotacion or 0.0,
        dimension = params.dimension or 0,
        zona_id = params.zona_id,

        -- Estado de salud
        salud = params.salud or tipoConfig.saludBase,
        saludMaxima = params.saludMaxima or tipoConfig.saludBase,
        armadura = params.armadura or 0,

        -- Equipamiento
        armaActual = params.arma,
        inventario = params.inventario or {},

        -- Comportamiento
        comportamiento = params.comportamiento or tipoConfig.comportamientoDefault,
        estado = 'spawning',
        velocidad = params.velocidad or tipoConfig.velocidadBase,

        -- Ruta
        rutaId = params.ruta_id,
        puntoRutaActual = 0,
        puntosRuta = {},

        -- Objetivo actual
        objetivo = nil,
        objetivoTipo = nil,
        objetivoCoords = nil,

        -- Escenario y animacion
        escenario = params.escenario,
        animacion = params.animacion,

        -- Interaccion
        dialogoId = params.dialogo_id,
        interactuable = tipoConfig.interactuable,
        enInteraccion = false,
        interaccionCon = nil,

        -- Relaciones
        grupo = params.grupo or AI.Relaciones.grupos.civiles,
        hostil = tipoConfig.hostil,
        armado = tipoConfig.armado,

        -- Faccion
        faccionId = params.faccion_id,
        propietarioCharId = params.propietario_char_id,

        -- Flags
        persistente = params.persistente or tipoConfig.persistente,
        invencible = params.invencible or false,
        congelado = params.congelado or false,
        activo = true,

        -- Distancias
        despawnDistancia = params.despawnDistancia or tipoConfig.despawnDistancia,
        prioridad = params.prioridad or tipoConfig.prioridad,

        -- Network
        netId = nil,
        entityHandle = nil,

        -- Timestamps
        creadoEn = os.time(),
        ultimaActualizacion = os.time(),
        ultimoSpawn = nil,

        -- Metadata adicional
        metadata = params.metadata or {},
    }

    -- Cargar ruta si tiene una asignada
    if npc.rutaId then
        npc.puntosRuta = AI.CargarPuntosRuta(npc.rutaId)
    end

    -- Guardar en memoria
    AI.npcsActivos[identificador] = npc

    -- Guardar en BD si es persistente
    if npc.persistente then
        AI.GuardarNPCEnBD(npc)
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('ai.npc.created', {
            identificador = identificador,
            tipo = npc.tipo,
            posicion = npc.posicion,
        })
    end

    if AIT.Log then
        AIT.Log.debug('AI', ('NPC creado: %s (%s)'):format(npc.nombre, identificador))
    end

    return npc, identificador
end

--- Spawna un NPC en el mundo
---@param identificador string
---@param sourceDestino number|nil Source del jugador destino para sincronizacion
---@return boolean, string
function AI.Spawn(identificador, sourceDestino)
    local npc = AI.npcsActivos[identificador]
    if not npc then
        return false, 'NPC no encontrado'
    end

    if npc.estado == 'spawned' then
        return false, 'NPC ya spawneado'
    end

    -- Solicitar spawn al cliente mas cercano o destino especifico
    local targetSource = sourceDestino
    if not targetSource then
        targetSource = AI.ObtenerClienteMasCercano(npc.posicion)
    end

    if not targetSource then
        -- Añadir a cola de spawn pendiente
        table.insert(AI.colaSpawn, identificador)
        return false, 'No hay clientes disponibles para spawn'
    end

    -- Preparar datos para el cliente
    local spawnData = {
        identificador = npc.identificador,
        modelo = npc.modelo,
        posicion = { x = npc.posicion.x, y = npc.posicion.y, z = npc.posicion.z },
        rotacion = npc.rotacion,
        salud = npc.salud,
        saludMaxima = npc.saludMaxima,
        armadura = npc.armadura,
        arma = npc.armaActual,
        invencible = npc.invencible,
        congelado = npc.congelado,
        escenario = npc.escenario,
        animacion = npc.animacion,
        comportamiento = npc.comportamiento,
        interactuable = npc.interactuable,
        nombre = npc.nombre,
        tipo = npc.tipo,
    }

    -- Enviar al cliente
    TriggerClientEvent('ait:ai:spawn', targetSource, spawnData)

    -- Actualizar estado
    npc.estado = 'spawning'
    npc.ultimoSpawn = os.time()

    return true, 'Spawn solicitado'
end

--- Despawnea un NPC
---@param identificador string
---@param guardarEstado boolean
---@return boolean
function AI.Despawn(identificador, guardarEstado)
    local npc = AI.npcsActivos[identificador]
    if not npc then
        return false
    end

    -- Guardar estado si es persistente
    if guardarEstado and npc.persistente then
        AI.GuardarEstadoNPC(npc)
    end

    -- Notificar a todos los clientes
    TriggerClientEvent('ait:ai:despawn', -1, identificador)

    -- Actualizar estado
    npc.estado = 'despawned'
    npc.netId = nil
    npc.entityHandle = nil

    -- Si no es persistente, eliminar de memoria
    if not npc.persistente then
        AI.npcsActivos[identificador] = nil
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('ai.npc.despawned', {
            identificador = identificador,
            tipo = npc.tipo,
        })
    end

    return true
end

--- Elimina un NPC completamente
---@param identificador string
---@return boolean
function AI.Eliminar(identificador)
    local npc = AI.npcsActivos[identificador]

    -- Despawnear primero si esta activo
    if npc and npc.estado == 'spawned' then
        AI.Despawn(identificador, false)
    end

    -- Eliminar de memoria
    AI.npcsActivos[identificador] = nil
    AI.npcsPersistentes[identificador] = nil

    -- Eliminar de BD
    MySQL.query([[
        DELETE FROM ait_npcs WHERE identificador = ?
    ]], { identificador })

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('ai.npc.deleted', {
            identificador = identificador,
        })
    end

    return true
end

--- Obtiene un NPC por identificador
---@param identificador string
---@return table|nil
function AI.Obtener(identificador)
    return AI.npcsActivos[identificador] or AI.npcsPersistentes[identificador]
end

--- Lista NPCs con filtros
---@param filtros table|nil
---@return table
function AI.Listar(filtros)
    filtros = filtros or {}
    local resultado = {}

    for identificador, npc in pairs(AI.npcsActivos) do
        local incluir = true

        if filtros.tipo and npc.tipo ~= filtros.tipo then
            incluir = false
        end

        if filtros.zona_id and npc.zona_id ~= filtros.zona_id then
            incluir = false
        end

        if filtros.estado and npc.estado ~= filtros.estado then
            incluir = false
        end

        if filtros.comportamiento and npc.comportamiento ~= filtros.comportamiento then
            incluir = false
        end

        if filtros.faccion_id and npc.faccionId ~= filtros.faccion_id then
            incluir = false
        end

        if incluir then
            table.insert(resultado, npc)
        end
    end

    return resultado
end

-- =====================================================================================
-- RUTAS Y PUNTOS DE NAVEGACION
-- =====================================================================================

--- Carga los puntos de una ruta
---@param rutaId number
---@return table
function AI.CargarPuntosRuta(rutaId)
    local puntos = MySQL.query.await([[
        SELECT * FROM ait_npc_ruta_puntos
        WHERE ruta_id = ?
        ORDER BY orden ASC
    ]], { rutaId })

    local resultado = {}
    for _, punto in ipairs(puntos or {}) do
        punto.metadata = punto.metadata and json.decode(punto.metadata) or {}
        table.insert(resultado, {
            orden = punto.orden,
            posicion = vector3(punto.posicion_x, punto.posicion_y, punto.posicion_z),
            rotacion = punto.rotacion,
            tiempoEspera = punto.tiempo_espera,
            accion = punto.accion,
            animacion = punto.animacion,
            escenario = punto.escenario,
            metadata = punto.metadata,
        })
    end

    return resultado
end

--- Crea una nueva ruta
---@param params table
---@return number|nil, string
function AI.CrearRuta(params)
    local rutaId = MySQL.insert.await([[
        INSERT INTO ait_npc_rutas (nombre, descripcion, tipo, zona_id, velocidad, tiempo_espera, repetir, invertir)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        params.nombre,
        params.descripcion or '',
        params.tipo or 'patrol',
        params.zona_id,
        params.velocidad or 1.0,
        params.tiempo_espera or 5000,
        params.repetir and 1 or 0,
        params.invertir and 1 or 0,
    })

    if not rutaId then
        return nil, 'Error al crear ruta'
    end

    -- Insertar puntos si se proporcionaron
    if params.puntos then
        for i, punto in ipairs(params.puntos) do
            MySQL.insert([[
                INSERT INTO ait_npc_ruta_puntos
                (ruta_id, orden, posicion_x, posicion_y, posicion_z, rotacion, tiempo_espera, accion, animacion, escenario)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                rutaId,
                i,
                punto.posicion.x,
                punto.posicion.y,
                punto.posicion.z,
                punto.rotacion,
                punto.tiempoEspera,
                punto.accion,
                punto.animacion,
                punto.escenario,
            })
        end
    end

    return rutaId, 'Ruta creada'
end

--- Asigna una ruta a un NPC
---@param identificador string
---@param rutaId number
---@return boolean
function AI.AsignarRuta(identificador, rutaId)
    local npc = AI.npcsActivos[identificador]
    if not npc then
        return false
    end

    npc.rutaId = rutaId
    npc.puntoRutaActual = 0
    npc.puntosRuta = AI.CargarPuntosRuta(rutaId)

    -- Actualizar BD si es persistente
    if npc.persistente then
        MySQL.query([[
            UPDATE ait_npcs SET ruta_id = ?, punto_ruta_actual = 0 WHERE identificador = ?
        ]], { rutaId, identificador })
    end

    -- Notificar al cliente
    TriggerClientEvent('ait:ai:ruta', -1, identificador, npc.puntosRuta)

    return true
end

-- =====================================================================================
-- INTERACCIONES
-- =====================================================================================

--- Inicia una interaccion con un NPC
---@param identificador string
---@param charId number
---@param tipoInteraccion string
---@return boolean, table|string
function AI.IniciarInteraccion(identificador, charId, tipoInteraccion)
    local npc = AI.npcsActivos[identificador]
    if not npc then
        return false, 'NPC no encontrado'
    end

    if not npc.interactuable then
        return false, 'Este NPC no es interactuable'
    end

    if npc.enInteraccion then
        return false, 'El NPC ya esta en una interaccion'
    end

    -- Marcar en interaccion
    npc.enInteraccion = true
    npc.interaccionCon = charId

    -- Registrar interaccion
    MySQL.insert([[
        INSERT INTO ait_npc_interacciones (npc_id, char_id, tipo)
        SELECT npc_id, ?, ? FROM ait_npcs WHERE identificador = ?
    ]], { charId, tipoInteraccion, identificador })

    -- Obtener dialogo si tiene
    local dialogo = nil
    if npc.dialogoId then
        dialogo = AI.ObtenerDialogo(npc.dialogoId)
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('ai.npc.interaction.start', {
            identificador = identificador,
            char_id = charId,
            tipo = tipoInteraccion,
        })
    end

    return true, {
        nombre = npc.nombre,
        tipo = npc.tipo,
        dialogo = dialogo,
        faccionId = npc.faccionId,
    }
end

--- Finaliza una interaccion
---@param identificador string
---@param resultado string|nil
---@return boolean
function AI.FinalizarInteraccion(identificador, resultado)
    local npc = AI.npcsActivos[identificador]
    if not npc then
        return false
    end

    local charId = npc.interaccionCon

    npc.enInteraccion = false
    npc.interaccionCon = nil

    -- Actualizar registro
    if charId then
        MySQL.query([[
            UPDATE ait_npc_interacciones
            SET resultado = ?
            WHERE npc_id = (SELECT npc_id FROM ait_npcs WHERE identificador = ?)
            AND char_id = ?
            ORDER BY fecha DESC
            LIMIT 1
        ]], { resultado or 'completada', identificador, charId })
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('ai.npc.interaction.end', {
            identificador = identificador,
            char_id = charId,
            resultado = resultado,
        })
    end

    return true
end

--- Obtiene un dialogo por ID
---@param dialogoId number
---@return table|nil
function AI.ObtenerDialogo(dialogoId)
    local dialogo = MySQL.query.await([[
        SELECT * FROM ait_npc_dialogos WHERE dialogo_id = ? AND activo = 1
    ]], { dialogoId })

    if dialogo and dialogo[1] then
        local d = dialogo[1]
        d.opciones = d.opciones and json.decode(d.opciones) or {}
        d.condiciones = d.condiciones and json.decode(d.condiciones) or {}
        d.recompensas = d.recompensas and json.decode(d.recompensas) or {}
        return d
    end

    return nil
end

-- =====================================================================================
-- PERSISTENCIA
-- =====================================================================================

--- Guarda un NPC en la base de datos
---@param npc table
function AI.GuardarNPCEnBD(npc)
    MySQL.insert([[
        INSERT INTO ait_npcs
        (identificador, nombre, tipo, modelo, posicion_x, posicion_y, posicion_z, rotacion, dimension,
         zona_id, salud_actual, salud_maxima, armadura, arma_actual, comportamiento, ruta_id,
         estado, escenario, dialogo_id, faccion_id, propietario_char_id, invencible, congelado, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            posicion_x = VALUES(posicion_x),
            posicion_y = VALUES(posicion_y),
            posicion_z = VALUES(posicion_z),
            rotacion = VALUES(rotacion),
            salud_actual = VALUES(salud_actual),
            armadura = VALUES(armadura),
            estado = VALUES(estado),
            comportamiento = VALUES(comportamiento)
    ]], {
        npc.identificador,
        npc.nombre,
        npc.tipo,
        npc.modelo,
        npc.posicion.x,
        npc.posicion.y,
        npc.posicion.z,
        npc.rotacion,
        npc.dimension,
        npc.zona_id,
        npc.salud,
        npc.saludMaxima,
        npc.armadura,
        npc.armaActual,
        npc.comportamiento,
        npc.rutaId,
        npc.estado,
        npc.escenario,
        npc.dialogoId,
        npc.faccionId,
        npc.propietarioCharId,
        npc.invencible and 1 or 0,
        npc.congelado and 1 or 0,
        npc.metadata and json.encode(npc.metadata) or nil,
    })
end

--- Guarda el estado actual de un NPC
---@param npc table
function AI.GuardarEstadoNPC(npc)
    MySQL.insert([[
        INSERT INTO ait_npc_estado (npc_id, posicion, salud, armadura, estado, comportamiento, objetivo, metadata)
        SELECT npc_id, ?, ?, ?, ?, ?, ?, ?
        FROM ait_npcs WHERE identificador = ?
    ]], {
        json.encode({ x = npc.posicion.x, y = npc.posicion.y, z = npc.posicion.z }),
        npc.salud,
        npc.armadura,
        npc.estado,
        npc.comportamiento,
        npc.objetivo and json.encode(npc.objetivo) or nil,
        npc.metadata and json.encode(npc.metadata) or nil,
        npc.identificador,
    })
end

--- Guarda el estado de todos los NPCs persistentes
function AI.GuardarEstadoNPCs()
    for identificador, npc in pairs(AI.npcsActivos) do
        if npc.persistente and npc.estado == 'spawned' then
            AI.GuardarEstadoNPC(npc)
        end
    end
end

-- =====================================================================================
-- THREADS DE GESTION
-- =====================================================================================

function AI.IniciarThreadPrincipal()
    CreateThread(function()
        while true do
            Wait(1000) -- Tick cada segundo

            for identificador, npc in pairs(AI.npcsActivos) do
                if npc.estado == 'spawned' and npc.activo then
                    -- Actualizar timestamp
                    npc.ultimaActualizacion = os.time()

                    -- Procesar comportamiento
                    if AIT.Engines.AI.Behavior then
                        AIT.Engines.AI.Behavior.Procesar(npc)
                    end
                end
            end
        end
    end)
end

function AI.IniciarThreadSpawn()
    CreateThread(function()
        while true do
            Wait(2000) -- Cada 2 segundos

            -- Procesar cola de spawn pendiente
            while #AI.colaSpawn > 0 do
                local identificador = table.remove(AI.colaSpawn, 1)
                local npc = AI.npcsActivos[identificador]

                if npc and npc.estado ~= 'spawned' then
                    local targetSource = AI.ObtenerClienteMasCercano(npc.posicion)
                    if targetSource then
                        AI.Spawn(identificador, targetSource)
                    else
                        -- Re-encolar si no hay cliente disponible
                        table.insert(AI.colaSpawn, identificador)
                        break
                    end
                end

                Wait(100) -- Pequeña pausa entre spawns
            end
        end
    end)
end

function AI.IniciarThreadDespawn()
    CreateThread(function()
        while true do
            Wait(5000) -- Cada 5 segundos

            local jugadores = GetPlayers()

            for identificador, npc in pairs(AI.npcsActivos) do
                if npc.estado == 'spawned' and not npc.persistente then
                    -- Verificar si hay jugadores cerca
                    local hayJugadorCerca = false

                    for _, playerId in ipairs(jugadores) do
                        local ped = GetPlayerPed(playerId)
                        if ped and DoesEntityExist(ped) then
                            local playerCoords = GetEntityCoords(ped)
                            local distancia = #(npc.posicion - playerCoords)

                            if distancia <= npc.despawnDistancia then
                                hayJugadorCerca = true
                                break
                            end
                        end
                    end

                    -- Despawnear si no hay jugadores cerca
                    if not hayJugadorCerca then
                        AI.Despawn(identificador, false)
                    end
                end
            end
        end
    end)
end

function AI.IniciarThreadPersistencia()
    CreateThread(function()
        while true do
            Wait(120000) -- Cada 2 minutos

            AI.GuardarEstadoNPCs()
        end
    end)
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

--- Obtiene el cliente mas cercano a una posicion
---@param posicion vector3
---@return number|nil
function AI.ObtenerClienteMasCercano(posicion)
    local jugadores = GetPlayers()
    local masCercano = nil
    local menorDistancia = AI.distanciaActivacion

    for _, playerId in ipairs(jugadores) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            local distancia = #(posicion - playerCoords)

            if distancia < menorDistancia then
                menorDistancia = distancia
                masCercano = playerId
            end
        end
    end

    return masCercano
end

--- Limpia NPCs huerfanos (sin spawn pero en memoria)
function AI.LimpiarNPCsHuerfanos()
    local ahora = os.time()
    local eliminados = 0

    for identificador, npc in pairs(AI.npcsActivos) do
        if not npc.persistente then
            -- NPCs sin actividad por mas de 10 minutos
            if ahora - npc.ultimaActualizacion > 600 then
                AI.npcsActivos[identificador] = nil
                eliminados = eliminados + 1
            end
        end
    end

    if eliminados > 0 and AIT.Log then
        AIT.Log.debug('AI', ('Limpiados %d NPCs huerfanos'):format(eliminados))
    end
end

--- Balancea la poblacion de NPCs por zona
function AI.BalancearPoblacion()
    if AIT.Engines.AI.Spawner then
        AIT.Engines.AI.Spawner.BalancearZonas()
    end
end

--- Cuenta NPCs activos
---@return number
function AI.ContarActivos()
    local total = 0
    for _ in pairs(AI.npcsActivos) do
        total = total + 1
    end
    return total
end

--- Cuenta NPCs spawneados
---@return number
function AI.ContarSpawneados()
    local total = 0
    for _, npc in pairs(AI.npcsActivos) do
        if npc.estado == 'spawned' then
            total = total + 1
        end
    end
    return total
end

-- =====================================================================================
-- EVENTOS
-- =====================================================================================

function AI.RegistrarEventos()
    -- Cliente confirma spawn
    RegisterNetEvent('ait:ai:spawned', function(identificador, netId, entityHandle)
        local npc = AI.npcsActivos[identificador]
        if npc then
            npc.estado = 'spawned'
            npc.netId = netId
            npc.entityHandle = entityHandle

            if AIT.Log then
                AIT.Log.debug('AI', ('NPC spawneado: %s (NetID: %d)'):format(identificador, netId or 0))
            end
        end
    end)

    -- NPC recibe danio
    RegisterNetEvent('ait:ai:damage', function(identificador, danio, atacanteNetId)
        local npc = AI.npcsActivos[identificador]
        if npc and not npc.invencible then
            npc.salud = math.max(0, npc.salud - danio)

            if npc.salud <= 0 then
                npc.estado = 'muerto'

                -- Emitir evento
                if AIT.EventBus then
                    AIT.EventBus.emit('ai.npc.died', {
                        identificador = identificador,
                        atacante = atacanteNetId,
                    })
                end
            else
                -- Reaccion al danio
                if AIT.Engines.AI.Behavior then
                    AIT.Engines.AI.Behavior.ReaccionarDanio(npc, atacanteNetId)
                end
            end
        end
    end)

    -- Actualizar posicion de NPC
    RegisterNetEvent('ait:ai:position', function(identificador, posicion)
        local npc = AI.npcsActivos[identificador]
        if npc then
            npc.posicion = vector3(posicion.x, posicion.y, posicion.z)
        end
    end)

    -- Jugador entra en zona
    if AIT.EventBus then
        AIT.EventBus.on('player.zone.enter', function(event)
            if AIT.Engines.AI.Spawner then
                AIT.Engines.AI.Spawner.JugadorEntraZona(event.payload.source, event.payload.zona_id)
            end
        end)

        AIT.EventBus.on('player.zone.exit', function(event)
            if AIT.Engines.AI.Spawner then
                AIT.Engines.AI.Spawner.JugadorSaleZona(event.payload.source, event.payload.zona_id)
            end
        end)
    end
end

-- =====================================================================================
-- COMANDOS
-- =====================================================================================

function AI.RegistrarComandos()
    -- Comando para crear NPC
    RegisterCommand('spawnnpc', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.spawn') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local tipo = args[1] or 'civil'
        local modelo = args[2]

        -- Obtener posicion del jugador
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        local npc, identificador = AI.Crear({
            tipo = tipo,
            modelo = modelo,
            posicion = coords + vector3(2.0, 0.0, 0.0),
            rotacion = GetEntityHeading(ped),
        })

        if npc then
            AI.Spawn(identificador, source)
            TriggerClientEvent('QBCore:Notify', source, 'NPC creado: ' .. identificador, 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'Error: ' .. identificador, 'error')
        end
    end, false)

    -- Comando para eliminar NPC
    RegisterCommand('deletenpc', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.delete') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local identificador = args[1]
        if not identificador then
            TriggerClientEvent('QBCore:Notify', source, 'Uso: /deletenpc [identificador]', 'error')
            return
        end

        if AI.Eliminar(identificador) then
            TriggerClientEvent('QBCore:Notify', source, 'NPC eliminado', 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'NPC no encontrado', 'error')
        end
    end, false)

    -- Comando para listar NPCs
    RegisterCommand('listnpcs', function(source, args, rawCommand)
        if source > 0 then
            if not AIT.RBAC or not AIT.RBAC.HasPermission(source, 'ai.list') then
                TriggerClientEvent('QBCore:Notify', source, 'Sin permisos', 'error')
                return
            end
        end

        local total = AI.ContarActivos()
        local spawneados = AI.ContarSpawneados()

        local msg = ('NPCs: %d total, %d spawneados'):format(total, spawneados)

        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'AI', msg } })
        else
            print(msg)
        end
    end, false)
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Getters
AI.Get = AI.Obtener
AI.List = AI.Listar
AI.GetActive = AI.ContarActivos
AI.GetSpawned = AI.ContarSpawneados

-- Actions
AI.Create = AI.Crear
AI.Delete = AI.Eliminar
AI.StartInteraction = AI.IniciarInteraccion
AI.EndInteraction = AI.FinalizarInteraccion
AI.CreateRoute = AI.CrearRuta
AI.AssignRoute = AI.AsignarRuta
AI.GetDialog = AI.ObtenerDialogo

-- =====================================================================================
-- REGISTRAR ENGINE
-- =====================================================================================

AIT.Engines.AI = AI

return AI
