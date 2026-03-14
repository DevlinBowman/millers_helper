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

    local services =
        app:services()

    local ctor =
        services[service_name]

    assert(type(ctor) == "function",
        "[execution] unknown service: " .. tostring(service_name))

    local service =
        ctor(services)

    assert(type(service) == "table",
        "[execution] service instance required")

    assert(type(service.run) == "function",
        "[execution] service.run() required")

    return service
end


------------------------------------------------------------
-- Execution
------------------------------------------------------------

function Runner.execute(app, ctx)

    ctx.depth =
        (ctx.depth or 0)

    local plan =
        ctx.plan or { ctx.service }

    local final_result

    for _, service_name in ipairs(plan) do

        Reporter.begin(ctx, service_name)

        local service =
            load_service(app, service_name)

        ctx.service = service_name
        ctx.status  = "running"

        local result =
            service:run(ctx)

        ------------------------------------------------
        -- materialization
        ------------------------------------------------

        local patch =
            Projector.materialize(
                service_name,
                ctx.target,
                {
                    ok     = true,
                    result = result
                }
            )

        ------------------------------------------------
        -- mutation
        ------------------------------------------------

        if patch then

            PatchValidator.validate_patch(patch)

            Mutator.apply(
                ctx.target.batch,
                { patch }
            )

            Reporter.mutation(ctx, patch.capability)

        end

        Reporter.finish(ctx)

        final_result = result
    end

    ctx.result = final_result
    ctx.status = "complete"

    return final_result
end

return Runner
