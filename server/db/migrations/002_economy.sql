-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb DATABASE SCHEMA V1.0
-- Migration 002: Economy System
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────────
-- ACCOUNTS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_accounts (
    acc_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    owner_type ENUM('player', 'char', 'faction', 'business', 'system', 'escrow') NOT NULL,
    owner_id BIGINT NOT NULL,

    currency ENUM('cash', 'bank', 'crypto', 'black', 'token', 'event', 'faction') NOT NULL DEFAULT 'bank',
    balance BIGINT NOT NULL DEFAULT 0,

    status ENUM('active', 'frozen', 'closed') NOT NULL DEFAULT 'active',
    frozen_reason TEXT NULL,
    frozen_at DATETIME NULL,
    frozen_by BIGINT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    meta JSON NULL,

    UNIQUE KEY idx_owner_currency (owner_type, owner_id, currency),
    KEY idx_status (status),
    KEY idx_balance (balance)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- LEDGER (TRANSACTION LOG)
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_ledger_tx (
    tx_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    src_acc_id BIGINT NULL,
    dst_acc_id BIGINT NULL,

    amount BIGINT NOT NULL,
    currency ENUM('cash', 'bank', 'crypto', 'black', 'token', 'event', 'faction') NOT NULL,

    category VARCHAR(64) NOT NULL,
    subcategory VARCHAR(64) NULL,
    tags JSON NULL,

    actor_player_id BIGINT NULL,
    actor_char_id BIGINT NULL,

    reason VARCHAR(512) NULL,
    reference_type VARCHAR(32) NULL,
    reference_id BIGINT NULL,

    status ENUM('pending', 'completed', 'reversed', 'failed') NOT NULL DEFAULT 'completed',
    reversed_tx_id BIGINT NULL,
    reversed_at DATETIME NULL,
    reversed_by BIGINT NULL,

    meta JSON NULL,
    sig CHAR(64) NOT NULL,

    KEY idx_ts (ts),
    KEY idx_src (src_acc_id),
    KEY idx_dst (dst_acc_id),
    KEY idx_category (category),
    KEY idx_actor (actor_player_id, actor_char_id),
    KEY idx_reference (reference_type, reference_id),
    KEY idx_status (status),
    KEY idx_sig (sig)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- TRANSACTION CATEGORIES
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_tx_categories (
    category VARCHAR(64) PRIMARY KEY,
    display_name VARCHAR(128) NOT NULL,
    type ENUM('income', 'expense', 'transfer', 'system') NOT NULL,
    is_sink TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Money leaves the economy',
    is_source TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Money enters the economy',
    meta JSON NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default categories
INSERT INTO ait_tx_categories (category, display_name, type, is_sink, is_source) VALUES
-- Sources (money enters)
('job_payment', 'Pago de Trabajo', 'income', 0, 1),
('mission_reward', 'Recompensa de Misión', 'income', 0, 1),
('event_reward', 'Recompensa de Evento', 'income', 0, 1),
('loot_sell', 'Venta de Loot', 'income', 0, 1),
('government_payout', 'Pago del Gobierno', 'income', 0, 1),
('interest_earned', 'Interés Ganado', 'income', 0, 1),
('shop_refund', 'Reembolso de Tienda', 'income', 0, 1),

-- Sinks (money leaves)
('purchase_item', 'Compra de Item', 'expense', 1, 0),
('purchase_vehicle', 'Compra de Vehículo', 'expense', 1, 0),
('purchase_property', 'Compra de Propiedad', 'expense', 1, 0),
('tax_payment', 'Pago de Impuesto', 'expense', 1, 0),
('fine_payment', 'Pago de Multa', 'expense', 1, 0),
('insurance_payment', 'Pago de Seguro', 'expense', 1, 0),
('repair_cost', 'Costo de Reparación', 'expense', 1, 0),
('license_fee', 'Tarifa de Licencia', 'expense', 1, 0),
('impound_fee', 'Tarifa de Depósito', 'expense', 1, 0),
('crafting_cost', 'Costo de Fabricación', 'expense', 1, 0),
('maintenance_cost', 'Costo de Mantenimiento', 'expense', 1, 0),

-- Transfers (money moves)
('player_trade', 'Comercio entre Jugadores', 'transfer', 0, 0),
('faction_deposit', 'Depósito a Facción', 'transfer', 0, 0),
('faction_withdraw', 'Retiro de Facción', 'transfer', 0, 0),
('business_revenue', 'Ingresos de Negocio', 'transfer', 0, 0),
('contract_payment', 'Pago de Contrato', 'transfer', 0, 0),
('bank_deposit', 'Depósito Bancario', 'transfer', 0, 0),
('bank_withdraw', 'Retiro Bancario', 'transfer', 0, 0),

-- System
('admin_adjustment', 'Ajuste de Admin', 'system', 0, 0),
('correction', 'Corrección', 'system', 0, 0),
('initial_balance', 'Saldo Inicial', 'system', 0, 1);

-- ───────────────────────────────────────────────────────────────────────────────────────
-- TAX RATES
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_tax_rates (
    tax_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tax_type VARCHAR(64) NOT NULL,
    scope_type ENUM('global', 'zone', 'faction') NOT NULL DEFAULT 'global',
    scope_id BIGINT NULL,

    rate DECIMAL(5,2) NOT NULL COMMENT 'Percentage',
    min_amount INT NULL,
    max_amount INT NULL,

    active TINYINT(1) NOT NULL DEFAULT 1,
    valid_from DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until DATETIME NULL,

    UNIQUE KEY idx_tax_scope (tax_type, scope_type, scope_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default tax rates
INSERT INTO ait_tax_rates (tax_type, scope_type, rate) VALUES
('sales', 'global', 7.00),
('income', 'global', 15.00),
('property', 'global', 2.00),
('luxury', 'global', 25.00),
('transfer', 'global', 1.00);

-- ───────────────────────────────────────────────────────────────────────────────────────
-- MARKET PRICES
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_market_prices (
    sku VARCHAR(64) PRIMARY KEY,
    item_type ENUM('item', 'vehicle', 'property', 'service') NOT NULL,

    base_price INT NOT NULL,
    current_price INT NOT NULL,

    supply INT NOT NULL DEFAULT 1000,
    demand INT NOT NULL DEFAULT 1000,

    price_floor INT NULL,
    price_ceiling INT NULL,

    last_sale DATETIME NULL,
    total_sold INT NOT NULL DEFAULT 0,
    total_volume BIGINT NOT NULL DEFAULT 0,

    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- MARKET HISTORY
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_market_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sku VARCHAR(64) NOT NULL,
    price INT NOT NULL,
    volume INT NOT NULL DEFAULT 0,

    KEY idx_sku_ts (sku, ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- ECONOMY DAILY STATS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_economy_daily (
    day DATE PRIMARY KEY,

    -- Money supply
    total_cash BIGINT NOT NULL DEFAULT 0,
    total_bank BIGINT NOT NULL DEFAULT 0,
    total_crypto BIGINT NOT NULL DEFAULT 0,
    total_faction BIGINT NOT NULL DEFAULT 0,

    -- Flow
    money_generated BIGINT NOT NULL DEFAULT 0,
    money_destroyed BIGINT NOT NULL DEFAULT 0,
    tx_count INT NOT NULL DEFAULT 0,
    tx_volume BIGINT NOT NULL DEFAULT 0,

    -- Indices
    cpi INT NOT NULL DEFAULT 100 COMMENT 'Consumer Price Index (base 100)',
    weapons_index INT NOT NULL DEFAULT 100,
    housing_index INT NOT NULL DEFAULT 100,
    vehicle_index INT NOT NULL DEFAULT 100,

    -- Players
    active_players INT NOT NULL DEFAULT 0,
    new_players INT NOT NULL DEFAULT 0,
    avg_balance BIGINT NOT NULL DEFAULT 0,
    median_balance BIGINT NOT NULL DEFAULT 0,
    gini_coefficient FLOAT NULL COMMENT 'Inequality measure 0-1',

    meta JSON NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CRYPTO WALLETS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_crypto_wallets (
    wallet_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    player_id BIGINT NOT NULL,

    address VARCHAR(64) NOT NULL,
    public_key VARCHAR(128) NULL,

    balance_ait DECIMAL(18,8) NOT NULL DEFAULT 0 COMMENT 'Our token',
    balance_pending DECIMAL(18,8) NOT NULL DEFAULT 0,

    nonce INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity DATETIME NULL,

    status ENUM('active', 'frozen', 'locked') NOT NULL DEFAULT 'active',

    UNIQUE KEY idx_player (player_id),
    UNIQUE KEY idx_address (address),

    FOREIGN KEY (player_id) REFERENCES ait_players(player_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CRYPTO TRANSACTIONS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_crypto_transactions (
    crypto_tx_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    tx_hash VARCHAR(128) NULL COMMENT 'Blockchain tx hash',
    block_number BIGINT NULL,

    from_wallet_id BIGINT NULL,
    to_wallet_id BIGINT NULL,
    from_address VARCHAR(64) NULL,
    to_address VARCHAR(64) NULL,

    amount DECIMAL(18,8) NOT NULL,
    fee DECIMAL(18,8) NOT NULL DEFAULT 0,

    tx_type ENUM('transfer', 'deposit', 'withdraw', 'purchase', 'reward', 'burn') NOT NULL,

    status ENUM('pending', 'confirmed', 'failed', 'cancelled') NOT NULL DEFAULT 'pending',
    confirmations INT NOT NULL DEFAULT 0,

    reference_type VARCHAR(32) NULL,
    reference_id BIGINT NULL,

    meta JSON NULL,

    KEY idx_ts (ts),
    KEY idx_from (from_wallet_id),
    KEY idx_to (to_wallet_id),
    KEY idx_hash (tx_hash),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CREATE SYSTEM ACCOUNTS
-- ───────────────────────────────────────────────────────────────────────────────────────

INSERT INTO ait_accounts (owner_type, owner_id, currency, balance, status) VALUES
('system', 1, 'bank', 0, 'active'),  -- Treasury
('system', 2, 'bank', 0, 'active'),  -- Tax Pool
('system', 3, 'bank', 0, 'active'),  -- Sink Pool
('system', 4, 'crypto', 0, 'active'); -- Token Reserve
