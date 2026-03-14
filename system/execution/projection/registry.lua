local Registry = {}

Registry.projectors = {
    pricing = "system.execution.projection.pricing",
}

---@param service string
---@return string|nil
function Registry.get(service)
    assert(type(service) == "string" and service ~= "",
        "[execution.projection.registry] service required")

    return Registry.projectors[service]
end

---@param service string
---@param module_path string
function Registry.register(service, module_path)

    assert(type(service) == "string" and service ~= "",
        "[execution.projection.registry] service required")

    assert(type(module_path) == "string" and module_path ~= "",
        "[execution.projection.registry] module_path required")

    Registry.projectors[service] = module_path
end

return Registry
