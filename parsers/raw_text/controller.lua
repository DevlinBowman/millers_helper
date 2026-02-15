-- parsers/raw_text/controller.lua
--
-- Public boundary surface for raw_text.
-- ARC-SCHEMA COMPLIANT:
--   • Contract lives here
--   • Delegates to internal via registry
--   • No logic duplication

local Registry = require("parsers.raw_text.registry")

local Controller = {}

----------------------------------------------------------------
-- CONTRACT
----------------------------------------------------------------

Controller.CONTRACT = {
    run = {
        in_  = { lines = "table" },
        out  = { data = "table" },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string[]
---@return table result
function Controller.run(lines)
    assert(type(lines) == "table", "raw_text.controller.run(): lines must be table")
    return Registry.internal.preprocess.run(lines)
end

return Controller
