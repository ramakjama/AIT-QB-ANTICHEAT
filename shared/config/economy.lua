-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb ECONOMY CONFIGURATION
-- Configuración del sistema económico
-- ═══════════════════════════════════════════════════════════════════════════════════════

return {
    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MONEDAS
    -- ───────────────────────────────────────────────────────────────────────────────────
    currencies = {
        cash = {
            name = 'Efectivo',
            symbol = '$',
            decimals = 0,
            color = '#22c55e',
            tradeable = true,
            maxAmount = 10000000000, -- 10 billion
        },
        bank = {
            name = 'Banco',
            symbol = '$',
            decimals = 0,
            color = '#3b82f6',
            tradeable = true,
            maxAmount = 10000000000,
        },
        crypto = {
            name = 'AIT Token',
            symbol = 'AIT',
            decimals = 8,
            color = '#f59e0b',
            tradeable = true,
            maxAmount = 1000000000,
        },
        black = {
            name = 'Dinero Negro',
            symbol = '$',
            decimals = 0,
            color = '#374151',
            tradeable = false,
            maxAmount = 10000000000,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- CUENTAS POR DEFECTO
    -- ───────────────────────────────────────────────────────────────────────────────────
    defaultAccounts = {
        'cash',
        'bank',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- IMPUESTOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    taxes = {
        sales = {
            rate = 7.0, -- 7%
            description = 'Impuesto sobre ventas',
        },
        income = {
            rate = 15.0, -- 15%
            description = 'Impuesto sobre la renta',
            brackets = {
                { min = 0, max = 10000, rate = 5 },
                { min = 10001, max = 50000, rate = 10 },
                { min = 50001, max = 200000, rate = 15 },
                { min = 200001, max = 1000000, rate = 20 },
                { min = 1000001, max = nil, rate = 25 },
            },
        },
        property = {
            rate = 2.0, -- 2% del valor
            description = 'Impuesto sobre propiedades',
            frequency = 'weekly',
        },
        luxury = {
            rate = 25.0, -- 25%
            description = 'Impuesto de lujo',
            threshold = 100000, -- Items > $100k
        },
        transfer = {
            rate = 1.0, -- 1%
            description = 'Comisión por transferencia',
            minAmount = 10000, -- Solo en transferencias > $10k
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ANTI-INFLACIÓN (SINKS)
    -- ───────────────────────────────────────────────────────────────────────────────────
    sinks = {
        -- Vehículos
        vehicleMaintenance = {
            enabled = true,
            costPerMile = 5,
            frequency = 'daily',
        },
        vehicleInsurance = {
            enabled = true,
            rateOfValue = 0.01, -- 1% del valor del vehículo
            frequency = 'weekly',
        },
        vehicleImpound = {
            enabled = true,
            baseCost = 500,
            perHour = 100,
            maxCost = 10000,
        },

        -- Propiedades
        propertyMaintenance = {
            enabled = true,
            rateOfValue = 0.005, -- 0.5% del valor
            frequency = 'weekly',
        },
        utilities = {
            enabled = true,
            baseCost = 200,
            perUpgrade = 50,
            frequency = 'weekly',
        },

        -- Armas
        weaponMaintenance = {
            enabled = true,
            costPerUse = 10,
            jamThreshold = 20, -- % de condición para encasquillarse
        },
        ammoPrice = {
            multiplier = 1.0, -- Ajustar para controlar inflación
        },

        -- Licencias
        licenses = {
            driving = { cost = 500, duration = nil }, -- Permanente
            weapon = { cost = 10000, duration = 30 }, -- 30 días
            hunting = { cost = 2000, duration = 30 },
            fishing = { cost = 1000, duration = 30 },
            business = { cost = 50000, duration = nil },
            pilot = { cost = 25000, duration = nil },
        },

        -- Multas
        fines = {
            minAmount = 100,
            maxAmount = 100000,
            interestRate = 0.05, -- 5% si no se paga a tiempo
            daysUntilInterest = 7,
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MERCADO DINÁMICO
    -- ───────────────────────────────────────────────────────────────────────────────────
    dynamicMarket = {
        enabled = true,
        updateInterval = 300, -- 5 minutos
        priceFluctuation = {
            min = 0.5, -- -50%
            max = 1.5, -- +50%
        },
        supplyDemand = {
            enabled = true,
            demandDecay = 0.99, -- Decae 1% por ciclo
            supplyRegen = 1.01, -- Regenera 1% por ciclo
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- BANCOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    banks = {
        interest = {
            enabled = true,
            rate = 0.001, -- 0.1% diario
            maxBalance = 10000000, -- Solo hasta $10M generan interés
            frequency = 'daily',
        },
        loans = {
            enabled = true,
            maxAmount = 500000,
            interestRate = 0.05, -- 5%
            maxDuration = 30, -- días
            latePaymentPenalty = 0.10, -- 10%
        },
        atmLocations = {
            -- Cargadas desde data/world/atms.lua
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- TRANSACCIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    transactions = {
        maxCashTransaction = 100000, -- Máximo en efectivo sin reporte
        largeTransactionThreshold = 50000, -- Log especial
        dailyTransferLimit = 1000000, -- Por jugador
        suspiciousPatterns = {
            rapidTransfers = 10, -- más de 10 en 1 minuto = sospechoso
            roundNumbers = true, -- $100,000 exactos = sospechoso
            newAccountLargeTransfer = 100000, -- Cuenta < 1 día
        },
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- CRYPTO (AIT TOKEN)
    -- ───────────────────────────────────────────────────────────────────────────────────
    crypto = {
        enabled = true,
        exchangeRate = 100, -- 100 in-game $ = 1 AIT
        minWithdraw = 10, -- Mínimo 10 AIT
        maxWithdrawDaily = 1000, -- Máximo 1000 AIT/día
        withdrawFee = 0.05, -- 5%
        depositFee = 0.02, -- 2%
        contractAddress = '', -- Set via convar
        rpcUrl = 'https://bsc-dataseed.binance.org/',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ÍNDICES ECONÓMICOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    indices = {
        targetCPI = 100, -- Consumer Price Index objetivo
        maxInflation = 5, -- Alerta si > 5%
        rebalanceThreshold = 10, -- Rebalanceo automático si > 10%
    },
}
