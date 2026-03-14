local Registry = require("system.execution.projection.registry")

local Projector = {}

---@param service string
---@param target table
---@param service_result table
---@return table|nil
function Projector.materialize(service, target, service_result)

    assert(type(service) == "string" and service ~= "",
        "[execution.projector] service required")

    assert(type(target) == "table",
        "[execution.projector] target required")

    assert(type(service_result) == "table",
        "[execution.projector] service_result required")

    local module_path =
        Registry.get(service)

    if not module_path then
        return nil
    end

    local projector =
        require(module_path)

    assert(type(projector) == "table",
        "[execution.projector] projector module must return table")

    assert(type(projector.materialize) == "function",
        "[execution.projector] projector.materialize() required")

    return projector.materialize(target, service_result)
end

return Projector
