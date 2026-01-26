--[[
    AIT-QB: Sistema de Tráfico de Armas
    Trabajo ILEGAL - Compra, venta y fabricación de armas
    Servidor Español
]]

AIT = AIT or {}
AIT.Jobs = AIT.Jobs or {}
AIT.Jobs.Weapons = {}

local isCrafting = false
local weaponLevel = 1
local weaponXP = 0

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Traficante de armas (contacto)
    dealer = {
        coords = vector3(968.0, -149.0, 74.0),
        name = 'El Armero',
        spawnTime = { 22, 6 }, -- Solo aparece de noche (22:00 - 06:00)
    },

    -- Taller de fabricación (ubicación secreta)
    workshop = {
        coords = vector3(900.0, -3199.0, -98.0), -- Interior de búnker
        benchCoords = vector3(902.0, -3201.0, -98.0),
    },

    -- Armas disponibles para comprar
    weaponsForSale = {
        -- Pistolas
        { name = 'weapon_pistol', label = 'Pistola 9mm', price = 2500, ammoPrice = 50, level = 1 },
        { name = 'weapon_combatpistol', label = 'Pistola de Combate', price = 4000, ammoPrice = 60, level = 1 },
        { name = 'weapon_pistol50', label = 'Pistola .50', price = 8000, ammoPrice = 100, level = 2 },
        { name = 'weapon_heavypistol', label = 'Pistola Pesada', price = 6000, ammoPrice = 80, level = 2 },

        -- SMGs
        { name = 'weapon_microsmg', label = 'Micro SMG', price = 12000, ammoPrice = 100, level = 2 },
        { name = 'weapon_smg', label = 'SMG', price = 18000, ammoPrice = 120, level = 3 },
        { name = 'weapon_assaultsmg', label = 'SMG de Asalto', price = 25000, ammoPrice = 150, level = 3 },

        -- Rifles
        { name = 'weapon_carbinerifle', label = 'Rifle Carabina', price = 35000, ammoPrice = 200, level = 4 },
        { name = 'weapon_assaultrifle', label = 'Rifle de Asalto', price = 45000, ammoPrice = 200, level = 4 },
        { name = 'weapon_specialcarbine', label = 'Carabina Especial', price = 55000, ammoPrice = 250, level = 5 },
        { name = 'weapon_advancedrifle', label = 'Rifle Avanzado', price = 65000, ammoPrice = 300, level = 5 },

        -- Escopetas
        { name = 'weapon_pumpshotgun', label = 'Escopeta', price = 15000, ammoPrice = 150, level = 2 },
        { name = 'weapon_sawnoffshotgun', label = 'Escopeta Recortada', price = 10000, ammoPrice = 120, level = 2 },
        { name = 'weapon_assaultshotgun', label = 'Escopeta de Asalto', price = 40000, ammoPrice = 200, level = 4 },

        -- Armas cuerpo a cuerpo
        { name = 'weapon_bat', label = 'Bate de Béisbol', price = 500, level = 1 },
        { name = 'weapon_knife', label = 'Cuchillo', price = 800, level = 1 },
        { name = 'weapon_machete', label = 'Machete', price = 2000, level = 1 },
        { name = 'weapon_switchblade', label = 'Navaja', price = 1500, level = 1 },

        -- Explosivos (nivel alto)
        { name = 'weapon_molotov', label = 'Cóctel Molotov', price = 1000, level = 3 },
        { name = 'weapon_stickybomb', label = 'Bomba Adhesiva', price = 5000, level = 5 },
        { name = 'weapon_pipebomb', label = 'Bomba Casera', price = 3000, level = 4 },
    },

    -- Munición
    ammoTypes = {
        { name = 'pistol_ammo', label = 'Munición de Pistola', price = 50, amount = 24 },
        { name = 'smg_ammo', label = 'Munición de SMG', price = 100, amount = 60 },
        { name = 'rifle_ammo', label = 'Munición de Rifle', price = 150, amount = 60 },
        { name = 'shotgun_ammo', label = 'Cartuchos', price = 100, amount = 12 },
    },

    -- Componentes de armas
    attachments = {
        { name = 'COMPONENT_AT_PI_SUPP', label = 'Silenciador Pistola', price = 5000, level = 2 },
        { name = 'COMPONENT_AT_AR_SUPP', label = 'Silenciador Rifle', price = 15000, level = 4 },
        { name = 'COMPONENT_AT_SCOPE_MEDIUM', label = 'Mira Media', price = 8000, level = 3 },
        { name = 'COMPONENT_AT_SCOPE_MACRO', label = 'Mira Macro', price = 5000, level = 2 },
        { name = 'COMPONENT_AT_AR_AFGRIP', label = 'Empuñadura', price = 4000, level = 2 },
        { name = 'COMPONENT_AT_PI_FLSH', label = 'Linterna Pistola', price = 3000, level = 1 },
        { name = 'COMPONENT_AT_AR_FLSH', label = 'Linterna Rifle', price = 4000, level = 2 },
    },

    -- Fabricación de armas (taller)
    crafting = {
        -- Armas caseras
        {
            result = 'weapon_pistol',
            resultLabel = 'Pistola 9mm',
            materials = {
                { item = 'steel', amount = 5 },
                { item = 'metalscrap', amount = 10 },
                { item = 'plastic', amount = 3 },
            },
            time = 60000,
            xp = 50,
            level = 1,
        },
        {
            result = 'weapon_microsmg',
            resultLabel = 'Micro SMG',
            materials = {
                { item = 'steel', amount = 10 },
                { item = 'metalscrap', amount = 15 },
                { item = 'plastic', amount = 5 },
                { item = 'electronics', amount = 2 },
            },
            time = 120000,
            xp = 100,
            level = 2,
        },
        {
            result = 'weapon_sawnoffshotgun',
            resultLabel = 'Escopeta Recortada',
            materials = {
                { item = 'steel', amount = 8 },
                { item = 'metalscrap', amount = 12 },
                { item = 'wood', amount = 3 },
            },
            time = 90000,
            xp = 75,
            level = 2,
        },
        {
            result = 'weapon_pipebomb',
            resultLabel = 'Bomba Casera',
            materials = {
                { item = 'metalscrap', amount = 5 },
                { item = 'gunpowder', amount = 10 },
                { item = 'electronics', amount = 3 },
            },
            time = 45000,
            xp = 60,
            level = 3,
        },
        {
            result = 'weapon_molotov',
            resultLabel = 'Cóctel Molotov',
            materials = {
                { item = 'empty_bottle', amount = 1 },
                { item = 'gasoline', amount = 2 },
                { item = 'cloth', amount = 1 },
            },
            time = 15000,
            xp = 20,
            level = 1,
        },
    },

    -- Fabricación de munición
    ammoCrafting = {
        {
            result = 'pistol_ammo',
            resultLabel = 'Munición de Pistola',
            resultAmount = 24,
            materials = {
                { item = 'metalscrap', amount = 3 },
                { item = 'gunpowder', amount = 2 },
            },
            time = 20000,
            xp = 10,
            level = 1,
        },
        {
            result = 'smg_ammo',
            resultLabel = 'Munición de SMG',
            resultAmount = 60,
            materials = {
                { item = 'metalscrap', amount = 5 },
                { item = 'gunpowder', amount = 4 },
            },
            time = 30000,
            xp = 15,
            level = 2,
        },
        {
            result = 'rifle_ammo',
            resultLabel = 'Munición de Rifle',
            resultAmount = 60,
            materials = {
                { item = 'steel', amount = 3 },
                { item = 'gunpowder', amount = 5 },
            },
            time = 40000,
            xp = 20,
            level = 2,
        },
    },

    -- Materiales para crafteo (dónde conseguirlos)
    materialsSources = {
        metalscrap = 'Chatarrería, desguace de coches',
        steel = 'Minería, refinería',
        plastic = 'Tiendas industriales',
        electronics = 'Robos a tiendas de electrónica',
        gunpowder = 'Fabricación química, robos militares',
        wood = 'Trabajo de leñador',
    },

    -- Niveles
    levels = {
        { level = 1, xpRequired = 0, title = 'Aficionado', discount = 0 },
        { level = 2, xpRequired = 300, title = 'Conocedor', discount = 5 },
        { level = 3, xpRequired = 800, title = 'Traficante', discount = 10 },
        { level = 4, xpRequired = 2000, title = 'Armero', discount = 15 },
        { level = 5, xpRequired = 5000, title = 'Señor de las Armas', discount = 25 },
    },

    -- Riesgo policial
    policeRisk = {
        buy = 20,
        sell = 35,
        craft = 15,
    },
}

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Weapons.Init()
    -- No blips para actividades ilegales
    print('[AIT-QB] Sistema de tráfico de armas inicializado')
