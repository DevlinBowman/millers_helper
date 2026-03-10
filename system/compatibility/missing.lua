-- system/compatibility/missing.lua

local Validator = require("system.compatibility.validator")

local Missing = {}

---@param contract table
---@param strategy string|nil
---@param env table
---@return table
function Missing.detect(contract, strategy, env)
    local result = Validator.validate(contract, strategy, env)
    return result.missing or {}
end

return Missing
