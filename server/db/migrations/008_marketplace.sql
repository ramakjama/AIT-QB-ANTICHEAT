-- ============================================================================
-- AIT-QB Migration 008: Sistema de Mercado
-- Descripcion: Tablas para listados de venta y transacciones del marketplace
-- Fecha: 2026-01-25
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: ait_marketplace_listings
-- Descripcion: Listados de articulos en venta en el mercado
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_marketplace_listings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico del listado',
    `seller_id` INT UNSIGNED NOT NULL COMMENT 'ID del personaje vendedor',
    `item_name` VARCHAR(100) NOT NULL COMMENT 'Nombre del item para busqueda rapida',
    `item_data` JSON NOT NULL COMMENT 'Datos completos del item (nombre, cantidad, metadata, etc)',
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Cantidad de items en venta',
    `price` BIGINT UNSIGNED NOT NULL COMMENT 'Precio total solicitado',
    `price_per_unit` BIGINT UNSIGNED NOT NULL COMMENT 'Precio por unidad',
    `currency` ENUM('cash', 'bank', 'crypto', 'tokens') NOT NULL DEFAULT 'cash' COMMENT 'Tipo de moneda aceptada',
    `category` VARCHAR(50) NULL COMMENT 'Categoria del producto',
    `status` ENUM('active', 'sold', 'expired', 'cancelled', 'pending') NOT NULL DEFAULT 'active' COMMENT 'Estado del listado',
    `is_featured` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Listado destacado (promocionado)',
    `views_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Numero de visualizaciones',
    `expires_at` DATETIME NULL COMMENT 'Fecha de expiracion del listado',
    `sold_at` DATETIME NULL COMMENT 'Fecha y hora de venta',
    `sold_to` INT UNSIGNED NULL COMMENT 'ID del comprador (si se vendio)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de publicacion',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Ultima actualizacion',

    PRIMARY KEY (`id`),
    INDEX `idx_listings_seller` (`seller_id`),
    INDEX `idx_listings_status` (`status`),
    INDEX `idx_listings_category` (`category`),
    INDEX `idx_listings_item_name` (`item_name`),
    INDEX `idx_listings_price` (`price`),
    INDEX `idx_listings_expires` (`expires_at`),
    INDEX `idx_listings_featured` (`is_featured`, `status`),
    INDEX `idx_listings_created` (`created_at`),

    -- Indice compuesto para busquedas comunes
    INDEX `idx_listings_active_category` (`status`, `category`, `price`),

    CONSTRAINT `fk_listings_seller`
        FOREIGN KEY (`seller_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_listings_buyer`
        FOREIGN KEY (`sold_to`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Listados de articulos en el mercado';

-- ----------------------------------------------------------------------------
-- Tabla: ait_marketplace_transactions
-- Descripcion: Historial de transacciones completadas en el mercado
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_marketplace_transactions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico de la transaccion',
    `listing_id` INT UNSIGNED NULL COMMENT 'ID del listado original (puede ser NULL si se elimino)',
    `seller_id` INT UNSIGNED NOT NULL COMMENT 'ID del vendedor',
    `buyer_id` INT UNSIGNED NOT NULL COMMENT 'ID del comprador',
    `item_name` VARCHAR(100) NOT NULL COMMENT 'Nombre del item vendido',
    `item_data` JSON NOT NULL COMMENT 'Snapshot de los datos del item al momento de la venta',
    `quantity` INT UNSIGNED NOT NULL COMMENT 'Cantidad vendida',
    `sale_price` BIGINT UNSIGNED NOT NULL COMMENT 'Precio final de venta',
    `currency` ENUM('cash', 'bank', 'crypto', 'tokens') NOT NULL DEFAULT 'cash' COMMENT 'Moneda utilizada',
    `marketplace_fee` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Comision del mercado',
    `seller_received` BIGINT UNSIGNED NOT NULL COMMENT 'Cantidad recibida por el vendedor',
    `transaction_type` ENUM('direct', 'auction', 'offer', 'trade') NOT NULL DEFAULT 'direct' COMMENT 'Tipo de transaccion',
    `status` ENUM('completed', 'refunded', 'disputed', 'cancelled') NOT NULL DEFAULT 'completed' COMMENT 'Estado de la transaccion',
    `notes` TEXT NULL COMMENT 'Notas adicionales de la transaccion',
    `completed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de completado',

    PRIMARY KEY (`id`),
    INDEX `idx_transactions_listing` (`listing_id`),
    INDEX `idx_transactions_seller` (`seller_id`),
    INDEX `idx_transactions_buyer` (`buyer_id`),
    INDEX `idx_transactions_item` (`item_name`),
    INDEX `idx_transactions_date` (`completed_at`),
    INDEX `idx_transactions_status` (`status`),
    INDEX `idx_transactions_type` (`transaction_type`),

    -- Indices para reportes y estadisticas
    INDEX `idx_transactions_seller_date` (`seller_id`, `completed_at`),
    INDEX `idx_transactions_buyer_date` (`buyer_id`, `completed_at`),

    CONSTRAINT `fk_transactions_listing`
        FOREIGN KEY (`listing_id`)
        REFERENCES `ait_marketplace_listings` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `fk_transactions_seller`
        FOREIGN KEY (`seller_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_transactions_buyer`
        FOREIGN KEY (`buyer_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Historial de transacciones del mercado';

-- ----------------------------------------------------------------------------
-- Tabla: ait_marketplace_favorites
-- Descripcion: Listados marcados como favoritos por los jugadores
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_marketplace_favorites` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico',
    `char_id` INT UNSIGNED NOT NULL COMMENT 'ID del personaje',
    `listing_id` INT UNSIGNED NOT NULL COMMENT 'ID del listado favorito',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de marcado',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_favorite_char_listing` (`char_id`, `listing_id`),
    INDEX `idx_favorites_listing` (`listing_id`),

    CONSTRAINT `fk_favorites_char`
        FOREIGN KEY (`char_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_favorites_listing`
        FOREIGN KEY (`listing_id`)
        REFERENCES `ait_marketplace_listings` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Listados favoritos de los jugadores';

-- ----------------------------------------------------------------------------
-- Tabla: ait_marketplace_offers
-- Descripcion: Ofertas realizadas por compradores en listados
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_marketplace_offers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico de la oferta',
    `listing_id` INT UNSIGNED NOT NULL COMMENT 'ID del listado',
    `buyer_id` INT UNSIGNED NOT NULL COMMENT 'ID del personaje que hace la oferta',
    `offer_amount` BIGINT UNSIGNED NOT NULL COMMENT 'Cantidad ofrecida',
    `message` VARCHAR(500) NULL COMMENT 'Mensaje del comprador al vendedor',
    `status` ENUM('pending', 'accepted', 'rejected', 'expired', 'cancelled') NOT NULL DEFAULT 'pending' COMMENT 'Estado de la oferta',
    `response_message` VARCHAR(500) NULL COMMENT 'Respuesta del vendedor',
    `expires_at` DATETIME NOT NULL COMMENT 'Fecha de expiracion de la oferta',
    `responded_at` DATETIME NULL COMMENT 'Fecha de respuesta del vendedor',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de la oferta',

    PRIMARY KEY (`id`),
    INDEX `idx_offers_listing` (`listing_id`),
    INDEX `idx_offers_buyer` (`buyer_id`),
    INDEX `idx_offers_status` (`status`),
    INDEX `idx_offers_expires` (`expires_at`),

    CONSTRAINT `fk_offers_listing`
        FOREIGN KEY (`listing_id`)
        REFERENCES `ait_marketplace_listings` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_offers_buyer`
        FOREIGN KEY (`buyer_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Ofertas en listados del mercado';

-- ----------------------------------------------------------------------------
-- Vista: v_marketplace_active_listings
-- Descripcion: Vista rapida de listados activos con informacion del vendedor
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_marketplace_active_listings` AS
SELECT
    l.id,
    l.item_name,
    l.item_data,
    l.quantity,
    l.price,
    l.price_per_unit,
    l.currency,
    l.category,
    l.is_featured,
    l.views_count,
    l.expires_at,
    l.created_at,
    l.seller_id,
    c.first_name AS seller_first_name,
    c.last_name AS seller_last_name
FROM `ait_marketplace_listings` l
INNER JOIN `ait_characters` c ON l.seller_id = c.id
WHERE l.status = 'active'
    AND (l.expires_at IS NULL OR l.expires_at > NOW());
