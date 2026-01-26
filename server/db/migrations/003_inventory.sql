-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb DATABASE SCHEMA V1.0
-- Migration 003: Inventory System
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────────
-- DEFINICIONES DE ITEMS
-- Catálogo maestro de todos los items disponibles en el servidor
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_item_definitions (
    name VARCHAR(64) PRIMARY KEY COMMENT 'Identificador único del item (ej: water_bottle)',
    label VARCHAR(128) NOT NULL COMMENT 'Nombre mostrado al jugador',
    description TEXT NULL COMMENT 'Descripción del item',

    weight FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Peso en kg',
    stackable TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Si se puede apilar',
    max_stack INT NOT NULL DEFAULT 100 COMMENT 'Cantidad máxima por stack',

    `unique` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si cada unidad es única (con metadata individual)',
    usable TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si el item se puede usar/consumir',

    image VARCHAR(255) NULL COMMENT 'Ruta o URL de la imagen',
    model VARCHAR(128) NULL COMMENT 'Modelo 3D para drops',

    category VARCHAR(64) NOT NULL DEFAULT 'misc' COMMENT 'Categoría principal',
    subcategory VARCHAR(64) NULL COMMENT 'Subcategoría',

    rarity ENUM('common', 'uncommon', 'rare', 'epic', 'legendary', 'unique') NOT NULL DEFAULT 'common',

    -- Restricciones
    min_level INT NULL COMMENT 'Nivel mínimo para usar',
    required_license VARCHAR(64) NULL COMMENT 'Licencia requerida',
    job_restricted JSON NULL COMMENT 'Lista de trabajos que pueden usar',

    -- Propiedades de uso
    use_time INT NULL COMMENT 'Tiempo de uso en ms',
    use_animation VARCHAR(64) NULL COMMENT 'Animación al usar',
    use_effect VARCHAR(64) NULL COMMENT 'Efecto al usar',

    -- Economía
    default_price INT NULL COMMENT 'Precio base sugerido',
    can_sell TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Si se puede vender',
    can_trade TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Si se puede intercambiar',
    can_drop TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Si se puede tirar al suelo',

    -- Decaimiento
    decay_rate FLOAT NULL COMMENT 'Tasa de deterioro por hora (0-1)',
    expires_in INT NULL COMMENT 'Segundos hasta expirar desde creación',

    -- Metadata
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    active TINYINT(1) NOT NULL DEFAULT 1,
    meta JSON NULL COMMENT 'Datos adicionales específicos del item',

    KEY idx_category (category),
    KEY idx_subcategory (subcategory),
    KEY idx_rarity (rarity),
    KEY idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- INVENTARIOS
-- Contenedores de items (jugador, vehículo, propiedad, stash, etc.)
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_inventories (
    inventory_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    -- Propietario del inventario
    owner_type ENUM('char', 'vehicle', 'property', 'stash', 'trunk', 'glovebox', 'faction', 'shop', 'evidence', 'temp') NOT NULL,
    owner_id BIGINT NOT NULL COMMENT 'ID del propietario según owner_type',

    -- Identificador único opcional para stashes con nombre
    identifier VARCHAR(128) NULL COMMENT 'Identificador único para stashes nombrados',

    -- Configuración
    slots INT NOT NULL DEFAULT 50 COMMENT 'Número de slots disponibles',
    max_weight FLOAT NOT NULL DEFAULT 100.0 COMMENT 'Peso máximo en kg',
    current_weight FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Peso actual (calculado)',

    -- Estado
    locked TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si está bloqueado',
    locked_reason VARCHAR(128) NULL,
    access_level ENUM('public', 'private', 'faction', 'job', 'key') NOT NULL DEFAULT 'private',

    -- Permisos
    allowed_items JSON NULL COMMENT 'Lista de items permitidos (null = todos)',
    blocked_items JSON NULL COMMENT 'Lista de items bloqueados',

    -- Metadata
    label VARCHAR(128) NULL COMMENT 'Nombre personalizado del inventario',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_accessed DATETIME NULL COMMENT 'Última vez que se abrió',

    meta JSON NULL,

    UNIQUE KEY idx_owner (owner_type, owner_id),
    UNIQUE KEY idx_identifier (identifier),
    KEY idx_access_level (access_level),
    KEY idx_locked (locked)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- ITEMS EN INVENTARIO
-- Instancias de items dentro de inventarios
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_inventory_items (
    item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    inventory_id BIGINT NOT NULL,

    item_name VARCHAR(64) NOT NULL COMMENT 'Referencia a ait_item_definitions.name',
    amount INT NOT NULL DEFAULT 1 COMMENT 'Cantidad del item',

    slot INT NULL COMMENT 'Posición en el inventario (null = auto)',

    -- Durabilidad y estado
    durability FLOAT NULL COMMENT 'Durabilidad actual (0-100)',
    quality FLOAT NULL COMMENT 'Calidad del item (0-100)',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Cuando se creó esta instancia',
    expires_at DATETIME NULL COMMENT 'Cuando expira el item',

    -- Metadata del item específico
    metadata JSON NULL COMMENT 'Datos únicos de esta instancia (serial, ammo, etc.)',

    -- Origen del item (para tracking)
    source_type VARCHAR(32) NULL COMMENT 'craft, loot, purchase, trade, admin',
    source_id BIGINT NULL COMMENT 'ID de referencia del origen',
    source_char_id BIGINT NULL COMMENT 'Personaje que creó/obtuvo el item',

    KEY idx_inventory (inventory_id),
    KEY idx_item_name (item_name),
    KEY idx_slot (inventory_id, slot),
    KEY idx_expires (expires_at),
    KEY idx_source (source_type, source_id),

    FOREIGN KEY (inventory_id) REFERENCES ait_inventories(inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (item_name) REFERENCES ait_item_definitions(name) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- LOGS DE INVENTARIO
-- Historial de movimientos de items para auditoría
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_inventory_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ts DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Quién realizó la acción
    actor_player_id BIGINT NULL,
    actor_char_id BIGINT NULL,

    -- Tipo de acción
    action ENUM('add', 'remove', 'move', 'use', 'split', 'merge', 'decay', 'expire', 'admin') NOT NULL,

    -- Item afectado
    item_id BIGINT NULL COMMENT 'ID del item (puede ser null si fue eliminado)',
    item_name VARCHAR(64) NOT NULL,
    amount INT NOT NULL,

    -- Inventarios involucrados
    from_inventory_id BIGINT NULL,
    to_inventory_id BIGINT NULL,
    from_slot INT NULL,
    to_slot INT NULL,

    -- Contexto
    reason VARCHAR(255) NULL,
    metadata JSON NULL,

    KEY idx_ts (ts),
    KEY idx_actor (actor_char_id),
    KEY idx_action (action),
    KEY idx_item (item_name),
    KEY idx_from_inv (from_inventory_id),
    KEY idx_to_inv (to_inventory_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- RECETAS DE CRAFTEO
-- Definiciones de como fabricar items
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_crafting_recipes (
    recipe_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(64) NOT NULL COMMENT 'Identificador de la receta',
    label VARCHAR(128) NOT NULL COMMENT 'Nombre mostrado',

    result_item VARCHAR(64) NOT NULL COMMENT 'Item que se produce',
    result_amount INT NOT NULL DEFAULT 1,
    result_metadata JSON NULL COMMENT 'Metadata del item resultante',

    -- Ingredientes
    ingredients JSON NOT NULL COMMENT '[{"item":"wood","amount":5},...]',

    -- Requisitos
    workbench VARCHAR(64) NULL COMMENT 'Tipo de estación de trabajo requerida',
    min_skill_level INT NULL COMMENT 'Nivel mínimo de habilidad',
    skill_type VARCHAR(64) NULL COMMENT 'Tipo de habilidad requerida',
    required_job VARCHAR(64) NULL,

    -- Proceso
    craft_time INT NOT NULL DEFAULT 5000 COMMENT 'Tiempo en ms',
    xp_reward INT NOT NULL DEFAULT 0 COMMENT 'XP de crafting otorgada',
    success_chance FLOAT NOT NULL DEFAULT 100.0 COMMENT 'Probabilidad de éxito (%)',

    -- Estado
    active TINYINT(1) NOT NULL DEFAULT 1,

    UNIQUE KEY idx_name (name),
    KEY idx_result (result_item),
    KEY idx_workbench (workbench),
    KEY idx_active (active),

    FOREIGN KEY (result_item) REFERENCES ait_item_definitions(name) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────────────────
-- CATEGORÍAS DE ITEMS
-- ───────────────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ait_item_categories (
    category VARCHAR(64) PRIMARY KEY,
    label VARCHAR(128) NOT NULL,
    description TEXT NULL,
    icon VARCHAR(64) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    parent_category VARCHAR(64) NULL,

    KEY idx_parent (parent_category),
    KEY idx_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar categorías por defecto
INSERT INTO ait_item_categories (category, label, sort_order) VALUES
('weapons', 'Armas', 1),
('ammo', 'Munición', 2),
('food', 'Comida', 3),
('drinks', 'Bebidas', 4),
('medical', 'Médico', 5),
('tools', 'Herramientas', 6),
('materials', 'Materiales', 7),
('electronics', 'Electrónica', 8),
('clothing', 'Ropa', 9),
('accessories', 'Accesorios', 10),
('keys', 'Llaves', 11),
('documents', 'Documentos', 12),
('drugs', 'Drogas', 13),
('misc', 'Varios', 99);

-- ───────────────────────────────────────────────────────────────────────────────────────
-- ITEMS BASE DE EJEMPLO
-- ───────────────────────────────────────────────────────────────────────────────────────

INSERT INTO ait_item_definitions (name, label, weight, stackable, max_stack, usable, category, rarity, default_price) VALUES
-- Comida y bebida
('water_bottle', 'Botella de Agua', 0.5, 1, 20, 1, 'drinks', 'common', 10),
('sandwich', 'Sandwich', 0.3, 1, 10, 1, 'food', 'common', 25),
('energy_drink', 'Bebida Energética', 0.4, 1, 15, 1, 'drinks', 'common', 35),
('burger', 'Hamburguesa', 0.4, 1, 10, 1, 'food', 'common', 50),

-- Médico
('bandage', 'Vendaje', 0.1, 1, 50, 1, 'medical', 'common', 100),
('medkit', 'Botiquín', 1.0, 1, 5, 1, 'medical', 'uncommon', 500),
('painkillers', 'Analgésicos', 0.1, 1, 20, 1, 'medical', 'common', 150),

-- Herramientas
('lockpick', 'Ganzúa', 0.1, 1, 10, 1, 'tools', 'uncommon', 250),
('repair_kit', 'Kit de Reparación', 2.0, 1, 5, 1, 'tools', 'uncommon', 1000),
('flashlight', 'Linterna', 0.5, 1, 1, 1, 'tools', 'common', 150),

-- Materiales
('scrap_metal', 'Chatarra', 0.5, 1, 100, 0, 'materials', 'common', 5),
('plastic', 'Plástico', 0.2, 1, 100, 0, 'materials', 'common', 3),
('electronic_parts', 'Componentes Electrónicos', 0.3, 1, 50, 0, 'materials', 'uncommon', 25);
