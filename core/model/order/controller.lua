-- core/model/order/controller.lua

local Contract = require("core.contract")
local Trace    = require("tools.trace")

local BuildPipeline = require("core.model.order.pipelines.build")

local Controller = {}

Controller.CONTRACT = {
    build = {
        in_  = { ctx = true },
        out  = { order = true, unknown = true },
    },
}

function Controller.build(ctx)
    Trace.contract_enter("core.model.order.controller.build")
    Trace.contract_in(Controller.CONTRACT.build.in_)

    assert(type(ctx) == "table", "Order.controller.build(): ctx table required")
    Contract.assert({ ctx = ctx }, Controller.CONTRACT.build.in_)

    local result = BuildPipeline.run(ctx)

    Contract.assert(result, Controller.CONTRACT.build.out)
    Trace.contract_out(Controller.CONTRACT.build.out)

    return result
end

return Controller
