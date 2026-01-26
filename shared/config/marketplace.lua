-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb MARKETPLACE CONFIGURATION
-- Configuración de la tienda online y pasarela de pagos
-- ═══════════════════════════════════════════════════════════════════════════════════════

return {
    -- ───────────────────────────────────────────────────────────────────────────────────
    -- CONFIGURACIÓN GENERAL
    -- ───────────────────────────────────────────────────────────────────────────────────
    enabled = true,
    currency = 'EUR',
    defaultLocale = 'es',

    -- URLs
    shopUrl = 'https://shop.your-server.com',
    apiUrl = 'https://api.your-server.com',
    webhookSecret = '', -- Set via convar: set ait_shop_webhook_secret ""

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MÉTODOS DE PAGO
    -- ───────────────────────────────────────────────────────────────────────────────────
    paymentMethods = {
        stripe = {
            enabled = true,
            name = 'Tarjeta de Crédito/Débito',
            description = 'Paga con Visa, Mastercard, American Express',
            icon = 'credit-card',
            fee = 0.029, -- 2.9% + 0.30€
            fixedFee = 0.30,
            minAmount = 1.00,
            maxAmount = 10000.00,
            currencies = { 'EUR', 'USD', 'GBP' },
            -- Configuración (via convars)
            -- set ait_stripe_public_key ""
            -- set ait_stripe_secret_key ""
        },

        paypal = {
            enabled = true,
            name = 'PayPal',
            description = 'Paga con tu cuenta PayPal',
            icon = 'paypal',
            fee = 0.034, -- 3.4% + 0.35€
            fixedFee = 0.35,
            minAmount = 1.00,
            maxAmount = 10000.00,
            currencies = { 'EUR', 'USD', 'GBP' },
            sandbox = false,
            -- set ait_paypal_client_id ""
            -- set ait_paypal_client_secret ""
        },

        paysafecard = {
            enabled = true,
            name = 'Paysafecard',
            description = 'Paga con tu código Paysafecard',
            icon = 'paysafe',
            fee = 0.15, -- 15%
            fixedFee = 0,
            minAmount = 10.00,
            maxAmount = 100.00,
            currencies = { 'EUR' },
            -- set ait_paysafe_api_key ""
            -- set ait_paysafe_submerchant_id ""
        },

        crypto = {
            enabled = true,
            name = 'AIT Token (Crypto)',
            description = 'Paga con nuestra criptomoneda AIT',
            icon = 'bitcoin',
            fee = 0.02, -- 2%
            fixedFee = 0,
            minAmount = 0.10, -- 0.1 AIT
            maxAmount = 100000.00,
            currencies = { 'AIT' },
            discount = 0.10, -- 10% descuento pagando con AIT
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- CATEGORÍAS DE PRODUCTOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    categories = {
        {
            id = 'featured',
            name = 'Destacados',
            icon = 'star',
            order = 1,
        },
        {
            id = 'vip',
            name = 'VIP & Pases',
            icon = 'crown',
            order = 2,
        },
        {
            id = 'vehicles',
            name = 'Vehículos',
            icon = 'car',
            order = 3,
        },
        {
            id = 'weapons',
            name = 'Armas',
            icon = 'gun',
            order = 4,
        },
        {
            id = 'clothing',
            name = 'Ropa & Cosméticos',
            icon = 'shirt',
            order = 5,
        },
        {
            id = 'items',
            name = 'Items',
            icon = 'box',
            order = 6,
        },
        {
            id = 'money',
            name = 'Dinero & Tokens',
            icon = 'coins',
            order = 7,
        },
        {
            id = 'crypto',
            name = 'AIT Tokens',
            icon = 'bitcoin',
            order = 8,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- PRODUCTOS BASE (Ejemplo)
    -- ───────────────────────────────────────────────────────────────────────────────────
    products = {
        -- VIP
        {
            id = 'vip_bronze',
            name = 'VIP Bronze',
            description = 'Acceso VIP básico por 30 días',
            category = 'vip',
            price = 4.99,
            image = 'vip_bronze.png',
            featured = true,
            type = 'vip',
            metadata = { level = 1, days = 30 },
        },
        {
            id = 'vip_silver',
            name = 'VIP Silver',
            description = 'Acceso VIP intermedio por 30 días',
            category = 'vip',
            price = 9.99,
            image = 'vip_silver.png',
            featured = true,
            type = 'vip',
            metadata = { level = 2, days = 30 },
        },
        {
            id = 'vip_gold',
            name = 'VIP Gold',
            description = 'Acceso VIP premium por 30 días',
            category = 'vip',
            price = 19.99,
            image = 'vip_gold.png',
            featured = true,
            type = 'vip',
            metadata = { level = 3, days = 30 },
        },

        -- Dinero
        {
            id = 'money_pack_1',
            name = 'Pack Starter',
            description = '$100,000 de dinero en banco',
            category = 'money',
            price = 2.99,
            image = 'money_1.png',
            type = 'money',
            metadata = { amount = 100000, currency = 'bank' },
        },
        {
            id = 'money_pack_2',
            name = 'Pack Medium',
            description = '$500,000 de dinero en banco',
            category = 'money',
            price = 9.99,
            image = 'money_2.png',
            type = 'money',
            metadata = { amount = 500000, currency = 'bank' },
        },
        {
            id = 'money_pack_3',
            name = 'Pack Large',
            description = '$1,000,000 de dinero en banco',
            category = 'money',
            price = 14.99,
            image = 'money_3.png',
            featured = true,
            type = 'money',
            metadata = { amount = 1000000, currency = 'bank' },
        },

        -- AIT Tokens
        {
            id = 'ait_pack_1',
            name = '100 AIT',
            description = '100 tokens AIT',
            category = 'crypto',
            price = 9.99,
            image = 'ait_1.png',
            type = 'crypto',
            metadata = { amount = 100 },
        },
        {
            id = 'ait_pack_2',
            name = '500 AIT',
            description = '500 tokens AIT (+10% bonus)',
            category = 'crypto',
            price = 44.99,
            image = 'ait_2.png',
            type = 'crypto',
            metadata = { amount = 550 }, -- 10% bonus
        },
        {
            id = 'ait_pack_3',
            name = '1000 AIT',
            description = '1000 tokens AIT (+20% bonus)',
            category = 'crypto',
            price = 79.99,
            image = 'ait_3.png',
            featured = true,
            type = 'crypto',
            metadata = { amount = 1200 }, -- 20% bonus
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ENTREGAS
    -- ───────────────────────────────────────────────────────────────────────────────────
    delivery = {
        -- API del servidor FiveM para entregas
        fivemApiUrl = 'http://localhost:30120/ait-qb/api',
        fivemApiKey = '', -- set ait_delivery_api_key ""

        -- Reintentos
        maxRetries = 5,
        retryDelay = 5000, -- ms

        -- Notificación al jugador
        notifyOnDelivery = true,
        notifyMethod = 'both', -- 'ingame', 'discord', 'both'
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- REEMBOLSOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    refunds = {
        enabled = true,
        maxDays = 7, -- Días para solicitar reembolso
        autoRefund = false, -- Requiere aprobación manual
        minAmount = 1.00,

        -- Razones válidas
        reasons = {
            'not_delivered',
            'wrong_item',
            'duplicate_purchase',
            'other',
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- SUSCRIPCIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    subscriptions = {
        enabled = true,

        plans = {
            {
                id = 'vip_monthly',
                name = 'VIP Mensual',
                price = 9.99,
                interval = 'month',
                vipLevel = 2,
            },
            {
                id = 'vip_yearly',
                name = 'VIP Anual',
                price = 99.99, -- 2 meses gratis
                interval = 'year',
                vipLevel = 3,
            },
        },

        -- Gracia antes de cancelar
        gracePeriodDays = 3,
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- PROMOCIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    promotions = {
        enabled = true,

        -- Códigos de descuento
        codes = {
            {
                code = 'WELCOME10',
                discount = 0.10, -- 10%
                type = 'percentage',
                maxUses = 1000,
                perUser = 1,
                validUntil = '2025-12-31',
                categories = { 'all' },
            },
        },

        -- Descuentos por volumen
        volumeDiscounts = {
            { minAmount = 50, discount = 0.05 },  -- 5% en compras > 50€
            { minAmount = 100, discount = 0.10 }, -- 10% en compras > 100€
            { minAmount = 200, discount = 0.15 }, -- 15% en compras > 200€
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- LÍMITES Y SEGURIDAD
    -- ───────────────────────────────────────────────────────────────────────────────────
    limits = {
        maxOrdersPerDay = 10,
        maxSpendPerDay = 500.00,
        maxSpendPerWeek = 2000.00,
        maxSpendPerMonth = 5000.00,

        -- Verificación adicional para compras grandes
        verificationThreshold = 200.00,

        -- Bloqueo por fraude
        fraudDetection = {
            enabled = true,
            maxFailedPayments = 5,
            chargebackBan = true,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ANALYTICS
    -- ───────────────────────────────────────────────────────────────────────────────────
    analytics = {
        enabled = true,
        trackPurchases = true,
        trackViews = true,
        trackCartAbandonment = true,

        -- Integración con servicios externos
        googleAnalytics = '',
        facebookPixel = '',
    },
}