end

-- ═══════════════════════════════════════════════════════════════
-- TIENDA DEL TRAFICANTE
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Weapons.IsDealerAvailable()
    local hour = GetClockHours()
    return hour >= Config.dealer.spawnTime[1] or hour < Config.dealer.spawnTime[2]
end

RegisterNetEvent('ait:client:weapons:openDealer', function()
    if not AIT.Jobs.Weapons.IsDealerAvailable() then
        AIT.Notify('El traficante solo aparece de noche (22:00 - 06:00)', 'error')
        return
    end

    local options = {
        {
            title = '🔫 Comprar Armas',
            description = 'Ver arsenal disponible',
            icon = 'gun',
            onSelect = function()
                AIT.Jobs.Weapons.OpenWeaponShop()
            end,
        },
        {
            title = '📦 Comprar Munición',
            description = 'Munición para tus armas',
            icon = 'box',
            onSelect = function()
                AIT.Jobs.Weapons.OpenAmmoShop()
            end,
        },
        {
            title = '🔧 Componentes',
            description = 'Mejoras y accesorios',
            icon = 'wrench',
            onSelect = function()
                AIT.Jobs.Weapons.OpenAttachmentsShop()
            end,
        },
        {
            title = '💰 Vender Armas',
            description = 'Vender armas que ya no necesitas',
            icon = 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('ait:server:weapons:getInventoryForSale')
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_dealer',
            title = Config.dealer.name,
            options = options,
        })
        lib.showContext('weapons_dealer')
    end
end)

