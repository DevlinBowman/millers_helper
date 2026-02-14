local Coerce   = require("core.model.order.coerce")
local Validate = require("core.model.order.validate")

local Build = {}

function Build.run(ctx)
    assert(type(ctx) == "table", "Order.build(): context table required")

    local order = Coerce.run(ctx)
    Validate.run(order)

    return order
end

return Build
