-- system/enrichment/controller.lua
--
-- Capability resolution layer.
--
-- Owns:
--   • locating capability providers
--   • executing providers
--   • returning provider results
--
-- Does NOT:
--   • materialize patches
--   • validate patches
--   • mutate runtime

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
    local env     = request.env

    assert(type(env) == "table", "[enrichment] request.env required")

    local results = {}
    local unresolved = {}

    for _, capability in ipairs(missing) do

        local provider = providers[capability]

        if not provider then

            unresolved[#unresolved + 1] = {
                capability = capability,
                reason     = "no_provider"
            }

        else

            local ok, provider_result =
                pcall(provider, app, selector, env)

            if not ok then

                unresolved[#unresolved + 1] = {
                    capability = capability,
                    reason     = "provider_error"
                }

            elseif not provider_result
                or provider_result.ok ~= true then

                unresolved[#unresolved + 1] = {
                    capability = capability,
                    reason     = "provider_failed"
                }

            else

                results[capability] = provider_result
            end
        end
    end

    return {
        ok         = (#unresolved == 0),
        unresolved = unresolved,
        results    = results
    }
end

return Enrichment
