-- system/pipeline/compatibility/controller.lua

local Loader    = require("system.pipeline.compatibility.loader")
local Validator = require("system.pipeline.compatibility.validator")

local Compatibility = {}

---@param service string
---@param strategy string|nil
---@param env table
---@return table
function Compatibility.check(service, strategy, env)
    local contract = Loader.load(service)
    return Validator.validate(contract, strategy, env)
end

---@param service string
---@return table
function Compatibility.contract(service)
    return Loader.load(service)
end

return Compatibility
