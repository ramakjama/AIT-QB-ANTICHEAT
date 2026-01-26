--[[
    AIT-QB: Tablas de Loot
    Sistema de botín para diferentes actividades
    Servidor Español
]]

AIT = AIT or {}
AIT.Data = AIT.Data or {}
AIT.Data.Loot = {}

-- ROBOS A TIENDAS
AIT.Data.Loot.StoreRobbery = {
    -- 24/7
    convenience_small = {
        label = 'Tienda 24/7 Pequeña',
        difficulty = 1,
        cooldown = 30, -- minutos
        police = 2, -- policías requeridos
        items = {
            { item = 'cash', min = 500, max = 1500, chance = 100 },
            { item = 'phone', min = 1, max = 1, chance = 15 },
            { item = 'wallet', min = 1, max = 2, chance = 25 },
            { item = 'cigarettes', min = 1, max = 3, chance = 30 },
            { item = 'lighter', min = 1, max = 1, chance = 20 },
        },
    },

    convenience_large = {
        label = 'Tienda 24/7 Grande',
        difficulty = 2,
        cooldown = 35,
        police = 2,
        items = {
            { item = 'cash', min = 1000, max = 2500, chance = 100 },
            { item = 'phone', min = 1, max = 2, chance = 20 },
            { item = 'wallet', min = 1, max = 3, chance = 30 },
            { item = 'gold_chain', min = 1, max = 1, chance = 5 },
            { item = 'cigarettes', min = 2, max = 5, chance = 40 },
        },
    },

    liquor_store = {
        label = 'Licorería',
        difficulty = 2,
        cooldown = 40,
        police = 2,
        items = {
            { item = 'cash', min = 800, max = 2000, chance = 100 },
            { item = 'whiskey', min = 1, max = 3, chance = 50 },
            { item = 'vodka', min = 1, max = 3, chance = 50 },
            { item = 'wine', min = 1, max = 2, chance = 40 },
            { item = 'beer', min = 2, max = 6, chance = 60 },
        },
    },

    gas_station = {
        label = 'Gasolinera',
        difficulty = 1,
        cooldown = 25,
        police = 2,
        items = {
            { item = 'cash', min = 400, max = 1200, chance = 100 },
            { item = 'repair_kit', min = 1, max = 1, chance = 20 },
            { item = 'jerry_can', min = 1, max = 1, chance = 15 },
            { item = 'snacks', min = 2, max = 5, chance = 50 },
        },
    },
}

-- ROBOS A BANCOS
AIT.Data.Loot.BankRobbery = {
    fleeca = {
        label = 'Fleeca Bank',
        difficulty = 3,
        cooldown = 60,
        police = 4,
        hackDifficulty = 'easy',
        thermiteDoors = 1,
        items = {
            { item = 'cash', min = 15000, max = 35000, chance = 100 },
            { item = 'marked_bills', min = 5000, max = 15000, chance = 100 },
            { item = 'gold_bar', min = 1, max = 3, chance = 40 },
            { item = 'diamond', min = 1, max = 2, chance = 20 },
            { item = 'rolex', min = 1, max = 2, chance = 25 },
        },
    },

    paleto = {
        label = 'Banco Paleto',
        difficulty = 4,
        cooldown = 90,
        police = 5,
        hackDifficulty = 'medium',
        thermiteDoors = 2,
        items = {
            { item = 'cash', min = 40000, max = 80000, chance = 100 },
            { item = 'marked_bills', min = 15000, max = 30000, chance = 100 },
            { item = 'gold_bar', min = 3, max = 8, chance = 60 },
            { item = 'diamond', min = 2, max = 5, chance = 40 },
            { item = 'jewelry_box', min = 1, max = 3, chance = 35 },
        },
    },

    pacific = {
        label = 'Pacific Standard',
        difficulty = 5,
        cooldown = 120,
        police = 6,
        hackDifficulty = 'hard',
        thermiteDoors = 4,
        items = {
            { item = 'cash', min = 150000, max = 350000, chance = 100 },
            { item = 'marked_bills', min = 50000, max = 150000, chance = 100 },
            { item = 'gold_bar', min = 10, max = 30, chance = 80 },
            { item = 'diamond', min = 5, max = 15, chance = 60 },
            { item = 'rare_painting', min = 1, max = 2, chance = 20 },
            { item = 'bearer_bonds', min = 1, max = 3, chance = 30 },
        },
    },

    union_depository = {
        label = 'Union Depository',
        difficulty = 6,
        cooldown = 180,
        police = 8,
        hackDifficulty = 'expert',
        thermiteDoors = 6,
        items = {
            { item = 'cash', min = 500000, max = 1000000, chance = 100 },
            { item = 'gold_bar', min = 30, max = 70, chance = 100 },
            { item = 'diamond', min = 15, max = 40, chance = 80 },
            { item = 'rare_painting', min = 2, max = 5, chance = 40 },
            { item = 'bearer_bonds', min = 3, max = 8, chance = 50 },
            { item = 'artifact', min = 1, max = 2, chance = 15 },
        },
    },
}

