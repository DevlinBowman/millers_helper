-- system/pipeline/capability/materializer.lua

local Registry = require("system.pipeline.capability.registry")

local Materializer = {}

---@param capability string
---@param target table
---@param service_result table
---@return table|nil
function Materializer.materialize(capability, target, service_result)
    assert(type(capability) == "string" and capability ~= "",
        "[capability.materializer] capability required")
    assert(type(target) == "table",
        "[capability.materializer] target required")
    assert(type(service_result) == "table",
        "[capability.materializer] service_result required")

    local module_path = Registry.get_materializer(capability)
    if not module_path then
        return nil
    end

    local materializer = require(module_path)

    assert(type(materializer) == "table",
        "[capability.materializer] materializer module must return table")

    assert(type(materializer.materialize) == "function",
        "[capability.materializer] materializer.materialize() required")

    return materializer.materialize(target, service_result, capability)
end

return Materializer
