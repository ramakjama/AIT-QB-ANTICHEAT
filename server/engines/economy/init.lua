-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb ECONOMY ENGINE
-- Sistema económico completo con ledger, impuestos, mercado dinámico y crypto
-- Optimizado para 2048 slots
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}

local Economy = {
    accounts = {},
    txQueue = {},
    processing = false,
    batchSize = 100,
    flushInterval = 2000,
}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

Economy.Currencies = {
    cash = { name = 'Efectivo', symbol = '$', decimals = 0, tradeable = true },
    bank = { name = 'Banco', symbol = '$', decimals = 0, tradeable = true },
    crypto = { name = 'AIT Token', symbol = 'AIT', decimals = 8, tradeable = true },
    black = { name = 'Dinero Negro', symbol = '$', decimals = 0, tradeable = false },
    token = { name = 'Event Token', symbol = 'TKN', decimals = 0, tradeable = false },
    faction = { name = 'Fondos Facción', symbol = '$', decimals = 0, tradeable = false },
}

Economy.Categories = {
    job_payment = { type = 'source', sink = false },
    mission_reward = { type = 'source', sink = false },
    event_reward = { type = 'source', sink = false },
    loot_sell = { type = 'source', sink = false },
    purchase = { type = 'sink', sink = true },
    tax = { type = 'sink', sink = true },
    fee = { type = 'sink', sink = true },
    repair = { type = 'sink', sink = true },
    fine = { type = 'sink', sink = true },
    transfer = { type = 'transfer', sink = false },
    trade = { type = 'transfer', sink = false },
    bank_deposit = { type = 'transfer', sink = false },
    bank_withdraw = { type = 'transfer', sink = false },
    admin_adjustment = { type = 'system', sink = false },
}

Economy.TaxRates = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Economy.Initialize()
    -- Asegurar cuentas del sistema
    Economy.EnsureSystemAccounts()

    -- Cargar tasas de impuestos
    Economy.LoadTaxRates()

    -- Registrar jobs del scheduler
    if AIT.Scheduler then
        AIT.Scheduler.register('economy_daily_snapshot', {
            interval = 86400,
            fn = Economy.DailySnapshot
        })

        AIT.Scheduler.register('economy_hourly_metrics', {
            interval = 3600,
            fn = Economy.HourlyMetrics
        })

        AIT.Scheduler.register('economy_market_update', {
            interval = 300,
            fn = Economy.UpdateMarketPrices
        })

        AIT.Scheduler.register('economy_flush_tx', {
            interval = 2,
            fn = Economy.FlushTransactions
        })
    end

    -- Thread de flush de transacciones (batch para 2048 slots)
    CreateThread(function()
        while true do
            Wait(Economy.flushInterval)
            Economy.FlushTransactions()
        end
    end)

    -- Suscribirse a eventos
    if AIT.EventBus then
        AIT.EventBus.on('economy.tx.created', Economy.OnTransaction)
    end

    if AIT.Log then
        AIT.Log.info('ECONOMY', 'Economy engine initialized')
    end

    return true
end

function Economy.EnsureSystemAccounts()
    local systemAccounts = {
        { type = 'system', id = 1, currency = 'bank', name = 'Treasury' },
        { type = 'system', id = 2, currency = 'bank', name = 'Tax Pool' },
        { type = 'system', id = 3, currency = 'bank', name = 'Sink Pool' },
        { type = 'system', id = 4, currency = 'crypto', name = 'Token Reserve' },
    }

    for _, acc in ipairs(systemAccounts) do
        MySQL.insert.await([[
            INSERT IGNORE INTO ait_accounts (owner_type, owner_id, currency, balance, status)
            VALUES (?, ?, ?, 0, 'active')
        ]], { acc.type, acc.id, acc.currency })
    end
end

