-- system/app/services/enrichment_runner.lua

local Enrichment = require("system.pipeline.enrichment.controller")

local Runner = {}

---@param app Surface
---@param selector integer|string|nil
---@param request table
---@return table
function Runner.run(app, selector, request)
    return Enrichment.resolve(app, selector, request)
end

return Runner
