-- system/enrichment/controller.lua
--
-- System orchestration layer responsible for resolving
-- missing capabilities required by services.

local Mutator          = require("system.runtime.mutator")
local BuiltinProviders = require("system.enrichment.providers")
local Materializer     = require("system.capability.materializer")
local PatchValidator   = require("system.capability.patch_validator")

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
    local target = request.target

    assert(type(env) == "table", "[enrichment] request.env required")
    assert(type(target) == "table", "[enrichment] request.target required")

    local patches = {}
    local unresolved = {}
    local results = {}

    for _, capability in ipairs(missing) do
        local provider = providers[capability]

        if not provider then
            unresolved[#unresolved + 1] = {
                capability = capability,
                reason = "no_provider"
            }
        else
            local provider_result = provider(app, selector, env)

            if not provider_result or provider_result.ok ~= true then
                unresolved[#unresolved + 1] = {
                    capability = capability,
                    reason = "provider_failed"
                }
            else
                results[capability] = provider_result

                local patch = Materializer.materialize(
                    capability,
                    target,
                    provider_result
                )

                if patch then
                    PatchValidator.validate_patch(patch)
                    patches[#patches + 1] = patch
                end
            end
        end
    end

    if #patches > 0 then
        Mutator.apply(target, patches)
    end

    return {
        ok = (#unresolved == 0),
        unresolved = unresolved,
        patches = patches,
        results = results,
    }
end

return Enrichment
