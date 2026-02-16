-- core/model/order/controller.lua

local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local BuildPipeline = require("core.model.order.pipelines.build")

local Controller = {}

Controller.CONTRACT = {
    build = {
        in_  = { ctx = true, ["boards?"] = true },
        out  = { order = true, unknown = true },
    },
}

--- Build canonical Order.
--- @param ctx table
--- @param boards table[]|nil
--- @return table { order=table, unknown=table }
function Controller.build(ctx, boards)

    Trace.contract_enter("core.model.order.controller.build")
    Trace.contract_in({ ctx = ctx, boards = boards })

    local ok, result_or_err = pcall(function()

        assert(type(ctx) == "table",
            "Order.controller.build(): ctx table required")

        if boards ~= nil then
            assert(type(boards) == "table",
                "Order.controller.build(): boards must be table|nil")
        end

        Contract.assert(
            { ctx = ctx, boards = boards },
            Controller.CONTRACT.build.in_
        )

        local result = BuildPipeline.run(ctx, boards)

        Contract.assert(result, Controller.CONTRACT.build.out)
        Trace.contract_out(result)

        return result
    end)

    Trace.contract_leave()

    if not ok then
        error(result_or_err, 0)
    end

    return result_or_err
end

return Controller
