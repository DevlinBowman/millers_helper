-- system/execution/controller.lua

local Resolver = require("system.execution.context_resolver")
local Rules    = require("system.execution.rules")
local Runner   = require("system.execution.runner")

local Executor = {}

------------------------------------------------------------
-- Strategy Resolution
------------------------------------------------------------

local function resolve_strategy(intent, opts)

    if type(opts.strategy) == "string"
    and opts.strategy ~= "" then
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
-- Execution
------------------------------------------------------------

---@param app Surface
---@param service_name string
---@param opts table|nil
---@return any
function Executor.run(app, service_name, opts)

    opts = opts or {}

    local data           = app:data()
    local ctx_controller = data:context()
    local intent         = data:intent()

    ------------------------------------------------
    -- Resolve runtime context
    ------------------------------------------------

    local resolved =
        Resolver.resolve(app, service_name, opts)

    local job_env        = resolved.job_env
    local vendor_env     = resolved.vendor_env
    local target         = resolved.job_target
    local vendor_batches = resolved.vendor_batches

    ------------------------------------------------
    -- Strategy
    ------------------------------------------------

    local strategy =
        resolve_strategy(intent, opts)

    ------------------------------------------------
    -- Rule Context
    ------------------------------------------------

    local rule_ctx = {
        service  = service_name,
        target   = target,
        intent   = intent,
        opts     = opts,
        strategy = strategy,

        env = {
            job     = job_env,
            vendor  = vendor_env,
            vendors = vendor_batches
        }
    }

    ------------------------------------------------
    -- Execution Plan
    ------------------------------------------------

    local plan =
        Rules.plan(service_name, rule_ctx)

    ------------------------------------------------
    -- Execution Context
    ------------------------------------------------

    local ctx = {

        service  = service_name,
        plan     = plan,
        strategy = strategy,

        target = target,

        env = {
            job     = job_env,
            vendor  = vendor_env,
            vendors = vendor_batches,
            opts    = opts,
            intent  = intent
        },

        resolved = resolved.resolved
    }

    ------------------------------------------------
    -- Context lifecycle
    ------------------------------------------------

    ctx =
        ctx_controller:create("execution", ctx)

    local result =
        Runner.execute(app, ctx)

    ctx_controller:clear("execution")

    return result
end

return Executor
