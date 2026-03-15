-- system/execution/runner.lua

local Projector      = require("system.execution.projection.projector")
local PatchValidator = require("system.execution.mutation.patch_validator")
local Mutator        = require("system.execution.mutation.mutator")
local Reporter       = require("system.execution.report")

local Runner = {}

------------------------------------------------------------
-- Service Loader
------------------------------------------------------------

local function load_service(app, service_name)
    local services = app:services()
    local ctor     = services[service_name]

    assert(type(ctor) == "function",
        "[execution.runner] unknown service: " .. tostring(service_name))

    local service = ctor(services)

    assert(type(service) == "table",
        "[execution.runner] service instance required")

    assert(type(service.run) == "function",
        "[execution.runner] service.run() required")

    return service
end

local function materialize_result(service_name, ctx, result)
    local patch = Projector.materialize(
        service_name,
        ctx.target,
        {
            ok     = true,
            result = result,
        }
    )

    if not patch then
        return nil
    end

    PatchValidator.validate_patch(patch)

    Mutator.apply(ctx.target.batch, { patch })
    Reporter.mutation(ctx, patch.capability)

    return patch
end

local function execute_service(app, ctx, service_name)
    local service = load_service(app, service_name)

    ctx.service = service_name
    ctx.status  = "running"

    Reporter.begin(ctx, service_name)

    local ok, result_or_err = xpcall(function()
        return service:run(ctx)
    end, debug.traceback)

    if not ok then
        ctx.status = "failed"
        Reporter.finish(ctx, service_name, "failed")
        error(result_or_err, 0)
    end

    local result = result_or_err
    local patch  = materialize_result(service_name, ctx, result)

    ctx.steps[#ctx.steps + 1] = {
        service = service_name,
        result  = result,
        patch   = patch,
    }

    ctx.status = "complete"
    Reporter.finish(ctx, service_name, "complete")

    return result
end

------------------------------------------------------------
-- Execution
------------------------------------------------------------

function Runner.execute(app, ctx)
    assert(app ~= nil, "[execution.runner] app required")
    assert(type(ctx) == "table", "[execution.runner] ctx required")

    ctx.depth  = ctx.depth or 0
    ctx.steps  = ctx.steps or {}
    ctx.status = "running"

    local plan = ctx.plan or { ctx.service }
    local final_result = nil

    for _, service_name in ipairs(plan) do
        final_result = execute_service(app, ctx, service_name)
    end

    ctx.result = final_result
    ctx.status = "complete"

    return final_result
end

return Runner
