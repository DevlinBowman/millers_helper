-- classify/controller.lua
--

--[[
ingest
-- ]]

local objectPipeline = require("classify.pipelines.object")
local Trace       = require("tools.trace.trace")
local Contract    = require("core.contract")

local Controller = {}

----------------------------------------------------------------
-- Contract
----------------------------------------------------------------

Controller.CONTRACT = {
    object = {
        in_ = {
            object = true,
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

function Controller.object(object)
    Trace.contract_enter("classify.controller.object")
    Trace.contract_in(Controller.CONTRACT.object.in_)

    local ok, result_or_err = pcall(function()
        Contract.assert({ object = object }, Controller.CONTRACT.object.in_)

        local result = objectPipeline.run(object)

        Contract.assert(result, Controller.CONTRACT.object.out)
        Trace.contract_out(
            Controller.CONTRACT.object.out,
            "classify.pipeline.object",
            "caller"
        )

        return result
    end)

    Trace.contract_leave()

    if not ok then
        error(result_or_err, 0)
    end

    return result_or_err
end

return Controller