function Economy.LoadTaxRates()
    local rates = MySQL.query.await([[
        SELECT * FROM ait_tax_rates WHERE active = 1
    ]])

    Economy.TaxRates = {}
    for _, rate in ipairs(rates or {}) do
        local key = rate.tax_type .. ':' .. rate.scope_type .. ':' .. tostring(rate.scope_id or 'global')
        Economy.TaxRates[key] = {
            rate = tonumber(rate.rate),
            min = rate.min_amount,
            max = rate.max_amount
        }
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE CUENTAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene una cuenta
---@param ownerType string
---@param ownerId number
---@param currency string
---@return table|nil
function Economy.GetAccount(ownerType, ownerId, currency)
    currency = currency or 'bank'

    -- Cache
    local cacheKey = string.format('%s:%d:%s', ownerType, ownerId, currency)
    if AIT.Cache then
        local cached = AIT.Cache.get('economy.accounts', cacheKey)
        if cached then return cached end
    end

    local account = MySQL.query.await([[
        SELECT * FROM ait_accounts
        WHERE owner_type = ? AND owner_id = ? AND currency = ?
    ]], { ownerType, ownerId, currency })

    if account and account[1] then
        if AIT.Cache then
            AIT.Cache.set('economy.accounts', cacheKey, account[1], 60)
        end
        return account[1]
    end

    return nil
end

--- Crea una cuenta
---@param ownerType string
---@param ownerId number
---@param currency string
---@param initialBalance? number
---@return number accId
function Economy.CreateAccount(ownerType, ownerId, currency, initialBalance)
    currency = currency or 'bank'
    initialBalance = initialBalance or 0

    local accId = MySQL.insert.await([[
        INSERT INTO ait_accounts (owner_type, owner_id, currency, balance, status)
        VALUES (?, ?, ?, ?, 'active')
        ON DUPLICATE KEY UPDATE acc_id = LAST_INSERT_ID(acc_id)
    ]], { ownerType, ownerId, currency, initialBalance })

    -- Invalidar cache
    local cacheKey = string.format('%s:%d:%s', ownerType, ownerId, currency)
    if AIT.Cache then
        AIT.Cache.delete('economy.accounts', cacheKey)
    end

    return accId
end

--- Obtiene el balance de una cuenta
---@param ownerType string
---@param ownerId number
---@param currency? string
---@return number
function Economy.GetBalance(ownerType, ownerId, currency)
    local account = Economy.GetAccount(ownerType, ownerId, currency or 'bank')
    return account and account.balance or 0
end