function AIT.Jobs.Weapons.OpenWeaponShop()
    local levelData = Config.levels[weaponLevel] or Config.levels[1]
    local options = {}

    for _, weapon in ipairs(Config.weaponsForSale) do
        local canBuy = weaponLevel >= weapon.level
        local price = math.floor(weapon.price * (1 - levelData.discount / 100))

        table.insert(options, {
            title = weapon.label,
            description = canBuy and ('Precio: $' .. price) or ('Requiere nivel ' .. weapon.level),
            icon = 'crosshairs',
            disabled = not canBuy,
            onSelect = function()
                if weapon.ammoPrice then
                    -- Preguntar cantidad de munición
                    if lib and lib.inputDialog then
                        local input = lib.inputDialog('Comprar ' .. weapon.label, {
                            { type = 'checkbox', label = 'Incluir munición (+$' .. weapon.ammoPrice * 2 .. ')' },
                        })

                        local includeAmmo = input and input[1]
                        local totalPrice = price + (includeAmmo and weapon.ammoPrice * 2 or 0)

                        TriggerServerEvent('ait:server:weapons:buyWeapon', weapon.name, totalPrice, includeAmmo)
                    end
                else
                    TriggerServerEvent('ait:server:weapons:buyWeapon', weapon.name, price, false)
                end
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_shop',
            title = 'Arsenal',
            menu = 'weapons_dealer',
            options = options,
        })
        lib.showContext('weapons_shop')
    end
end

