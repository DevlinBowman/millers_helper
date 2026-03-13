-- system/pipeline/capability/registry.lua

local Registry = {}

Registry.materializers = {
    board_prices = "system.pipeline.capability.materializers.pricing",
}

---@param capability string
---@return string|nil
function Registry.get_materializer(capability)
    assert(type(capability) == "string" and capability ~= "",
        "[capability.registry] capability required")
    return Registry.materializers[capability]
end

---@param capability string
---@param module_path string
function Registry.register(capability, module_path)
    assert(type(capability) == "string" and capability ~= "",
        "[capability.registry] capability required")
    assert(type(module_path) == "string" and module_path ~= "",
        "[capability.registry] module_path required")

    Registry.materializers[capability] = module_path
end

return Registry
