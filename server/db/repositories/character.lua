--[[
    AIT Framework - Repositorio de Personajes
    Maneja todas las operaciones de base de datos relacionadas con personajes

    Autor: AIT Development Team
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.DB = AIT.DB or {}
AIT.DB.Repositories = AIT.DB.Repositories or {}

-- ============================================================================
-- CLASE CHARACTER REPOSITORY
-- ============================================================================

AIT.DB.Repositories.Character = setmetatable({}, {__index = AIT.DB.Repositories.Base})
AIT.DB.Repositories.Character.__index = AIT.DB.Repositories.Character

-- ============================================================================
-- CONFIGURACION ESPECIFICA
-- ============================================================================

local CharacterConfig = {
    tableName = "characters",
    primaryKey = "id",
    timestamps = true,
    createdAtColumn = "created_at",
    updatedAtColumn = "updated_at",
    softDeletes = true,
    deletedAtColumn = "deleted_at",

    fillable = {
        "player_id",
        "citizen_id",
        "first_name",
        "last_name",
        "date_of_birth",
        "gender",
        "nationality",
        "phone_number",
        "bank_account",
        "cash",
        "bank",
        "job_name",
        "job_grade",
        "job_duty",
        "gang_name",
        "gang_grade",
        "position_x",
        "position_y",
        "position_z",
        "position_heading",
        "health",
        "armor",
        "hunger",
        "thirst",
        "stress",
        "is_dead",
        "metadata",
        "skin",
        "clothes",
        "last_played",
        "total_playtime"
    },

    guarded = {
        "id",
        "created_at"
    },

    hidden = {},

    defaults = {
        cash = 500,
        bank = 5000,
        job_name = "unemployed",
        job_grade = 0,
        job_duty = false,
        gang_name = "none",
        gang_grade = 0,
        health = 200,
        armor = 0,
        hunger = 100,
        thirst = 100,
        stress = 0,
        is_dead = false,
        total_playtime = 0
    }
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

--- Crea una nueva instancia del repositorio de personajes
---@return table
function AIT.DB.Repositories.Character:New()
    local instance = AIT.DB.Repositories.Base:New(CharacterConfig)
    setmetatable(instance, self)
    return instance
end

-- ============================================================================
-- METODOS DE BUSQUEDA ESPECIFICOS
-- ============================================================================

--- Busca personajes por ID del jugador
---@param playerId number ID del jugador
---@return table
function AIT.DB.Repositories.Character:FindByPlayerId(playerId)
    local query = [[
        SELECT * FROM characters
        WHERE player_id = ?
        AND deleted_at IS NULL
        ORDER BY last_played DESC
    ]]

    return AIT.DB.Query(query, {playerId}) or {}
end

--- Busca un personaje por su Citizen ID
---@param citizenId string Citizen ID del personaje
---@return table|nil
function AIT.DB.Repositories.Character:FindByCitizenId(citizenId)
    local cacheKey = "FindByCitizenId_" .. citizenId
    local cached = self:GetFromCache(cacheKey)
    if cached then
        return cached
    end

    local query = [[
        SELECT * FROM characters
        WHERE citizen_id = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {citizenId})

    if result then
        self:SetCache(cacheKey, result)
    end

    return result
end

--- Busca un personaje por numero de telefono
---@param phoneNumber string Numero de telefono
---@return table|nil
function AIT.DB.Repositories.Character:FindByPhoneNumber(phoneNumber)
    local query = [[
        SELECT * FROM characters
        WHERE phone_number = ?
        AND deleted_at IS NULL
    ]]

    return AIT.DB.Single(query, {phoneNumber})
end

--- Busca un personaje por numero de cuenta bancaria
---@param bankAccount string Numero de cuenta bancaria
---@return table|nil
function AIT.DB.Repositories.Character:FindByBankAccount(bankAccount)
    local query = [[
        SELECT * FROM characters
        WHERE bank_account = ?
        AND deleted_at IS NULL
    ]]

    return AIT.DB.Single(query, {bankAccount})
end

--- Busca personajes por nombre
---@param firstName string Nombre
---@param lastName? string Apellido
---@return table
function AIT.DB.Repositories.Character:FindByName(firstName, lastName)
    local query
    local params

    if lastName then
        query = [[
            SELECT * FROM characters
            WHERE first_name LIKE ?
            AND last_name LIKE ?
            AND deleted_at IS NULL
        ]]
        params = {"%" .. firstName .. "%", "%" .. lastName .. "%"}
    else
        query = [[
            SELECT * FROM characters
            WHERE (first_name LIKE ? OR last_name LIKE ?)
            AND deleted_at IS NULL
        ]]
        params = {"%" .. firstName .. "%", "%" .. firstName .. "%"}
    end

    return AIT.DB.Query(query, params) or {}
end

--- Busca personajes por trabajo
---@param jobName string Nombre del trabajo
---@param jobGrade? number Grado del trabajo
---@return table
function AIT.DB.Repositories.Character:FindByJob(jobName, jobGrade)
    local query
    local params

    if jobGrade then
        query = [[
            SELECT * FROM characters
            WHERE job_name = ?
            AND job_grade = ?
            AND deleted_at IS NULL
        ]]
        params = {jobName, jobGrade}
    else
        query = [[
            SELECT * FROM characters
            WHERE job_name = ?
            AND deleted_at IS NULL
        ]]
        params = {jobName}
    end

    return AIT.DB.Query(query, params) or {}
end

--- Busca personajes por banda
---@param gangName string Nombre de la banda
---@param gangGrade? number Grado en la banda
---@return table
function AIT.DB.Repositories.Character:FindByGang(gangName, gangGrade)
    local query
    local params

    if gangGrade then
        query = [[
            SELECT * FROM characters
            WHERE gang_name = ?
            AND gang_grade = ?
            AND deleted_at IS NULL
        ]]
        params = {gangName, gangGrade}
    else
        query = [[
            SELECT * FROM characters
            WHERE gang_name = ?
            AND deleted_at IS NULL
        ]]
        params = {gangName}
    end

    return AIT.DB.Query(query, params) or {}
end

--- Cuenta los personajes de un jugador
---@param playerId number ID del jugador
---@return number
function AIT.DB.Repositories.Character:CountByPlayerId(playerId)
    local query = [[
        SELECT COUNT(*) as count FROM characters
        WHERE player_id = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {playerId})
    return result and result.count or 0
end

-- ============================================================================
-- METODOS DE POSICION
-- ============================================================================

--- Guarda la posicion del personaje
---@param characterId number ID del personaje
---@param x number Coordenada X
---@param y number Coordenada Y
---@param z number Coordenada Z
---@param heading? number Orientacion
---@return boolean
function AIT.DB.Repositories.Character:SavePosition(characterId, x, y, z, heading)
    heading = heading or 0.0

    local query = [[
        UPDATE characters
        SET position_x = ?,
            position_y = ?,
            position_z = ?,
            position_heading = ?,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {x, y, z, heading, characterId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Obtiene la posicion del personaje
---@param characterId number ID del personaje
---@return table|nil {x, y, z, heading}
function AIT.DB.Repositories.Character:GetPosition(characterId)
    local query = [[
        SELECT position_x, position_y, position_z, position_heading
        FROM characters
        WHERE id = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {characterId})

    if result then
        return {
            x = result.position_x,
            y = result.position_y,
            z = result.position_z,
            heading = result.position_heading
        }
    end

    return nil
end

-- ============================================================================
-- METODOS DE ESTADO
-- ============================================================================

--- Guarda el estado del personaje (salud, armadura, hambre, sed, estres)
---@param characterId number ID del personaje
---@param status table {health, armor, hunger, thirst, stress}
---@return boolean
function AIT.DB.Repositories.Character:SaveStatus(characterId, status)
    local updates = {}
    local params = {}

    if status.health ~= nil then
        table.insert(updates, "health = ?")
        table.insert(params, status.health)
    end

    if status.armor ~= nil then
        table.insert(updates, "armor = ?")
        table.insert(params, status.armor)
    end

    if status.hunger ~= nil then
        table.insert(updates, "hunger = ?")
        table.insert(params, status.hunger)
    end

    if status.thirst ~= nil then
        table.insert(updates, "thirst = ?")
        table.insert(params, status.thirst)
    end

    if status.stress ~= nil then
        table.insert(updates, "stress = ?")
        table.insert(params, status.stress)
    end

    if #updates == 0 then
        return false
    end

    table.insert(updates, "updated_at = NOW()")
    table.insert(params, characterId)

    local query = string.format(
        "UPDATE characters SET %s WHERE id = ?",
        table.concat(updates, ", ")
    )

    local affected = AIT.DB.Update(query, params)

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Obtiene el estado del personaje
---@param characterId number ID del personaje
---@return table|nil
function AIT.DB.Repositories.Character:GetStatus(characterId)
    local query = [[
        SELECT health, armor, hunger, thirst, stress, is_dead
        FROM characters
        WHERE id = ?
        AND deleted_at IS NULL
    ]]

    return AIT.DB.Single(query, {characterId})
end

--- Marca al personaje como muerto
---@param characterId number ID del personaje
---@return boolean
function AIT.DB.Repositories.Character:SetDead(characterId)
    return self:Update(characterId, {is_dead = true}) ~= nil
end

--- Marca al personaje como vivo
---@param characterId number ID del personaje
---@return boolean
function AIT.DB.Repositories.Character:SetAlive(characterId)
    return self:Update(characterId, {is_dead = false, health = 200}) ~= nil
end

-- ============================================================================
-- METODOS DE DINERO
-- ============================================================================

--- Agrega dinero en efectivo
---@param characterId number ID del personaje
---@param amount number Cantidad a agregar
---@return boolean
function AIT.DB.Repositories.Character:AddCash(characterId, amount)
    if amount <= 0 then
        return false
    end

    local query = [[
        UPDATE characters
        SET cash = cash + ?,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {amount, characterId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Remueve dinero en efectivo
---@param characterId number ID del personaje
---@param amount number Cantidad a remover
---@return boolean
function AIT.DB.Repositories.Character:RemoveCash(characterId, amount)
    if amount <= 0 then
        return false
    end

    local query = [[
        UPDATE characters
        SET cash = GREATEST(cash - ?, 0),
            updated_at = NOW()
        WHERE id = ? AND cash >= ?
    ]]

    local affected = AIT.DB.Update(query, {amount, characterId, amount})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Agrega dinero al banco
---@param characterId number ID del personaje
---@param amount number Cantidad a agregar
---@return boolean
function AIT.DB.Repositories.Character:AddBank(characterId, amount)
    if amount <= 0 then
        return false
    end

    local query = [[
        UPDATE characters
        SET bank = bank + ?,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {amount, characterId})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Remueve dinero del banco
---@param characterId number ID del personaje
---@param amount number Cantidad a remover
---@return boolean
function AIT.DB.Repositories.Character:RemoveBank(characterId, amount)
    if amount <= 0 then
        return false
    end

    local query = [[
        UPDATE characters
        SET bank = GREATEST(bank - ?, 0),
            updated_at = NOW()
        WHERE id = ? AND bank >= ?
    ]]

    local affected = AIT.DB.Update(query, {amount, characterId, amount})

    if affected > 0 then
        self:InvalidateCache()
        return true
    end

    return false
end

--- Obtiene el balance del personaje
---@param characterId number ID del personaje
---@return table|nil {cash, bank}
function AIT.DB.Repositories.Character:GetBalance(characterId)
    local query = [[
        SELECT cash, bank
        FROM characters
        WHERE id = ?
        AND deleted_at IS NULL
    ]]

    return AIT.DB.Single(query, {characterId})
end

-- ============================================================================
-- METODOS DE TRABAJO
-- ============================================================================

--- Actualiza el trabajo del personaje
---@param characterId number ID del personaje
---@param jobName string Nombre del trabajo
---@param jobGrade number Grado del trabajo
---@return boolean
function AIT.DB.Repositories.Character:SetJob(characterId, jobName, jobGrade)
    return self:Update(characterId, {
        job_name = jobName,
        job_grade = jobGrade
    }) ~= nil
end

--- Cambia el estado de servicio
---@param characterId number ID del personaje
---@param onDuty boolean En servicio
---@return boolean
function AIT.DB.Repositories.Character:SetDuty(characterId, onDuty)
    return self:Update(characterId, {job_duty = onDuty}) ~= nil
end

--- Actualiza la banda del personaje
---@param characterId number ID del personaje
---@param gangName string Nombre de la banda
---@param gangGrade number Grado en la banda
---@return boolean
function AIT.DB.Repositories.Character:SetGang(characterId, gangName, gangGrade)
    return self:Update(characterId, {
        gang_name = gangName,
        gang_grade = gangGrade
    }) ~= nil
end

-- ============================================================================
-- METODOS DE APARIENCIA
-- ============================================================================

--- Guarda la skin del personaje
---@param characterId number ID del personaje
---@param skinData table Datos de la skin
---@return boolean
function AIT.DB.Repositories.Character:SaveSkin(characterId, skinData)
    local skinJson = json.encode(skinData)
    return self:Update(characterId, {skin = skinJson}) ~= nil
end

--- Obtiene la skin del personaje
---@param characterId number ID del personaje
---@return table|nil
function AIT.DB.Repositories.Character:GetSkin(characterId)
    local query = [[
        SELECT skin FROM characters
        WHERE id = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {characterId})

    if result and result.skin then
        return json.decode(result.skin)
    end

    return nil
end

--- Guarda la ropa del personaje
---@param characterId number ID del personaje
---@param clothesData table Datos de la ropa
---@return boolean
function AIT.DB.Repositories.Character:SaveClothes(characterId, clothesData)
    local clothesJson = json.encode(clothesData)
    return self:Update(characterId, {clothes = clothesJson}) ~= nil
end

--- Obtiene la ropa del personaje
---@param characterId number ID del personaje
---@return table|nil
function AIT.DB.Repositories.Character:GetClothes(characterId)
    local query = [[
        SELECT clothes FROM characters
        WHERE id = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {characterId})

    if result and result.clothes then
        return json.decode(result.clothes)
    end

    return nil
end

-- ============================================================================
-- METODOS DE METADATA
-- ============================================================================

--- Guarda metadata del personaje
---@param characterId number ID del personaje
---@param metadata table Metadata
---@return boolean
function AIT.DB.Repositories.Character:SaveMetadata(characterId, metadata)
    local metadataJson = json.encode(metadata)
    return self:Update(characterId, {metadata = metadataJson}) ~= nil
end

--- Obtiene metadata del personaje
---@param characterId number ID del personaje
---@return table
function AIT.DB.Repositories.Character:GetMetadata(characterId)
    local query = [[
        SELECT metadata FROM characters
        WHERE id = ?
        AND deleted_at IS NULL
    ]]

    local result = AIT.DB.Single(query, {characterId})

    if result and result.metadata then
        return json.decode(result.metadata)
    end

    return {}
end

-- ============================================================================
-- METODOS DE UTILIDAD
-- ============================================================================

--- Genera un nuevo Citizen ID unico
---@return string
function AIT.DB.Repositories.Character:GenerateCitizenId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local citizenId
    local exists = true

    while exists do
        citizenId = ""
        for i = 1, 8 do
            local randIndex = math.random(1, #chars)
            citizenId = citizenId .. chars:sub(randIndex, randIndex)
        end

        exists = self:FindByCitizenId(citizenId) ~= nil
    end

    return citizenId
end

--- Genera un numero de telefono unico
---@return string
function AIT.DB.Repositories.Character:GeneratePhoneNumber()
    local phoneNumber
    local exists = true

    while exists do
        phoneNumber = string.format("%03d-%04d", math.random(100, 999), math.random(1000, 9999))
        exists = self:FindByPhoneNumber(phoneNumber) ~= nil
    end

    return phoneNumber
end

--- Genera un numero de cuenta bancaria unico
---@return string
function AIT.DB.Repositories.Character:GenerateBankAccount()
    local bankAccount
    local exists = true

    while exists do
        bankAccount = string.format("ES%02d%04d%04d%010d",
            math.random(10, 99),
            math.random(1000, 9999),
            math.random(1000, 9999),
            math.random(1000000000, 9999999999)
        )
        exists = self:FindByBankAccount(bankAccount) ~= nil
    end

    return bankAccount
end

--- Actualiza la ultima vez que se jugo con el personaje
---@param characterId number ID del personaje
---@return boolean
function AIT.DB.Repositories.Character:UpdateLastPlayed(characterId)
    local query = [[
        UPDATE characters
        SET last_played = NOW(),
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {characterId})
    return affected > 0
end

--- Agrega tiempo de juego al personaje
---@param characterId number ID del personaje
---@param minutes number Minutos a agregar
---@return boolean
function AIT.DB.Repositories.Character:AddPlaytime(characterId, minutes)
    local query = [[
        UPDATE characters
        SET total_playtime = total_playtime + ?,
            updated_at = NOW()
        WHERE id = ?
    ]]

    local affected = AIT.DB.Update(query, {minutes, characterId})
    return affected > 0
end

--- Obtiene estadisticas de personajes
---@return table
function AIT.DB.Repositories.Character:GetStatistics()
    local query = [[
        SELECT
            COUNT(*) as total_characters,
            COUNT(DISTINCT player_id) as unique_players,
            SUM(cash) as total_cash,
            SUM(bank) as total_bank,
            AVG(total_playtime) as avg_playtime,
            COUNT(CASE WHEN is_dead = 1 THEN 1 END) as dead_characters
        FROM characters
        WHERE deleted_at IS NULL
    ]]

    return AIT.DB.Single(query) or {}
end

-- ============================================================================
-- SINGLETON
-- ============================================================================

-- Instancia singleton del repositorio
local instance = nil

--- Obtiene la instancia singleton del repositorio
---@return table
function AIT.DB.Repositories.Character:GetInstance()
    if not instance then
        instance = self:New()
    end
    return instance
end

-- Crear shortcut global
AIT.DB.Characters = AIT.DB.Repositories.Character:GetInstance()

-- Exportar funciones principales
exports("DB_Characters_FindByPlayerId", function(playerId)
    return AIT.DB.Characters:FindByPlayerId(playerId)
end)

exports("DB_Characters_FindByCitizenId", function(citizenId)
    return AIT.DB.Characters:FindByCitizenId(citizenId)
end)

exports("DB_Characters_SavePosition", function(characterId, x, y, z, heading)
    return AIT.DB.Characters:SavePosition(characterId, x, y, z, heading)
end)

exports("DB_Characters_SaveStatus", function(characterId, status)
    return AIT.DB.Characters:SaveStatus(characterId, status)
end)

exports("DB_Characters_AddCash", function(characterId, amount)
    return AIT.DB.Characters:AddCash(characterId, amount)
end)

exports("DB_Characters_AddBank", function(characterId, amount)
    return AIT.DB.Characters:AddBank(characterId, amount)
end)

exports("DB_Characters_SetJob", function(characterId, jobName, jobGrade)
    return AIT.DB.Characters:SetJob(characterId, jobName, jobGrade)
end)

print("[AIT.DB.Repositories] Repositorio de Personajes cargado correctamente")