function AIT.Jobs.Weapons.OpenAmmoShop()
    local options = {}

    for _, ammo in ipairs(Config.ammoTypes) do
        table.insert(options, {
            title = ammo.label .. ' x' .. ammo.amount,
            description = 'Precio: $' .. ammo.price,
            icon = 'box',
            onSelect = function()
                TriggerServerEvent('ait:server:weapons:buyAmmo', ammo.name, ammo.amount, ammo.price)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_ammo',
            title = 'Munición',
            menu = 'weapons_dealer',
            options = options,
        })
        lib.showContext('weapons_ammo')
    end
end

function AIT.Jobs.Weapons.OpenAttachmentsShop()
    local levelData = Config.levels[weaponLevel] or Config.levels[1]
    local options = {}

    for _, attachment in ipairs(Config.attachments) do
        local canBuy = weaponLevel >= attachment.level
        local price = math.floor(attachment.price * (1 - levelData.discount / 100))

        table.insert(options, {
            title = attachment.label,
            description = canBuy and ('Precio: $' .. price) or ('Requiere nivel ' .. attachment.level),
            icon = 'puzzle-piece',
            disabled = not canBuy,
            onSelect = function()
                TriggerServerEvent('ait:server:weapons:buyAttachment', attachment.name, price)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_attachments',
            title = 'Componentes',
            menu = 'weapons_dealer',
            options = options,
        })
        lib.showContext('weapons_attachments')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TALLER DE FABRICACIÓN
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:weapons:openWorkshop', function()
    local options = {
        {
            title = '🔫 Fabricar Armas',
            description = 'Crear armas caseras',
            icon = 'hammer',
            onSelect = function()
                TriggerServerEvent('ait:server:weapons:getInventoryForCrafting')
            end,
        },
        {
            title = '📦 Fabricar Munición',
            description = 'Crear munición',
            icon = 'box',
            onSelect = function()
                TriggerServerEvent('ait:server:weapons:getInventoryForAmmoCrafting')
            end,
        },
    }

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_workshop',
            title = 'Taller de Armas',
            options = options,
        })
        lib.showContext('weapons_workshop')
    end
end)

RegisterNetEvent('ait:client:weapons:openCraftingMenu', function(inventory)
    local options = {}

    for _, recipe in ipairs(Config.crafting) do
        local canCraft = weaponLevel >= recipe.level
        local hasMaterials = true
        local materialsDesc = ''

        for _, mat in ipairs(recipe.materials) do
            local hasAmount = inventory[mat.item] or 0
            materialsDesc = materialsDesc .. mat.item .. ': ' .. hasAmount .. '/' .. mat.amount .. ', '

            if hasAmount < mat.amount then
                hasMaterials = false
            end
        end

        table.insert(options, {
            title = recipe.resultLabel,
            description = canCraft and materialsDesc or ('Requiere nivel ' .. recipe.level),
            icon = 'hammer',
            disabled = not canCraft or not hasMaterials,
            onSelect = function()
                AIT.Jobs.Weapons.CraftWeapon(recipe)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_crafting',
            title = 'Fabricar Armas',
            menu = 'weapons_workshop',
            options = options,
        })
        lib.showContext('weapons_crafting')
    end
end)

function AIT.Jobs.Weapons.CraftWeapon(recipe)
    if isCrafting then
        AIT.Notify('Ya estás fabricando algo', 'error')
        return
    end

    isCrafting = true

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = recipe.time,
            label = 'Fabricando ' .. recipe.resultLabel .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = 'mini@repair',
                clip = 'fixing_a_player',
            },
        }) then
            TriggerServerEvent('ait:server:weapons:completeCraft', recipe.result, recipe.materials)
            AIT.Jobs.Weapons.AddXP(recipe.xp)
            AIT.Notify(recipe.resultLabel .. ' fabricada', 'success')
        else
            AIT.Notify('Fabricación cancelada', 'error')
        end
    end

    isCrafting = false
end

