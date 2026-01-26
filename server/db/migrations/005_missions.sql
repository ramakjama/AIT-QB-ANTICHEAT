-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb DATABASE SCHEMA V1.0
-- Migration 005: Missions System
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────────
-- DEFINICIONES DE MISIONES
-- Templates/plantillas de misiones disponibles
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_mission_definitions (
    mission_def_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(64) NOT NULL COMMENT 'Identificador único',
    label VARCHAR(128) NOT NULL COMMENT 'Nombre mostrado',
    description TEXT NULL,

    -- Tipo y categoría
    type ENUM('daily', 'weekly', 'story', 'side', 'faction', 'event', 'contract', 'heist', 'delivery', 'collection') NOT NULL,
    category VARCHAR(64) NOT NULL DEFAULT 'general',

    -- Configuración de repetición
    repeatable TINYINT(1) NOT NULL DEFAULT 0,
    cooldown INT NULL COMMENT 'Segundos hasta poder repetir',
    max_completions INT NULL COMMENT 'Máximo de veces que se puede completar',

    -- Requisitos
    min_level INT NULL,
    required_licenses JSON NULL COMMENT '["driver","weapon"]',
    required_faction VARCHAR(64) NULL,
    min_faction_rank INT NULL,
    required_reputation JSON NULL COMMENT '{"criminal":50}',

    -- Configuración de jugadores
    min_players INT NOT NULL DEFAULT 1,
    max_players INT NOT NULL DEFAULT 1,

    -- Dificultad
    difficulty ENUM('easy', 'medium', 'hard', 'extreme', 'legendary') NOT NULL DEFAULT 'medium',
    estimated_time INT NULL COMMENT 'Tiempo estimado en minutos',

    -- Datos de la misión
    data JSON NOT NULL COMMENT 'Configuración específica de la misión',
    objectives JSON NOT NULL COMMENT '[{"id":"obj1","type":"goto","label":"Ir al punto","data":{}}]',

    -- Recompensas base
    rewards JSON NOT NULL COMMENT '{"cash":1000,"xp":50,"items":[]}',

    -- Visual
    blip_sprite INT NULL,
    blip_color INT NULL,
    image VARCHAR(255) NULL,

    -- Disponibilidad
    available_from DATETIME NULL COMMENT 'Fecha desde que está disponible',
    available_until DATETIME NULL COMMENT 'Fecha hasta que está disponible',
    active TINYINT(1) NOT NULL DEFAULT 1,

    -- Pesos para selección aleatoria
    weight INT NOT NULL DEFAULT 100 COMMENT 'Peso para selección aleatoria',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY idx_name (name),
    KEY idx_type (type),
    KEY idx_category (category),
    KEY idx_difficulty (difficulty),
    KEY idx_faction (required_faction),
    KEY idx_active (active),
    KEY idx_repeatable (repeatable)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- INSTANCIAS DE MISIONES
-- Misiones activas o completadas
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_missions (
    mission_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    -- Referencia a la definición (puede ser null para misiones dinámicas)
    mission_def_id BIGINT NULL,

    -- Identificador de la misión
    name VARCHAR(64) NOT NULL COMMENT 'Nombre/identificador de la misión',
    label VARCHAR(128) NOT NULL,

    -- Tipo
    type ENUM('daily', 'weekly', 'story', 'side', 'faction', 'event', 'contract', 'heist', 'delivery', 'collection') NOT NULL,

    -- Estado actual
    status ENUM('pending', 'active', 'completed', 'failed', 'expired', 'cancelled') NOT NULL DEFAULT 'pending',

    -- Datos dinámicos de la instancia
    data JSON NULL COMMENT 'Datos específicos de esta instancia',

    -- Objetivos con su estado
    objectives JSON NULL COMMENT '[{"id":"obj1","completed":false,"progress":0,"max":10}]',

    -- Recompensas (pueden ser modificadas respecto al template)
    rewards JSON NULL COMMENT '{"cash":1000,"xp":50,"items":[]}',

    -- Jugador/Grupo que inició la misión
    owner_char_id BIGINT NULL COMMENT 'Personaje que inició/posee la misión',
    group_id BIGINT NULL COMMENT 'ID del grupo si es misión grupal',

    -- Facción (si es misión de facción)
    faction_id BIGINT NULL,

    -- Tiempo
    started_at DATETIME NULL,
    completed_at DATETIME NULL,
    expires_at DATETIME NULL COMMENT 'Tiempo límite para completar',

    -- Ubicaciones
    start_location JSON NULL COMMENT '{"x":0,"y":0,"z":0}',
    current_location JSON NULL,

    -- Estadísticas de la instancia
    attempts INT NOT NULL DEFAULT 0,
    time_spent INT NOT NULL DEFAULT 0 COMMENT 'Segundos en la misión',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    meta JSON NULL,

    KEY idx_def (mission_def_id),
    KEY idx_name (name),
    KEY idx_type (type),
    KEY idx_status (status),
    KEY idx_owner (owner_char_id),
    KEY idx_group (group_id),
    KEY idx_faction (faction_id),
    KEY idx_expires (expires_at),
    KEY idx_started (started_at),

    FOREIGN KEY (mission_def_id) REFERENCES ait_mission_definitions(mission_def_id) ON DELETE SET NULL,
    FOREIGN KEY (faction_id) REFERENCES ait_factions(faction_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- PROGRESO DE MISIONES
-- Progreso individual de cada jugador en misiones
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_mission_progress (
    progress_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    char_id BIGINT NOT NULL,
    mission_id BIGINT NOT NULL,

    -- Rol en la misión (para misiones grupales)
    role ENUM('leader', 'member', 'support') NOT NULL DEFAULT 'member',

    -- Progreso individual
    progress JSON NULL COMMENT '{"objectives":{"obj1":{"current":5,"max":10}},"checkpoints":[]}',

    -- Estado del jugador en la misión
    status ENUM('active', 'completed', 'failed', 'left', 'kicked') NOT NULL DEFAULT 'active',

    -- Contribución (para reparto de recompensas)
    contribution FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Porcentaje de contribución (0-100)',

    -- Recompensas recibidas
    rewards_claimed TINYINT(1) NOT NULL DEFAULT 0,
    rewards_received JSON NULL COMMENT 'Lo que realmente recibió',

    -- Tiempo
    joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    left_at DATETIME NULL,

    -- Estadísticas individuales
    kills INT NOT NULL DEFAULT 0,
    deaths INT NOT NULL DEFAULT 0,
    damage_dealt INT NOT NULL DEFAULT 0,
    items_collected INT NOT NULL DEFAULT 0,

    meta JSON NULL,

    UNIQUE KEY idx_char_mission (char_id, mission_id),
    KEY idx_mission (mission_id),
    KEY idx_char (char_id),
    KEY idx_status (status),
    KEY idx_role (role),

    FOREIGN KEY (char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE,
    FOREIGN KEY (mission_id) REFERENCES ait_missions(mission_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- HISTORIAL DE MISIONES COMPLETADAS
-- Registro histórico de misiones completadas por personaje
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_mission_history (
    history_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    char_id BIGINT NOT NULL,
    mission_name VARCHAR(64) NOT NULL COMMENT 'Nombre de la misión (por si se elimina la definición)',
    mission_def_id BIGINT NULL,

    -- Resultado
    result ENUM('completed', 'failed', 'abandoned') NOT NULL,

    -- Tiempo
    started_at DATETIME NOT NULL,
    ended_at DATETIME NOT NULL,
    duration INT NOT NULL COMMENT 'Segundos',

    -- Recompensas obtenidas
    rewards_received JSON NULL,

    -- Estadísticas
    stats JSON NULL COMMENT '{"kills":5,"deaths":1,"contribution":75}',

    -- Fue en grupo?
    was_group TINYINT(1) NOT NULL DEFAULT 0,
    group_size INT NULL,

    KEY idx_char (char_id),
    KEY idx_mission (mission_name),
    KEY idx_def (mission_def_id),
    KEY idx_result (result),
    KEY idx_ended (ended_at),

    FOREIGN KEY (char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE,
    FOREIGN KEY (mission_def_id) REFERENCES ait_mission_definitions(mission_def_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- MISIONES DIARIAS/SEMANALES
-- Asignación de misiones diarias/semanales a jugadores
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_daily_missions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    char_id BIGINT NOT NULL,

    mission_type ENUM('daily', 'weekly') NOT NULL,
    mission_def_id BIGINT NOT NULL,

    -- Estado
    completed TINYINT(1) NOT NULL DEFAULT 0,
    completed_at DATETIME NULL,

    -- Progreso
    progress JSON NULL COMMENT '{"current":3,"max":5}',

    -- Período
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,

    -- Slot (máx 3 diarias, 1 semanal)
    slot INT NOT NULL,

    -- Recompensas
    bonus_multiplier FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Multiplicador de racha',

    UNIQUE KEY idx_char_type_slot (char_id, mission_type, slot, assigned_at),
    KEY idx_char (char_id),
    KEY idx_def (mission_def_id),
    KEY idx_expires (expires_at),
    KEY idx_completed (completed),

    FOREIGN KEY (char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE,
    FOREIGN KEY (mission_def_id) REFERENCES ait_mission_definitions(mission_def_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- LOGS DE MISIONES
-- Historial de eventos de misiones para depuración
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_mission_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    mission_id BIGINT NOT NULL,
    char_id BIGINT NULL,

    event ENUM(
        'started', 'completed', 'failed', 'expired', 'cancelled',
        'objective_progress', 'objective_completed',
        'player_joined', 'player_left', 'player_kicked',
        'checkpoint_reached', 'reward_claimed',
        'error', 'debug'
    ) NOT NULL,

    details TEXT NULL,
    data JSON NULL,

    KEY idx_ts (ts),
    KEY idx_mission (mission_id),
    KEY idx_char (char_id),
    KEY idx_event (event),

    FOREIGN KEY (mission_id) REFERENCES ait_missions(mission_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CATEGORÍAS DE MISIONES
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_mission_categories (
    category VARCHAR(64) PRIMARY KEY,
    label VARCHAR(128) NOT NULL,
    description TEXT NULL,
    icon VARCHAR(64) NULL,
    color VARCHAR(7) NULL,
    sort_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO ait_mission_categories (category, label, icon, color, sort_order) VALUES
('general', 'General', 'fa-tasks', '#FFFFFF', 1),
('combat', 'Combate', 'fa-crosshairs', '#FF4444', 2),
('delivery', 'Entregas', 'fa-truck', '#44FF44', 3),
('collection', 'Recolección', 'fa-box', '#FFAA00', 4),
('stealth', 'Sigilo', 'fa-user-secret', '#AA44FF', 5),
('heist', 'Atracos', 'fa-mask', '#FF0000', 6),
('racing', 'Carreras', 'fa-flag-checkered', '#00AAFF', 7),
('faction', 'Facción', 'fa-users', '#0066FF', 8),
('event', 'Eventos', 'fa-star', '#FFD700', 9);

-- ───────────────────────────────────────────────────────────────────────────────────────
-- MISIONES DE EJEMPLO
-- ───────────────────────────────────────────────────────────────────────────────────────

INSERT INTO ait_mission_definitions (name, label, description, type, category, difficulty, min_players, max_players, data, objectives, rewards, repeatable, cooldown) VALUES
('daily_delivery_food', 'Entrega de Comida', 'Entrega pedidos de comida a los clientes', 'daily', 'delivery', 'easy', 1, 1,
 '{"vehicle":"faggio","pickup_zones":["downtown","beach"],"delivery_count":5}',
 '[{"id":"deliver","type":"delivery","label":"Entregar pedidos","target":5}]',
 '{"cash":500,"xp":25}',
 1, 3600),

('daily_collect_materials', 'Recolección de Materiales', 'Recoge materiales de construcción', 'daily', 'collection', 'easy', 1, 1,
 '{"item":"scrap_metal","locations":["junkyard","construction"]}',
 '[{"id":"collect","type":"collect","label":"Recoger chatarra","target":20}]',
 '{"cash":300,"xp":15,"items":[{"name":"scrap_metal","amount":5}]}',
 1, 3600),

('heist_fleeca', 'Atraco al Fleeca', 'Roba el banco Fleeca con tu equipo', 'heist', 'heist', 'hard', 2, 4,
 '{"bank":"fleeca_downtown","hack_difficulty":3,"drill_time":120}',
 '[{"id":"scout","type":"goto","label":"Reconocer el banco"},{"id":"hack","type":"minigame","label":"Hackear la seguridad"},{"id":"drill","type":"timer","label":"Abrir la caja fuerte"},{"id":"escape","type":"goto","label":"Escapar"}]',
 '{"cash":25000,"xp":500}',
 1, 86400);
