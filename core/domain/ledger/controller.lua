local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local Registry = require("core.domain.ledger.registry")

local Controller = {}

----------------------------------------------------------------
-- CONTRACT
----------------------------------------------------------------

Controller.CONTRACT = {
    commit = {
        in_  = { runtime = true, opts = false },
        out  = { transactions = true },
    },
}

----------------------------------------------------------------
-- COMMIT FROM RUNTIME
----------------------------------------------------------------

---@param runtime RuntimeView
---@param opts table|nil
function Controller.commit(runtime, opts)
    Trace.contract_enter("core.domain.ledger.controller.commit")
    Trace.contract_in({ runtime = runtime, opts = opts })

    opts = opts or {}

    ------------------------------------------------------------
    -- Enforce Runtime Boundary
    ------------------------------------------------------------

    assert(
        type(runtime) == "table"
        and type(runtime.batches) == "function",
        "[ledger] expected RuntimeView"
    )

    local batches = runtime:batches()
    assert(#batches > 0, "[ledger] runtime has no batches")

    ------------------------------------------------------------
    -- Policy: only commit order-category batches
    ------------------------------------------------------------

    local eligible = {}

    for _, batch in ipairs(batches) do
        local category = batch.meta and batch.meta.category
        if category == "order" then
            eligible[#eligible + 1] = batch
        end
    end

    if #eligible == 0 then
        error("[ledger] no eligible order batches found", 2)
    end

    ------------------------------------------------------------
    -- Commit
    ------------------------------------------------------------

    local results = {}

    print("\n[ledger] BEGIN COMMIT")
    print(string.format(
        "[ledger] eligible_batches=%d | force=%s",
        #eligible,
        tostring(opts.force or false)
    ))

    for i, batch in ipairs(eligible) do

        local txn_id = Registry.identity.from_batch(batch)

        print(string.format(
            "[ledger] [%02d/%02d] txn_id=%s | order_number=%s | boards=%d",
            i,
            #eligible,
            txn_id,
            tostring(batch.order.order_number),
            #(batch.boards or {})
        ))

        local existing = Registry.ledger.read_one(txn_id)

        if existing and not opts.force then
            results[#results + 1] = existing
        else
            local entry = Registry.build.run({
                transaction_id = txn_id,
                type           = batch.order.use or "sale",
                date           = batch.order.date,
                order_id       = batch.order.order_id,
                customer_id    = batch.order.customer_id,
                value          = batch.order.value or 0,
                total_bf       = batch.order.bf_batch or 0,
            })

            Registry.storage.write_bundle(
                txn_id,
                entry,
                batch.order,
                batch.boards
            )

            Registry.ledger.append(entry)

            results[#results + 1] = entry
        end
    end

    print("[ledger] COMPLETE\n")

    local out = { transactions = results }

    Trace.contract_out(out, "ledger.commit", "caller")
    Trace.contract_leave()

    return out
end

----------------------------------------------------------------
-- READ
----------------------------------------------------------------

function Controller.read_all()
    return { transactions = Registry.ledger.read_all() }
end

function Controller.read_one(transaction_id)
    return { transaction = Registry.ledger.read_one(transaction_id) }
end

function Controller.read_bundle(transaction_id)
    return Registry.storage.read_bundle(transaction_id)
end

----------------------------------------------------------------
-- INDEX VIEW (SUMMARY)
----------------------------------------------------------------

function Controller.index()
    local transactions = Registry.ledger.read_all()

    local out = {}

    for _, txn in ipairs(transactions) do
        out[#out + 1] = {
            transaction_id = txn.transaction_id,
            date           = txn.date,
            type           = txn.type,
            order_id       = txn.order_id,
            customer_id    = txn.customer_id,
            total_bf       = txn.total_bf,
            value          = txn.value,
        }
    end

    return { transactions = out }
end

----------------------------------------------------------------
-- FULL REHYDRATED VIEW
----------------------------------------------------------------

function Controller.index_full()
    local transactions = Registry.ledger.read_all()
    local hydrated = {}

    for _, txn in ipairs(transactions) do
        local bundle = Registry.storage.read_bundle(txn.transaction_id)

        hydrated[#hydrated + 1] = {
            entry  = bundle.entry,
            order  = bundle.order,
            boards = bundle.boards,
        }
    end

    return { transactions = hydrated }
end

----------------------------------------------------------------
-- ANALYTICS
----------------------------------------------------------------

function Controller.analytics()
    return require("core.domain.ledger.internal.analytics").full_report()
end


return Controller
