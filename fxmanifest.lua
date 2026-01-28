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
-- SERVER SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

server_scripts {
    -- Driver MySQL
    '@oxmysql/lib/MySQL.lua',

    -- ⚡ SISTEMA DE ARRANQUE SEGURO ⚡
    -- Este script carga todos los módulos en el orden correcto
    -- para prevenir crashes por sobrecarga
    'installer/startup.lua',
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CLIENT SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

client_scripts {
    -- ⚡ SISTEMA DE ARRANQUE SEGURO ⚡
    -- El cliente se carga de forma controlada desde startup.lua
    -- No es necesario listar los scripts aquí
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
