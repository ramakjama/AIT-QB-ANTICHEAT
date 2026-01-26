-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb DATABASE SCHEMA V1.0
-- Migration 004: Factions System
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────────
-- FACCIONES
-- Organizaciones del servidor (policía, EMS, bandas, empresas, etc.)
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_factions (
    faction_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(64) NOT NULL COMMENT 'Identificador único (ej: police, ambulance)',
    label VARCHAR(128) NOT NULL COMMENT 'Nombre mostrado',
    description TEXT NULL,

    -- Tipo de facción
    type ENUM('government', 'emergency', 'gang', 'mafia', 'business', 'neutral', 'illegal', 'legal') NOT NULL DEFAULT 'neutral',

    -- Finanzas
    treasury BIGINT NOT NULL DEFAULT 0 COMMENT 'Fondos de la facción',
    treasury_limit BIGINT NULL COMMENT 'Límite máximo de fondos',
    salary_account_id BIGINT NULL COMMENT 'Cuenta de donde salen los salarios',

    -- Jerarquía de rangos
    ranks JSON NOT NULL COMMENT '[{"grade":0,"name":"Recluta","salary":100,"permissions":[]},...]',

    -- Configuración
    max_members INT NULL COMMENT 'Límite de miembros',
    recruitment ENUM('open', 'invite', 'closed', 'application') NOT NULL DEFAULT 'invite',
    is_gang TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si es una organización criminal',

    -- Territorio y ubicaciones
    headquarters JSON NULL COMMENT '{"x":0,"y":0,"z":0,"heading":0}',
    territory JSON NULL COMMENT 'Zona de influencia',
    spawn_points JSON NULL COMMENT 'Puntos de spawn para miembros',

    -- Visual
    color VARCHAR(7) NULL COMMENT 'Color HEX',
    logo VARCHAR(255) NULL COMMENT 'URL o ruta del logo',
    blip_sprite INT NULL COMMENT 'Sprite del blip en mapa',
    blip_color INT NULL COMMENT 'Color del blip',

    -- Discord
    discord_role_id VARCHAR(32) NULL COMMENT 'ID del rol de Discord',
    discord_webhook VARCHAR(255) NULL COMMENT 'Webhook para notificaciones',

    -- Estado
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Metadata
    meta JSON NULL,

    UNIQUE KEY idx_name (name),
    KEY idx_type (type),
    KEY idx_active (active),
    KEY idx_is_gang (is_gang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- MIEMBROS DE FACCIÓN
-- Relación entre personajes y facciones
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_faction_members (
    member_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    char_id BIGINT NOT NULL,
    faction_id BIGINT NOT NULL,

    -- Rango (grade del JSON de ranks)
    rank INT NOT NULL DEFAULT 0 COMMENT 'Nivel/grado dentro de la facción',
    rank_name VARCHAR(64) NULL COMMENT 'Nombre del rango (cache)',

    -- Salario
    salary INT NOT NULL DEFAULT 0 COMMENT 'Salario personalizado (0 = usar default del rango)',
    last_salary_at DATETIME NULL COMMENT 'Última vez que recibió salario',

    -- Permisos adicionales (además de los del rango)
    extra_permissions JSON NULL COMMENT 'Permisos extra específicos del miembro',

    -- Estado
    status ENUM('active', 'suspended', 'on_leave', 'probation') NOT NULL DEFAULT 'active',
    suspended_reason TEXT NULL,
    suspended_until DATETIME NULL,

    -- Actividad
    joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    promoted_at DATETIME NULL COMMENT 'Última promoción',
    last_active DATETIME NULL COMMENT 'Última actividad en la facción',

    -- Estadísticas
    total_earned BIGINT NOT NULL DEFAULT 0 COMMENT 'Total ganado en la facción',
    tasks_completed INT NOT NULL DEFAULT 0,
    reputation INT NOT NULL DEFAULT 0 COMMENT 'Reputación dentro de la facción',

    -- Quién lo reclutó
    recruited_by BIGINT NULL COMMENT 'char_id del reclutador',

    meta JSON NULL,

    UNIQUE KEY idx_char_faction (char_id, faction_id),
    KEY idx_faction (faction_id),
    KEY idx_rank (faction_id, rank),
    KEY idx_status (status),
    KEY idx_joined (joined_at),

    FOREIGN KEY (char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE,
    FOREIGN KEY (faction_id) REFERENCES ait_factions(faction_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- LOGS DE FACCIÓN
-- Historial de acciones dentro de las facciones
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_faction_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    faction_id BIGINT NOT NULL,

    -- Quién realizó la acción
    actor_char_id BIGINT NULL,
    actor_name VARCHAR(128) NULL COMMENT 'Nombre del actor (para cuando se elimina)',

    -- Objetivo de la acción (si aplica)
    target_char_id BIGINT NULL,
    target_name VARCHAR(128) NULL,

    -- Tipo de acción
    action ENUM(
        'hire', 'fire', 'promote', 'demote', 'suspend', 'unsuspend',
        'deposit', 'withdraw', 'salary_pay',
        'settings_change', 'rank_create', 'rank_update', 'rank_delete',
        'permission_grant', 'permission_revoke',
        'announcement', 'duty_on', 'duty_off',
        'vehicle_spawn', 'vehicle_store',
        'other'
    ) NOT NULL,

    -- Detalles
    details TEXT NULL,
    old_value JSON NULL COMMENT 'Valor anterior',
    new_value JSON NULL COMMENT 'Valor nuevo',

    -- Contexto adicional
    ip_address VARCHAR(64) NULL,
    meta JSON NULL,

    KEY idx_ts (ts),
    KEY idx_faction (faction_id),
    KEY idx_actor (actor_char_id),
    KEY idx_target (target_char_id),
    KEY idx_action (action),
    KEY idx_faction_ts (faction_id, ts),

    FOREIGN KEY (faction_id) REFERENCES ait_factions(faction_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- PERMISOS DE FACCIÓN
-- Definición de permisos disponibles para las facciones
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_faction_permissions (
    permission VARCHAR(64) PRIMARY KEY,
    label VARCHAR(128) NOT NULL,
    description TEXT NULL,
    category VARCHAR(64) NOT NULL DEFAULT 'general',

    KEY idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar permisos por defecto
INSERT INTO ait_faction_permissions (permission, label, description, category) VALUES
-- Gestión de miembros
('hire', 'Contratar', 'Puede reclutar nuevos miembros', 'members'),
('fire', 'Despedir', 'Puede despedir miembros', 'members'),
('promote', 'Promover', 'Puede promover miembros', 'members'),
('demote', 'Degradar', 'Puede degradar miembros', 'members'),
('suspend', 'Suspender', 'Puede suspender miembros', 'members'),
('view_members', 'Ver Miembros', 'Puede ver la lista de miembros', 'members'),

-- Finanzas
('treasury_view', 'Ver Tesorería', 'Puede ver el balance', 'treasury'),
('treasury_deposit', 'Depositar', 'Puede depositar fondos', 'treasury'),
('treasury_withdraw', 'Retirar', 'Puede retirar fondos', 'treasury'),
('salary_pay', 'Pagar Salarios', 'Puede pagar salarios', 'treasury'),

-- Vehículos
('vehicle_spawn', 'Sacar Vehículos', 'Puede sacar vehículos de facción', 'vehicles'),
('vehicle_store', 'Guardar Vehículos', 'Puede guardar vehículos', 'vehicles'),
('vehicle_manage', 'Gestionar Vehículos', 'Puede comprar/vender vehículos', 'vehicles'),

-- Inventario
('stash_access', 'Acceso a Almacén', 'Puede acceder al almacén', 'inventory'),
('stash_manage', 'Gestionar Almacén', 'Puede gestionar el almacén', 'inventory'),
('armory_access', 'Acceso a Armería', 'Puede acceder a la armería', 'inventory'),

-- Administración
('settings_edit', 'Editar Configuración', 'Puede editar configuración', 'admin'),
('ranks_manage', 'Gestionar Rangos', 'Puede crear/editar rangos', 'admin'),
('announcements', 'Anuncios', 'Puede hacer anuncios', 'admin'),
('logs_view', 'Ver Logs', 'Puede ver historial', 'admin');

-- ───────────────────────────────────────────────────────────────────────────────────────
-- ANUNCIOS DE FACCIÓN
-- Sistema de comunicados internos
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_faction_announcements (
    announcement_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    faction_id BIGINT NOT NULL,
    author_char_id BIGINT NOT NULL,

    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,

    priority ENUM('low', 'normal', 'high', 'urgent') NOT NULL DEFAULT 'normal',
    pinned TINYINT(1) NOT NULL DEFAULT 0,

    visible_to_ranks JSON NULL COMMENT 'Rangos que pueden ver (null = todos)',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NULL,

    KEY idx_faction (faction_id),
    KEY idx_created (created_at),
    KEY idx_priority (priority),
    KEY idx_pinned (pinned),

    FOREIGN KEY (faction_id) REFERENCES ait_factions(faction_id) ON DELETE CASCADE,
    FOREIGN KEY (author_char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- VEHÍCULOS DE FACCIÓN
-- Vehículos propiedad de las facciones
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_faction_vehicles (
    vehicle_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    faction_id BIGINT NOT NULL,

    model VARCHAR(64) NOT NULL,
    plate VARCHAR(10) NOT NULL,

    min_rank INT NOT NULL DEFAULT 0 COMMENT 'Rango mínimo para usar',

    mods JSON NULL,
    livery INT NULL,

    spawned TINYINT(1) NOT NULL DEFAULT 0,
    spawned_by BIGINT NULL COMMENT 'char_id que lo sacó',
    spawned_at DATETIME NULL,

    fuel FLOAT NOT NULL DEFAULT 100.0,
    body_health FLOAT NOT NULL DEFAULT 1000.0,
    engine_health FLOAT NOT NULL DEFAULT 1000.0,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY idx_plate (plate),
    KEY idx_faction (faction_id),
    KEY idx_model (model),
    KEY idx_spawned (spawned),

    FOREIGN KEY (faction_id) REFERENCES ait_factions(faction_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- FACCIONES POR DEFECTO
-- ───────────────────────────────────────────────────────────────────────────────────────

INSERT INTO ait_factions (name, label, type, ranks, color, is_gang) VALUES
('police', 'Policía de Santabria', 'government',
 '[{"grade":0,"name":"Cadete","salary":500,"permissions":["view_members","vehicle_spawn","stash_access"]},
   {"grade":1,"name":"Oficial","salary":700,"permissions":["view_members","vehicle_spawn","stash_access","armory_access"]},
   {"grade":2,"name":"Sargento","salary":1000,"permissions":["view_members","vehicle_spawn","stash_access","armory_access","hire"]},
   {"grade":3,"name":"Teniente","salary":1500,"permissions":["view_members","vehicle_spawn","stash_access","armory_access","hire","fire","promote","demote"]},
   {"grade":4,"name":"Capitán","salary":2000,"permissions":["view_members","vehicle_spawn","stash_access","armory_access","hire","fire","promote","demote","treasury_view"]},
   {"grade":5,"name":"Comisario","salary":3000,"permissions":["hire","fire","promote","demote","suspend","view_members","treasury_view","treasury_deposit","treasury_withdraw","vehicle_spawn","vehicle_store","vehicle_manage","stash_access","stash_manage","armory_access","settings_edit","ranks_manage","announcements","logs_view"]}]',
 '#1E90FF', 0),

('ambulance', 'Servicio Médico de Emergencias', 'emergency',
 '[{"grade":0,"name":"Paramédico en Prácticas","salary":400,"permissions":["view_members","vehicle_spawn","stash_access"]},
   {"grade":1,"name":"Paramédico","salary":600,"permissions":["view_members","vehicle_spawn","stash_access"]},
   {"grade":2,"name":"Médico de Emergencias","salary":900,"permissions":["view_members","vehicle_spawn","stash_access","hire"]},
   {"grade":3,"name":"Médico Jefe","salary":1400,"permissions":["view_members","vehicle_spawn","stash_access","hire","fire","promote","demote"]},
   {"grade":4,"name":"Director Médico","salary":2500,"permissions":["hire","fire","promote","demote","suspend","view_members","treasury_view","treasury_deposit","treasury_withdraw","vehicle_spawn","vehicle_store","vehicle_manage","stash_access","stash_manage","settings_edit","ranks_manage","announcements","logs_view"]}]',
 '#FF4444', 0),

('mechanic', 'Taller Mecánico', 'business',
 '[{"grade":0,"name":"Aprendiz","salary":200,"permissions":["view_members","stash_access"]},
   {"grade":1,"name":"Mecánico","salary":400,"permissions":["view_members","stash_access"]},
   {"grade":2,"name":"Mecánico Senior","salary":600,"permissions":["view_members","stash_access","hire"]},
   {"grade":3,"name":"Jefe de Taller","salary":1000,"permissions":["hire","fire","promote","demote","view_members","treasury_view","treasury_deposit","treasury_withdraw","stash_access","stash_manage","announcements","logs_view"]}]',
 '#FFA500', 0);
