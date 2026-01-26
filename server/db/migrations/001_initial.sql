-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb DATABASE SCHEMA V1.0
-- Migration 001: Initial Setup
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────────
-- PLAYERS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_players (
    player_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    license VARCHAR(64) NOT NULL,
    discord VARCHAR(64) NULL,
    steam VARCHAR(64) NULL,
    xbox VARCHAR(64) NULL,
    live VARCHAR(64) NULL,
    fivem VARCHAR(64) NULL,
    ip VARCHAR(64) NULL,
    hwid VARCHAR(128) NULL,

    first_seen DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_playtime INT NOT NULL DEFAULT 0 COMMENT 'seconds',

    risk_score INT NOT NULL DEFAULT 0,
    vip_level INT NOT NULL DEFAULT 0,
    vip_expires DATETIME NULL,

    locale VARCHAR(10) DEFAULT 'es',
    settings JSON NULL,
    meta JSON NULL,

    UNIQUE KEY idx_license (license),
    KEY idx_discord (discord),
    KEY idx_steam (steam),
    KEY idx_last_seen (last_seen),
    KEY idx_risk_score (risk_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CHARACTERS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_characters (
    char_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    player_id BIGINT NOT NULL,
    slot TINYINT NOT NULL DEFAULT 1,

    citizenid VARCHAR(32) NOT NULL,
    firstname VARCHAR(64) NOT NULL,
    lastname VARCHAR(64) NOT NULL,
    nickname VARCHAR(64) NULL,

    dob DATE NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL DEFAULT 'male',
    nationality VARCHAR(64) DEFAULT 'Santabria',

    phone_number VARCHAR(20) NULL,

    -- Appearance
    model VARCHAR(64) DEFAULT 'mp_m_freemode_01',
    skin JSON NULL,
    clothing JSON NULL,

    -- Status
    health INT NOT NULL DEFAULT 200,
    armor INT NOT NULL DEFAULT 0,
    hunger FLOAT NOT NULL DEFAULT 100.0,
    thirst FLOAT NOT NULL DEFAULT 100.0,
    stress FLOAT NOT NULL DEFAULT 0.0,

    -- Position
    position JSON NULL,
    last_property BIGINT NULL,
    routing_bucket INT DEFAULT 0,

    -- Stats
    total_playtime INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_played DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Progression
    level INT NOT NULL DEFAULT 1,
    xp BIGINT NOT NULL DEFAULT 0,
    skills JSON NULL,
    achievements JSON NULL,

    -- RP Data
    reputation JSON NULL COMMENT '{"legal":0,"criminal":0,"business":0,"social":0}',
    traits JSON NULL,
    background TEXT NULL,
    licenses JSON NULL,

    -- State
    is_dead TINYINT(1) NOT NULL DEFAULT 0,
    jail_time INT NOT NULL DEFAULT 0,
    status ENUM('active', 'jailed', 'hospitalized', 'inactive', 'deleted') DEFAULT 'active',

    meta JSON NULL,

    UNIQUE KEY idx_citizenid (citizenid),
    UNIQUE KEY idx_player_slot (player_id, slot),
    KEY idx_status (status),
    KEY idx_last_played (last_played),

    FOREIGN KEY (player_id) REFERENCES ait_players(player_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CHARACTER HISTORY
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_character_history (
    history_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    char_id BIGINT NOT NULL,
    action VARCHAR(64) NOT NULL,
    data JSON NULL,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY idx_char_action (char_id, action),
    KEY idx_ts (ts),

    FOREIGN KEY (char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- FEATURE FLAGS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_feature_flags (
    flag_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `key` VARCHAR(128) NOT NULL,
    value VARCHAR(255) NOT NULL DEFAULT 'false',
    rollout_percent INT NOT NULL DEFAULT 100,
    conditions JSON NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY idx_key (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- SESSIONS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_sessions (
    session_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    player_id BIGINT NOT NULL,
    char_id BIGINT NULL,

    ts_start DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ts_end DATETIME NULL,

    ip VARCHAR(64) NULL,
    license VARCHAR(64) NULL,

    meta JSON NULL,

    KEY idx_player (player_id),
    KEY idx_char (char_id),
    KEY idx_ts (ts_start),

    FOREIGN KEY (player_id) REFERENCES ait_players(player_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
