-- ============================================================================
-- AIT-QB Migration 009: Sistema de Analiticas
-- Descripcion: Tablas para eventos, metricas y estadisticas del servidor
-- Fecha: 2026-01-25
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: ait_analytics_events
-- Descripcion: Registro de todos los eventos del servidor para analisis
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_analytics_events` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico del evento',
    `event_type` VARCHAR(100) NOT NULL COMMENT 'Tipo de evento (ej: player_login, item_pickup, death)',
    `event_category` VARCHAR(50) NULL COMMENT 'Categoria del evento (ej: player, economy, combat)',
    `player_id` INT UNSIGNED NULL COMMENT 'ID del jugador relacionado (puede ser NULL para eventos del sistema)',
    `char_id` INT UNSIGNED NULL COMMENT 'ID del personaje relacionado',
    `target_player_id` INT UNSIGNED NULL COMMENT 'ID del jugador objetivo (si aplica)',
    `target_char_id` INT UNSIGNED NULL COMMENT 'ID del personaje objetivo (si aplica)',
    `data` JSON NULL COMMENT 'Datos adicionales del evento en formato JSON',
    `location_x` FLOAT NULL COMMENT 'Coordenada X donde ocurrio el evento',
    `location_y` FLOAT NULL COMMENT 'Coordenada Y donde ocurrio el evento',
    `location_z` FLOAT NULL COMMENT 'Coordenada Z donde ocurrio el evento',
    `session_id` VARCHAR(64) NULL COMMENT 'ID de sesion del jugador',
    `server_id` VARCHAR(20) NULL COMMENT 'Identificador del servidor (para multi-servidor)',
    `ts` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp del evento',

    PRIMARY KEY (`id`),
    INDEX `idx_events_type` (`event_type`),
    INDEX `idx_events_category` (`event_category`),
    INDEX `idx_events_player` (`player_id`),
    INDEX `idx_events_char` (`char_id`),
    INDEX `idx_events_timestamp` (`ts`),
    INDEX `idx_events_session` (`session_id`),
    INDEX `idx_events_server` (`server_id`),

    -- Indices compuestos para consultas frecuentes
    INDEX `idx_events_type_ts` (`event_type`, `ts`),
    INDEX `idx_events_player_ts` (`player_id`, `ts`),
    INDEX `idx_events_category_ts` (`event_category`, `ts`),

    -- Indice para busqueda por ubicacion
    INDEX `idx_events_location` (`location_x`, `location_y`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de eventos para analiticas'
-- Particionamiento por rango de fechas para mejor rendimiento
PARTITION BY RANGE (TO_DAYS(`ts`)) (
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
-- Tabla: ait_metrics_hourly
-- Descripcion: Metricas agregadas por hora para dashboards
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_metrics_hourly` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico',
    `metric_name` VARCHAR(100) NOT NULL COMMENT 'Nombre de la metrica',
    `metric_category` VARCHAR(50) NOT NULL COMMENT 'Categoria de la metrica',
    `hour_start` DATETIME NOT NULL COMMENT 'Inicio de la hora de agregacion',
    `value_count` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Conteo de ocurrencias',
    `value_sum` DECIMAL(20, 4) NULL COMMENT 'Suma de valores',
    `value_avg` DECIMAL(20, 4) NULL COMMENT 'Promedio de valores',
    `value_min` DECIMAL(20, 4) NULL COMMENT 'Valor minimo',
    `value_max` DECIMAL(20, 4) NULL COMMENT 'Valor maximo',
    `unique_players` INT UNSIGNED NULL COMMENT 'Jugadores unicos en la hora',
    `unique_characters` INT UNSIGNED NULL COMMENT 'Personajes unicos en la hora',
    `metadata` JSON NULL COMMENT 'Datos adicionales de la metrica',
    `server_id` VARCHAR(20) NULL COMMENT 'Identificador del servidor',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creacion',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_metric_hour` (`metric_name`, `hour_start`, `server_id`),
    INDEX `idx_hourly_name` (`metric_name`),
    INDEX `idx_hourly_category` (`metric_category`),
    INDEX `idx_hourly_hour` (`hour_start`),
    INDEX `idx_hourly_server` (`server_id`),

    -- Indice compuesto para consultas de rango de tiempo
    INDEX `idx_hourly_name_range` (`metric_name`, `hour_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Metricas agregadas por hora';

-- ----------------------------------------------------------------------------
-- Tabla: ait_metrics_daily
-- Descripcion: Metricas agregadas por dia para reportes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_metrics_daily` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico',
    `metric_name` VARCHAR(100) NOT NULL COMMENT 'Nombre de la metrica',
    `metric_category` VARCHAR(50) NOT NULL COMMENT 'Categoria de la metrica',
    `date` DATE NOT NULL COMMENT 'Fecha de agregacion',
    `value_count` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Conteo total de ocurrencias',
    `value_sum` DECIMAL(20, 4) NULL COMMENT 'Suma total de valores',
    `value_avg` DECIMAL(20, 4) NULL COMMENT 'Promedio del dia',
    `value_min` DECIMAL(20, 4) NULL COMMENT 'Valor minimo del dia',
    `value_max` DECIMAL(20, 4) NULL COMMENT 'Valor maximo del dia',
    `value_median` DECIMAL(20, 4) NULL COMMENT 'Mediana del dia',
    `value_stddev` DECIMAL(20, 4) NULL COMMENT 'Desviacion estandar',
    `peak_hour` TINYINT UNSIGNED NULL COMMENT 'Hora pico (0-23)',
    `peak_value` DECIMAL(20, 4) NULL COMMENT 'Valor en hora pico',
    `unique_players` INT UNSIGNED NULL COMMENT 'Jugadores unicos del dia',
    `unique_characters` INT UNSIGNED NULL COMMENT 'Personajes unicos del dia',
    `new_players` INT UNSIGNED NULL COMMENT 'Nuevos jugadores del dia',
    `returning_players` INT UNSIGNED NULL COMMENT 'Jugadores que regresaron',
    `metadata` JSON NULL COMMENT 'Datos adicionales',
    `server_id` VARCHAR(20) NULL COMMENT 'Identificador del servidor',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creacion',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Ultima actualizacion',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_metric_date` (`metric_name`, `date`, `server_id`),
    INDEX `idx_daily_name` (`metric_name`),
    INDEX `idx_daily_category` (`metric_category`),
    INDEX `idx_daily_date` (`date`),
    INDEX `idx_daily_server` (`server_id`),

    -- Indices para reportes mensuales/anuales
    INDEX `idx_daily_name_range` (`metric_name`, `date`),
    INDEX `idx_daily_category_range` (`metric_category`, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Metricas agregadas por dia';

-- ----------------------------------------------------------------------------
-- Tabla: ait_player_sessions
-- Descripcion: Seguimiento de sesiones de jugadores
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_player_sessions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico de sesion',
    `session_id` VARCHAR(64) NOT NULL COMMENT 'ID unico de sesion',
    `player_id` INT UNSIGNED NOT NULL COMMENT 'ID del jugador',
    `char_id` INT UNSIGNED NULL COMMENT 'ID del personaje usado',
    `ip_address` VARCHAR(45) NULL COMMENT 'Direccion IP del jugador',
    `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Inicio de sesion',
    `ended_at` DATETIME NULL COMMENT 'Fin de sesion',
    `duration_minutes` INT UNSIGNED NULL COMMENT 'Duracion en minutos',
    `disconnect_reason` VARCHAR(100) NULL COMMENT 'Razon de desconexion',
    `server_id` VARCHAR(20) NULL COMMENT 'Servidor donde jugo',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_session_id` (`session_id`),
    INDEX `idx_sessions_player` (`player_id`),
    INDEX `idx_sessions_char` (`char_id`),
    INDEX `idx_sessions_started` (`started_at`),
    INDEX `idx_sessions_ended` (`ended_at`),
    INDEX `idx_sessions_server` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de sesiones de jugadores';

-- ----------------------------------------------------------------------------
-- Tabla: ait_economy_snapshots
-- Descripcion: Instantaneas periodicas del estado economico
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_economy_snapshots` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico',
    `snapshot_type` ENUM('hourly', 'daily', 'weekly') NOT NULL COMMENT 'Tipo de snapshot',
    `snapshot_time` DATETIME NOT NULL COMMENT 'Momento del snapshot',
    `total_cash_circulation` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Dinero efectivo total en circulacion',
    `total_bank_balance` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total en cuentas bancarias',
    `total_crypto` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total de criptomonedas',
    `avg_player_wealth` DECIMAL(20, 4) NULL COMMENT 'Riqueza promedio por jugador',
    `median_player_wealth` DECIMAL(20, 4) NULL COMMENT 'Mediana de riqueza',
    `top_1_percent_wealth` DECIMAL(20, 4) NULL COMMENT 'Riqueza del 1% superior',
    `gini_coefficient` DECIMAL(5, 4) NULL COMMENT 'Coeficiente de Gini (desigualdad)',
    `active_players` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Jugadores activos en el periodo',
    `transactions_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Numero de transacciones',
    `transactions_volume` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Volumen total de transacciones',
    `items_traded` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Items comerciados',
    `metadata` JSON NULL COMMENT 'Datos adicionales del snapshot',
    `server_id` VARCHAR(20) NULL COMMENT 'Identificador del servidor',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creacion',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_snapshot_type_time` (`snapshot_type`, `snapshot_time`, `server_id`),
    INDEX `idx_snapshots_type` (`snapshot_type`),
    INDEX `idx_snapshots_time` (`snapshot_time`),
    INDEX `idx_snapshots_server` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Instantaneas del estado economico del servidor';

-- ----------------------------------------------------------------------------
-- Procedimiento: sp_aggregate_hourly_metrics
-- Descripcion: Procedimiento para agregar eventos en metricas horarias
-- ----------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS `sp_aggregate_hourly_metrics`(
    IN p_hour_start DATETIME,
    IN p_hour_end DATETIME
)
BEGIN
    -- Declaracion de variables
    DECLARE v_metric_name VARCHAR(100);
    DECLARE v_done INT DEFAULT FALSE;

    -- Agregar metricas de eventos por tipo
    INSERT INTO `ait_metrics_hourly` (
        `metric_name`,
        `metric_category`,
        `hour_start`,
        `value_count`,
        `unique_players`,
        `unique_characters`
    )
    SELECT
        CONCAT('events_', event_type),
        COALESCE(event_category, 'general'),
        p_hour_start,
        COUNT(*),
        COUNT(DISTINCT player_id),
        COUNT(DISTINCT char_id)
    FROM `ait_analytics_events`
    WHERE `ts` >= p_hour_start AND `ts` < p_hour_end
    GROUP BY event_type, event_category
    ON DUPLICATE KEY UPDATE
        `value_count` = VALUES(`value_count`),
        `unique_players` = VALUES(`unique_players`),
        `unique_characters` = VALUES(`unique_characters`);

    -- Agregar metrica de jugadores conectados
    INSERT INTO `ait_metrics_hourly` (
        `metric_name`,
        `metric_category`,
        `hour_start`,
        `value_count`,
        `unique_players`
    )
    SELECT
        'players_online',
        'server',
        p_hour_start,
        COUNT(*),
        COUNT(DISTINCT player_id)
    FROM `ait_player_sessions`
    WHERE `started_at` < p_hour_end
        AND (`ended_at` IS NULL OR `ended_at` > p_hour_start)
    ON DUPLICATE KEY UPDATE
        `value_count` = VALUES(`value_count`),
        `unique_players` = VALUES(`unique_players`);

END //

DELIMITER ;