--- Obtiene todos los balances de un personaje
---@param charId number
---@return table
function Economy.GetCharacterBalances(charId)
    local accounts = MySQL.query.await([[
        SELECT currency, balance FROM ait_accounts
        WHERE owner_type = 'char' AND owner_id = ?
    ]], { charId })

    local balances = {}
    for _, acc in ipairs(accounts or {}) do
        balances[acc.currency] = acc.balance
    end

    -- Asegurar que existan las cuentas básicas
    if not balances.cash then balances.cash = 0 end
    if not balances.bank then balances.bank = 0 end

    return balances
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- TRANSACCIONES
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Crea una transacción
---@param params table
---@return boolean, number|string
function Economy.CreateTransaction(params)
    --[[
        params = {
            source = source (server ID),
            fromOwnerType = 'char',
            fromOwnerId = 123,
            toOwnerType = 'char',
            toOwnerId = 456,
            amount = 1000,
            currency = 'bank',
            category = 'transfer',
            reason = 'Player trade',
            playerId = 123,
            charId = 123,
            meta = {}
        }
    ]]

    -- Validar amount
    if not params.amount or params.amount <= 0 then
        return false, 'Invalid amount'
    end

    params.currency = params.currency or 'bank'
    params.category = params.category or 'transfer'

    -- Rate limiting
    if params.source and AIT.RateLimit then
        local allowed = AIT.RateLimit.check(tostring(params.source), 'economy.tx')
        if not allowed then
            return false, 'Rate limit exceeded'
        end
    end

    -- Obtener cuentas
    local fromAccId = nil
    local toAccId = nil
    local fromBalance = 0

    if params.fromOwnerType and params.fromOwnerId then
        local fromAcc = Economy.GetAccount(params.fromOwnerType, params.fromOwnerId, params.currency)
        if not fromAcc then
            return false, 'Source account not found'
        end
        if fromAcc.status ~= 'active' then
            return false, 'Source account is frozen'
        end
        if fromAcc.balance < params.amount then
            return false, 'Insufficient funds'
        end
        fromAccId = fromAcc.acc_id
        fromBalance = fromAcc.balance
    end

    if params.toOwnerType and params.toOwnerId then
        local toAcc = Economy.GetAccount(params.toOwnerType, params.toOwnerId, params.currency)
        if not toAcc then
            toAccId = Economy.CreateAccount(params.toOwnerType, params.toOwnerId, params.currency)
        else
            if toAcc.status ~= 'active' then
                return false, 'Destination account is frozen'
            end
            toAccId = toAcc.acc_id
        end
    end

    -- Calcular impuesto
    local tax = 0
    local taxCategory = Economy.Categories[params.category]
    if taxCategory and taxCategory.type == 'transfer' and params.currency == 'bank' then
        if params.amount >= 10000 then -- Solo en transferencias > $10k
            tax = Economy.CalculateTax('transfer', params.amount)
        end
    end

    local netAmount = params.amount - tax

    -- Crear signature
    local sigData = string.format('%s:%s:%d:%d:%d',
        tostring(fromAccId), tostring(toAccId), params.amount, os.time(), math.random(1000000))
    local sig = tostring(GetHashKey(sigData))

    -- Añadir a cola de transacciones (batch processing para 2048 slots)
    local tx = {
        fromAccId = fromAccId,
        toAccId = toAccId,
        amount = params.amount,
        netAmount = netAmount,
        tax = tax,
        currency = params.currency,
        category = params.category,
        playerId = params.playerId,
        charId = params.charId,
        reason = params.reason,
        meta = params.meta,
        sig = sig,
        timestamp = os.time(),
    }

    table.insert(Economy.txQueue, tx)

    -- Actualizar balance en cache inmediatamente
    if fromAccId then
        local cacheKey = string.format('%s:%d:%s', params.fromOwnerType, params.fromOwnerId, params.currency)
        if AIT.Cache then
            local cached = AIT.Cache.get('economy.accounts', cacheKey)
            if cached then
                cached.balance = cached.balance - params.amount
                AIT.Cache.set('economy.accounts', cacheKey, cached, 60)
            end
        end
    end

    if toAccId then
        local cacheKey = string.format('%s:%d:%s', params.toOwnerType, params.toOwnerId, params.currency)
        if AIT.Cache then
            local cached = AIT.Cache.get('economy.accounts', cacheKey)
            if cached then
                cached.balance = cached.balance + netAmount
                AIT.Cache.set('economy.accounts', cacheKey, cached, 60)
            end
        end
    end

    -- Emitir evento
    if AIT.EventBus then
        AIT.EventBus.emit('economy.tx.created', {
            sig = sig,
            from = { type = params.fromOwnerType, id = params.fromOwnerId },
            to = { type = params.toOwnerType, id = params.toOwnerId },
            amount = params.amount,
            tax = tax,
            currency = params.currency,
            category = params.category,
        })
    end

    return true, sig
end