-- JOYERÍA
AIT.Data.Loot.JewelryStore = {
    vangelico = {
        label = 'Joyería Vangelico',
        difficulty = 4,
        cooldown = 75,
        police = 4,
        vitrinas = 20,
        items = {
            { item = 'diamond', min = 1, max = 3, chance = 50 },
            { item = 'gold_chain', min = 1, max = 2, chance = 60 },
            { item = 'rolex', min = 1, max = 1, chance = 40 },
            { item = 'diamond_ring', min = 1, max = 2, chance = 55 },
            { item = 'gold_ring', min = 1, max = 3, chance = 70 },
            { item = 'earrings', min = 1, max = 2, chance = 65 },
            { item = 'necklace', min = 1, max = 1, chance = 45 },
            { item = 'bracelet', min = 1, max = 2, chance = 50 },
        },
    },
}

-- CAJEROS ATM
AIT.Data.Loot.ATM = {
    atm_small = {
        label = 'Cajero Normal',
        difficulty = 2,
        cooldown = 45,
        police = 2,
        items = {
            { item = 'cash', min = 2000, max = 5000, chance = 100 },
            { item = 'credit_card', min = 1, max = 2, chance = 30 },
        },
    },

    atm_fleeca = {
        label = 'Cajero Fleeca',
        difficulty = 2,
        cooldown = 50,
        police = 3,
        items = {
            { item = 'cash', min = 3000, max = 7000, chance = 100 },
            { item = 'credit_card', min = 1, max = 3, chance = 40 },
        },
    },
}

-- NPCs
AIT.Data.Loot.NPCs = {
    civilian = {
        label = 'Civil',
        items = {
            { item = 'cash', min = 20, max = 150, chance = 70 },
            { item = 'phone', min = 1, max = 1, chance = 25 },
            { item = 'wallet', min = 1, max = 1, chance = 40 },
            { item = 'id_card', min = 1, max = 1, chance = 35 },
        },
    },

    rich_civilian = {
        label = 'Civil Rico',
        items = {
            { item = 'cash', min = 200, max = 800, chance = 90 },
            { item = 'phone', min = 1, max = 1, chance = 60 },
            { item = 'rolex', min = 1, max = 1, chance = 15 },
            { item = 'gold_chain', min = 1, max = 1, chance = 20 },
            { item = 'credit_card', min = 1, max = 2, chance = 45 },
        },
    },

    gang_member = {
        label = 'Pandillero',
        items = {
            { item = 'cash', min = 100, max = 500, chance = 85 },
            { item = 'weed_baggy', min = 1, max = 5, chance = 45 },
            { item = 'coke_baggy', min = 1, max = 2, chance = 20 },
            { item = 'lockpick', min = 1, max = 2, chance = 25 },
            { item = 'weapon_pistol', min = 1, max = 1, chance = 10 },
            { item = 'weapon_knife', min = 1, max = 1, chance = 30 },
        },
    },

    drug_dealer = {
        label = 'Traficante',
        items = {
            { item = 'cash', min = 500, max = 2000, chance = 100 },
            { item = 'weed_baggy', min = 5, max = 20, chance = 70 },
            { item = 'coke_baggy', min = 2, max = 10, chance = 50 },
            { item = 'meth_baggy', min = 1, max = 5, chance = 30 },
            { item = 'phone', min = 1, max = 1, chance = 50 },
            { item = 'weapon_pistol', min = 1, max = 1, chance = 25 },
        },
    },

    security_guard = {
        label = 'Guardia de Seguridad',
        items = {
            { item = 'cash', min = 50, max = 200, chance = 60 },
            { item = 'security_keycard', min = 1, max = 1, chance = 80 },
            { item = 'radio', min = 1, max = 1, chance = 70 },
            { item = 'handcuffs', min = 1, max = 1, chance = 40 },
        },
    },
}

