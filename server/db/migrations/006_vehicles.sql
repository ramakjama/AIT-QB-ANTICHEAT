-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb DATABASE SCHEMA V1.0
-- Migration 006: Vehicles System
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────────
-- VEHÍCULOS
-- Vehículos propiedad de jugadores
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_vehicles (
    vehicle_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    -- Propietario
    owner_id BIGINT NOT NULL COMMENT 'char_id del propietario',
    owner_type ENUM('char', 'faction', 'business', 'rental', 'impound') NOT NULL DEFAULT 'char',

    -- Identificación
    plate VARCHAR(10) NOT NULL COMMENT 'Matrícula del vehículo',
    vin VARCHAR(17) NULL COMMENT 'Número de identificación del vehículo',

    -- Modelo y tipo
    model VARCHAR(64) NOT NULL COMMENT 'Nombre del modelo (spawn name)',
    model_hash INT NULL COMMENT 'Hash del modelo',
    vehicle_type ENUM('car', 'motorcycle', 'bicycle', 'boat', 'aircraft', 'helicopter', 'trailer', 'other') NOT NULL DEFAULT 'car',
    class VARCHAR(32) NULL COMMENT 'Clase del vehículo (sports, muscle, etc.)',

    -- Modificaciones y apariencia
    mods JSON NULL COMMENT 'Modificaciones del vehículo',
    colors JSON NULL COMMENT '{"primary":0,"secondary":0,"pearlescent":0,"wheel":0}',
    livery INT NULL COMMENT 'Livery aplicada',
    extras JSON NULL COMMENT 'Extras activos',
    neon JSON NULL COMMENT '{"enabled":false,"color":[255,0,0]}',
    xenon JSON NULL COMMENT '{"enabled":false,"color":0}',

    -- Matrícula personalizada
    plate_style INT NOT NULL DEFAULT 0,

    -- Estado del vehículo
    fuel FLOAT NOT NULL DEFAULT 100.0 COMMENT 'Nivel de combustible (0-100)',
    body_health FLOAT NOT NULL DEFAULT 1000.0 COMMENT 'Salud de la carrocería',
    engine_health FLOAT NOT NULL DEFAULT 1000.0 COMMENT 'Salud del motor',
    tank_health FLOAT NOT NULL DEFAULT 1000.0 COMMENT 'Salud del tanque',
    dirt_level FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Nivel de suciedad',

    -- Desgaste y mantenimiento
    mileage INT NOT NULL DEFAULT 0 COMMENT 'Kilómetros recorridos',
    last_service DATETIME NULL COMMENT 'Último mantenimiento',
    next_service_mileage INT NULL COMMENT 'Kilómetros para próximo servicio',

    -- Ubicación y estado
    garage VARCHAR(64) NULL COMMENT 'Garaje donde está guardado',
    parking_spot INT NULL COMMENT 'Plaza de aparcamiento',
    state ENUM('garaged', 'out', 'impounded', 'destroyed', 'stolen', 'seized') NOT NULL DEFAULT 'garaged',

    -- Posición si está fuera
    position JSON NULL COMMENT '{"x":0,"y":0,"z":0,"heading":0}',
    dimension INT NOT NULL DEFAULT 0,

    -- Seguro
    insurance TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si tiene seguro',
    insurance_tier ENUM('none', 'basic', 'full', 'premium') NOT NULL DEFAULT 'none',
    insurance_expires DATETIME NULL,
    insurance_claims INT NOT NULL DEFAULT 0 COMMENT 'Reclamaciones realizadas',

    -- Financiación
    financed TINYINT(1) NOT NULL DEFAULT 0,
    finance_amount BIGINT NOT NULL DEFAULT 0 COMMENT 'Cantidad financiada',
    finance_paid BIGINT NOT NULL DEFAULT 0 COMMENT 'Cantidad pagada',
    finance_payments_left INT NOT NULL DEFAULT 0,
    finance_payment_amount INT NOT NULL DEFAULT 0,
    finance_next_payment DATETIME NULL,

    -- Historial de propiedad
    original_owner_id BIGINT NULL COMMENT 'Propietario original',
    purchase_price BIGINT NULL COMMENT 'Precio de compra',
    purchased_at DATETIME NULL,
    previous_owners INT NOT NULL DEFAULT 0,

    -- Llaves
    keys JSON NULL COMMENT '[{"char_id":1,"type":"owner"},{"char_id":2,"type":"temp"}]',

    -- Robo
    stolen TINYINT(1) NOT NULL DEFAULT 0,
    stolen_at DATETIME NULL,
    stolen_by BIGINT NULL COMMENT 'char_id del ladrón',

    -- Depósito/Incautación
    impounded_at DATETIME NULL,
    impound_reason TEXT NULL,
    impound_fee INT NULL,
    impound_by BIGINT NULL COMMENT 'char_id del agente',
    seizure_reason TEXT NULL,

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_used DATETIME NULL,

    meta JSON NULL,

    UNIQUE KEY idx_plate (plate),
    UNIQUE KEY idx_vin (vin),
    KEY idx_owner (owner_id, owner_type),
    KEY idx_model (model),
    KEY idx_type (vehicle_type),
    KEY idx_state (state),
    KEY idx_garage (garage),
    KEY idx_insurance (insurance, insurance_expires),
    KEY idx_financed (financed),
    KEY idx_stolen (stolen),

    FOREIGN KEY (owner_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- LOGS DE VEHÍCULOS
-- Historial de acciones sobre vehículos
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_vehicle_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    vehicle_id BIGINT NOT NULL,
    plate VARCHAR(10) NOT NULL COMMENT 'Copia de la matrícula por si se elimina el vehículo',

    -- Quién realizó la acción
    actor_char_id BIGINT NULL,
    actor_name VARCHAR(128) NULL,

    -- Tipo de evento
    action ENUM(
        'purchased', 'sold', 'traded', 'gifted',
        'spawned', 'stored', 'impounded', 'retrieved',
        'repaired', 'upgraded', 'painted', 'modded',
        'stolen', 'recovered', 'destroyed',
        'insurance_claim', 'insurance_purchased',
        'key_given', 'key_revoked',
        'financed', 'payment_made', 'payment_missed',
        'seized', 'released',
        'other'
    ) NOT NULL,

    -- Detalles
    details TEXT NULL,
    old_value JSON NULL,
    new_value JSON NULL,

    -- Ubicación del evento
    location JSON NULL COMMENT '{"x":0,"y":0,"z":0}',

    -- Contexto adicional
    cost INT NULL COMMENT 'Costo asociado a la acción',

    KEY idx_ts (ts),
    KEY idx_vehicle (vehicle_id),
    KEY idx_plate (plate),
    KEY idx_actor (actor_char_id),
    KEY idx_action (action),
    KEY idx_vehicle_ts (vehicle_id, ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- GARAJES
-- Definición de garajes disponibles
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_garages (
    garage_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(64) NOT NULL COMMENT 'Identificador único',
    label VARCHAR(128) NOT NULL COMMENT 'Nombre mostrado',

    -- Tipo
    type ENUM('public', 'house', 'faction', 'impound', 'depot', 'hangar', 'marina') NOT NULL DEFAULT 'public',

    -- Vehículos aceptados
    vehicle_types JSON NOT NULL DEFAULT '["car","motorcycle"]' COMMENT 'Tipos de vehículos aceptados',

    -- Ubicación
    location JSON NOT NULL COMMENT '{"x":0,"y":0,"z":0}',
    spawn_points JSON NOT NULL COMMENT '[{"x":0,"y":0,"z":0,"heading":0}]',
    blip_sprite INT NULL,
    blip_color INT NULL,

    -- Capacidad
    capacity INT NULL COMMENT 'Capacidad máxima (null = ilimitado)',
    current_count INT NOT NULL DEFAULT 0,

    -- Propietario (para garajes privados)
    owner_type ENUM('public', 'char', 'faction', 'property') NOT NULL DEFAULT 'public',
    owner_id BIGINT NULL,

    -- Costos
    retrieval_fee INT NOT NULL DEFAULT 0 COMMENT 'Costo por sacar vehículo',
    storage_fee_daily INT NOT NULL DEFAULT 0 COMMENT 'Costo diario de almacenamiento',

    -- Estado
    active TINYINT(1) NOT NULL DEFAULT 1,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY idx_name (name),
    KEY idx_type (type),
    KEY idx_owner (owner_type, owner_id),
    KEY idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- DEPÓSITO DE VEHÍCULOS
-- Vehículos en el depósito municipal
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_impound_lot (
    impound_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    vehicle_id BIGINT NOT NULL,
    plate VARCHAR(10) NOT NULL,
    model VARCHAR(64) NOT NULL,

    -- Razón
    reason ENUM('abandoned', 'illegal_parking', 'crime', 'accident', 'evidence', 'seized') NOT NULL,
    reason_details TEXT NULL,

    -- Quién lo llevó
    impounded_by_char_id BIGINT NULL,
    impounded_by_name VARCHAR(128) NULL,
    impounded_by_faction VARCHAR(64) NULL,

    -- Ubicación original
    original_location JSON NULL,

    -- Costo de recuperación
    base_fee INT NOT NULL DEFAULT 500,
    daily_fee INT NOT NULL DEFAULT 100,
    total_fee INT NOT NULL DEFAULT 500,

    -- Estado del vehículo al ser incautado
    vehicle_state JSON NULL COMMENT 'Estado completo del vehículo',

    -- Fechas
    impounded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NULL COMMENT 'Fecha en que se subastará/destruirá',
    retrieved_at DATETIME NULL,
    retrieved_by BIGINT NULL,

    -- Estado
    status ENUM('impounded', 'retrieved', 'auctioned', 'destroyed', 'seized') NOT NULL DEFAULT 'impounded',

    KEY idx_vehicle (vehicle_id),
    KEY idx_plate (plate),
    KEY idx_status (status),
    KEY idx_impounded_at (impounded_at),
    KEY idx_expires (expires_at),

    FOREIGN KEY (vehicle_id) REFERENCES ait_vehicles(vehicle_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- SEGUROS DE VEHÍCULOS
-- Pólizas de seguro
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_vehicle_insurance (
    insurance_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    vehicle_id BIGINT NOT NULL,

    -- Tipo de póliza
    tier ENUM('basic', 'full', 'premium') NOT NULL,

    -- Cobertura
    coverage JSON NOT NULL COMMENT '{"theft":true,"damage":true,"total_loss":true,"liability":false}',

    -- Costos
    premium INT NOT NULL COMMENT 'Costo mensual',
    deductible INT NOT NULL COMMENT 'Franquicia',
    max_payout INT NOT NULL COMMENT 'Pago máximo',

    -- Historial
    claims_made INT NOT NULL DEFAULT 0,
    total_claimed BIGINT NOT NULL DEFAULT 0,

    -- Vigencia
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    cancelled_at DATETIME NULL,

    -- Estado
    status ENUM('active', 'expired', 'cancelled', 'suspended') NOT NULL DEFAULT 'active',

    KEY idx_vehicle (vehicle_id),
    KEY idx_tier (tier),
    KEY idx_status (status),
    KEY idx_expires (expires_at),

    FOREIGN KEY (vehicle_id) REFERENCES ait_vehicles(vehicle_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- RECLAMACIONES DE SEGURO
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_insurance_claims (
    claim_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    insurance_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    char_id BIGINT NOT NULL,

    -- Tipo de reclamación
    claim_type ENUM('theft', 'damage', 'total_loss', 'liability') NOT NULL,

    -- Detalles
    description TEXT NULL,
    evidence JSON NULL COMMENT 'Screenshots, ubicación, etc.',

    -- Montos
    claimed_amount INT NOT NULL,
    approved_amount INT NULL,
    deductible_paid INT NOT NULL DEFAULT 0,

    -- Estado
    status ENUM('pending', 'reviewing', 'approved', 'denied', 'paid') NOT NULL DEFAULT 'pending',

    -- Procesamiento
    reviewed_by BIGINT NULL COMMENT 'Admin que revisó',
    reviewed_at DATETIME NULL,
    denial_reason TEXT NULL,

    -- Pago
    paid_at DATETIME NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY idx_insurance (insurance_id),
    KEY idx_vehicle (vehicle_id),
    KEY idx_char (char_id),
    KEY idx_status (status),
    KEY idx_created (created_at),

    FOREIGN KEY (insurance_id) REFERENCES ait_vehicle_insurance(insurance_id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES ait_vehicles(vehicle_id) ON DELETE CASCADE,
    FOREIGN KEY (char_id) REFERENCES ait_characters(char_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CATÁLOGO DE VEHÍCULOS
-- Definiciones de vehículos disponibles para compra
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_vehicle_catalog (
    model VARCHAR(64) PRIMARY KEY,

    label VARCHAR(128) NOT NULL,
    make VARCHAR(64) NOT NULL COMMENT 'Marca',

    -- Tipo y clase
    vehicle_type ENUM('car', 'motorcycle', 'bicycle', 'boat', 'aircraft', 'helicopter', 'trailer', 'other') NOT NULL,
    class VARCHAR(32) NOT NULL COMMENT 'sports, muscle, sedans, etc.',

    -- Precio
    price INT NOT NULL,
    resale_percentage FLOAT NOT NULL DEFAULT 60.0 COMMENT 'Porcentaje del precio al vender',

    -- Disponibilidad
    shop VARCHAR(64) NULL COMMENT 'Tienda donde se vende',
    available TINYINT(1) NOT NULL DEFAULT 1,

    -- Requisitos
    min_level INT NULL,
    required_license VARCHAR(64) NULL,
    vip_only TINYINT(1) NOT NULL DEFAULT 0,

    -- Estadísticas base
    top_speed FLOAT NULL,
    acceleration FLOAT NULL,
    braking FLOAT NULL,
    handling FLOAT NULL,

    -- Capacidad
    seats INT NOT NULL DEFAULT 4,
    trunk_slots INT NOT NULL DEFAULT 20,
    trunk_weight FLOAT NOT NULL DEFAULT 50.0,
    fuel_capacity FLOAT NOT NULL DEFAULT 65.0,

    -- Categoría de seguro
    insurance_category ENUM('economy', 'standard', 'sports', 'super', 'exotic') NOT NULL DEFAULT 'standard',

    -- Visual
    image VARCHAR(255) NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY idx_type (vehicle_type),
    KEY idx_class (class),
    KEY idx_price (price),
    KEY idx_shop (shop),
    KEY idx_available (available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- GARAJES POR DEFECTO
-- ───────────────────────────────────────────────────────────────────────────────────────

INSERT INTO ait_garages (name, label, type, vehicle_types, location, spawn_points, blip_sprite, blip_color, retrieval_fee) VALUES
('legion_square', 'Garaje Legion Square', 'public', '["car","motorcycle"]',
 '{"x":215.0,"y":-810.0,"z":30.0}',
 '[{"x":220.0,"y":-800.0,"z":30.0,"heading":160.0}]',
 357, 3, 100),

('airport', 'Garaje Aeropuerto', 'public', '["car","motorcycle"]',
 '{"x":-789.0,"y":-2024.0,"z":9.0}',
 '[{"x":-780.0,"y":-2020.0,"z":9.0,"heading":60.0}]',
 357, 3, 150),

('impound_police', 'Depósito Municipal', 'impound', '["car","motorcycle","boat"]',
 '{"x":409.0,"y":-1623.0,"z":29.0}',
 '[{"x":420.0,"y":-1620.0,"z":29.0,"heading":230.0}]',
 68, 1, 500),

('marina', 'Marina de Los Santos', 'marina', '["boat"]',
 '{"x":-807.0,"y":-1496.0,"z":1.0}',
 '[{"x":-810.0,"y":-1490.0,"z":0.0,"heading":110.0}]',
 410, 3, 200),

('hangar_lsia', 'Hangar LSIA', 'hangar', '["aircraft","helicopter"]',
 '{"x":-1234.0,"y":-3389.0,"z":13.0}',
 '[{"x":-1240.0,"y":-3380.0,"z":13.0,"heading":330.0}]',
 359, 3, 500);

-- ───────────────────────────────────────────────────────────────────────────────────────
-- VEHÍCULOS DE EJEMPLO EN CATÁLOGO
-- ───────────────────────────────────────────────────────────────────────────────────────

INSERT INTO ait_vehicle_catalog (model, label, make, vehicle_type, class, price, seats, trunk_slots, trunk_weight, insurance_category) VALUES
-- Económicos
('asea', 'Asea', 'Declasse', 'car', 'sedans', 12000, 4, 25, 60.0, 'economy'),
('emperor', 'Emperor', 'Albany', 'car', 'sedans', 15000, 4, 30, 70.0, 'economy'),
('ingot', 'Ingot', 'Vulcar', 'car', 'sedans', 10000, 4, 20, 50.0, 'economy'),

-- Standard
('sultan', 'Sultan', 'Karin', 'car', 'sports', 35000, 4, 20, 50.0, 'standard'),
('buffalo', 'Buffalo', 'Bravado', 'car', 'sports', 40000, 4, 25, 55.0, 'standard'),
('dominator', 'Dominator', 'Vapid', 'car', 'muscle', 45000, 2, 15, 40.0, 'standard'),

-- Sports
('elegy', 'Elegy RH8', 'Annis', 'car', 'sports', 95000, 2, 10, 30.0, 'sports'),
('jester', 'Jester', 'Dinka', 'car', 'sports', 120000, 2, 10, 25.0, 'sports'),
('massacro', 'Massacro', 'Dewbauchee', 'car', 'sports', 150000, 2, 8, 20.0, 'sports'),

-- Super
('adder', 'Adder', 'Truffade', 'car', 'super', 1000000, 2, 5, 15.0, 'super'),
('zentorno', 'Zentorno', 'Pegassi', 'car', 'super', 750000, 2, 5, 15.0, 'super'),
('t20', 'T20', 'Progen', 'car', 'super', 1200000, 2, 5, 10.0, 'exotic'),

-- Motos
('bati', 'Bati 801', 'Pegassi', 'motorcycle', 'motorcycles', 25000, 2, 5, 10.0, 'standard'),
('akuma', 'Akuma', 'Dinka', 'motorcycle', 'motorcycles', 20000, 2, 5, 10.0, 'standard'),
('sanchez', 'Sanchez', 'Maibatsu', 'motorcycle', 'motorcycles', 8000, 2, 3, 5.0, 'economy');
