-- ═══════════════════════════════════════════════════════════════════════════════════════
-- AIT-QB ANTICHEAT - SIGNATURES DATABASE
-- Base de datos de firmas de RedEngine, PhazeMenu, y otros menús de cheat
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Signatures = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIRMAS DE REDENGINE
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.RedEngine = {
    name = "RedEngine",
    severity = "CRITICAL",
    description = "Menú de cheat popular para FiveM",

    -- Nombres de recursos
    resources = {
        "redengine", "red-engine", "red_engine", "redmenu",
        "re_menu", "re-mod", "reloader", "red-loader",
        "redeng", "rengine", "r-engine"
    },

    -- Exports conocidos
    exports = {
        "RedEngine_Execute", "RE_Inject", "RE_Spawn",
        "RE_GodMode", "RE_Teleport", "RE_Money",
        "RE_Vehicle", "RE_Weapon", "RE_Admin"
    },

    -- Eventos conocidos
    events = {
        "redengine:execute", "redengine:spawn",
        "redengine:money", "redengine:godmode",
        "re:client:init", "re:server:verify"
    },

    -- Patrones en memoria/código
    patterns = {
        "RedEngine v%d", "RE_SIGNATURE",
        "red-engine.io", "redengine.menu"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIRMAS DE PHAZEMENU
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.PhazeMenu = {
    name = "PhazeMenu",
    severity = "CRITICAL",
    description = "Menú de cheat avanzado para FiveM",

    resources = {
        "phazemenu", "phaze-menu", "phaze_menu", "phazem",
        "phaze", "pz-menu", "pzmenu", "phaze-mod",
        "phazeloader", "phaze-loader"
    },

    exports = {
        "Phaze_Execute", "PZ_Inject", "Phaze_Init",
        "PZ_GodMode", "PZ_ESP", "PZ_Aimbot",
        "Phaze_Spawn", "PZ_Money", "PZ_Teleport"
    },

    events = {
        "phazemenu:execute", "phaze:init",
        "pz:client:load", "pz:server:auth",
        "phaze:spawn", "phaze:money"
    },

    patterns = {
        "PhazeMenu", "PHAZE_SIG", "phaze.menu",
        "phazemenu.com", "PZ_VERSION"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIRMAS DE EULEN
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.Eulen = {
    name = "Eulen",
    severity = "CRITICAL",
    description = "Menú de cheat conocido",

    resources = {
        "eulen", "eulenmenu", "eulen-menu", "eulen_menu",
        "eul3n", "eu-menu", "eulenmod", "eulen-mod"
    },

    exports = {
        "Eulen_Init", "Eulen_Execute", "EU_Inject",
        "Eulen_GodMode", "Eulen_Money", "Eulen_Spawn"
    },

    events = {
        "eulen:init", "eulen:execute", "eulen:spawn",
        "eu:client:load", "eu:server:verify"
    },

    patterns = {
        "EulenMenu", "EULEN_SIG", "eulen.io"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIRMAS DE LYNX
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.Lynx = {
    name = "Lynx",
    severity = "CRITICAL",
    description = "Menú de cheat Lynx",

    resources = {
        "lynx", "lynxmenu", "lynx-menu", "lynx_menu",
        "lynxmod", "lynx-mod", "lynxcheats", "l-menu"
    },

    exports = {
        "Lynx_Init", "Lynx_Execute", "LX_Inject",
        "Lynx_GodMode", "Lynx_ESP", "Lynx_Teleport"
    },

    events = {
        "lynx:init", "lynx:execute", "lynx:spawn",
        "lx:client:load", "lx:server:auth"
    },

    patterns = {
        "LynxMenu", "LYNX_SIG", "lynx.menu"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIRMAS DE OTROS MENÚS CONOCIDOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.OtherMenus = {
    -- Ham Mafia
    {
        name = "HamMafia",
        resources = {"hammafia", "ham-mafia", "ham_mafia", "hm-menu"},
        exports = {"HM_Execute", "HM_Inject", "Ham_Init"},
        events = {"hammafia:init", "hm:execute"}
    },

    -- Skid Menu
    {
        name = "SkidMenu",
        resources = {"skid", "skidmenu", "skid-menu", "sk1d"},
        exports = {"Skid_Execute", "SK_Inject"},
        events = {"skid:init", "skid:execute"}
    },

    -- 2Take1
    {
        name = "2Take1",
        resources = {"2take1", "2t1", "2t1menu", "twotakeone"},
        exports = {"TT1_Execute", "2T1_Inject"},
        events = {"2t1:init", "2take1:execute"}
    },

    -- Stand
    {
        name = "Stand",
        resources = {"stand", "standmenu", "stand-menu", "st4nd"},
        exports = {"Stand_Execute", "ST_Inject"},
        events = {"stand:init", "stand:execute"}
    },

    -- Cherax
    {
        name = "Cherax",
        resources = {"cherax", "cheraxmenu", "cherax-menu", "ch3rax"},
        exports = {"Cherax_Execute", "CX_Inject"},
        events = {"cherax:init", "cherax:execute"}
    },

    -- Paragon
    {
        name = "Paragon",
        resources = {"paragon", "paragonmenu", "para-menu", "prg"},
        exports = {"Paragon_Execute", "PRG_Inject"},
        events = {"paragon:init", "paragon:execute"}
    },

    -- Midnight
    {
        name = "Midnight",
        resources = {"midnight", "midnightmenu", "mid-menu", "mdn"},
        exports = {"Midnight_Execute", "MDN_Inject"},
        events = {"midnight:init", "midnight:execute"}
    },

    -- Ozark
    {
        name = "Ozark",
        resources = {"ozark", "ozarkmenu", "oz-menu", "ozrk"},
        exports = {"Ozark_Execute", "OZ_Inject"},
        events = {"ozark:init", "ozark:execute"}
    },

    -- Impulse
    {
        name = "Impulse",
        resources = {"impulse", "impulsemenu", "imp-menu", "impl"},
        exports = {"Impulse_Execute", "IMP_Inject"},
        events = {"impulse:init", "impulse:execute"}
    },

    -- PhantomX
    {
        name = "PhantomX",
        resources = {"phantomx", "phantom-x", "phx-menu", "phantom"},
        exports = {"PhantomX_Execute", "PHX_Inject"},
        events = {"phantomx:init", "phantom:execute"}
    },

    -- Disturbed
    {
        name = "Disturbed",
        resources = {"disturbed", "disturbedmenu", "dist-menu", "dstb"},
        exports = {"Disturbed_Execute", "DST_Inject"},
        events = {"disturbed:init", "disturbed:execute"}
    },

    -- Luna
    {
        name = "Luna",
        resources = {"luna", "lunamenu", "luna-menu", "ln-menu"},
        exports = {"Luna_Execute", "LN_Inject"},
        events = {"luna:init", "luna:execute"}
    },

    -- Robust
    {
        name = "Robust",
        resources = {"robust", "robustmenu", "rob-menu", "rbst"},
        exports = {"Robust_Execute", "RB_Inject"},
        events = {"robust:init", "robust:execute"}
    },

    -- XCheats
    {
        name = "XCheats",
        resources = {"xcheats", "x-cheats", "xc-menu", "xcheat"},
        exports = {"XCheats_Execute", "XC_Inject"},
        events = {"xcheats:init", "xc:execute"}
    },

    -- Lambda Menu
    {
        name = "LambdaMenu",
        resources = {"lambda", "lambdamenu", "lambda-menu", "lmenu"},
        exports = {"Lambda_Execute", "LM_Spawn"},
        events = {"lambda:init", "lambda:spawn"}
    },

    -- Menyoo
    {
        name = "Menyoo",
        resources = {"menyoo", "menyoosp", "menyoo-menu"},
        exports = {"Menyoo_Execute", "MY_Spawn"},
        events = {"menyoo:init", "menyoo:spawn"}
    },

    -- Simple Trainer
    {
        name = "SimpleTrainer",
        resources = {"simpletrainer", "simple-trainer", "str"},
        exports = {"ST_Execute", "Trainer_Spawn"},
        events = {"trainer:init", "trainer:spawn"}
    },

    -- Kiddion's Modest Menu (detectar intentos de uso en FiveM)
    {
        name = "Kiddions",
        resources = {"kiddion", "kiddions", "modest", "modestmenu"},
        exports = {"Kiddion_Execute", "MM_Inject"},
        events = {"kiddion:init", "modest:execute"}
    },

    -- FiveM Trainer
    {
        name = "FiveMTrainer",
        resources = {"fivem-trainer", "fivemtrainer", "ftrainer", "fm-trainer"},
        exports = {"FMT_Execute", "Trainer_Init"},
        events = {"fmtrainer:init", "trainer:execute"}
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FIRMAS DE EXECUTORS/INJECTORS
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.Injectors = {
    -- Ejecutores de Lua
    luaExecutors = {
        "executelua", "execute-lua", "exec_lua", "luaexec",
        "runlua", "lua-runner", "lua_inject", "luainject",
        "scriptexec", "script-executor", "coderunner",
        "remoteexec", "remote-execute", "serverexec"
    },

    -- Inyectores conocidos
    injectors = {
        "dll_injector", "injector", "cheat-engine",
        "ce-inject", "memhack", "memory-hack",
        "bypass", "ac-bypass", "anticheat-bypass"
    },

    -- Funciones de inyección
    functions = {
        "ExecuteCode", "InjectScript", "RunRemote",
        "LoadExternalScript", "BypassAC", "DisableAnticheat",
        "HookFunction", "DetourFunction", "PatchMemory"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EVENTOS MALICIOSOS GENÉRICOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

Signatures.MaliciousEvents = {
    -- Eventos de economía (intentos de exploit)
    economy = {
        "esx:setJob", "esx:setAccountMoney", "esx:addAccountMoney",
        "esx_billing:sendBill", "esx_society:depositMoney",
        "qb-admin:server:setjob", "qb-admin:server:givemoney",
        "qb-core:server:setMoney", "qb-core:server:addMoney",
        "vrp:setMoney", "vrp:addMoney", "vrp:setGroup"
    },

    -- Eventos de admin (sin autorización)
    admin = {
        "txAdmin:menu:healPlayer", "txAdmin:menu:tpToCoords",
        "txAdmin:menu:spawnVehicle", "txAdmin:menu:deleteVehicle",
        "vMenu:SetWeather", "vMenu:SetTime", "vMenu:TeleportToCoords",
        "admin:heal", "admin:tp", "admin:give", "admin:spawn"
    },

    -- Eventos de spawn
    spawn = {
        "baseevents:onPlayerKilled", "esx_ambulancejob:revive",
        "hospital:revive", "spawn:vehicle", "spawn:weapon",
        "spawn:money", "spawn:item", "spawn:ped"
    },

    -- Eventos de teleport
    teleport = {
        "tp:coords", "teleport:to", "setcoords",
        "warp:player", "goto:coords", "position:set"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Verificar si un recurso coincide con alguna firma
function Signatures.CheckResource(resourceName)
    local lowerName = string.lower(resourceName)

    -- Verificar menús principales
    for menuName, menuData in pairs(Signatures) do
        if type(menuData) == "table" and menuData.resources then
            for _, sig in ipairs(menuData.resources) do
                if string.find(lowerName, string.lower(sig)) then
                    return {
                        detected = true,
                        menu = menuData.name or menuName,
                        severity = menuData.severity or "HIGH",
                        signature = sig
                    }
                end
            end
        end
    end

    -- Verificar otros menús
    if Signatures.OtherMenus then
        for _, menu in ipairs(Signatures.OtherMenus) do
            if menu.resources then
                for _, sig in ipairs(menu.resources) do
                    if string.find(lowerName, string.lower(sig)) then
                        return {
                            detected = true,
                            menu = menu.name,
                            severity = "HIGH",
                            signature = sig
                        }
                    end
                end
            end
        end
    end

    -- Verificar injectors
    if Signatures.Injectors then
        for _, injector in ipairs(Signatures.Injectors.luaExecutors or {}) do
            if string.find(lowerName, string.lower(injector)) then
                return {
                    detected = true,
                    menu = "LuaExecutor",
                    severity = "CRITICAL",
                    signature = injector
                }
            end
        end
    end

    return {detected = false}
end

-- Verificar si un evento coincide con alguna firma
function Signatures.CheckEvent(eventName)
    local lowerEvent = string.lower(eventName)

    -- Verificar eventos de economía
    for _, event in ipairs(Signatures.MaliciousEvents.economy) do
        if string.find(lowerEvent, string.lower(event)) then
            return {
                detected = true,
                category = "economy",
                severity = "CRITICAL",
                signature = event
            }
        end
    end

    -- Verificar eventos de admin
    for _, event in ipairs(Signatures.MaliciousEvents.admin) do
        if string.find(lowerEvent, string.lower(event)) then
            return {
                detected = true,
                category = "admin",
                severity = "HIGH",
                signature = event
            }
        end
    end

    -- Verificar eventos de spawn
    for _, event in ipairs(Signatures.MaliciousEvents.spawn) do
        if string.find(lowerEvent, string.lower(event)) then
            return {
                detected = true,
                category = "spawn",
                severity = "HIGH",
                signature = event
            }
        end
    end

    return {detected = false}
end

-- Obtener todas las firmas de recursos como lista plana
function Signatures.GetAllResourceSignatures()
    local all = {}

    -- Agregar de menús principales
    for menuName, menuData in pairs(Signatures) do
        if type(menuData) == "table" and menuData.resources then
            for _, sig in ipairs(menuData.resources) do
                table.insert(all, sig)
            end
        end
    end

    -- Agregar de otros menús
    if Signatures.OtherMenus then
        for _, menu in ipairs(Signatures.OtherMenus) do
            if menu.resources then
                for _, sig in ipairs(menu.resources) do
                    table.insert(all, sig)
                end
            end
        end
    end

    -- Agregar injectors
    if Signatures.Injectors then
        for _, sig in ipairs(Signatures.Injectors.luaExecutors or {}) do
            table.insert(all, sig)
        end
        for _, sig in ipairs(Signatures.Injectors.injectors or {}) do
            table.insert(all, sig)
        end
    end

    return all
end

-- Obtener todos los eventos maliciosos como lista plana
function Signatures.GetAllMaliciousEvents()
    local all = {}

    for category, events in pairs(Signatures.MaliciousEvents) do
        for _, event in ipairs(events) do
            table.insert(all, event)
        end
    end

    return all
end

-- Exportar
_G.AnticheatSignatures = Signatures

return Signatures
