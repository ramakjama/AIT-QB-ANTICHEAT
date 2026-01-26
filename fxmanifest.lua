-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb - Advanced Intelligence Technology for QBCore
-- Framework de servidor FiveM de próxima generación
-- Versión: 1.0.0
-- Servidor Español - 2048 slots
-- ═══════════════════════════════════════════════════════════════════════════════════════

fx_version 'cerulean'
game 'gta5'

name 'ait-qb'
author 'AIT-QB Team'
description 'Framework completo de servidor RP con economía, facciones, misiones, marketplace y más'
version '1.0.0'

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- DEPENDENCIAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SHARED (Cliente y Servidor)
-- ═══════════════════════════════════════════════════════════════════════════════════════

shared_scripts {
    -- Inicialización de ox_lib
    '@ox_lib/init.lua',

    -- Configuración global
    'shared/config/main.lua',
    'shared/config/economy.lua',
    'shared/config/security.lua',
    'shared/config/features.lua',
    'shared/config/marketplace.lua',
    'shared/config/vehicles.lua',
    'shared/config/jobs.lua',

    -- Enums y constantes
    'shared/enums/*.lua',

    -- Schemas de validación
    'shared/schemas/*.lua',

    -- Utilidades compartidas
    'shared/utils/math.lua',
    'shared/utils/string.lua',
    'shared/utils/table.lua',
    'shared/utils/validation.lua',
    'shared/utils/crypto.lua',

    -- Locales
    'shared/locales/es.lua',
    'shared/locales/en.lua',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SERVER SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

server_scripts {
    -- Driver MySQL
    '@oxmysql/lib/MySQL.lua',

    -- Core Engine
    'core/bootstrap.lua',
    'core/di.lua',
    'core/eventbus.lua',
    'core/state.lua',
    'core/cache.lua',
    'core/scheduler.lua',
    'core/rbac.lua',
    'core/audit.lua',
    'core/ratelimit.lua',
    'core/featureflags.lua',
    'core/rules.lua',
    'core/exports.lua',

    -- Bridges
    'bridges/qbcore.lua',
    'bridges/ox.lua',
    'bridges/inventory_ox.lua',
    'bridges/inventory_qb.lua',

    -- Database
    'server/db/connection.lua',
    'server/db/repositories/base.lua',
    'server/db/repositories/player.lua',
    'server/db/repositories/character.lua',

    -- Engines - Economy
    'server/engines/economy/init.lua',

    -- Engines - Inventory
    'server/engines/inventory/init.lua',

    -- Engines - Factions
    'server/engines/factions/init.lua',
    'server/engines/factions/duties.lua',
    'server/engines/factions/management.lua',

    -- Engines - Missions
    'server/engines/missions/init.lua',
    'server/engines/missions/generator.lua',
    'server/engines/missions/tracker.lua',

    -- Engines - Events
    'server/engines/events/init.lua',
    'server/engines/events/scheduler.lua',
    'server/engines/events/types/init.lua',

    -- Engines - Vehicles
    'server/engines/vehicles/init.lua',
    'server/engines/vehicles/garage.lua',
    'server/engines/vehicles/fuel.lua',
    'server/engines/vehicles/keys.lua',

    -- Engines - Housing
    'server/engines/housing/init.lua',
    'server/engines/housing/furniture.lua',
    'server/engines/housing/access.lua',

    -- Engines - Combat
    'server/engines/combat/init.lua',
    'server/engines/combat/death.lua',
    'server/engines/combat/weapons.lua',

    -- Engines - AI
    'server/engines/ai/init.lua',
    'server/engines/ai/behavior.lua',
    'server/engines/ai/spawner.lua',

    -- Engines - Justice
    'server/engines/justice/init.lua',
    'server/engines/justice/wanted.lua',
    'server/engines/justice/jail.lua',

    -- Admin
    'admin/init.lua',

    -- Server principal
    'server/main.lua',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CLIENT SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

client_scripts {
    -- Core del cliente
    'client/main.lua',

    -- Módulos del cliente
    'client/modules/hud/init.lua',
    'client/modules/interactions/init.lua',
    'client/modules/character/init.lua',
    'client/modules/vehicles/init.lua',

    -- Jobs del cliente
    'modules/jobs/police/init.lua',
    'modules/jobs/ambulance/init.lua',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- DATA FILES
-- ═══════════════════════════════════════════════════════════════════════════════════════

files {
    -- Datos de items
    'data/items/weapons.lua',
    'data/items/consumables.lua',
    'data/items/materials.lua',
    'data/items/drugs.lua',
    'data/items/misc.lua',

    -- Datos de vehículos
    'data/vehicles/catalog.lua',

    -- Datos de trabajos
    'data/jobs/catalog.lua',

    -- Datos de loot
    'data/loot/tables.lua',

    -- UI (cuando se implemente)
    'ui/dist/**/*',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- LUA54
-- ═══════════════════════════════════════════════════════════════════════════════════════

lua54 'yes'

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS - SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Core
exports {
    'GetVersion',
    'IsReady',
}

-- Player Management
exports {
    'GetPlayer',
    'GetPlayerByIdentifier',
    'GetPlayers',
    'Notify',
    'SaveCharacter',
}

-- Callbacks
exports {
    'RegisterCallback',
}

-- Economy
exports {
    'AddMoney',
    'RemoveMoney',
    'GetMoney',
    'Transfer',
}

-- RBAC
exports {
    'HasPermission',
    'RequirePermission',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS - CLIENTE
-- ═══════════════════════════════════════════════════════════════════════════════════════

client_exports {
    'GetPlayerData',
    'IsReady',
    'Notify',
    'ProgressBar',
    'GetCoords',
    'GetClosestPlayer',
    'TriggerCallback',
}
