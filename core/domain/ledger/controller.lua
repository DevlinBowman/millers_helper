-- core/domain/ledger/controller.lua
--
-- Ledger Domain Controller (PURE)
--
-- No runtime.
-- No filesystem.
-- No storage.
-- No side effects.
--
-- Provides domain-only transformations.

local Registry = require("core.domain.ledger.registry")
local Result   = require("core.domain.ledger.result")

local Controller = {}

----------------------------------------------------------------
-- Build Transaction Entry From Batch
----------------------------------------------------------------

---@param batch table
---@return string transaction_id
---@return table entry
function Controller.build_from_batch(batch)

    local txn_id = Registry.identity.from_batch(batch)

    local entry = Registry.build.run({
        transaction_id = txn_id,
        type           = batch.order.use or "sale",
        date           = batch.order.date,
        order_id       = batch.order.order_id,
        customer_id    = batch.order.customer_id,
        value          = batch.order.value or 0,
        total_bf       = batch.order.bf_batch or 0,
    })

    return txn_id, entry
end

----------------------------------------------------------------
-- Commit From Eligible Batches (Pure)
----------------------------------------------------------------


---@param batches table[]
---@return LedgerResult
function Controller.commit_from_batches(batches)
    assert(type(batches) == "table", "[ledger] batches table required")

    local out = {}

    for _, batch in ipairs(batches) do
        -- Service already decided eligibility; domain just shapes.
        local txn_id, entry = Controller.build_from_batch(batch)

        out[#out + 1] = {
            transaction_id = txn_id,
            entry          = entry,
            order          = batch.order,
            boards         = batch.boards,
        }
    end

    assert(#out > 0, "[ledger] no eligible batches")

    return Result.new({ transactions = out })
end

----------------------------------------------------------------
-- Shape Helpers (Pure)
----------------------------------------------------------------

function Controller.shape_index(transactions)
    return Result.new({ transactions = transactions })
end

function Controller.shape_single(transaction)
    return Result.new({ transaction = transaction })
end

----------------------------------------------------------------
-- Analytics (Pure – expects hydrated bundles)
----------------------------------------------------------------

-- core/domain/ledger/controller.lua

function Controller.analytics_from_bundles(bundles)
    assert(type(bundles) == "table", "[ledger] bundles table required")

    local mod = require("core.domain.ledger.internal.analytics")
    assert(type(mod) == "table", "[ledger] analytics module must return table")

    local fn = mod.from_bundles or mod.run or mod.build
    assert(type(fn) == "function",
        "[ledger] analytics module missing from_bundles/run/build")

    return fn(bundles)
end

return Controller