-- PESCA
AIT.Data.Loot.Fishing = {
    ocean = {
        label = 'Océano',
        items = {
            { item = 'fish_mackerel', min = 1, max = 1, chance = 40 },
            { item = 'fish_tuna', min = 1, max = 1, chance = 25 },
            { item = 'fish_shark', min = 1, max = 1, chance = 5 },
            { item = 'fish_salmon', min = 1, max = 1, chance = 20 },
            { item = 'seaweed', min = 1, max = 3, chance = 30 },
            { item = 'boot', min = 1, max = 1, chance = 10 },
            { item = 'treasure_map', min = 1, max = 1, chance = 1 },
        },
    },

    river = {
        label = 'Río',
        items = {
            { item = 'fish_trout', min = 1, max = 1, chance = 45 },
            { item = 'fish_bass', min = 1, max = 1, chance = 35 },
            { item = 'fish_catfish', min = 1, max = 1, chance = 25 },
            { item = 'fish_carp', min = 1, max = 1, chance = 30 },
            { item = 'boot', min = 1, max = 1, chance = 15 },
            { item = 'can', min = 1, max = 1, chance = 12 },
        },
    },

    lake = {
        label = 'Lago',
        items = {
            { item = 'fish_bass', min = 1, max = 1, chance = 40 },
            { item = 'fish_trout', min = 1, max = 1, chance = 35 },
            { item = 'fish_perch', min = 1, max = 1, chance = 30 },
            { item = 'fish_pike', min = 1, max = 1, chance = 15 },
            { item = 'fish_legendary', min = 1, max = 1, chance = 2 },
        },
    },
}

-- MINERÍA
AIT.Data.Loot.Mining = {
    surface = {
        label = 'Superficie',
        items = {
            { item = 'stone', min = 1, max = 3, chance = 70 },
            { item = 'iron_ore', min = 1, max = 2, chance = 35 },
            { item = 'copper_ore', min = 1, max = 2, chance = 30 },
            { item = 'coal', min = 1, max = 2, chance = 25 },
        },
    },

    cave = {
        label = 'Cueva',
        items = {
            { item = 'stone', min = 1, max = 2, chance = 50 },
            { item = 'iron_ore', min = 1, max = 3, chance = 45 },
            { item = 'copper_ore', min = 1, max = 3, chance = 40 },
            { item = 'silver_ore', min = 1, max = 2, chance = 25 },
            { item = 'gold_ore', min = 1, max = 1, chance = 10 },
        },
    },

    deep_mine = {
        label = 'Mina Profunda',
        items = {
            { item = 'iron_ore', min = 2, max = 5, chance = 60 },
            { item = 'silver_ore', min = 1, max = 3, chance = 40 },
            { item = 'gold_ore', min = 1, max = 2, chance = 20 },
            { item = 'diamond_uncut', min = 1, max = 1, chance = 5 },
            { item = 'emerald_uncut', min = 1, max = 1, chance = 8 },
            { item = 'ruby_uncut', min = 1, max = 1, chance = 6 },
        },
    },
}

-- CAZA
AIT.Data.Loot.Hunting = {
    deer = {
        label = 'Ciervo',
        items = {
            { item = 'raw_venison', min = 3, max = 6, chance = 100 },
            { item = 'animal_hide_large', min = 1, max = 2, chance = 90 },
            { item = 'antlers', min = 1, max = 1, chance = 50 },
            { item = 'animal_fat', min = 1, max = 2, chance = 60 },
        },
    },

    boar = {
        label = 'Jabalí',
        items = {
            { item = 'raw_pork', min = 2, max = 5, chance = 100 },
            { item = 'animal_hide_medium', min = 1, max = 2, chance = 85 },
            { item = 'tusks', min = 1, max = 2, chance = 40 },
            { item = 'animal_fat', min = 2, max = 4, chance = 70 },
        },
    },

    rabbit = {
        label = 'Conejo',
        items = {
            { item = 'raw_rabbit', min = 1, max = 2, chance = 100 },
            { item = 'rabbit_fur', min = 1, max = 1, chance = 80 },
        },
    },

    bird = {
        label = 'Ave',
        items = {
            { item = 'raw_poultry', min = 1, max = 2, chance = 100 },
            { item = 'feathers', min = 2, max = 5, chance = 90 },
        },
    },

    bear = {
        label = 'Oso',
        items = {
            { item = 'raw_meat', min = 5, max = 10, chance = 100 },
            { item = 'bear_hide', min = 1, max = 1, chance = 100 },
            { item = 'bear_claw', min = 2, max = 4, chance = 80 },
            { item = 'animal_fat', min = 3, max = 6, chance = 85 },
        },
    },

    cougar = {
        label = 'Puma',
        items = {
            { item = 'raw_meat', min = 3, max = 5, chance = 100 },
            { item = 'cougar_hide', min = 1, max = 1, chance = 100 },
            { item = 'cougar_fang', min = 1, max = 2, chance = 70 },
        },
    },
}

