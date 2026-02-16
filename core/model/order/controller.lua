-- core/model/order/controller.lua

local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local BuildPipeline = require("core.model.order.pipelines.build")

local Controller = {}

Controller.CONTRACT = {
    build = {
        in_  = { ctx = true },
        out  = { order = true, unknown = true },
    },
}

-- core/model/order/controller.lua

function Controller.build(ctx)
    Trace.contract_enter("core.model.order.controller.build")
    Trace.contract_in(Controller.CONTRACT.build.in_)

    local ok, result_or_err = pcall(function()
        assert(type(ctx) == "table", "Order.controller.build(): ctx table required")
        Contract.assert({ ctx = ctx }, Controller.CONTRACT.build.in_)

        local result = BuildPipeline.run(ctx)

        Contract.assert(result, Controller.CONTRACT.build.out)
        Trace.contract_out(Controller.CONTRACT.build.out)

        return result
    end)

    Trace.contract_leave()

    if not ok then
        error(result_or_err, 0)
    end

    return result_or_err
end

return Controller
