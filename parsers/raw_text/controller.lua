-- parsers/raw_text/controller.lua
--
-- Public boundary surface for raw_text.
-- ARC-SCHEMA COMPLIANT:
--   • Contract lives here
--   • Delegates to internal via registry
--   • No logic duplication

local Registry = require("parsers.raw_text.registry")

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local Controller = {}

----------------------------------------------------------------
-- CONTRACT
----------------------------------------------------------------

Controller.CONTRACT = {
    run = {
        in_  = { lines = true },
        out  = { true }, -- array presence-only
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string[]
---@return table records
function Controller.run(lines)

    Trace.contract_enter("parsers.raw_text.controller.run")
    Trace.contract_in(Controller.CONTRACT.run.in_)

    local function execute()

        Contract.assert(
            { lines = lines },
            Controller.CONTRACT.run.in_
        )

        local records = Registry.internal.preprocess.run(lines)

        assert(type(records) == "table", "raw_text must return table[]")

        Trace.contract_out(Controller.CONTRACT.run.out)

        return records
    end

    local ok, result = pcall(execute)

    Trace.contract_leave()

    if not ok then
        error(result, 0)
    end

    return result
end

return Controller
