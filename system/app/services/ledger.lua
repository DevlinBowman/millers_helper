-- system/app/services/ledger.lua
--
-- Ledger Application Service
--
-- Owns:
--   • Runtime resolution
--   • Eligibility filtering
--   • Existing detection
--   • Force policy
--   • Canonical store writes
--   • Index append
--   • Bundle hydration
--
-- This is the state machine.

local LedgerDomain = require("core.domain.ledger").controller

local LedgerIndex  = require("system.infrastructure.ledger.index")
local LedgerBundle = require("system.infrastructure.ledger.bundle")

local Ledger = {}
Ledger.__index = Ledger

function Ledger.new(app)
    return setmetatable({ __app = app }, Ledger)
end

----------------------------------------------------------------
-- Internal: Collect Eligible Order Batches
----------------------------------------------------------------


local function collect_order_batches(runtime)
    local envelope = runtime:require("user", "job", nil)
    assert(type(envelope) == "table", "[ledger.service] missing user.job runtime envelope")

    local batches

    if type(envelope.batches) == "function" then
        batches = envelope:batches()
    elseif type(envelope.__batches) == "table" then
        batches = envelope.__batches
    else
        error("[ledger.service] runtime envelope has no batches()", 2)
    end

    assert(type(batches) == "table" and #batches > 0,
        "[ledger.service] user job runtime has no batches")

    -- eligibility rule (category optional)
    local eligible = {}
    for _, batch in ipairs(batches) do
        local category = batch and batch.meta and batch.meta.category
        if category == nil or category == "order" then
            eligible[#eligible + 1] = batch
        end
    end

    assert(#eligible > 0, "[ledger.service] no eligible order batches")
    return eligible
end

----------------------------------------------------------------
-- Commit Runtime → Ledger Store
----------------------------------------------------------------

function Ledger:commit(opts)

    opts = opts or {}

    local runtime = self.__app:data():runtime()
    local eligible = collect_order_batches(runtime)

    local domain_result =
        LedgerDomain.commit_from_batches(eligible)

    local persisted = {}

    for _, txn in ipairs(domain_result:transactions()) do

        local existing =
            LedgerIndex.read_one(txn.transaction_id)

        if existing and not opts.force then
            persisted[#persisted + 1] = existing
        else
            LedgerBundle.write(
                txn.transaction_id,
                txn.entry,
                txn.order,
                txn.boards,
                txn.allocations
            )

            LedgerIndex.append(txn.entry)

            persisted[#persisted + 1] = txn.entry
        end
    end

    return LedgerDomain.shape_index(persisted)
end

----------------------------------------------------------------
-- Reads
----------------------------------------------------------------

function Ledger:read_all()
    local txns = LedgerIndex.read_all()
    return LedgerDomain.shape_index(txns)
end

function Ledger:read_one(transaction_id)
    local txn = LedgerIndex.read_one(transaction_id)
    return LedgerDomain.shape_single(txn)
end

-- system/app/services/ledger.lua

function Ledger:read_bundle(transaction_id)
    assert(type(transaction_id) == "string" and transaction_id ~= "",
        "[ledger.service] transaction_id required")
    return LedgerBundle.read(transaction_id)
end

function Ledger:index_full()

    local txns = LedgerIndex.read_all()
    local hydrated = {}

    for _, txn in ipairs(txns) do
        hydrated[#hydrated + 1] =
            LedgerBundle.read(txn.transaction_id)
    end

    return LedgerDomain.shape_index(hydrated)
end

function Ledger:analytics()

    local txns = LedgerIndex.read_all()
    local bundles = {}

    for _, txn in ipairs(txns) do
        bundles[#bundles + 1] =
            LedgerBundle.read(txn.transaction_id)
    end

    local report =
        LedgerDomain.analytics_from_bundles(bundles)

    return report
end

----------------------------------------------------------------

return Ledger
