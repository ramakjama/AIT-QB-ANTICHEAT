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

    -- ⚡ CARGA CONTROLADA - FASE 0: Configuración Global ⚡
    'shared/config/main.lua',
    'shared/config/economy.lua',
    'shared/config/security.lua',
    'shared/config/features.lua',
    'shared/config/marketplace.lua',
    'shared/config/vehicles.lua',
    'shared/config/jobs.lua',
    'shared/config/anticheat.lua',

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
-- SERVER SCRIPTS - CARGA ORDENADA EN FASES
-- ═══════════════════════════════════════════════════════════════════════════════════════

server_scripts {
    -- Driver MySQL
    '@oxmysql/lib/MySQL.lua',

    -- ⚡ FASE 1: Core Engine (CRÍTICO) ⚡
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

    -- ⚡ FASE 2: Bridges (CRÍTICO) ⚡
    'bridges/qbcore.lua',
    'bridges/ox.lua',
    'bridges/inventory_ox.lua',
    'bridges/inventory_qb.lua',

    -- ⚡ FASE 3: Base de Datos (CRÍTICO) ⚡
    'server/db/connection.lua',
    'server/db/repositories/base.lua',
    'server/db/repositories/player.lua',
    'server/db/repositories/character.lua',

    -- ⚡ FASE 4: Engines Básicos (CRÍTICO) ⚡
    'server/engines/economy/init.lua',
    'server/engines/inventory/init.lua',

    -- ⚡ FASE 5: Engines Opcionales ⚡
    'server/engines/factions/init.lua',
    'server/engines/factions/duties.lua',
    'server/engines/factions/management.lua',

    'server/engines/missions/init.lua',
    'server/engines/missions/generator.lua',
    'server/engines/missions/tracker.lua',

    'server/engines/events/init.lua',
    'server/engines/events/scheduler.lua',
    'server/engines/events/types/init.lua',

    'server/engines/vehicles/init.lua',
    'server/engines/vehicles/garage.lua',
    'server/engines/vehicles/fuel.lua',
    'server/engines/vehicles/keys.lua',

    'server/engines/housing/init.lua',
    'server/engines/housing/furniture.lua',
    'server/engines/housing/access.lua',

    'server/engines/combat/init.lua',
    'server/engines/combat/death.lua',
    'server/engines/combat/weapons.lua',

    'server/engines/ai/init.lua',
    'server/engines/ai/behavior.lua',
    'server/engines/ai/spawner.lua',

    'server/engines/justice/init.lua',
    'server/engines/justice/wanted.lua',
    'server/engines/justice/jail.lua',

    -- ⚡ FASE 6: Anticheat (CRÍTICO) ⚡
    'server/engines/anticheat/signatures.lua',
    'server/engines/anticheat/validator.lua',
    'server/engines/anticheat/init.lua',
    'server/engines/anticheat/commands.lua',
    'server/engines/anticheat/advanced.lua',
    'server/engines/anticheat/panel.lua',

    -- ⚡ FASE 7: Admin ⚡
    'admin/init.lua',
    'admin/commands.lua',

    -- ⚡ FASE 8: Server Handlers ⚡
    'server/handlers/jobs.lua',
    'server/handlers/phone.lua',
    'server/handlers/scoreboard.lua',

    -- ⚡ FASE 9: Server Principal ⚡
    'server/main.lua',

    -- ⚡ SISTEMA DE MONITOREO ⚡
    -- Este script solo MONITOREA la carga, NO la controla
    'installer/startup_monitor.lua',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CLIENT SCRIPTS - CARGA ORDENADA
-- ═══════════════════════════════════════════════════════════════════════════════════════

client_scripts {
    -- ⚡ FASE 1: Core del Cliente ⚡
    'client/main.lua',

    -- ⚡ FASE 2: Módulos Básicos del Cliente ⚡
    'client/modules/hud/init.lua',
    'client/modules/interactions/init.lua',
    'client/modules/character/init.lua',
    'client/modules/vehicles/init.lua',

    -- ⚡ FASE 3: Anticheat del Cliente ⚡
    'client/modules/anticheat/init.lua',
    'client/modules/anticheat/nui.lua',

    -- ⚡ FASE 4: Jobs del Cliente - Emergencias ⚡
    'modules/jobs/police/init.lua',
    'modules/jobs/ambulance/init.lua',

    -- ⚡ FASE 5: Jobs Legales ⚡
    'modules/jobs/mechanic/init.lua',
    'modules/jobs/taxi/init.lua',
    'modules/jobs/trucker/init.lua',
    'modules/jobs/garbage/init.lua',
    'modules/jobs/fishing/init.lua',
    'modules/jobs/mining/init.lua',
    'modules/jobs/lumberjack/init.lua',
    'modules/jobs/hunting/init.lua',
    'modules/jobs/delivery/init.lua',

    -- ⚡ FASE 6: Jobs Ilegales ⚡
    'modules/jobs/drugs/init.lua',
    'modules/jobs/robbery/init.lua',
    'modules/jobs/chopshop/init.lua',
    'modules/jobs/weapons/init.lua',
    'modules/jobs/laundering/init.lua',
    'modules/jobs/gangs/init.lua',

    -- ⚡ FASE 7: Módulos Adicionales del Cliente ⚡
    'client/modules/phone/init.lua',
    'client/modules/housing/init.lua',
    'client/modules/admin/init.lua',
    'client/modules/scoreboard/init.lua',
    'client/modules/inventory/init.lua',
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

    -- UI
    'ui/**/*',

    -- Configuración del instalador
    'installer/startup_config.json',
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
