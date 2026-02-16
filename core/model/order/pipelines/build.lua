-- core/model/order/pipelines/build.lua
--
-- Build pipeline for Order model.
-- Supports recalculation of derived fields (e.g., value).

local Registry = require("core.model.order.registry")

local Build = {}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Build one canonical Order.
--- @param ctx table
--- @param boards table[]|nil
--- @return table { order=table, unknown=table }
function Build.run(ctx, boards)

    assert(type(ctx) == "table",
        "Order.build(): ctx table required")

    ------------------------------------------------------------
    -- Coerce authoritative fields
    ------------------------------------------------------------

    local order, unknown = Registry.coerce.run(ctx)

    ------------------------------------------------------------
    -- Validate
    ------------------------------------------------------------

    Registry.validate.run(order)

    ------------------------------------------------------------
    -- Derive recalculable fields
    ------------------------------------------------------------

    Registry.derive.run(order, boards)

    return {
        order   = order,
        unknown = unknown,
    }
end

return Build
