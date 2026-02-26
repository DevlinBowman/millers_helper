-- core/domain/vendor_reference/internal/signals.lua
--
-- Pure signal helpers.

local Signals = {}

local function push(list, item)
    list[#list + 1] = item
end

function Signals.new()
    return {
        warnings = {},
        errors   = {},
        info     = {},
        stats    = {
            incoming_count      = 0,
            existing_count      = 0,

            projected_count     = 0,
            dropped_count       = 0,

            inserted_count      = 0,
            updated_count       = 0,
            unchanged_count     = 0,
            skipped_count       = 0,
            conflict_count      = 0,

            price_field_updates = 0,
        },
    }
end

function Signals.warn(sig, code, message, ctx)
    push(sig.warnings, { code = code, message = message, ctx = ctx })
end

function Signals.err(sig, code, message, ctx)
    push(sig.errors, { code = code, message = message, ctx = ctx })
end

function Signals.info(sig, code, message, ctx)
    push(sig.info, { code = code, message = message, ctx = ctx })
end

function Signals.has_errors(sig)
    return sig and sig.errors and #sig.errors > 0
end

return Signals