--- Flush de transacciones en batch
function Economy.FlushTransactions()
    if Economy.processing or #Economy.txQueue == 0 then return end
    Economy.processing = true

    local batch = {}
    for i = 1, math.min(Economy.batchSize, #Economy.txQueue) do
        table.insert(batch, table.remove(Economy.txQueue, 1))
    end

    if #batch > 0 then
        -- Procesar en una transacción DB
        local queries = {}

        for _, tx in ipairs(batch) do
            -- Deducir de origen
            if tx.fromAccId then
                table.insert(queries, {
                    query = 'UPDATE ait_accounts SET balance = balance - ? WHERE acc_id = ?',
                    values = { tx.amount, tx.fromAccId }
                })
            end

            -- Añadir a destino
            if tx.toAccId then
                table.insert(queries, {
                    query = 'UPDATE ait_accounts SET balance = balance + ? WHERE acc_id = ?',
                    values = { tx.netAmount, tx.toAccId }
                })
            end

            -- Impuesto al pool
            if tx.tax > 0 then
                table.insert(queries, {
                    query = [[
                        UPDATE ait_accounts SET balance = balance + ?
                        WHERE owner_type = 'system' AND owner_id = 2 AND currency = ?
                    ]],
                    values = { tx.tax, tx.currency }
                })
            end

            -- Registro de transacción
            table.insert(queries, {
                query = [[
                    INSERT INTO ait_ledger_tx
                    (src_acc_id, dst_acc_id, amount, currency, category, actor_player_id, actor_char_id, reason, meta, sig, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'completed')
                ]],
                values = {
                    tx.fromAccId, tx.toAccId, tx.amount, tx.currency, tx.category,
                    tx.playerId, tx.charId, tx.reason,
                    tx.meta and json.encode(tx.meta), tx.sig
                }
            })
        end

        -- Ejecutar batch
        MySQL.transaction(queries, function(success)
            if not success then
                if AIT.Log then
                    AIT.Log.error('ECONOMY', 'Transaction batch failed', { count = #batch })
                end
            end
        end)
    end

    Economy.processing = false
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FUNCIONES HELPER
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Añadir dinero a un personaje
---@param source number
---@param charId number
---@param amount number
---@param currency? string
---@param category? string
---@param reason? string
---@return boolean, string
function Economy.AddMoney(source, charId, amount, currency, category, reason)
    return Economy.CreateTransaction({
        source = source,
        toOwnerType = 'char',
        toOwnerId = charId,
        amount = amount,
        currency = currency or 'bank',
        category = category or 'system',
        reason = reason,
        charId = charId
    })
end

--- Quitar dinero a un personaje
---@param source number
---@param charId number
---@param amount number
---@param currency? string
---@param category? string
---@param reason? string
---@return boolean, string
function Economy.RemoveMoney(source, charId, amount, currency, category, reason)
    return Economy.CreateTransaction({
        source = source,
        fromOwnerType = 'char',
        fromOwnerId = charId,
        toOwnerType = 'system',
        toOwnerId = 3, -- Sink pool
        amount = amount,
        currency = currency or 'bank',
        category = category or 'system',
        reason = reason,
        charId = charId
    })
end

--- Transferir dinero entre personajes
---@param source number
---@param fromCharId number
---@param toCharId number
---@param amount number
---@param currency? string
---@param reason? string
---@return boolean, string
function Economy.TransferMoney(source, fromCharId, toCharId, amount, currency, reason)
    return Economy.CreateTransaction({
        source = source,
        fromOwnerType = 'char',
        fromOwnerId = fromCharId,
        toOwnerType = 'char',
        toOwnerId = toCharId,
        amount = amount,
        currency = currency or 'bank',
        category = 'transfer',
        reason = reason,
        charId = fromCharId
    })
end

--- Depositar efectivo en banco
---@param source number
---@param charId number
---@param amount number
---@return boolean, string
function Economy.Deposit(source, charId, amount)
    -- Quitar cash
    local success, err = Economy.CreateTransaction({
        source = source,
        fromOwnerType = 'char',
        fromOwnerId = charId,
        amount = amount,
        currency = 'cash',
        category = 'bank_deposit',
        reason = 'Deposit to bank',
        charId = charId
    })

    if not success then return false, err end

    -- Añadir a banco
    return Economy.CreateTransaction({
        source = source,
        toOwnerType = 'char',
        toOwnerId = charId,
        amount = amount,
        currency = 'bank',
        category = 'bank_deposit',
        reason = 'Deposit from cash',
        charId = charId
    })
end

--- Retirar del banco a efectivo
---@param source number
---@param charId number
---@param amount number
---@return boolean, string
function Economy.Withdraw(source, charId, amount)
    -- Quitar del banco
    local success, err = Economy.CreateTransaction({
        source = source,
        fromOwnerType = 'char',
        fromOwnerId = charId,
        amount = amount,
        currency = 'bank',
        category = 'bank_withdraw',
        reason = 'Withdraw to cash',
        charId = charId
    })

    if not success then return false, err end

    -- Añadir a cash
    return Economy.CreateTransaction({
        source = source,
        toOwnerType = 'char',
        toOwnerId = charId,
        amount = amount,
        currency = 'cash',
        category = 'bank_withdraw',
        reason = 'Withdraw from bank',
        charId = charId
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- IMPUESTOS
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Calcula el impuesto para una transacción
---@param taxType string
---@param amount number
---@param zoneId? number
---@param factionId? number
---@return number
function Economy.CalculateTax(taxType, amount, zoneId, factionId)
    local keys = {}
    if factionId then
        table.insert(keys, taxType .. ':faction:' .. tostring(factionId))
    end
    if zoneId then
        table.insert(keys, taxType .. ':zone:' .. tostring(zoneId))
    end
    table.insert(keys, taxType .. ':global:global')

    for _, key in ipairs(keys) do
        local rate = Economy.TaxRates[key]
        if rate then
            local tax = math.floor(amount * (rate.rate / 100))
            if rate.min and tax < rate.min then tax = rate.min end
            if rate.max and tax > rate.max then tax = rate.max end
            return tax
        end
    end

    return 0
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MERCADO DINÁMICO
-- ═══════════════════════════════════════════════════════════════════════════════════════

--- Obtiene el precio actual de un item
---@param sku string
---@return number|nil
function Economy.GetMarketPrice(sku)
    local price = MySQL.query.await([[
        SELECT current_price FROM ait_market_prices WHERE sku = ?
    ]], { sku })

    return price and price[1] and price[1].current_price or nil
end

--- Actualiza los precios del mercado (oferta/demanda)
function Economy.UpdateMarketPrices()
    local items = MySQL.query.await([[
        SELECT sku, base_price, current_price, supply, demand, price_floor, price_ceiling
        FROM ait_market_prices
    ]])

    for _, item in ipairs(items or {}) do
        local ratio = item.demand / math.max(item.supply, 1)
        local priceMultiplier = 0.5 + (ratio * 0.5)

        local newPrice = math.floor(item.base_price * priceMultiplier)

        if item.price_floor and newPrice < item.price_floor then
            newPrice = item.price_floor
        end
        if item.price_ceiling and newPrice > item.price_ceiling then
            newPrice = item.price_ceiling
        end

        -- Cambio gradual (máx 5%)
        local maxChange = math.floor(item.current_price * 0.05)
        local change = newPrice - item.current_price
        if math.abs(change) > maxChange then
            change = change > 0 and maxChange or -maxChange
        end
        newPrice = item.current_price + change

        if newPrice ~= item.current_price then
            MySQL.query([[
                UPDATE ait_market_prices SET current_price = ? WHERE sku = ?
            ]], { newPrice, item.sku })

            MySQL.insert([[
                INSERT INTO ait_market_history (sku, price) VALUES (?, ?)
            ]], { item.sku, newPrice })

            if AIT.EventBus then
                AIT.EventBus.emit('economy.market.price.changed', {
                    sku = item.sku,
                    oldPrice = item.current_price,
                    newPrice = newPrice
                })
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ANALYTICS
-- ═══════════════════════════════════════════════════════════════════════════════════════

function Economy.DailySnapshot()
    local today = os.date('%Y-%m-%d')

    local totals = MySQL.query.await([[
        SELECT currency, SUM(balance) as total
        FROM ait_accounts
        WHERE status = 'active'
        GROUP BY currency
    ]])

    local totalCash, totalBank, totalCrypto, totalFaction = 0, 0, 0, 0

    for _, row in ipairs(totals or {}) do
        if row.currency == 'cash' then totalCash = row.total
        elseif row.currency == 'bank' then totalBank = row.total
        elseif row.currency == 'crypto' then totalCrypto = row.total
        elseif row.currency == 'faction' then totalFaction = row.total
        end
    end

    local flows = MySQL.query.await([[
        SELECT
            SUM(CASE WHEN src_acc_id IS NULL THEN amount ELSE 0 END) as generated,
            SUM(CASE
                WHEN dst_acc_id IN (SELECT acc_id FROM ait_accounts WHERE owner_type = 'system' AND owner_id = 3)
                THEN amount ELSE 0
            END) as destroyed,
            COUNT(*) as tx_count,
            SUM(amount) as tx_volume
        FROM ait_ledger_tx
        WHERE DATE(ts) = ?
    ]], { today })

    local flow = flows and flows[1] or {}

    local stats = MySQL.query.await([[
        SELECT AVG(balance) as avg_balance, COUNT(DISTINCT owner_id) as player_count
        FROM ait_accounts
        WHERE owner_type = 'char' AND currency = 'bank' AND status = 'active'
    ]])[1] or {}

    MySQL.insert([[
        INSERT INTO ait_economy_daily
        (day, total_cash, total_bank, total_crypto, total_faction,
         money_generated, money_destroyed, tx_count, tx_volume,
         active_players, avg_balance)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            total_cash = ?, total_bank = ?, total_crypto = ?, total_faction = ?,
            money_generated = ?, money_destroyed = ?, tx_count = ?, tx_volume = ?,
            active_players = ?, avg_balance = ?
    ]], {
        today, totalCash, totalBank, totalCrypto, totalFaction,
        flow.generated or 0, flow.destroyed or 0, flow.tx_count or 0, flow.tx_volume or 0,
        stats.player_count or 0, stats.avg_balance or 0,
        totalCash, totalBank, totalCrypto, totalFaction,
        flow.generated or 0, flow.destroyed or 0, flow.tx_count or 0, flow.tx_volume or 0,
        stats.player_count or 0, stats.avg_balance or 0
    })

    if AIT.Log then
        AIT.Log.info('ECONOMY', 'Daily snapshot completed', {
            total = totalCash + totalBank,
            generated = flow.generated,
            destroyed = flow.destroyed
        })
    end
end

function Economy.HourlyMetrics()
    local hour = os.date('%Y-%m-%d %H:00:00')

    local metrics = MySQL.query.await([[
        SELECT
            SUM(CASE WHEN src_acc_id IS NULL THEN amount ELSE 0 END) as generated,
            SUM(CASE
                WHEN dst_acc_id IN (SELECT acc_id FROM ait_accounts WHERE owner_type = 'system' AND owner_id = 3)
                THEN amount ELSE 0
            END) as destroyed,
            COUNT(*) as tx_count,
            SUM(amount) as tx_volume
        FROM ait_ledger_tx
        WHERE ts >= ? AND ts < DATE_ADD(?, INTERVAL 1 HOUR)
    ]], { hour, hour })[1] or {}

    -- Guardar en cache para dashboard
    if AIT.State then
        AIT.State.set('economy.hourly', {
            generated = metrics.generated or 0,
            destroyed = metrics.destroyed or 0,
            txCount = metrics.tx_count or 0,
            txVolume = metrics.tx_volume or 0,
            players = #GetPlayers(),
        })
    end
end

-- Event handler
function Economy.OnTransaction(event)
    -- Log de transacciones grandes
    if event.payload and event.payload.amount and event.payload.amount >= 1000000 then
        if AIT.Audit then
            AIT.Audit.Log('system', 'ECONOMY:LargeTransaction', nil, event.payload, 'warn')
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

Economy.BalanceGet = Economy.GetBalance
Economy.BalanceAdjust = function(source, ownerType, ownerId, currency, delta, reason)
    if delta > 0 then
        return Economy.AddMoney(source, ownerId, delta, currency, 'admin_adjustment', reason)
    else
        return Economy.RemoveMoney(source, ownerId, -delta, currency, 'admin_adjustment', reason)
    end
end
Economy.TxCreate = Economy.CreateTransaction

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- REGISTRAR ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════════════

AIT.Engines.economy = Economy

return Economy
