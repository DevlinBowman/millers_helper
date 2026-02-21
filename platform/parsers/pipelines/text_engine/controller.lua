-- parsers/pipelines/text_engine/controller.lua
--
-- Public control surface for text_engine.
-- Boundary only:
--   • Contract
--   • Trace
--   • Delegation
--   • No internal orchestration

local Pipeline = require("platform.parsers.pipelines.text_engine.pipeline")

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local Controller = {}

Controller.CONTRACT = {
    run = {
        in_ = {
            lines = true,
            opts  = false,
        },
        out = {
            kind = true,
            data = true,
            meta = true,
        },
    },
}

---@param lines string|table
---@param opts table|nil
---@return table result
function Controller.run(lines, opts)

    Trace.contract_enter("parsers.pipelines.text_engine.controller.run")
    Trace.contract_in(Controller.CONTRACT.run.in_)

    Contract.assert(
        { lines = lines, opts = opts },
        Controller.CONTRACT.run.in_
    )

    local ok, result = pcall(function()
        return Pipeline.run(lines, opts)
    end)

    if not ok then
        Trace.contract_leave()
        error(result, 2)
    end

    Contract.assert(result, Controller.CONTRACT.run.out)

    Trace.contract_out(
        Controller.CONTRACT.run.out,
        "parsers.pipelines.text_engine",
        "caller"
    )

    Trace.contract_leave()

    return result
end

return Controller
