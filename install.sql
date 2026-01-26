-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB: Script de Instalación Completo
-- Ejecutar este archivo para crear todas las tablas necesarias
-- Compatible con MySQL 8.0+ y MariaDB 10.5+
-- ═══════════════════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- TABLAS BASE - JUGADORES Y PERSONAJES
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Tabla de jugadores (cuentas)
CREATE TABLE IF NOT EXISTS `ait_players` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `license` VARCHAR(60) DEFAULT NULL,
    `discord` VARCHAR(60) DEFAULT NULL,
    `steam` VARCHAR(60) DEFAULT NULL,
    `fivem` VARCHAR(60) DEFAULT NULL,
    `ip` VARCHAR(45) DEFAULT NULL,
    `tokens` JSON DEFAULT NULL,
    `first_join` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_join` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `playtime` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_banned` TINYINT(1) NOT NULL DEFAULT 0,
    `is_whitelisted` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`),
    KEY `idx_discord` (`discord`),
    KEY `idx_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de personajes
CREATE TABLE IF NOT EXISTS `ait_characters` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `player_identifier` VARCHAR(60) NOT NULL,
    `slot` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(50) NOT NULL,
    `date_of_birth` DATE NOT NULL,
    `gender` ENUM('male', 'female') NOT NULL DEFAULT 'male',
    `nationality` VARCHAR(50) NOT NULL DEFAULT 'Los Santos',
    `phone_number` VARCHAR(20) DEFAULT NULL,
    `cash` BIGINT NOT NULL DEFAULT 500,
    `bank` BIGINT NOT NULL DEFAULT 5000,
    `crypto` BIGINT NOT NULL DEFAULT 0,
    `job` JSON NOT NULL DEFAULT '{"name":"unemployed","label":"Desempleado","grade":0,"gradeName":"Desempleado"}',
    `gang` JSON DEFAULT '{"name":"none","label":"Sin Banda","grade":0}',
    `position` JSON NOT NULL DEFAULT '{"x":-269.4,"y":-955.3,"z":31.2,"w":205.8}',
    `metadata` JSON NOT NULL DEFAULT '{"hunger":100,"thirst":100,"stress":0,"health":200,"armor":0,"isDead":false}',
    `skin` JSON DEFAULT NULL,
    `stats` JSON DEFAULT '{"playTime":0,"deaths":0,"kills":0}',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_played` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `player_slot` (`player_identifier`, `slot`),
    KEY `idx_player` (`player_identifier`),
    KEY `idx_phone` (`phone_number`),
    CONSTRAINT `fk_char_player` FOREIGN KEY (`player_identifier`) REFERENCES `ait_players` (`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ECONOMÍA
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Cuentas bancarias
CREATE TABLE IF NOT EXISTS `ait_bank_accounts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_number` VARCHAR(20) NOT NULL,
    `account_type` ENUM('personal', 'business', 'faction', 'shared') NOT NULL DEFAULT 'personal',
    `owner_type` ENUM('character', 'faction', 'business') NOT NULL DEFAULT 'character',
    `owner_id` INT UNSIGNED NOT NULL,
    `balance` BIGINT NOT NULL DEFAULT 0,
    `is_frozen` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `account_number` (`account_number`),
    KEY `idx_owner` (`owner_type`, `owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transacciones (ledger de doble entrada)
CREATE TABLE IF NOT EXISTS `ait_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `transaction_id` VARCHAR(36) NOT NULL,
    `type` ENUM('deposit', 'withdraw', 'transfer', 'payment', 'salary', 'purchase', 'sale', 'fine', 'tax', 'refund') NOT NULL,
    `from_type` ENUM('character', 'faction', 'business', 'system') NOT NULL,
    `from_id` INT UNSIGNED DEFAULT NULL,
    `to_type` ENUM('character', 'faction', 'business', 'system') NOT NULL,
    `to_id` INT UNSIGNED DEFAULT NULL,
    `amount` BIGINT NOT NULL,
    `currency` ENUM('cash', 'bank', 'crypto') NOT NULL DEFAULT 'bank',
    `description` VARCHAR(255) DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `transaction_id` (`transaction_id`),
    KEY `idx_from` (`from_type`, `from_id`),
    KEY `idx_to` (`to_type`, `to_id`),
    KEY `idx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Facturas
CREATE TABLE IF NOT EXISTS `ait_invoices` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_number` VARCHAR(20) NOT NULL,
    `from_type` ENUM('character', 'faction', 'business') NOT NULL,
    `from_id` INT UNSIGNED NOT NULL,
    `to_character_id` INT UNSIGNED NOT NULL,
    `amount` BIGINT NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `status` ENUM('pending', 'paid', 'cancelled', 'expired') NOT NULL DEFAULT 'pending',
    `due_date` DATETIME DEFAULT NULL,
    `paid_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `invoice_number` (`invoice_number`),
    KEY `idx_to` (`to_character_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INVENTARIO
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Items de personajes
CREATE TABLE IF NOT EXISTS `ait_inventory` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `character_id` INT UNSIGNED NOT NULL,
    `item_name` VARCHAR(50) NOT NULL,
    `amount` INT UNSIGNED NOT NULL DEFAULT 1,
    `slot` TINYINT UNSIGNED NOT NULL,
    `metadata` JSON DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `char_slot` (`character_id`, `slot`),
    KEY `idx_item` (`item_name`),
    CONSTRAINT `fk_inv_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stashes (almacenes)
CREATE TABLE IF NOT EXISTS `ait_stashes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `stash_id` VARCHAR(100) NOT NULL,
    `stash_type` ENUM('personal', 'property', 'vehicle', 'faction', 'shared') NOT NULL DEFAULT 'personal',
    `owner_id` INT UNSIGNED DEFAULT NULL,
    `max_weight` INT UNSIGNED NOT NULL DEFAULT 100000,
    `max_slots` TINYINT UNSIGNED NOT NULL DEFAULT 50,
    `items` JSON DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `stash_id` (`stash_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- VEHÍCULOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Vehículos de jugadores
CREATE TABLE IF NOT EXISTS `ait_vehicles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(10) NOT NULL,
    `vin` VARCHAR(17) NOT NULL,
    `owner_id` INT UNSIGNED NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `model_hash` BIGINT DEFAULT NULL,
    `garage` VARCHAR(50) NOT NULL DEFAULT 'public_pillbox',
    `state` ENUM('garaged', 'out', 'impounded') NOT NULL DEFAULT 'garaged',
    `fuel` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `body_health` FLOAT NOT NULL DEFAULT 1000.0,
    `engine_health` FLOAT NOT NULL DEFAULT 1000.0,
    `mods` JSON DEFAULT NULL,
    `extras` JSON DEFAULT NULL,
    `position` JSON DEFAULT NULL,
    `impound_reason` VARCHAR(255) DEFAULT NULL,
    `impound_fee` INT UNSIGNED DEFAULT NULL,
    `impound_date` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    UNIQUE KEY `vin` (`vin`),
    KEY `idx_owner` (`owner_id`),
    KEY `idx_garage` (`garage`),
    KEY `idx_state` (`state`),
    CONSTRAINT `fk_veh_owner` FOREIGN KEY (`owner_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Llaves de vehículos
CREATE TABLE IF NOT EXISTS `ait_vehicle_keys` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `character_id` INT UNSIGNED NOT NULL,
    `key_type` ENUM('owner', 'copy', 'temporary') NOT NULL DEFAULT 'copy',
    `expires_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `veh_char` (`vehicle_id`, `character_id`),
    CONSTRAINT `fk_key_veh` FOREIGN KEY (`vehicle_id`) REFERENCES `ait_vehicles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_key_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- PROPIEDADES (HOUSING)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Propiedades disponibles
CREATE TABLE IF NOT EXISTS `ait_properties` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `property_id` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` ENUM('house', 'apartment', 'garage', 'warehouse', 'business') NOT NULL DEFAULT 'house',
    `tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `price` INT UNSIGNED NOT NULL,
    `rent_price` INT UNSIGNED DEFAULT NULL,
    `owner_id` INT UNSIGNED DEFAULT NULL,
    `coords_enter` JSON NOT NULL,
    `coords_exit` JSON NOT NULL,
    `interior` VARCHAR(50) DEFAULT NULL,
    `max_storage` INT UNSIGNED NOT NULL DEFAULT 100000,
    `garage_slots` TINYINT UNSIGNED DEFAULT NULL,
    `is_locked` TINYINT(1) NOT NULL DEFAULT 1,
    `is_for_sale` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `property_id` (`property_id`),
    KEY `idx_owner` (`owner_id`),
    KEY `idx_type` (`type`),
    KEY `idx_for_sale` (`is_for_sale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Accesos a propiedades
CREATE TABLE IF NOT EXISTS `ait_property_access` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `property_id` INT UNSIGNED NOT NULL,
    `character_id` INT UNSIGNED NOT NULL,
    `access_level` ENUM('visitor', 'resident', 'co-owner') NOT NULL DEFAULT 'visitor',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `prop_char` (`property_id`, `character_id`),
    CONSTRAINT `fk_acc_prop` FOREIGN KEY (`property_id`) REFERENCES `ait_properties` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Muebles de propiedades
CREATE TABLE IF NOT EXISTS `ait_property_furniture` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `property_id` INT UNSIGNED NOT NULL,
    `furniture_id` VARCHAR(50) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `position` JSON NOT NULL,
    `rotation` JSON NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_property` (`property_id`),
    CONSTRAINT `fk_furn_prop` FOREIGN KEY (`property_id`) REFERENCES `ait_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FACCIONES Y TRABAJOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Facciones/Trabajos
CREATE TABLE IF NOT EXISTS `ait_factions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` ENUM('job', 'gang', 'organization') NOT NULL DEFAULT 'job',
    `is_public` TINYINT(1) NOT NULL DEFAULT 1,
    `is_legal` TINYINT(1) NOT NULL DEFAULT 1,
    `account_balance` BIGINT NOT NULL DEFAULT 0,
    `headquarters` JSON DEFAULT NULL,
    `settings` JSON DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Rangos de facciones
CREATE TABLE IF NOT EXISTS `ait_faction_ranks` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `faction_id` INT UNSIGNED NOT NULL,
    `grade` TINYINT UNSIGNED NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `salary` INT UNSIGNED NOT NULL DEFAULT 0,
    `permissions` JSON DEFAULT NULL,
    `is_boss` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `faction_grade` (`faction_id`, `grade`),
    CONSTRAINT `fk_rank_faction` FOREIGN KEY (`faction_id`) REFERENCES `ait_factions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Miembros de facciones
CREATE TABLE IF NOT EXISTS `ait_faction_members` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `faction_id` INT UNSIGNED NOT NULL,
    `character_id` INT UNSIGNED NOT NULL,
    `rank_grade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_on_duty` TINYINT(1) NOT NULL DEFAULT 0,
    `duty_time` INT UNSIGNED NOT NULL DEFAULT 0,
    `joined_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `faction_char` (`faction_id`, `character_id`),
    CONSTRAINT `fk_mem_faction` FOREIGN KEY (`faction_id`) REFERENCES `ait_factions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mem_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MISIONES
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Misiones activas
CREATE TABLE IF NOT EXISTS `ait_missions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mission_id` VARCHAR(50) NOT NULL,
    `character_id` INT UNSIGNED NOT NULL,
    `type` ENUM('delivery', 'collect', 'hunt', 'escort', 'race', 'custom') NOT NULL,
    `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `status` ENUM('active', 'completed', 'failed', 'abandoned') NOT NULL DEFAULT 'active',
    `objectives` JSON NOT NULL,
    `progress` JSON DEFAULT NULL,
    `rewards` JSON NOT NULL,
    `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` DATETIME DEFAULT NULL,
    `expires_at` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_char` (`character_id`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_mis_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Historial de misiones
CREATE TABLE IF NOT EXISTS `ait_mission_history` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `character_id` INT UNSIGNED NOT NULL,
    `mission_type` VARCHAR(50) NOT NULL,
    `difficulty` TINYINT UNSIGNED NOT NULL,
    `result` ENUM('completed', 'failed', 'abandoned') NOT NULL,
    `rewards_earned` JSON DEFAULT NULL,
    `duration` INT UNSIGNED DEFAULT NULL,
    `completed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_char` (`character_id`),
    KEY `idx_type` (`mission_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- JUSTICIA
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Antecedentes penales
CREATE TABLE IF NOT EXISTS `ait_criminal_records` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `character_id` INT UNSIGNED NOT NULL,
    `officer_id` INT UNSIGNED DEFAULT NULL,
    `charge` VARCHAR(100) NOT NULL,
    `fine` INT UNSIGNED DEFAULT NULL,
    `jail_time` INT UNSIGNED DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_char` (`character_id`),
    KEY `idx_officer` (`officer_id`),
    CONSTRAINT `fk_rec_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Búsqueda y captura
CREATE TABLE IF NOT EXISTS `ait_wanted` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `character_id` INT UNSIGNED NOT NULL,
    `wanted_level` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `reason` VARCHAR(255) NOT NULL,
    `issuer_id` INT UNSIGNED DEFAULT NULL,
    `expires_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_char` (`character_id`),
    CONSTRAINT `fk_want_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sentencias de cárcel
CREATE TABLE IF NOT EXISTS `ait_jail` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `character_id` INT UNSIGNED NOT NULL,
    `time_remaining` INT UNSIGNED NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `officer_id` INT UNSIGNED DEFAULT NULL,
    `jailed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_char` (`character_id`),
    CONSTRAINT `fk_jail_char` FOREIGN KEY (`character_id`) REFERENCES `ait_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ADMINISTRACIÓN Y LOGS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Bans
CREATE TABLE IF NOT EXISTS `ait_bans` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `banned_by` VARCHAR(100) DEFAULT NULL,
    `expires_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Whitelist
CREATE TABLE IF NOT EXISTS `ait_whitelist` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `discord` VARCHAR(60) DEFAULT NULL,
    `added_by` VARCHAR(100) DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Logs de auditoría
CREATE TABLE IF NOT EXISTS `ait_audit_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `action` VARCHAR(100) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `source_type` ENUM('player', 'character', 'system', 'admin') NOT NULL,
    `source_id` VARCHAR(60) DEFAULT NULL,
    `target_type` VARCHAR(50) DEFAULT NULL,
    `target_id` VARCHAR(60) DEFAULT NULL,
    `details` JSON DEFAULT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_action` (`action`),
    KEY `idx_category` (`category`),
    KEY `idx_source` (`source_type`, `source_id`),
    KEY `idx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permisos de admin
CREATE TABLE IF NOT EXISTS `ait_admin_permissions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `permission_group` VARCHAR(50) NOT NULL DEFAULT 'mod',
    `permissions` JSON DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FEATURE FLAGS
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `ait_feature_flags` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `config` JSON DEFAULT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- DATOS INICIALES (SEEDS)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Feature flags por defecto
INSERT INTO `ait_feature_flags` (`name`, `enabled`) VALUES
    ('economy', 1),
    ('inventory', 1),
    ('vehicles', 1),
    ('housing', 1),
    ('factions', 1),
    ('missions', 1),
    ('events', 1),
    ('combat', 1),
    ('justice', 1),
    ('ai', 1),
    ('marketplace', 0),
    ('crypto', 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Facciones/Trabajos por defecto
INSERT INTO `ait_factions` (`name`, `label`, `type`, `is_public`, `is_legal`) VALUES
    ('police', 'Policía de Los Santos', 'job', 0, 1),
    ('ambulance', 'Servicios Médicos', 'job', 0, 1),
    ('mechanic', 'Mecánicos LS Customs', 'job', 1, 1),
    ('taxi', 'Taxis Downtown', 'job', 1, 1),
    ('trucker', 'Camioneros de San Andreas', 'job', 1, 1),
    ('garbage', 'Recogida de Basuras', 'job', 1, 1),
    ('realestate', 'Inmobiliaria Dynasty', 'job', 0, 1),
    ('cardealer', 'Premium Deluxe Motorsport', 'job', 0, 1),
    ('vagos', 'Los Vagos', 'gang', 0, 0),
    ('ballas', 'Ballas', 'gang', 0, 0),
    ('families', 'Grove Street Families', 'gang', 0, 0),
    ('marabunta', 'Marabunta Grande', 'gang', 0, 0)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- Rangos de policía
INSERT INTO `ait_faction_ranks` (`faction_id`, `grade`, `name`, `label`, `salary`, `is_boss`) VALUES
    ((SELECT id FROM ait_factions WHERE name = 'police'), 0, 'cadet', 'Cadete', 500, 0),
    ((SELECT id FROM ait_factions WHERE name = 'police'), 1, 'officer', 'Oficial', 750, 0),
    ((SELECT id FROM ait_factions WHERE name = 'police'), 2, 'sergeant', 'Sargento', 1000, 0),
    ((SELECT id FROM ait_factions WHERE name = 'police'), 3, 'lieutenant', 'Teniente', 1250, 0),
    ((SELECT id FROM ait_factions WHERE name = 'police'), 4, 'captain', 'Capitán', 1500, 0),
    ((SELECT id FROM ait_factions WHERE name = 'police'), 5, 'chief', 'Jefe de Policía', 2000, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- Rangos de EMS
INSERT INTO `ait_faction_ranks` (`faction_id`, `grade`, `name`, `label`, `salary`, `is_boss`) VALUES
    ((SELECT id FROM ait_factions WHERE name = 'ambulance'), 0, 'trainee', 'Aprendiz', 400, 0),
    ((SELECT id FROM ait_factions WHERE name = 'ambulance'), 1, 'emt', 'Técnico Emergencias', 600, 0),
    ((SELECT id FROM ait_factions WHERE name = 'ambulance'), 2, 'paramedic', 'Paramédico', 800, 0),
    ((SELECT id FROM ait_factions WHERE name = 'ambulance'), 3, 'doctor', 'Doctor', 1000, 0),
    ((SELECT id FROM ait_factions WHERE name = 'ambulance'), 4, 'surgeon', 'Cirujano', 1200, 0),
    ((SELECT id FROM ait_factions WHERE name = 'ambulance'), 5, 'chief', 'Director Médico', 1500, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- Rangos de mecánico
INSERT INTO `ait_faction_ranks` (`faction_id`, `grade`, `name`, `label`, `salary`, `is_boss`) VALUES
    ((SELECT id FROM ait_factions WHERE name = 'mechanic'), 0, 'trainee', 'Aprendiz', 300, 0),
    ((SELECT id FROM ait_factions WHERE name = 'mechanic'), 1, 'mechanic', 'Mecánico', 500, 0),
    ((SELECT id FROM ait_factions WHERE name = 'mechanic'), 2, 'senior', 'Mecánico Senior', 700, 0),
    ((SELECT id FROM ait_factions WHERE name = 'mechanic'), 3, 'manager', 'Encargado', 900, 0),
    ((SELECT id FROM ait_factions WHERE name = 'mechanic'), 4, 'boss', 'Jefe de Taller', 1200, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- Propiedades de ejemplo
INSERT INTO `ait_properties` (`property_id`, `label`, `type`, `tier`, `price`, `rent_price`, `coords_enter`, `coords_exit`, `interior`) VALUES
    ('apartment_1', 'Apartamento Vinewood 1', 'apartment', 1, 50000, 500, '{"x":-1452.56,"y":-540.73,"z":34.74}', '{"x":-1452.0,"y":-540.0,"z":34.74}', 'low_end_1'),
    ('apartment_2', 'Apartamento Vinewood 2', 'apartment', 2, 100000, 1000, '{"x":-1453.56,"y":-541.73,"z":34.74}', '{"x":-1453.0,"y":-541.0,"z":34.74}', 'mid_end_1'),
    ('house_1', 'Casa Grove Street', 'house', 2, 150000, 1500, '{"x":-14.56,"y":-1438.73,"z":31.10}', '{"x":-14.0,"y":-1438.0,"z":31.10}', 'mid_end_2'),
    ('house_2', 'Mansión Vinewood Hills', 'house', 3, 500000, 5000, '{"x":-174.0,"y":497.0,"z":137.0}', '{"x":-174.0,"y":497.0,"z":137.0}', 'high_end_1')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ANTICHEAT - SISTEMA DE PROTECCIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Tabla de baneos del anticheat
CREATE TABLE IF NOT EXISTS `ait_anticheat_bans` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ban_id` VARCHAR(20) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `reason` TEXT NOT NULL,
    `detection_type` VARCHAR(50) NOT NULL,
    `banned_by` VARCHAR(100) NOT NULL DEFAULT 'AIT-Anticheat',
    `ban_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expire_time` DATETIME DEFAULT NULL COMMENT 'NULL = permanente',
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `hardware_ids` JSON DEFAULT NULL,
    `evidence` JSON DEFAULT NULL COMMENT 'Screenshots, logs, etc.',
    `appeal_status` ENUM('none', 'pending', 'approved', 'denied') NOT NULL DEFAULT 'none',
    `appeal_notes` TEXT DEFAULT NULL,
    `unbanned_by` VARCHAR(100) DEFAULT NULL,
    `unbanned_at` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ban_id` (`ban_id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_active` (`active`),
    KEY `idx_expire` (`expire_time`),
    KEY `idx_detection` (`detection_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs del anticheat
CREATE TABLE IF NOT EXISTS `ait_anticheat_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `detection_type` VARCHAR(50) NOT NULL,
    `data` JSON NOT NULL,
    `severity` ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    `action_taken` VARCHAR(50) DEFAULT NULL,
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `server_id` VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_detection` (`detection_type`),
    KEY `idx_timestamp` (`timestamp`),
    KEY `idx_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de strikes (advertencias)
CREATE TABLE IF NOT EXISTS `ait_anticheat_strikes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `reason` TEXT NOT NULL,
    `detection_type` VARCHAR(50) NOT NULL,
    `strike_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expire_time` DATETIME NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_active` (`active`),
    KEY `idx_expire` (`expire_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de whitelist del anticheat
CREATE TABLE IF NOT EXISTS `ait_anticheat_whitelist` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(255) DEFAULT NULL,
    `reason` TEXT DEFAULT NULL,
    `added_by` VARCHAR(100) NOT NULL,
    `added_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de recursos bloqueados detectados
CREATE TABLE IF NOT EXISTS `ait_anticheat_blocked_resources` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `resource_name` VARCHAR(100) NOT NULL,
    `signature_matched` VARCHAR(100) NOT NULL,
    `detected_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `detected_count` INT UNSIGNED NOT NULL DEFAULT 1,
    `last_detected` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `resource_name` (`resource_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Procedimiento para limpiar logs antiguos
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS `sp_cleanup_anticheat_logs`(IN days_to_keep INT)
BEGIN
    DELETE FROM `ait_anticheat_logs` WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    DELETE FROM `ait_anticheat_strikes` WHERE `expire_time` < NOW();
END //
DELIMITER ;

-- Evento para limpieza automática (cada día a las 3 AM)
CREATE EVENT IF NOT EXISTS `evt_cleanup_anticheat`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 3 HOUR
DO CALL sp_cleanup_anticheat_logs(30);

SET FOREIGN_KEY_CHECKS = 1;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIN DE LA INSTALACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════
