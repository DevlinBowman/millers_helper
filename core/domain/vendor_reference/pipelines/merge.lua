-- core/domain/vendor_reference/pipelines/merge.lua
--
-- Merge existing rows + incoming rows.

local Registry = require("core.domain.vendor_reference.registry")

local Pipeline = {}

function Pipeline.run(existing_rows, incoming_rows)
    local Signals = Registry.signals
    local Schema  = Registry.schema
    local Key     = Registry.key
    local Merge   = Registry.merge

    local sig = Signals.new()

    existing_rows = existing_rows or {}
    incoming_rows = incoming_rows or {}

    local valid_existing = Schema.validate_rows(existing_rows, sig, Signals)
    local valid_incoming = Schema.validate_rows(incoming_rows, sig, Signals)

    local merged, report = Merge.merge(valid_existing, valid_incoming, Key)

    sig.stats.merged_count    = #merged
    sig.stats.inserted_count  = #report.inserts
    sig.stats.updated_count   = #report.updates
    sig.stats.unchanged_count = #report.unchanged

    for i = 1, #report.updates do
        local u = report.updates[i]
        Signals.info(sig, "price_changed", "price changed for " .. u.key, u)
    end

    return {
        rows    = merged,
        report  = report,
        signals = sig,
    }
end

return Pipeline
