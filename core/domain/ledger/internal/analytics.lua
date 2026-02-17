local Registry = require("core.domain.ledger.registry")

local Analytics = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function safe_number(v)
    return tonumber(v) or 0
end

local function new_group()
    return {
        txn_count    = 0,
        total_bf     = 0,
        total_value  = 0,
    }
end

local function update(group, bf, value)
    group.txn_count   = group.txn_count + 1
    group.total_bf    = group.total_bf + bf
    group.total_value = group.total_value + value
end

local function finalize(group)
    group.avg_bf_per_txn =
        group.txn_count > 0 and (group.total_bf / group.txn_count) or 0

    group.avg_value_per_txn =
        group.txn_count > 0 and (group.total_value / group.txn_count) or 0

    group.avg_value_per_bf =
        group.total_bf > 0 and (group.total_value / group.total_bf) or 0
end

local function sort_desc(map, key)
    local arr = {}
    for k, v in pairs(map) do
        arr[#arr + 1] = { key = k, data = v }
    end

    table.sort(arr, function(a, b)
        return (a.data[key] or 0) > (b.data[key] or 0)
    end)

    return arr
end

----------------------------------------------------------------
-- Full Ledger Analytics (Order + Board Hybrid)
----------------------------------------------------------------

function Analytics.full_report()
    local index = Registry.ledger.read_all()

    local by_type     = {}
    local by_buyer    = {}
    local by_claimant = {}
    local personal    = new_group()

    for _, entry in ipairs(index) do
        local bundle = Registry.storage.read_bundle(entry.transaction_id)

        local order  = bundle.order or {}
        local boards = bundle.boards or {}

        local type_     = order.use or "unknown"
        local buyer     = order.client
        local claimant  = order.claimant
        local value     = safe_number(order.value)

        --------------------------------------------------------
        -- Compute Physical Volume From Boards
        --------------------------------------------------------
        local total_bf = 0
        for _, b in ipairs(boards) do
            total_bf = total_bf + safe_number(b.bf_batch)
        end

        --------------------------------------------------------
        -- By Type
        --------------------------------------------------------
        if not by_type[type_] then
            by_type[type_] = new_group()
        end
        update(by_type[type_], total_bf, value)

        --------------------------------------------------------
        -- By Buyer (Revenue)
        --------------------------------------------------------
        if buyer then
            if not by_buyer[buyer] then
                by_buyer[buyer] = new_group()
            end
            update(by_buyer[buyer], total_bf, value)
        end

        --------------------------------------------------------
        -- By Claimant (Usage)
        --------------------------------------------------------
        if claimant then
            if not by_claimant[claimant] then
                by_claimant[claimant] = new_group()
            end
            update(by_claimant[claimant], total_bf, value)
        end

        --------------------------------------------------------
        -- Personal Use (self consumption)
        --------------------------------------------------------
        if buyer and claimant and buyer == claimant then
            update(personal, total_bf, value)
        end
    end

    ------------------------------------------------------------
    -- Finalize
    ------------------------------------------------------------
    for _, g in pairs(by_type) do
        finalize(g)
    end

    for _, g in pairs(by_buyer) do
        finalize(g)
    end

    for _, g in pairs(by_claimant) do
        finalize(g)
    end

    finalize(personal)

    ------------------------------------------------------------
    -- Rankings
    ------------------------------------------------------------
    return {
        by_type     = by_type,
        by_buyer    = by_buyer,
        by_claimant = by_claimant,

        rankings = {
            top_buyers_by_value = sort_desc(by_buyer, "total_value"),
            top_users_by_bf     = sort_desc(by_claimant, "total_bf"),
        },

        personal_use = personal,
    }
end

return Analytics
