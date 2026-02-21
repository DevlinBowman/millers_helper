-- order_context/internal/signal.lua
--
-- Canonical signal constructor for order_context.
-- Pure data shaping.

local Signal = {}

--- @param spec table
--- @return table signal
function Signal.new(spec)
    return {
        module     = "order_context",
        kind       = spec.kind,
        severity   = spec.severity,   -- "error" | "warn" | "info"
        field      = spec.field,      -- "value", "date", etc.
        values     = spec.values,     -- distinct conflicting values
        resolution = spec.resolution, -- "error" | "keep_first" | "defer_recalc" | "drop" | "keep"
        message    = spec.message,
        meta       = spec.meta or {},
    }
end

return Signal
