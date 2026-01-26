-- ============================================================================
-- AIT-QB Migration 007: Sistema de Viviendas
-- Descripcion: Tablas para propiedades, interiores y control de acceso
-- Fecha: 2026-01-25
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: ait_properties
-- Descripcion: Almacena todas las propiedades disponibles en el servidor
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_properties` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico de la propiedad',
    `type` ENUM('house', 'apartment', 'garage', 'business', 'warehouse') NOT NULL DEFAULT 'house' COMMENT 'Tipo de propiedad',
    `name` VARCHAR(100) NULL COMMENT 'Nombre personalizado de la propiedad',
    `description` TEXT NULL COMMENT 'Descripcion de la propiedad',
    `coords_x` FLOAT NOT NULL COMMENT 'Coordenada X de la entrada',
    `coords_y` FLOAT NOT NULL COMMENT 'Coordenada Y de la entrada',
    `coords_z` FLOAT NOT NULL COMMENT 'Coordenada Z de la entrada',
    `coords_heading` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Direccion de orientacion al entrar',
    `interior` VARCHAR(50) NOT NULL COMMENT 'Identificador del interior (IPL o MLO)',
    `interior_coords_x` FLOAT NOT NULL COMMENT 'Coordenada X dentro del interior',
    `interior_coords_y` FLOAT NOT NULL COMMENT 'Coordenada Y dentro del interior',
    `interior_coords_z` FLOAT NOT NULL COMMENT 'Coordenada Z dentro del interior',
    `owner_id` INT UNSIGNED NULL COMMENT 'ID del personaje propietario (NULL si esta en venta)',
    `price` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Precio de compra de la propiedad',
    `rent_price` INT UNSIGNED NULL COMMENT 'Precio de alquiler mensual (opcional)',
    `furniture` JSON NULL COMMENT 'Datos de muebles y decoracion en formato JSON',
    `storage_capacity` INT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Capacidad de almacenamiento (peso maximo)',
    `garage_slots` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Numero de espacios de garage',
    `is_locked` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Estado del cerrojo (1=cerrado, 0=abierto)',
    `is_for_sale` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Indica si esta disponible para compra',
    `purchased_at` DATETIME NULL COMMENT 'Fecha y hora de compra',
    `last_visited` DATETIME NULL COMMENT 'Ultima visita del propietario',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creacion del registro',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Ultima actualizacion',

    PRIMARY KEY (`id`),
    INDEX `idx_properties_owner` (`owner_id`),
    INDEX `idx_properties_type` (`type`),
    INDEX `idx_properties_for_sale` (`is_for_sale`),
    INDEX `idx_properties_coords` (`coords_x`, `coords_y`, `coords_z`),

    CONSTRAINT `fk_properties_owner`
        FOREIGN KEY (`owner_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Propiedades y viviendas del servidor';

-- ----------------------------------------------------------------------------
-- Tabla: ait_property_access
-- Descripcion: Control de acceso a propiedades (llaves compartidas)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_property_access` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico del registro',
    `property_id` INT UNSIGNED NOT NULL COMMENT 'ID de la propiedad',
    `char_id` INT UNSIGNED NOT NULL COMMENT 'ID del personaje con acceso',
    `access_level` ENUM('visitor', 'tenant', 'manager', 'owner') NOT NULL DEFAULT 'visitor' COMMENT 'Nivel de acceso otorgado',
    `can_manage_furniture` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Permiso para modificar muebles',
    `can_access_storage` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Permiso para acceder al almacenamiento',
    `can_invite_others` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Permiso para invitar a otros jugadores',
    `granted_by` INT UNSIGNED NULL COMMENT 'ID del personaje que otorgo el acceso',
    `expires_at` DATETIME NULL COMMENT 'Fecha de expiracion del acceso (NULL=permanente)',
    `notes` VARCHAR(255) NULL COMMENT 'Notas adicionales sobre el acceso',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creacion',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Ultima actualizacion',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_property_char` (`property_id`, `char_id`),
    INDEX `idx_access_char` (`char_id`),
    INDEX `idx_access_level` (`access_level`),
    INDEX `idx_access_expires` (`expires_at`),

    CONSTRAINT `fk_access_property`
        FOREIGN KEY (`property_id`)
        REFERENCES `ait_properties` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_access_char`
        FOREIGN KEY (`char_id`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_access_granted_by`
        FOREIGN KEY (`granted_by`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Control de acceso y permisos para propiedades';

-- ----------------------------------------------------------------------------
-- Tabla: ait_property_furniture
-- Descripcion: Inventario detallado de muebles por propiedad
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ait_property_furniture` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador unico del mueble',
    `property_id` INT UNSIGNED NOT NULL COMMENT 'ID de la propiedad',
    `furniture_type` VARCHAR(50) NOT NULL COMMENT 'Tipo/modelo del mueble',
    `position_x` FLOAT NOT NULL COMMENT 'Posicion X dentro del interior',
    `position_y` FLOAT NOT NULL COMMENT 'Posicion Y dentro del interior',
    `position_z` FLOAT NOT NULL COMMENT 'Posicion Z dentro del interior',
    `rotation_x` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Rotacion en eje X',
    `rotation_y` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Rotacion en eje Y',
    `rotation_z` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Rotacion en eje Z',
    `metadata` JSON NULL COMMENT 'Datos adicionales del mueble (color, estado, etc)',
    `placed_by` INT UNSIGNED NULL COMMENT 'ID del personaje que coloco el mueble',
    `placed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de colocacion',

    PRIMARY KEY (`id`),
    INDEX `idx_furniture_property` (`property_id`),
    INDEX `idx_furniture_type` (`furniture_type`),

    CONSTRAINT `fk_furniture_property`
        FOREIGN KEY (`property_id`)
        REFERENCES `ait_properties` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `fk_furniture_placed_by`
        FOREIGN KEY (`placed_by`)
        REFERENCES `ait_characters` (`id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Muebles y decoracion colocados en propiedades';

-- ----------------------------------------------------------------------------
-- Indices adicionales para optimizacion de consultas frecuentes
-- ----------------------------------------------------------------------------

-- Indice para busqueda de propiedades cercanas (radio de busqueda)
-- Util para mostrar propiedades disponibles en el mapa
CREATE INDEX `idx_properties_location` ON `ait_properties` (`coords_x`, `coords_y`);

-- Indice para propiedades por rango de precio
CREATE INDEX `idx_properties_price_range` ON `ait_properties` (`price`, `is_for_sale`);
