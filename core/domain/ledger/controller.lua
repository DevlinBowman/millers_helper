local Trace         = require("tools.trace.trace")
local Contract      = require("core.contract")

local Registry      = require("core.domain.ledger.registry")
local FromIngest    = require("core.domain.ledger.pipelines.from_ingest")

local Controller    = {}

Controller.CONTRACT = {
    from_ingest = {
        in_ = { input = true, opts = false },
        out = { transactions = true },
    },

    read_all = {
        in_ = {},
        out = { transactions = true },
    },

    read_one = {
        in_ = { transaction_id = true },
        out = { transaction = false },
    },
    read_all_full = {
        in_ = {},
        out = { transactions = true },
    },
}

------------------------------------------------------------
-- CREATE (IDEMPOTENT)
------------------------------------------------------------

function Controller.from_ingest(input, opts)
    Trace.contract_enter("core.domain.ledger.controller.from_ingest")
    Trace.contract_in({ input = input, opts = opts })

    Contract.assert(
        { input = input, opts = opts },
        Controller.CONTRACT.from_ingest.in_
    )

    opts = opts or {}

    ------------------------------------------------------------
    -- Normalize to batches
    ------------------------------------------------------------

    local batches = input.data or input
    if batches.order then
        batches = { batches }
    end

    local attempted = #batches
    local skipped   = 0
    local added     = 0
    local results   = {}

    print("\n[ledger] BEGIN INGEST")
    print(string.format(
        "[ledger] batches=%d | force=%s",
        attempted,
        tostring(opts.force or false)
    ))

    ------------------------------------------------------------
    -- Deterministic Identity + Idempotency
    ------------------------------------------------------------

    for i, batch in ipairs(batches) do
        local txn_id      =
            Registry.identity.from_batch(batch)

        local board_count = #(batch.boards or {})
        local value       = batch.order.value or 0

        print(string.format(
            "[ledger] [%02d/%02d] CHECK txn_id=%s | order_number=%s | date=%s | type=%s | boards=%d | value=%s",
            i,
            attempted,
            tostring(txn_id),
            tostring(batch.order.order_number),
            tostring(batch.order.date),
            tostring(batch.order.use),
            board_count,
            tostring(value)
        ))

        local existing =
            Registry.ledger.read_one(txn_id)

        if existing and not opts.force then
            skipped = skipped + 1

            print(string.format(
                "[ledger]      SKIP -> existing_txn=%s",
                tostring(existing.transaction_id)
            ))

            results[#results + 1] = existing
        else
            local out =
                require("core.domain.ledger.pipelines.from_ingest")
                .run({ batch }, opts)

            added = added + 1

            print(string.format(
                "[ledger]      ADD  -> new_txn=%s",
                tostring(out.transactions[1].transaction_id)
            ))

            results[#results + 1] = out.transactions[1]
        end
    end

    ------------------------------------------------------------
    -- Final Ledger Count
    ------------------------------------------------------------

    local total =
        #Registry.ledger.read_all()

    ------------------------------------------------------------
    -- Reporting
    ------------------------------------------------------------

    print(string.format(
        "\n[ledger] SUMMARY attempted=%d | added=%d | skipped=%d | total=%d",
        attempted,
        added,
        skipped,
        total
    ))

    local out = { transactions = results }

    Trace.contract_out(out, "ledger.controller", "caller")
    Trace.contract_leave()

    return out
end

------------------------------------------------------------
-- READ ALL
------------------------------------------------------------

function Controller.read_all()
    Trace.contract_enter("core.domain.ledger.controller.read_all")

    local data = Registry.ledger.read_all()

    local out = { transactions = data }

    Trace.contract_out(out, "ledger.read_all", "caller")
    Trace.contract_leave()

    return out
end

------------------------------------------------------------
-- READ ONE
------------------------------------------------------------

function Controller.read_one(transaction_id)
    Trace.contract_enter("core.domain.ledger.controller.read_one")
    Trace.contract_in({ transaction_id = transaction_id })

    Contract.assert(
        { transaction_id = transaction_id },
        Controller.CONTRACT.read_one.in_
    )

    local entry =
        Registry.ledger.read_one(transaction_id)

    local out = { transaction = entry }

    Trace.contract_out(out, "ledger.read_one", "caller")
    Trace.contract_leave()

    return out
end

function Controller.read_bundle(transaction_id)
    Trace.contract_enter("core.domain.ledger.controller.read_bundle")
    Trace.contract_in({ transaction_id = transaction_id })

    Contract.assert(
        { transaction_id = transaction_id },
        { transaction_id = true }
    )

    local bundle =
        Registry.storage.read_bundle(transaction_id)

    Trace.contract_out(bundle, "ledger.read_bundle", "caller")
    Trace.contract_leave()

    return bundle
end

------------------------------------------------------------
-- READ ALL (FULL REHYDRATION)
------------------------------------------------------------

function Controller.read_all_full()
    Trace.contract_enter("core.domain.ledger.controller.read_all_full")

    local index = Registry.ledger.read_all()
    local hydrated = {}

    for _, entry in ipairs(index) do
        local bundle =
            Registry.storage.read_bundle(entry.transaction_id)

        hydrated[#hydrated + 1] = {
            entry  = bundle.entry,
            order  = bundle.order,
            boards = bundle.boards,
        }
    end

    local out = { transactions = hydrated }

    Trace.contract_out(out, "ledger.read_all_full", "caller")
    Trace.contract_leave()

    return out
end

------------------------------------------------------------
-- ANALYTICS (FULL REPORT)
------------------------------------------------------------

function Controller.analytics_full_report()
    Trace.contract_enter("core.domain.ledger.controller.analytics_full_report")

    local result =
        require("core.domain.ledger.internal.analytics")
        .full_report()

    Trace.contract_out(result, "ledger.analytics_full_report", "caller")
    Trace.contract_leave()

    return result
end

function Controller.print_report()
    local report = require("core.domain.ledger.internal.analytics")
        .full_report()

    require("core.domain.ledger.internal.analytics_printer")
        .print_full(report)
end

return Controller
