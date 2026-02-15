-- classify/controller.lua
--
-- Public control surface for classification module.

local RowPipeline = require("classify.pipelines.row")
local Trace       = require("tools.trace")
local Contract    = require("core.contract")

local Controller = {}

----------------------------------------------------------------
-- Contract
----------------------------------------------------------------

Controller.CONTRACT = {
    row = {
        in_ = {
            row = true,
        },

        out = {
            board       = true,
            order       = true,
            unknown     = true,
            diagnostics = true,
        },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Controller.row(row)
    -- Trace.contract_enter("classify.controller.row")
    -- Trace.contract_in(Controller.CONTRACT.row.in_)

    Contract.assert({ row = row }, Controller.CONTRACT.row.in_)

    local result = RowPipeline.run(row)

    -- Trace.contract_out(Controller.CONTRACT.row.out, "classify.pipeline.row", "caller")
    Contract.assert(result, Controller.CONTRACT.row.out)

    -- Trace.contract_leave()

    return result
end

return Controller
