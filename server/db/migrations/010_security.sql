-- ============================================================================
-- AIT-QB Migration 010: Sistema de Seguridad
-- Descripcion: Tablas para baneos, advertencias y registros de anticheat
-- Fecha: 2026-01-25
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: ait_bans
-- Descripcion: Registro de baneos de jugadores
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_bans` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico del baneo',
    `player_id` INT UNSIGNED NOT NULL COMMENT 'ID del jugador baneado',
    `license` VARCHAR(50) NULL COMMENT 'Identificador de licencia del jugador',
    `discord_id` VARCHAR(30) NULL COMMENT 'ID de Discord del jugador',
    `ip_address` VARCHAR(45) NULL COMMENT 'Direccion IP al momento del baneo',
    `hwid` VARCHAR(64) NULL COMMENT 'Hardware ID (si esta disponible)',
    `reason` TEXT NOT NULL COMMENT 'Razon del baneo',
    `evidence` TEXT NULL COMMENT 'Evidencia del baneo (enlaces, descripcion)',
    `ban_type` ENUM('temporary', 'permanent', 'global') NOT NULL DEFAULT 'temporary' COMMENT 'Tipo de baneo',
    `banned_by` INT UNSIGNED NULL COMMENT 'ID del admin que aplico el baneo',
    `banned_by_name` VARCHAR(100) NULL COMMENT 'Nombre del admin (respaldo)',
    `expires` DATETIME NULL COMMENT 'Fecha de expiracion (NULL=permanente)',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Indica si el baneo esta activo',
    `appeal_status` ENUM('none', 'pending', 'approved', 'denied') NOT NULL DEFAULT 'none' COMMENT 'Estado de apelacion',
    `appeal_reason` TEXT NULL COMMENT 'Razon de apelacion del jugador',
    `appeal_response` TEXT NULL COMMENT 'Respuesta a la apelacion',
    `appeal_handled_by` INT UNSIGNED NULL COMMENT 'Admin que manejo la apelacion',
    `unbanned_by` INT UNSIGNED NULL COMMENT 'Admin que levanto el baneo',
    `unbanned_at` DATETIME NULL COMMENT 'Fecha en que se levanto el baneo',
    `unban_reason` TEXT NULL COMMENT 'Razon del levantamiento',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha del baneo',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Ultima actualizacion',

    PRIMARY KEY (`id`),
    INDEX `idx_bans_player` (`player_id`),
    INDEX `idx_bans_license` (`license`),
    INDEX `idx_bans_discord` (`discord_id`),
    INDEX `idx_bans_ip` (`ip_address`),
    INDEX `idx_bans_hwid` (`hwid`),
    INDEX `idx_bans_active` (`is_active`),
    INDEX `idx_bans_expires` (`expires`),
    INDEX `idx_bans_type` (`ban_type`),
    INDEX `idx_bans_appeal` (`appeal_status`),
    INDEX `idx_bans_created` (`created_at`),

    -- Indice compuesto para verificacion rapida de baneo activo
    INDEX `idx_bans_active_check` (`player_id`, `is_active`, `expires`),
    INDEX `idx_bans_license_active` (`license`, `is_active`),
    INDEX `idx_bans_ip_active` (`ip_address`, `is_active`),

    CONSTRAINT `fk_bans_player`
        FOREIGN KEY (`player_id`)
        REFERENCES `ait_players` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_bans_banned_by`
        FOREIGN KEY (`banned_by`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `fk_bans_appeal_handler`
        FOREIGN KEY (`appeal_handled_by`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `fk_bans_unbanned_by`
        FOREIGN KEY (`unbanned_by`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de baneos de jugadores';

-- ----------------------------------------------------------------------------
-- Tabla: ait_warnings
-- Descripcion: Sistema de advertencias para jugadores
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_warnings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico de la advertencia',
    `player_id` INT UNSIGNED NOT NULL COMMENT 'ID del jugador advertido',
    `char_id` INT UNSIGNED NULL COMMENT 'ID del personaje (si aplica)',
    `warning_type` ENUM('verbal', 'written', 'final', 'system') NOT NULL DEFAULT 'written' COMMENT 'Tipo de advertencia',
    `category` VARCHAR(50) NOT NULL COMMENT 'Categoria de la infraccion (ej: RDM, VDM, Metagaming)',
    `reason` TEXT NOT NULL COMMENT 'Razon detallada de la advertencia',
    `evidence` TEXT NULL COMMENT 'Evidencia de la infraccion',
    `points` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Puntos de infraccion asignados',
    `issued_by` INT UNSIGNED NULL COMMENT 'ID del admin que emitio la advertencia',
    `issued_by_name` VARCHAR(100) NULL COMMENT 'Nombre del admin (respaldo)',
    `expires` DATETIME NULL COMMENT 'Fecha de expiracion de la advertencia',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Indica si la advertencia esta activa',
    `acknowledged` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Jugador reconocio la advertencia',
    `acknowledged_at` DATETIME NULL COMMENT 'Fecha de reconocimiento',
    `revoked_by` INT UNSIGNED NULL COMMENT 'Admin que revoco la advertencia',
    `revoked_at` DATETIME NULL COMMENT 'Fecha de revocacion',
    `revoke_reason` TEXT NULL COMMENT 'Razon de revocacion',
    `notes` TEXT NULL COMMENT 'Notas internas del staff',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de la advertencia',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Ultima actualizacion',

    PRIMARY KEY (`id`),
    INDEX `idx_warnings_player` (`player_id`),
    INDEX `idx_warnings_char` (`char_id`),
    INDEX `idx_warnings_type` (`warning_type`),
    INDEX `idx_warnings_category` (`category`),
    INDEX `idx_warnings_active` (`is_active`),
    INDEX `idx_warnings_expires` (`expires`),
    INDEX `idx_warnings_issued_by` (`issued_by`),
    INDEX `idx_warnings_created` (`created_at`),

    -- Indice para contar advertencias activas de un jugador
    INDEX `idx_warnings_player_active` (`player_id`, `is_active`, `expires`),

    CONSTRAINT `fk_warnings_player`
        FOREIGN KEY (`player_id`)
        REFERENCES `ait_players` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_warnings_char`
        FOREIGN KEY (`char_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `fk_warnings_issued_by`
        FOREIGN KEY (`issued_by`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `fk_warnings_revoked_by`
        FOREIGN KEY (`revoked_by`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sistema de advertencias para jugadores';

-- ----------------------------------------------------------------------------
-- Tabla: ait_anticheat_logs
-- Descripcion: Registro de detecciones del sistema anticheat
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_anticheat_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico del registro',
    `player_id` INT UNSIGNED NOT NULL COMMENT 'ID del jugador detectado',
    `char_id` INT UNSIGNED NULL COMMENT 'ID del personaje activo',
    `detection_type` VARCHAR(100) NOT NULL COMMENT 'Tipo de deteccion (ej: speedhack, teleport, aimbot)',
    `detection_module` VARCHAR(50) NOT NULL COMMENT 'Modulo del anticheat que detecto',
    `severity` ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium' COMMENT 'Severidad de la deteccion',
    `confidence` DECIMAL(5, 2) NOT NULL DEFAULT 0.00 COMMENT 'Porcentaje de confianza de la deteccion (0-100)',
    `description` TEXT NOT NULL COMMENT 'Descripcion detallada de la deteccion',
    `detection_data` JSON NULL COMMENT 'Datos tecnicos de la deteccion',
    `player_position_x` FLOAT NULL COMMENT 'Posicion X del jugador',
    `player_position_y` FLOAT NULL COMMENT 'Posicion Y del jugador',
    `player_position_z` FLOAT NULL COMMENT 'Posicion Z del jugador',
    `expected_value` VARCHAR(255) NULL COMMENT 'Valor esperado por el sistema',
    `actual_value` VARCHAR(255) NULL COMMENT 'Valor detectado',
    `resource_name` VARCHAR(100) NULL COMMENT 'Recurso relacionado (si aplica)',
    `action_taken` ENUM('none', 'logged', 'warned', 'kicked', 'banned', 'flagged') NOT NULL DEFAULT 'logged' COMMENT 'Accion tomada automaticamente',
    `is_false_positive` TINYINT(1) NULL COMMENT 'Marcado como falso positivo por admin',
    `reviewed_by` INT UNSIGNED NULL COMMENT 'Admin que reviso el registro',
    `reviewed_at` DATETIME NULL COMMENT 'Fecha de revision',
    `review_notes` TEXT NULL COMMENT 'Notas de la revision',
    `ip_address` VARCHAR(45) NULL COMMENT 'Direccion IP del jugador',
    `session_id` VARCHAR(64) NULL COMMENT 'ID de sesion del jugador',
    `server_id` VARCHAR(20) NULL COMMENT 'Identificador del servidor',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de la deteccion',

    PRIMARY KEY (`id`),
    INDEX `idx_ac_player` (`player_id`),
    INDEX `idx_ac_char` (`char_id`),
    INDEX `idx_ac_type` (`detection_type`),
    INDEX `idx_ac_module` (`detection_module`),
    INDEX `idx_ac_severity` (`severity`),
    INDEX `idx_ac_confidence` (`confidence`),
    INDEX `idx_ac_action` (`action_taken`),
    INDEX `idx_ac_false_positive` (`is_false_positive`),
    INDEX `idx_ac_created` (`created_at`),
    INDEX `idx_ac_session` (`session_id`),
    INDEX `idx_ac_server` (`server_id`),

    -- Indices compuestos para analisis
    INDEX `idx_ac_player_type` (`player_id`, `detection_type`, `created_at`),
    INDEX `idx_ac_severity_time` (`severity`, `created_at`),
    INDEX `idx_ac_unreviewed` (`reviewed_by`, `severity`, `created_at`),

    CONSTRAINT `fk_ac_player`
        FOREIGN KEY (`player_id`)
        REFERENCES `ait_players` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_ac_char`
        FOREIGN KEY (`char_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `fk_ac_reviewed_by`
        FOREIGN KEY (`reviewed_by`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registros del sistema anticheat'
-- Particionamiento por rango de fechas para mejor rendimiento
PARTITION BY RANGE (TO_DAYS(`created_at`)) (
    PARTITION p_old VALUES LESS THAN (TO_DAYS('2026-01-01')),
    PARTITION p_2026_01 VALUES LESS THAN (TO_DAYS('2026-02-01')),
    PARTITION p_2026_02 VALUES LESS THAN (TO_DAYS('2026-03-01')),
    PARTITION p_2026_03 VALUES LESS THAN (TO_DAYS('2026-04-01')),
    PARTITION p_2026_04 VALUES LESS THAN (TO_DAYS('2026-05-01')),
    PARTITION p_2026_05 VALUES LESS THAN (TO_DAYS('2026-06-01')),
    PARTITION p_2026_06 VALUES LESS THAN (TO_DAYS('2026-07-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- ----------------------------------------------------------------------------
-- Tabla: ait_admin_actions
-- Descripcion: Registro de todas las acciones administrativas
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_admin_actions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico de la accion',
    `admin_id` INT UNSIGNED NOT NULL COMMENT 'ID del administrador',
    `admin_name` VARCHAR(100) NOT NULL COMMENT 'Nombre del admin (respaldo)',
    `target_player_id` INT UNSIGNED NULL COMMENT 'ID del jugador objetivo',
    `target_char_id` INT UNSIGNED NULL COMMENT 'ID del personaje objetivo',
    `action_type` VARCHAR(100) NOT NULL COMMENT 'Tipo de accion (ej: kick, ban, give_item, teleport)',
    `action_category` VARCHAR(50) NOT NULL COMMENT 'Categoria de la accion',
    `description` TEXT NOT NULL COMMENT 'Descripcion de la accion realizada',
    `action_data` JSON NULL COMMENT 'Datos adicionales de la accion',
    `ip_address` VARCHAR(45) NULL COMMENT 'IP del admin',
    `server_id` VARCHAR(20) NULL COMMENT 'Servidor donde se ejecuto',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de la accion',

    PRIMARY KEY (`id`),
    INDEX `idx_admin_actions_admin` (`admin_id`),
    INDEX `idx_admin_actions_target` (`target_player_id`),
    INDEX `idx_admin_actions_type` (`action_type`),
    INDEX `idx_admin_actions_category` (`action_category`),
    INDEX `idx_admin_actions_created` (`created_at`),
    INDEX `idx_admin_actions_server` (`server_id`),

    CONSTRAINT `fk_admin_actions_admin`
        FOREIGN KEY (`admin_id`)
        REFERENCES `ait_players` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_admin_actions_target`
        FOREIGN KEY (`target_player_id`)
        REFERENCES `ait_players` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de acciones administrativas';

-- ----------------------------------------------------------------------------
-- Tabla: ait_ip_whitelist
-- Descripcion: Lista blanca de IPs permitidas (para servidores privados)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_ip_whitelist` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico',
    `ip_address` VARCHAR(45) NOT NULL COMMENT 'Direccion IP permitida',
    `ip_range_start` VARCHAR(45) NULL COMMENT 'Inicio del rango de IPs (opcional)',
    `ip_range_end` VARCHAR(45) NULL COMMENT 'Fin del rango de IPs (opcional)',
    `description` VARCHAR(255) NULL COMMENT 'Descripcion o razon',
    `added_by` INT UNSIGNED NULL COMMENT 'Admin que agrego la IP',
    `expires` DATETIME NULL COMMENT 'Fecha de expiracion (NULL=permanente)',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Estado activo',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creacion',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_ip_whitelist` (`ip_address`),
    INDEX `idx_whitelist_active` (`is_active`),
    INDEX `idx_whitelist_expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Lista blanca de IPs permitidas';

-- ----------------------------------------------------------------------------
-- Vista: v_active_bans
-- Descripcion: Vista de baneos actualmente activos
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_active_bans` AS
SELECT
    b.id,
    b.player_id,
    p.username AS player_name,
    b.license,
    b.discord_id,
    b.ip_address,
    b.reason,
    b.ban_type,
    b.banned_by,
    b.banned_by_name,
    b.expires,
    b.appeal_status,
    b.created_at,
    CASE
        WHEN b.expires IS NULL THEN 'Permanente'
        ELSE CONCAT(DATEDIFF(b.expires, NOW()), ' dias restantes')
    END AS time_remaining
FROM `ait_bans` b
LEFT JOIN `ait_players` p ON b.player_id = p.id
WHERE b.is_active = 1
    AND (b.expires IS NULL OR b.expires > NOW());

-- ----------------------------------------------------------------------------
-- Vista: v_player_warning_summary
-- Descripcion: Resumen de advertencias por jugador
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_player_warning_summary` AS
SELECT
    w.player_id,
    p.username AS player_name,
    COUNT(*) AS total_warnings,
    SUM(CASE WHEN w.is_active = 1 AND (w.expires IS NULL OR w.expires > NOW()) THEN 1 ELSE 0 END) AS active_warnings,
    SUM(CASE WHEN w.is_active = 1 AND (w.expires IS NULL OR w.expires > NOW()) THEN w.points ELSE 0 END) AS active_points,
    MAX(w.created_at) AS last_warning_date,
    GROUP_CONCAT(DISTINCT w.category ORDER BY w.created_at DESC SEPARATOR ', ') AS warning_categories
FROM `ait_warnings` w
LEFT JOIN `ait_players` p ON w.player_id = p.id
GROUP BY w.player_id, p.username;

-- ----------------------------------------------------------------------------
-- Procedimiento: sp_check_player_banned
-- Descripcion: Verifica si un jugador esta baneado
-- ----------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS `sp_check_player_banned`(
    IN p_player_id INT UNSIGNED,
    IN p_license VARCHAR(50),
    IN p_ip_address VARCHAR(45),
    IN p_hwid VARCHAR(64),
    OUT p_is_banned TINYINT(1),
    OUT p_ban_id INT UNSIGNED,
    OUT p_ban_reason TEXT,
    OUT p_ban_expires DATETIME
)
BEGIN
    -- Buscar baneo activo por cualquier identificador
    SELECT
        1,
        id,
        reason,
        expires
    INTO
        p_is_banned,
        p_ban_id,
        p_ban_reason,
        p_ban_expires
    FROM `ait_bans`
    WHERE is_active = 1
        AND (expires IS NULL OR expires > NOW())
        AND (
            player_id = p_player_id
            OR (license IS NOT NULL AND license = p_license)
            OR (ip_address IS NOT NULL AND ip_address = p_ip_address)
            OR (hwid IS NOT NULL AND hwid = p_hwid)
        )
    ORDER BY
        CASE WHEN expires IS NULL THEN 0 ELSE 1 END, -- Permanentes primero
        expires DESC
    LIMIT 1;

    -- Si no se encontro baneo, establecer valores por defecto
    IF p_is_banned IS NULL THEN
        SET p_is_banned = 0;
        SET p_ban_id = NULL;
        SET p_ban_reason = NULL;
        SET p_ban_expires = NULL;
    END IF;
END //

DELIMITER ;

-- ----------------------------------------------------------------------------
-- Procedimiento: sp_auto_expire_warnings
-- Descripcion: Desactiva advertencias expiradas automaticamente
-- ----------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS `sp_auto_expire_warnings`()
BEGIN
    UPDATE `ait_warnings`
    SET
        is_active = 0,
        updated_at = NOW()
    WHERE is_active = 1
        AND expires IS NOT NULL
        AND expires <= NOW();

    SELECT ROW_COUNT() AS warnings_expired;
END //

DELIMITER ;

-- ----------------------------------------------------------------------------
-- Evento: evt_cleanup_old_anticheat_logs
-- Descripcion: Limpia registros de anticheat antiguos (mas de 90 dias)
-- ----------------------------------------------------------------------------
DELIMITER //

CREATE EVENT IF NOT EXISTS `evt_cleanup_old_anticheat_logs`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- Eliminar registros de falsos positivos confirmados mayores a 30 dias
    DELETE FROM `ait_anticheat_logs`
    WHERE is_false_positive = 1
        AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

    -- Eliminar registros de baja severidad mayores a 60 dias
    DELETE FROM `ait_anticheat_logs`
    WHERE severity = 'low'
        AND created_at < DATE_SUB(NOW(), INTERVAL 60 DAY);

    -- Eliminar registros de severidad media mayores a 90 dias
    DELETE FROM `ait_anticheat_logs`
    WHERE severity = 'medium'
        AND created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

    -- Los registros de alta severidad y criticos se mantienen indefinidamente
END //

DELIMITER ;
