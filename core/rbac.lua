-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb RBAC SYSTEM
-- Role-Based Access Control con permisos granulares
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}

AIT.RBAC = {
    roles = {},
    permissions = {},
    bindings = {},
    cache = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CATÁLOGO DE PERMISOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT.RBAC.PermissionCatalog = {
    -- Core
    ['core.state.read']           = { category = 'core', risk = 'low' },
    ['core.state.write']          = { category = 'core', risk = 'high' },
    ['core.featureflags.read']    = { category = 'core', risk = 'low' },
    ['core.featureflags.write']   = { category = 'core', risk = 'high' },
    ['core.config.read']          = { category = 'core', risk = 'low' },
    ['core.config.write']         = { category = 'core', risk = 'critical' },

    -- Economy
    ['economy.read']              = { category = 'economy', risk = 'low' },
    ['economy.balance.view']      = { category = 'economy', risk = 'low' },
    ['economy.balance.adjust']    = { category = 'economy', risk = 'critical' },
    ['economy.tx.create']         = { category = 'economy', risk = 'med' },
    ['economy.tx.reverse']        = { category = 'economy', risk = 'high' },
    ['economy.market.set']        = { category = 'economy', risk = 'high' },
    ['economy.tax.set']           = { category = 'economy', risk = 'high' },
    ['economy.crypto.admin']      = { category = 'economy', risk = 'critical' },

    -- Inventory
    ['inventory.read']            = { category = 'inventory', risk = 'low' },
    ['inventory.give']            = { category = 'inventory', risk = 'high' },
    ['inventory.remove']          = { category = 'inventory', risk = 'high' },
    ['inventory.move']            = { category = 'inventory', risk = 'med' },
    ['inventory.stash.manage']    = { category = 'inventory', risk = 'med' },
    ['inventory.catalog.edit']    = { category = 'inventory', risk = 'high' },

    -- Factions
    ['faction.create']            = { category = 'faction', risk = 'high' },
    ['faction.delete']            = { category = 'faction', risk = 'critical' },
    ['faction.invite']            = { category = 'faction', risk = 'low' },
    ['faction.kick']              = { category = 'faction', risk = 'med' },
    ['faction.rank.set']          = { category = 'faction', risk = 'med' },
    ['faction.funds.access']      = { category = 'faction', risk = 'high' },
    ['faction.territory.manage']  = { category = 'faction', risk = 'med' },

    -- Missions
    ['mission.start']             = { category = 'mission', risk = 'low' },
    ['mission.complete.manual']   = { category = 'mission', risk = 'high' },
    ['mission.template.create']   = { category = 'mission', risk = 'med' },
    ['mission.template.edit']     = { category = 'mission', risk = 'med' },
    ['mission.reward.grant']      = { category = 'mission', risk = 'high' },

    -- Events
    ['event.start']               = { category = 'event', risk = 'med' },
    ['event.stop']                = { category = 'event', risk = 'med' },
    ['event.edit']                = { category = 'event', risk = 'med' },

    -- Vehicles
    ['vehicle.spawn']             = { category = 'vehicle', risk = 'med' },
    ['vehicle.delete']            = { category = 'vehicle', risk = 'high' },
    ['vehicle.impound']           = { category = 'vehicle', risk = 'low' },
    ['vehicle.release']           = { category = 'vehicle', risk = 'low' },

    -- Housing
    ['housing.create']            = { category = 'housing', risk = 'med' },
    ['housing.delete']            = { category = 'housing', risk = 'high' },
    ['housing.access.override']   = { category = 'housing', risk = 'high' },

    -- Security
    ['security.flag.read']        = { category = 'security', risk = 'low' },
    ['security.flag.resolve']     = { category = 'security', risk = 'med' },
    ['security.quarantine']       = { category = 'security', risk = 'high' },
    ['security.ban.create']       = { category = 'security', risk = 'high' },
    ['security.ban.revoke']       = { category = 'security', risk = 'high' },

    -- Audit
    ['audit.read']                = { category = 'audit', risk = 'med' },
    ['audit.query']               = { category = 'audit', risk = 'med' },
    ['audit.export']              = { category = 'audit', risk = 'med' },

    -- Admin
    ['admin.player.view']         = { category = 'admin', risk = 'low' },
    ['admin.player.kick']         = { category = 'admin', risk = 'med' },
    ['admin.player.teleport']     = { category = 'admin', risk = 'low' },
    ['admin.player.spectate']     = { category = 'admin', risk = 'low' },
    ['admin.player.freeze']       = { category = 'admin', risk = 'med' },
    ['admin.server.restart']      = { category = 'admin', risk = 'critical' },
    ['admin.resource.manage']     = { category = 'admin', risk = 'critical' },
    ['admin.safe.execute']        = { category = 'admin', risk = 'critical' },
    ['admin.safe.approve']        = { category = 'admin', risk = 'critical' },

    -- Analytics
    ['analytics.view']            = { category = 'analytics', risk = 'low' },
    ['analytics.export']          = { category = 'analytics', risk = 'med' },

    -- Marketplace
    ['shop.products.manage']      = { category = 'shop', risk = 'high' },
    ['shop.orders.view']          = { category = 'shop', risk = 'low' },
    ['shop.orders.refund']        = { category = 'shop', risk = 'high' },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ROLES POR DEFECTO
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT.RBAC.DefaultRoles = {
    player = {
        name = 'Player',
        priority = 1000,
        permissions = {}
    },
    vip = {
        name = 'VIP',
        priority = 900,
        permissions = {}
    },
    helper = {
        name = 'Helper',
        priority = 500,
        permissions = {
            'admin.player.view',
            'admin.player.spectate',
            'audit.read'
        }
    },
    moderator = {
        name = 'Moderator',
        priority = 400,
        permissions = {
            'admin.player.view',
            'admin.player.kick',
            'admin.player.teleport',
            'admin.player.spectate',
            'admin.player.freeze',
            'security.flag.read',
            'security.flag.resolve',
            'audit.read',
            'audit.query'
        }
    },
    admin = {
        name = 'Admin',
        priority = 200,
        permissions = {
            'admin.*',
            'security.*',
            'audit.*',
            'economy.read',
            'economy.balance.view',
            'inventory.read',
            'inventory.give',
            'vehicle.spawn',
            'vehicle.impound',
            'event.start',
            'event.stop',
            'mission.start',
        }
    },
    senior_admin = {
        name = 'Senior Admin',
        priority = 100,
        permissions = {
            'admin.*',
            'security.*',
            'audit.*',
            'economy.*',
            'inventory.*',
            'vehicle.*',
            'event.*',
            'mission.*',
            'faction.create',
            'housing.*',
            'analytics.*'
        }
    },
    developer = {
        name = 'Developer',
        priority = 50,
        permissions = {
            'core.*',
            'admin.*',
            'security.*',
            'audit.*',
            'economy.*',
            'inventory.*',
            'vehicle.*',
            'event.*',
            'mission.*',
            'faction.*',
            'housing.*',
            'analytics.*',
            'shop.*'
        }
    },
    owner = {
        name = 'Owner',
        priority = 1,
        permissions = { '*' }
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.RBAC.Initialize()
    -- Crear tabla de permisos si no existe
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_rbac_permissions (
            perm VARCHAR(128) PRIMARY KEY,
            category VARCHAR(64) NOT NULL,
            risk ENUM('low', 'med', 'high', 'critical') NOT NULL DEFAULT 'low',
            description TEXT NULL,
            meta JSON NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Crear tabla de roles
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_rbac_roles (
            role_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            scope_type ENUM('global', 'faction', 'business', 'zone') NOT NULL DEFAULT 'global',
            scope_id BIGINT NULL,
            name VARCHAR(64) NOT NULL,
            display_name VARCHAR(128) NULL,
            priority INT NOT NULL DEFAULT 100,
            color VARCHAR(16) NULL,
            meta JSON NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_scope (scope_type, scope_id),
            KEY idx_name (name),
            KEY idx_priority (priority)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Crear tabla de permisos por rol
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_rbac_role_permissions (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            role_id BIGINT NOT NULL,
            permission VARCHAR(128) NOT NULL,
            UNIQUE KEY idx_role_perm (role_id, permission),
            FOREIGN KEY (role_id) REFERENCES ait_rbac_roles(role_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Crear tabla de bindings
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ait_rbac_bindings (
            binding_id BIGINT AUTO_INCREMENT PRIMARY KEY,
            role_id BIGINT NOT NULL,
            subject_type ENUM('player', 'char') NOT NULL,
            subject_id BIGINT NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            created_by BIGINT NULL,
            expires_at DATETIME NULL,
            meta JSON NULL,
            KEY idx_subject (subject_type, subject_id),
            KEY idx_expires (expires_at),
            FOREIGN KEY (role_id) REFERENCES ait_rbac_roles(role_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Insertar permisos por defecto
    for perm, meta in pairs(AIT.RBAC.PermissionCatalog) do
        MySQL.insert.await([[
            INSERT IGNORE INTO ait_rbac_permissions (perm, category, risk)
            VALUES (?, ?, ?)
        ]], { perm, meta.category, meta.risk })
    end

    -- Insertar roles por defecto
    for roleKey, roleDef in pairs(AIT.RBAC.DefaultRoles) do
        local existing = MySQL.query.await(
            'SELECT role_id FROM ait_rbac_roles WHERE name = ? AND scope_type = ?',
            { roleKey, 'global' }
        )

        if not existing or #existing == 0 then
            local roleId = MySQL.insert.await([[
                INSERT INTO ait_rbac_roles (scope_type, name, display_name, priority)
                VALUES ('global', ?, ?, ?)
            ]], { roleKey, roleDef.name, roleDef.priority })

            -- Insertar permisos del rol
            for _, perm in ipairs(roleDef.permissions) do
                MySQL.insert.await([[
                    INSERT INTO ait_rbac_role_permissions (role_id, permission)
                    VALUES (?, ?)
                ]], { roleId, perm })
            end
        end
    end

    -- Cargar roles en memoria
    AIT.RBAC.LoadRoles()

    if AIT.Log then
        AIT.Log.info('RBAC', 'RBAC system initialized')
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CARGAR ROLES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.RBAC.LoadRoles()
    local roles = MySQL.query.await([[
        SELECT r.*, GROUP_CONCAT(rp.permission) as permissions
        FROM ait_rbac_roles r
        LEFT JOIN ait_rbac_role_permissions rp ON r.role_id = rp.role_id
        GROUP BY r.role_id
    ]])

    AIT.RBAC.roles = {}
    for _, role in ipairs(roles or {}) do
        local perms = {}
        if role.permissions then
            for perm in string.gmatch(role.permissions, '[^,]+') do
                table.insert(perms, perm)
            end
        end

        AIT.RBAC.roles[role.role_id] = {
            id = role.role_id,
            name = role.name,
            displayName = role.display_name,
            scopeType = role.scope_type,
            scopeId = role.scope_id,
            priority = role.priority,
            permissions = perms
        }
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- VERIFICAR PERMISOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Verifica si un jugador tiene un permiso
---@param source number Server ID del jugador
---@param permission string Permiso a verificar
---@param scope? table Scope opcional { type, id }
---@return boolean
function AIT.RBAC.HasPermission(source, permission, scope)
    if not source or source <= 0 then return false end

    -- Check ACE primero (para consola y txAdmin)
    if IsPlayerAceAllowed(source, 'ait.' .. permission) then
        return true
    end

    -- Obtener player ID
    local playerId = AIT.RBAC.GetPlayerId(source)
    if not playerId then return false end

    -- Cache key
    local cacheKey = string.format('%d:%s:%s:%s',
        playerId,
        permission,
        scope and scope.type or 'global',
        scope and scope.id or 'all'
    )

    -- Verificar cache
    if AIT.RBAC.cache[cacheKey] ~= nil then
        local cached = AIT.RBAC.cache[cacheKey]
        if cached.expires > os.time() then
            return cached.value
        end
    end

    -- Obtener roles del jugador
    local roles = AIT.RBAC.GetPlayerRoles(playerId, scope and scope.type, scope and scope.id)

    -- Verificar permisos de cada rol
    for _, roleData in ipairs(roles) do
        local role = AIT.RBAC.roles[roleData.role_id]
        if role then
            for _, perm in ipairs(role.permissions) do
                if AIT.RBAC.MatchPermission(perm, permission) then
                    AIT.RBAC.cache[cacheKey] = { value = true, expires = os.time() + 300 }
                    return true
                end
            end
        end
    end

    AIT.RBAC.cache[cacheKey] = { value = false, expires = os.time() + 60 }
    return false
end

--- Match de permisos con wildcards
---@param granted string Permiso concedido
---@param requested string Permiso solicitado
---@return boolean
function AIT.RBAC.MatchPermission(granted, requested)
    if granted == requested then return true end
    if granted == '*' then return true end

    -- Wildcard de categoría (ej: 'economy.*')
    if granted:sub(-2) == '.*' then
        local prefix = granted:sub(1, -3)
        if requested:sub(1, #prefix) == prefix then
            return true
        end
    end

    return false
end

--- Requiere un permiso (lanza error si no tiene)
---@param source number
---@param permission string
---@param scope? table
---@return boolean, string?
function AIT.RBAC.Require(source, permission, scope)
    if not AIT.RBAC.HasPermission(source, permission, scope) then
        if AIT.Audit then
            AIT.Audit.Log(source, 'RBAC:PermissionDenied', nil, {
                permission = permission,
                scope = scope
            }, 'warn')
        end
        return false, 'Permission denied: ' .. permission
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- OBTENER ROLES DE JUGADOR
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.RBAC.GetPlayerRoles(playerId, scopeType, scopeId)
    local query = [[
        SELECT r.*
        FROM ait_rbac_bindings b
        JOIN ait_rbac_roles r ON b.role_id = r.role_id
        WHERE b.subject_type = 'player' AND b.subject_id = ?
        AND (b.expires_at IS NULL OR b.expires_at > NOW())
    ]]
    local params = { playerId }

    if scopeType then
        query = query .. ' AND r.scope_type = ?'
        table.insert(params, scopeType)
    end

    if scopeId then
        query = query .. ' AND (r.scope_id IS NULL OR r.scope_id = ?)'
        table.insert(params, scopeId)
    end

    query = query .. ' ORDER BY r.priority ASC'

    return MySQL.query.await(query, params) or {}
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ASIGNAR / REVOCAR ROLES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Asigna un rol a un jugador
---@param source number Quien asigna
---@param targetPlayerId number A quien se asigna
---@param roleId number ID del rol
---@param expiresAt? string Fecha de expiración
---@return boolean, string?
function AIT.RBAC.Grant(source, targetPlayerId, roleId, expiresAt)
    local role = AIT.RBAC.roles[roleId]
    if not role then
        return false, 'Role not found'
    end

    -- Verificar que quien asigna tenga mayor prioridad
    if source and source > 0 then
        local assignerId = AIT.RBAC.GetPlayerId(source)
        if assignerId then
            local assignerRoles = AIT.RBAC.GetPlayerRoles(assignerId)
            local assignerPriority = 9999

            for _, r in ipairs(assignerRoles) do
                if r.priority < assignerPriority then
                    assignerPriority = r.priority
                end
            end

            if role.priority <= assignerPriority then
                return false, 'Cannot grant role with higher or equal priority'
            end
        end
    end

    -- Crear binding
    MySQL.insert.await([[
        INSERT INTO ait_rbac_bindings (role_id, subject_type, subject_id, expires_at, created_by)
        VALUES (?, 'player', ?, ?, ?)
    ]], { roleId, targetPlayerId, expiresAt, source and AIT.RBAC.GetPlayerId(source) })

    -- Invalidar cache
    AIT.RBAC.InvalidateCache(targetPlayerId)

    if AIT.Audit then
        AIT.Audit.Log(source, 'RBAC:RoleGranted', targetPlayerId, {
            role_id = roleId,
            role_name = role.name,
            expires_at = expiresAt
        })
    end

    return true
end

--- Revoca un rol de un jugador
---@param source number Quien revoca
---@param targetPlayerId number A quien se revoca
---@param roleId number ID del rol
---@return boolean
function AIT.RBAC.Revoke(source, targetPlayerId, roleId)
    MySQL.query.await([[
        DELETE FROM ait_rbac_bindings
        WHERE role_id = ? AND subject_type = 'player' AND subject_id = ?
    ]], { roleId, targetPlayerId })

    -- Invalidar cache
    AIT.RBAC.InvalidateCache(targetPlayerId)

    if AIT.Audit then
        AIT.Audit.Log(source, 'RBAC:RoleRevoked', targetPlayerId, {
            role_id = roleId
        })
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════════════

function AIT.RBAC.GetPlayerId(source)
    if type(source) ~= 'number' or source <= 0 then
        return nil
    end

    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return nil end

    local result = MySQL.query.await(
        'SELECT player_id FROM ait_players WHERE license = ?',
        { license }
    )

    if result and result[1] then
        return result[1].player_id
    end

    return nil
end

function AIT.RBAC.InvalidateCache(playerId)
    -- Invalidar todas las entradas de cache para este jugador
    for key in pairs(AIT.RBAC.cache) do
        if key:match('^' .. playerId .. ':') then
            AIT.RBAC.cache[key] = nil
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- RETURN
-- ═══════════════════════════════════════════════════════════════════════════════════════

return AIT.RBAC