-- CONTENEDORES / BASURA
AIT.Data.Loot.Containers = {
    trash_can = {
        label = 'Papelera',
        items = {
            { item = 'can', min = 1, max = 2, chance = 40 },
            { item = 'plastic_bottle', min = 1, max = 2, chance = 35 },
            { item = 'newspaper', min = 1, max = 1, chance = 30 },
            { item = 'cash', min = 1, max = 20, chance = 5 },
        },
    },

    dumpster = {
        label = 'Contenedor',
        items = {
            { item = 'scrap_metal', min = 1, max = 3, chance = 45 },
            { item = 'plastic', min = 1, max = 4, chance = 50 },
            { item = 'cloth', min = 1, max = 2, chance = 35 },
            { item = 'electronics_scrap', min = 1, max = 1, chance = 15 },
            { item = 'food_scraps', min = 1, max = 3, chance = 60 },
            { item = 'cash', min = 5, max = 50, chance = 8 },
            { item = 'weapon_knife', min = 1, max = 1, chance = 3 },
        },
    },

    supply_crate = {
        label = 'Caja de Suministros',
        items = {
            { item = 'armor', min = 1, max = 1, chance = 40 },
            { item = 'medkit', min = 1, max = 2, chance = 50 },
            { item = 'weapon_ammo', min = 20, max = 50, chance = 60 },
            { item = 'lockpick', min = 1, max = 3, chance = 35 },
            { item = 'radio', min = 1, max = 1, chance = 25 },
        },
    },

    airdrop = {
        label = 'Suministro Aéreo',
        items = {
            { item = 'cash', min = 5000, max = 15000, chance = 100 },
            { item = 'gold_bar', min = 1, max = 3, chance = 40 },
            { item = 'weapon_assaultrifle', min = 1, max = 1, chance = 25 },
            { item = 'heavy_armor', min = 1, max = 1, chance = 35 },
            { item = 'military_grade_electronics', min = 1, max = 2, chance = 30 },
            { item = 'rare_item_crate', min = 1, max = 1, chance = 10 },
        },
    },
}

-- VEHÍCULOS (desguace/búsqueda)
AIT.Data.Loot.Vehicles = {
    civilian = {
        label = 'Vehículo Civil',
        items = {
            { item = 'scrap_metal', min = 2, max = 5, chance = 80 },
            { item = 'electronics_scrap', min = 1, max = 2, chance = 40 },
            { item = 'rubber', min = 1, max = 4, chance = 60 },
            { item = 'car_battery', min = 1, max = 1, chance = 50 },
            { item = 'cash', min = 10, max = 100, chance = 30 },
        },
    },

    luxury = {
        label = 'Vehículo de Lujo',
        items = {
            { item = 'scrap_metal', min = 3, max = 6, chance = 85 },
            { item = 'electronics_scrap', min = 2, max = 4, chance = 60 },
            { item = 'carbon_fiber', min = 1, max = 2, chance = 40 },
            { item = 'car_battery', min = 1, max = 1, chance = 70 },
            { item = 'gps_unit', min = 1, max = 1, chance = 50 },
            { item = 'cash', min = 50, max = 500, chance = 45 },
        },
    },
}

-- Función para calcular loot
function AIT.Data.Loot.Calculate(tableType, tableName)
    local lootTable = AIT.Data.Loot[tableType] and AIT.Data.Loot[tableType][tableName]
    if not lootTable or not lootTable.items then
        return {}
    end

    local rewards = {}
    for _, item in ipairs(lootTable.items) do
        local roll = math.random(1, 100)
        if roll <= item.chance then
            local amount = math.random(item.min, item.max)
            table.insert(rewards, {
                item = item.item,
                amount = amount,
            })
        end
    end

    return rewards
end

-- Función para obtener información de tabla de loot
function AIT.Data.Loot.GetInfo(tableType, tableName)
    return AIT.Data.Loot[tableType] and AIT.Data.Loot[tableType][tableName]
end

return AIT.Data.Loot
