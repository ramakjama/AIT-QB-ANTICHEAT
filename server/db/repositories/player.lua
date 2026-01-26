--[[
    AIT Framework - Repositorio de Jugadores
    Maneja todas las operaciones de base de datos relacionadas con jugadores

    Autor: AIT Development Team
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.DB = AIT.DB or {}
AIT.DB.Repositories = AIT.DB.Repositories or {}

-- ============================================================================
-- CLASE PLAYER REPOSITORY
-- ============================================================================

AIT.DB.Repositories.Player = setmetatable({}, {__index = AIT.DB.Repositories.Base})
AIT.DB.Repositories.Player.__index = AIT.DB.Repositories.Player

-- ============================================================================
-- CONFIGURACION ESPECIFICA
-- ============================================================================

local PlayerConfig = {
    tableName = "players",
    primaryKey = "id",
    timestamps = true,
    createdAtColumn = "created_at",
    updatedAtColumn = "updated_at",
    softDeletes = true,
    deletedAtColumn = "deleted_at",

    fillable = {
        "license",
        "discord",
        "steam",
        "name",
        "is_banned",
        "ban_reason",
        "ban_expires",
        "is_whitelisted",
        "permission_level",
        "last_seen",
        "total_playtime",
        "first_connection",
        "connection_count"
    },

    guarded = {
        "id",
        "created_at"
    },

    hidden = {},

    defaults = {
        is_banned = false,
        is_whitelisted = false,
        permission_level = 0,
        total_playtime = 0,
        connection_count = 0
    }
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

--- Crea una nueva instancia del repositorio de jugadores
---@return table
function AIT.DB.Repositories.Player:New()
    local instance = AIT.DB.Repositories.Base:New(PlayerConfig)
    setmetatable(instance, self)
    return instance
end

-- ============================================================================
-- METODOS DE BUSQUEDA ESPECIFICOS
-- ============================================================================

--- Busca un jugador por su licencia
---@param license string Licencia del jugador (license:xxxxx)
---@return table|nil
function AIT.DB.Repositories.Player:FindByLicense(license)
    -- Normalizar licencia
    if not license:find("license:") then
        license = "license:" .. license
    end

    local cacheKey = "FindByLicense_" .. license
    local cached = self:GetFromCache(cacheKey)
    if cached then
        return cached
    end

    local query = [[
        SELECT * FROM players
        WHERE license = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {license})

    if result then
        self:SetCache(cacheKey, result)
    end

    return result
end

--- Busca un jugador por su Discord ID
---@param discordId string ID de Discord del jugador
---@return table|nil
function AIT.DB.Repositories.Player:FindByDiscord(discordId)
    -- Normalizar Discord ID
    if not discordId:find("discord:") then
        discordId = "discord:" .. discordId
    end

    local query = [[
        SELECT * FROM players
        WHERE discord = ?
        AND deleted_at IS NULL
    ]]

    return AIT.DB.Single(query, {discordId})
end

--- Busca un jugador por su Steam ID
---@param steamId string Steam ID del jugador
---@return table|nil
function AIT.DB.Repositories.Player:FindBySteam(steamId)
    -- Normalizar Steam ID
    if not steamId:find("steam:") then
        steamId = "steam:" .. steamId
    end

    local query = [[
        SELECT * FROM players
        WHERE steam = ?
        AND deleted_at IS NULL
    ]]

    return AIT.DB.Single(query, {steamId})
end

--- Busca un jugador por cualquier identificador
---@param identifiers table Lista de identificadores
---@return table|nil
function AIT.DB.Repositories.Player:FindByIdentifiers(identifiers)
    local license, discord, steam = nil, nil, nil

    for _, identifier in ipairs(identifiers) do
        if identifier:find("license:") then
            license = identifier
        elseif identifier:find("discord:") then
            discord = identifier
        elseif identifier:find("steam:") then
            steam = identifier
        end
    end

    -- Priorizar busqueda por licencia
    if license then
        local result = self:FindByLicense(license)
        if result then return result end
    end

    -- Luego por Discord
    if discord then
        local result = self:FindByDiscord(discord)
        if result then return result end
    end

    -- Finalmente por Steam
    if steam then
        local result = self:FindBySteam(steam)
        if result then return result end
    end

    return nil
end

--- Busca un jugador por su nombre
---@param name string Nombre del jugador
---@param exact? boolean Busqueda exacta (default: false)
---@return table
function AIT.DB.Repositories.Player:FindByName(name, exact)
    local query
    local params

    if exact then
        query = [[
            SELECT * FROM players
            WHERE name = ?
            AND deleted_at IS NULL
        ]]
        params = {name}
    else
        query = [[
            SELECT * FROM players
            WHERE name LIKE ?
            AND deleted_at IS NULL
        ]]
        params = {"%" .. name .. "%"}
    end

    return AIT.DB.Query(query, params) or {}
end

-- ============================================================================
-- METODOS DE ACTUALIZACION ESPECIFICOS
-- ============================================================================

--- Actualiza la ultima vez que se vio al jugador
---@param playerId number ID del jugador
---@return boolean
function AIT.DB.Repositories.Player:UpdateLastSeen(playerId)
    local query = [[
        UPDATE players
        SET last_seen = NOW(),
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {playerId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Incrementa el contador de conexiones
---@param playerId number ID del jugador
---@return boolean
function AIT.DB.Repositories.Player:IncrementConnectionCount(playerId)
    local query = [[
        UPDATE players
        SET connection_count = connection_count + 1,
            last_seen = NOW(),
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {playerId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Actualiza el tiempo total de juego
---@param playerId number ID del jugador
---@param minutes number Minutos a agregar
---@return boolean
function AIT.DB.Repositories.Player:AddPlaytime(playerId, minutes)
    local query = [[
        UPDATE players
        SET total_playtime = total_playtime + ?,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {minutes, playerId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Actualiza el nivel de permisos
---@param playerId number ID del jugador
---@param level number Nuevo nivel de permisos
---@return boolean
function AIT.DB.Repositories.Player:SetPermissionLevel(playerId, level)
    return self:Update(playerId, {permission_level = level}) ~= nil
end

-- ============================================================================
-- METODOS DE BAN
-- ============================================================================

--- Banea a un jugador
---@param playerId number ID del jugador
---@param reason string Razon del ban
---@param duration? number Duracion en minutos (nil = permanente)
---@return boolean
function AIT.DB.Repositories.Player:Ban(playerId, reason, duration)
    local banExpires = nil
    if duration then
        banExpires = os.date("%Y-%m-%d %H:%M:%S", os.time() + (duration * 60))
    end

    local query = [[
        UPDATE players
        SET is_banned = 1,
            ban_reason = ?,
            ban_expires = ?,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {reason, banExpires, playerId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Desbanea a un jugador
---@param playerId number ID del jugador
---@return boolean
function AIT.DB.Repositories.Player:Unban(playerId)
    local query = [[
        UPDATE players
        SET is_banned = 0,
            ban_reason = NULL,
            ban_expires = NULL,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {playerId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Verifica si un jugador esta baneado
---@param playerId number ID del jugador
---@return boolean
---@return string|nil Razon del ban
---@return string|nil Fecha de expiracion
function AIT.DB.Repositories.Player:IsBanned(playerId)
    local player = self:FindById(playerId)

    if not player then
        return false, nil, nil
    end

    if not player.is_banned then
        return false, nil, nil
    end

    -- Verificar si el ban ha expirado
    if player.ban_expires then
        local banExpires = player.ban_expires
        local now = os.date("%Y-%m-%d %H:%M:%S")

        if banExpires < now then
            -- Ban expirado, desbanear automaticamente
            self:Unban(playerId)
            return false, nil, nil
        end
    end

    return true, player.ban_reason, player.ban_expires
end

--- Obtiene todos los jugadores baneados
---@param includePermanent? boolean Incluir bans permanentes (default: true)
---@return table
function AIT.DB.Repositories.Player:GetBannedPlayers(includePermanent)
    includePermanent = includePermanent ~= false

    local query
    if includePermanent then
        query = [[
            SELECT * FROM players
            WHERE is_banned = 1
            AND deleted_at IS NULL
            ORDER BY updated_at DESC
        ]]
    else
        query = [[
            SELECT * FROM players
            WHERE is_banned = 1
            AND ban_expires IS NOT NULL
            AND deleted_at IS NULL
            ORDER BY ban_expires ASC
        ]]
    end

    return AIT.DB.Query(query) or {}
end

-- ============================================================================
-- METODOS DE WHITELIST
-- ============================================================================

--- Agrega a un jugador a la whitelist
---@param playerId number ID del jugador
---@return boolean
function AIT.DB.Repositories.Player:AddToWhitelist(playerId)
    return self:Update(playerId, {is_whitelisted = true}) ~= nil
end

--- Remueve a un jugador de la whitelist
---@param playerId number ID del jugador
---@return boolean
function AIT.DB.Repositories.Player:RemoveFromWhitelist(playerId)
    return self:Update(playerId, {is_whitelisted = false}) ~= nil
end

--- Verifica si un jugador esta en la whitelist
---@param playerId number ID del jugador
---@return boolean
function AIT.DB.Repositories.Player:IsWhitelisted(playerId)
    local player = self:FindById(playerId)
    return player and player.is_whitelisted == 1
end

--- Obtiene todos los jugadores en whitelist
---@return table
function AIT.DB.Repositories.Player:GetWhitelistedPlayers()
    local query = [[
        SELECT * FROM players
        WHERE is_whitelisted = 1
        AND deleted_at IS NULL
        ORDER BY name ASC
    ]]

    return AIT.DB.Query(query) or {}
end

-- ============================================================================
-- METODOS DE ESTADISTICAS
-- ============================================================================

--- Obtiene los jugadores con mas tiempo de juego
---@param limit? number Limite de resultados (default: 10)
---@return table
function AIT.DB.Repositories.Player:GetTopPlaytime(limit)
    limit = limit or 10

    local query = [[
        SELECT * FROM players
        WHERE deleted_at IS NULL
        ORDER BY total_playtime DESC
        LIMIT ?
    ]]

    return AIT.DB.Query(query, {limit}) or {}
end

--- Obtiene los jugadores mas recientes
---@param limit? number Limite de resultados (default: 10)
---@return table
function AIT.DB.Repositories.Player:GetRecentPlayers(limit)
    limit = limit or 10

    local query = [[
        SELECT * FROM players
        WHERE deleted_at IS NULL
        ORDER BY last_seen DESC
        LIMIT ?
    ]]

    return AIT.DB.Query(query, {limit}) or {}
end

--- Obtiene los nuevos jugadores
---@param days? number Dias desde el registro (default: 7)
---@return table
function AIT.DB.Repositories.Player:GetNewPlayers(days)
    days = days or 7

    local query = [[
        SELECT * FROM players
        WHERE first_connection >= DATE_SUB(NOW(), INTERVAL ? DAY)
        AND deleted_at IS NULL
        ORDER BY first_connection DESC
    ]]

    return AIT.DB.Query(query, {days}) or {}
end

--- Obtiene estadisticas generales de jugadores
---@return table
function AIT.DB.Repositories.Player:GetStatistics()
    local query = [[
        SELECT
            COUNT(*) as total_players,
            SUM(CASE WHEN is_banned = 1 THEN 1 ELSE 0 END) as banned_players,
            SUM(CASE WHEN is_whitelisted = 1 THEN 1 ELSE 0 END) as whitelisted_players,
            SUM(total_playtime) as total_playtime,
            AVG(total_playtime) as avg_playtime,
            AVG(connection_count) as avg_connections,
            COUNT(CASE WHEN last_seen >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END) as active_24h,
            COUNT(CASE WHEN last_seen >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_7d,
            COUNT(CASE WHEN last_seen >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as active_30d
        FROM players
        WHERE deleted_at IS NULL
    ]]

    return AIT.DB.Single(query) or {}
end

-- ============================================================================
-- METODOS DE REGISTRO/CONEXION
-- ============================================================================

--- Registra un nuevo jugador o actualiza uno existente al conectarse
---@param identifiers table Identificadores del jugador
---@param name string Nombre del jugador
---@return table|nil Datos del jugador
function AIT.DB.Repositories.Player:RegisterOrUpdate(identifiers, name)
    local license, discord, steam = nil, nil, nil

    for _, identifier in ipairs(identifiers) do
        if identifier:find("license:") then
            license = identifier
        elseif identifier:find("discord:") then
            discord = identifier
        elseif identifier:find("steam:") then
            steam = identifier
        end
    end

    if not license then
        print("[AIT.DB.Repositories.Player] Error: No se encontro licencia en los identificadores")
        return nil
    end

    local existing = self:FindByLicense(license)

    if existing then
        -- Actualizar jugador existente
        self:IncrementConnectionCount(existing.id)

        -- Actualizar identificadores si cambiaron
        local updates = {}
        if discord and existing.discord ~= discord then
            updates.discord = discord
        end
        if steam and existing.steam ~= steam then
            updates.steam = steam
        end
        if name and existing.name ~= name then
            updates.name = name
        end

        if next(updates) then
            self:Update(existing.id, updates)
        end

        return self:FindById(existing.id)
    else
        -- Crear nuevo jugador
        return self:Create({
            license = license,
            discord = discord,
            steam = steam,
            name = name,
            first_connection = os.date("%Y-%m-%d %H:%M:%S"),
            last_seen = os.date("%Y-%m-%d %H:%M:%S"),
            connection_count = 1
        })
    end
end

-- ============================================================================
-- SINGLETON
-- ============================================================================

-- Instancia singleton del repositorio
local instance = nil

--- Obtiene la instancia singleton del repositorio
---@return table
function AIT.DB.Repositories.Player:GetInstance()
    if not instance then
        instance = self:New()
    end
    return instance
end

-- Crear shortcut global
AIT.DB.Players = AIT.DB.Repositories.Player:GetInstance()

-- Exportar funciones principales
exports("DB_Players_FindByLicense", function(license)
    return AIT.DB.Players:FindByLicense(license)
end)

exports("DB_Players_FindByDiscord", function(discordId)
    return AIT.DB.Players:FindByDiscord(discordId)
end)

exports("DB_Players_Ban", function(playerId, reason, duration)
    return AIT.DB.Players:Ban(playerId, reason, duration)
end)

exports("DB_Players_Unban", function(playerId)
    return AIT.DB.Players:Unban(playerId)
end)

exports("DB_Players_RegisterOrUpdate", function(identifiers, name)
    return AIT.DB.Players:RegisterOrUpdate(identifiers, name)
end)

print("[AIT.DB.Repositories] Repositorio de Jugadores cargado correctamente")