RegisterNetEvent('ait:client:weapons:openAmmoCraftingMenu', function(inventory)
    local options = {}

    for _, recipe in ipairs(Config.ammoCrafting) do
        local canCraft = weaponLevel >= recipe.level
        local hasMaterials = true
        local materialsDesc = ''

        for _, mat in ipairs(recipe.materials) do
            local hasAmount = inventory[mat.item] or 0
            materialsDesc = materialsDesc .. mat.item .. ': ' .. hasAmount .. '/' .. mat.amount .. ', '

            if hasAmount < mat.amount then
                hasMaterials = false
            end
        end

        table.insert(options, {
            title = recipe.resultLabel .. ' x' .. recipe.resultAmount,
            description = canCraft and materialsDesc or ('Requiere nivel ' .. recipe.level),
            icon = 'box',
            disabled = not canCraft or not hasMaterials,
            onSelect = function()
                AIT.Jobs.Weapons.CraftAmmo(recipe)
            end,
        })
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_ammo_crafting',
            title = 'Fabricar Munición',
            menu = 'weapons_workshop',
            options = options,
        })
        lib.showContext('weapons_ammo_crafting')
    end
end)

function AIT.Jobs.Weapons.CraftAmmo(recipe)
    if isCrafting then
        AIT.Notify('Ya estás fabricando algo', 'error')
        return
    end

    isCrafting = true

    if lib and lib.progressBar then
        if lib.progressBar({
            duration = recipe.time,
            label = 'Fabricando munición...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        }) then
            TriggerServerEvent('ait:server:weapons:completeAmmoCraft', recipe.result, recipe.resultAmount, recipe.materials)
            AIT.Jobs.Weapons.AddXP(recipe.xp)
            AIT.Notify(recipe.resultLabel .. ' x' .. recipe.resultAmount .. ' fabricada', 'success')
        else
            AIT.Notify('Fabricación cancelada', 'error')
        end
    end

    isCrafting = false
end

-- ═══════════════════════════════════════════════════════════════
-- VENTA DE ARMAS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('ait:client:weapons:openSellMenu', function(weapons)
    local options = {}
    local totalValue = 0

    for _, weapon in ipairs(weapons) do
        -- Buscar precio original
        local originalPrice = 1000 -- default
        for _, w in ipairs(Config.weaponsForSale) do
            if w.name == weapon.name then
                originalPrice = w.price
                break
            end
        end

        local sellPrice = math.floor(originalPrice * 0.4) -- 40% del valor original
        totalValue = totalValue + sellPrice

        table.insert(options, {
            title = weapon.label,
            description = 'Valor: $' .. sellPrice,
            icon = 'gun',
            onSelect = function()
                TriggerServerEvent('ait:server:weapons:sellWeapon', weapon.name, sellPrice)
            end,
        })
    end

    if #options == 0 then
        AIT.Notify('No tienes armas para vender', 'error')
        return
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'weapons_sell',
            title = 'Vender Armas',
            menu = 'weapons_dealer',
            options = options,
        })
        lib.showContext('weapons_sell')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES
-- ═══════════════════════════════════════════════════════════════

function AIT.Jobs.Weapons.AddXP(amount)
    weaponXP = weaponXP + amount

    for i = #Config.levels, 1, -1 do
        local levelData = Config.levels[i]
        if weaponXP >= levelData.xpRequired and weaponLevel < levelData.level then
            weaponLevel = levelData.level
            AIT.Notify('¡Nivel de armas ' .. weaponLevel .. ': ' .. levelData.title .. '!', 'success')
            TriggerServerEvent('ait:server:weapons:saveLevel', weaponLevel, weaponXP)
            break
        end
    end
end

RegisterNetEvent('ait:client:weapons:loadLevel', function(level, xp)
    weaponLevel = level or 1
    weaponXP = xp or 0
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('IsCraftingWeapon', function() return isCrafting end)
exports('GetWeaponLevel', function() return weaponLevel end)
exports('GetWeaponXP', function() return weaponXP end)

return AIT.Jobs.Weapons
