-- system/enrichment/controller.lua
--
-- System orchestration layer responsible for resolving
-- missing capabilities required by services.

local Mutator = require("system.runtime.mutator")
local BuiltinProviders = require("system.enrichment.providers")

local Enrichment = {}

------------------------------------------------------------
-- Provider Registry
------------------------------------------------------------

local providers = {}

---@param capability string
---@param fn function
function Enrichment.register(capability, fn)
    assert(type(capability) == "string" and capability ~= "",
        "[enrichment] capability required")
    assert(type(fn) == "function",
        "[enrichment] provider function required")

    providers[capability] = fn
end

local function register_builtin_providers()
    for capability, fn in pairs(BuiltinProviders or {}) do
        Enrichment.register(capability, fn)
    end
end

register_builtin_providers()

------------------------------------------------------------
-- Resolve Missing Capabilities
------------------------------------------------------------

---@param app Surface
---@param selector integer|string|nil
---@param request table
---@return table
function Enrichment.resolve(app, selector, request)

    assert(type(app) == "table", "[enrichment] app required")
    assert(type(request) == "table", "[enrichment] request required")

    local missing = request.missing or {}
    local env = request.env

    assert(type(env) == "table", "[enrichment] request.env required")

    local patches = {}
    local unresolved = {}

    for _, capability in ipairs(missing) do
        local provider = providers[capability]

        if not provider then
            unresolved[#unresolved + 1] = {
                capability = capability,
                reason = "no_provider"
            }
        else
            local result = provider(app, selector, env)

            if result and result.patch then
                patches[#patches + 1] = result.patch
            elseif result and result.ok then
                -- capability satisfied without mutation
            else
                unresolved[#unresolved + 1] = {
                    capability = capability,
                    reason = "provider_failed"
                }
            end
        end
    end

    --------------------------------------------------------
    -- apply patches
    --------------------------------------------------------

    if #patches > 0 then
        Mutator.apply(env.source or env.job or env, patches)
    end

    return {
        ok = (#unresolved == 0),
        unresolved = unresolved,
        patches = patches
    }
end

return Enrichment
