-- system/pipeline/compatibility/loader.lua

local Loader = {}

---@param service string
---@return table
function Loader.load(service)
    assert(type(service) == "string" and service ~= "",
        "[compatibility.loader] service required")

    local path = "core.domain." .. service .. ".contracts"

    local ok, contract = pcall(require, path)

    if not ok then
        error("[compatibility.loader] contract not found for service: " .. service, 2)
    end

    return contract
end

return Loader
