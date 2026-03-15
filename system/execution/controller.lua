-- system/execution/controller.lua

local Resolver = require("system.execution.context_resolver")
local Rules    = require("system.execution.rules")
local Runner   = require("system.execution.runner")

local Executor = {}

------------------------------------------------------------
-- Strategy Resolution
------------------------------------------------------------

local function resolve_strategy(intent_store, opts)
    if type(opts) == "table"
    and type(opts.strategy) == "string"
    and opts.strategy ~= "" then
        return opts.strategy
    end

    if not intent_store or type(intent_store.get) ~= "function" then
        return nil
    end

    local pricing_intent = intent_store:get("pricing") or {}

    if type(pricing_intent) == "table"
    and type(pricing_intent.basis) == "string"
    and pricing_intent.basis ~= "" then
        return pricing_intent.basis
    end

    return nil
end

local function build_rule_context(service_name, target, intent_store, opts, strategy, resolved)
    return {
        service  = service_name,
        target   = target,
        intent   = intent_store,
        opts     = opts,
        strategy = strategy,
        resolved = resolved,

        env = {
            job     = resolved.job_env,
            vendor  = resolved.vendor_env,
            vendors = resolved.vendor_batches,
        }
    }
end

local function build_execution_context(service_name, plan, target, intent_store, opts, strategy, resolved)
    return {
        service  = service_name,
        plan     = plan,
        strategy = strategy,
        target   = target,

        env = {
            job     = resolved.job_env,
            vendor  = resolved.vendor_env,
            vendors = resolved.vendor_batches,
            opts    = opts,
            intent  = intent_store,
        },

        resolved = resolved.resolved,
        steps    = {},
        status   = "pending",
    }
end

------------------------------------------------------------
-- Execution
------------------------------------------------------------

---@param app Surface
---@param service_name string
---@param opts table|nil
---@return any
function Executor.run(app, service_name, opts)
    assert(app ~= nil, "[execution.controller] app required")
    assert(type(service_name) == "string" and service_name ~= "",
        "[execution.controller] service_name required")

    opts = opts or {}

    local data           = app:data()
    local ctx_controller = data:context()
    local intent_store   = data:intent()

    local resolved = Resolver.resolve(app, service_name, opts)
    local target   = resolved.job_target
    local strategy = resolve_strategy(intent_store, opts)

    local rule_ctx = build_rule_context(
        service_name,
        target,
        intent_store,
        opts,
        strategy,
        resolved
    )

    local plan = Rules.plan(service_name, rule_ctx)

    local ctx = build_execution_context(
        service_name,
        plan,
        target,
        intent_store,
        opts,
        strategy,
        resolved
    )

    local created_ctx
    local final_result

    local ok, err = xpcall(function()
        created_ctx = ctx_controller:create("execution", ctx)
        final_result = Runner.execute(app, created_ctx)
    end, debug.traceback)

    ctx_controller:clear("execution")

    if not ok then
        error(err, 0)
    end

    return final_result
end

return Executor
