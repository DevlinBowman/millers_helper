-- core/model/order/pipelines/build.lua

local Registry = require("core.model.order.registry")

local Build = {}

--- Build one canonical Order from one input ctx (1:1), returning unknown inputs separately.
--- @param ctx table
--- @return table result { order=table, unknown=table }
function Build.run(ctx)
    local order, unknown = Registry.coerce.run(ctx)
    Registry.validate.run(order)

    return {
        order   = order,
        unknown = unknown,
    }
end

return Build
