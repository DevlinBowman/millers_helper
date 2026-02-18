-- core/domain/runtime/controller.lua

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local LoadPipeline = require("core.domain.runtime.pipelines.load")

local Controller = {}

Controller.CONTRACT = {
    load = {
        in_  = { input = true },
        out  = { batches = true },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Controller.load(input)
    Trace.contract_enter("core.domain.runtime.controller.load")
    Trace.contract_in({ input = input })

    Contract.assert(
        { input = input },
        Controller.CONTRACT.load.in_
    )

    local batches = LoadPipeline.run(input)

    local out = { batches = batches }

    Contract.assert(out, Controller.CONTRACT.load.out)

    Trace.contract_out(out, "runtime.controller.load", "caller")
    Trace.contract_leave()

    return out
end

return Controller
