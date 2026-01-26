-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb FEATURE FLAGS
-- Configuración de características activables/desactivables
-- ═══════════════════════════════════════════════════════════════════════════════════════

return {
    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MÓDULOS CORE
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['module.ain_identity'] = true,
    ['module.ain_economy'] = true,
    ['module.ain_inventory'] = true,
    ['module.ain_factions'] = true,
    ['module.ain_missions'] = true,
    ['module.ain_events'] = true,
    ['module.ain_vehicles'] = true,
    ['module.ain_housing'] = true,
    ['module.ain_weapons'] = true,
    ['module.ain_clothing'] = true,
    ['module.ain_jobs'] = true,
    ['module.ain_business'] = true,
    ['module.ain_heists'] = true,
    ['module.ain_drugs'] = true,
    ['module.ain_blackmarket'] = true,
    ['module.ain_arena'] = true,
    ['module.ain_matchmaker'] = true,
    ['module.ain_racing'] = true,
    ['module.ain_admin'] = true,
    ['module.ain_analytics'] = true,
    ['module.ain_security'] = true,
    ['module.ain_liveops'] = true,
    ['module.ain_marketplace'] = true,
    ['module.ain_crypto'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- SISTEMAS
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['system.multichar'] = true,
    ['system.needs'] = true, -- Hambre, sed, estrés
    ['system.injuries'] = true, -- Sistema de lesiones
    ['system.stress'] = true,
    ['system.temperature'] = false,
    ['system.alcohol'] = true,
    ['system.drugs_effects'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ECONOMÍA
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['economy.taxes'] = true,
    ['economy.dynamic_market'] = true,
    ['economy.bank_interest'] = true,
    ['economy.loans'] = true,
    ['economy.crypto'] = true,
    ['economy.inflation_control'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- VEHÍCULOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['vehicles.fuel'] = true,
    ['vehicles.damage'] = true,
    ['vehicles.keys'] = true,
    ['vehicles.insurance'] = true,
    ['vehicles.impound'] = true,
    ['vehicles.tuning'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ARMAS
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['weapons.durability'] = true,
    ['weapons.serial_numbers'] = true,
    ['weapons.ballistics'] = true,
    ['weapons.recoil'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- FACCIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['factions.territory'] = true,
    ['factions.diplomacy'] = true,
    ['factions.warfare'] = true,
    ['factions.heat'] = true,
    ['factions.logistics'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MISIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['missions.procedural'] = true,
    ['missions.coop'] = true,
    ['missions.raids'] = true,
    ['missions.daily'] = true,
    ['missions.seasonal'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- PVP
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['pvp.arenas'] = true,
    ['pvp.matchmaking'] = true,
    ['pvp.rankings'] = true,
    ['pvp.tournaments'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- VIVIENDA
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['housing.furniture'] = true,
    ['housing.upgrades'] = true,
    ['housing.robberies'] = true,
    ['housing.mortgages'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- SEGURIDAD
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['security.anticheat'] = true,
    ['security.rate_limiting'] = true,
    ['security.audit_logging'] = true,
    ['security.integrity_checks'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- UI
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['ui.hud'] = true,
    ['ui.minimap'] = true,
    ['ui.compass'] = true,
    ['ui.speedometer'] = true,
    ['ui.notifications'] = true,
    ['ui.radial_menu'] = true,

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MARKETPLACE
    -- ───────────────────────────────────────────────────────────────────────────────────
    ['shop.enabled'] = true,
    ['shop.crypto_payments'] = true,
    ['shop.card_payments'] = true,
    ['shop.paypal'] = true,
    ['shop.paysafe'] = true,
}
