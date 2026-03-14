local Selectors    = require("system.execution.context.selectors")
local Resolver     = require("system.execution.context.resolver")
local RuleRegistry = require("system.execution.rules.registry")

local ContextCompiler = {}

------------------------------------------------------------
-- Strategy Resolution
------------------------------------------------------------

local function resolve_strategy(intent, opts)

    if type(opts.strategy) == "string" and opts.strategy ~= "" then
        return opts.strategy
    end

    local pricing_intent =
        intent:get("pricing") or {}

    if type(pricing_intent) == "table"
    and type(pricing_intent.basis) == "string"
    and pricing_intent.basis ~= "" then
        return pricing_intent.basis
    end

    return nil
end

------------------------------------------------------------
-- Build Execution Context
------------------------------------------------------------

---@param app Surface
---@param service_name string
---@param opts table|nil
---@return table
function ContextCompiler.build(app, service_name, opts)

    opts = opts or {}

    local data    = app:data()
    local runtime = data:runtime()
    local slots   = data:slots()
    local intent  = data:intent()

    ------------------------------------------------
    -- selectors
    ------------------------------------------------

    local job_selector =
        Selectors.job(service_name, opts, slots)

    local vendor_selector =
        Selectors.vendor(service_name, opts, slots)

    ------------------------------------------------
    -- runtime resolution
    ------------------------------------------------

    local job_env, job_target, job_scope, job_resolved =
        Resolver.resolve_job(runtime, nil, job_selector)

    local vendor_env, vendor_batches, vendor_resolved =
        Resolver.resolve_vendors(runtime, vendor_selector)

    ------------------------------------------------
    -- strategy
    ------------------------------------------------

    local strategy =
        resolve_strategy(intent, opts)

    ------------------------------------------------
    -- rule context
    ------------------------------------------------

    local rule_ctx = {
        service = service_name,
        target  = job_target,
        scope   = job_scope,

        env = {
            job     = job_env,
            vendor  = vendor_env,
            vendors = vendor_batches,
        },

        intent   = intent,
        opts     = opts,
        strategy = strategy,
    }

    ------------------------------------------------
    -- execution plan
    ------------------------------------------------

    local rule =
        RuleRegistry.resolve(service_name)

    local plan =
        (type(rule.plan) == "function")
        and rule.plan(rule_ctx)
        or { service_name }

    ------------------------------------------------
    -- final execution context
    ------------------------------------------------

    return {
        service  = service_name,
        plan     = plan,
        strategy = strategy,

        target = job_target,
        scope  = job_scope,

        env = {
            job     = job_env,
            vendor  = vendor_env,
            vendors = vendor_batches,

            opts   = opts,
            intent = intent,
        },

        resolved = {
            job     = job_resolved,
            vendors = vendor_resolved,
        }
    }
end

return ContextCompiler
