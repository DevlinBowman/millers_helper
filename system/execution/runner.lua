-- system/execution/runner.lua

local Materializer   = require("system.pipeline.capability.materializer")
local PatchValidator = require("system.pipeline.capability.patch_validator")
local Mutator        = require("system.pipeline.runtime.mutator")

local Runner = {}

------------------------------------------------------------
-- Service Loader
------------------------------------------------------------

local function load_service(app, service_name)

    local services = app:services()

    local ctor = services[service_name]

    assert(type(ctor) == "function",
        "[execution] unknown service: " .. tostring(service_name))

    local service = ctor(services)

    assert(type(service) == "table",
        "[execution] service instance required")

    assert(type(service.run) == "function",
        "[execution] service.run() required")

    return service
end


------------------------------------------------------------
-- Execution
------------------------------------------------------------

---@param app Surface
---@param ctx table
---@return any
function Runner.execute(app, ctx)

    ctx.depth = (ctx.depth or 0)

    local indent =
        string.rep("  ", ctx.depth)

    local function log(msg)
        print(indent .. msg)
    end

    local plan =
        ctx.plan or { ctx.service }

    local final_result

    for _, service_name in ipairs(plan) do

        log("[execution] BEGIN")
        log(string.format(
            "[execution] service:  %s",
            tostring(service_name)
        ))

        ------------------------------------------------
        -- Context logging
        ------------------------------------------------

        if service_name ~= "pricing" then

            local batch =
                (ctx.resolved
                and ctx.resolved.job
                and ctx.resolved.job.batch)
                or "?"

            log(string.format(
                "[execution] target:   job -> batch[%s]",
                tostring(batch)
            ))

            if ctx.target and ctx.target.boards then
                log(string.format(
                    "[execution] boards:   %d",
                    #ctx.target.boards
                ))
            end

        else

            if ctx.env and ctx.env.vendors then

                local selector =
                    ctx.resolved
                    and ctx.resolved.vendors

                if selector
                and selector.batch
                and selector.batch ~= "all" then

                    log(string.format(
                        "[execution] vendor batch: %s",
                        tostring(selector.batch)
                    ))

                else

                    log(string.format(
                        "[execution] vendors: %d (all)",
                        #ctx.env.vendors
                    ))

                end
            end

            if ctx.strategy then
                log(string.format(
                    "[execution] strategy: %s",
                    tostring(ctx.strategy)
                ))
            end
        end

        ------------------------------------------------
        -- Load service
        ------------------------------------------------

        local service =
            load_service(app, service_name)

        ctx.service = service_name
        ctx.status  = "running"

        local result =
            service:run(ctx)

        ------------------------------------------------
        -- Capability materialization
        ------------------------------------------------

        if service_name == "pricing"
        and type(result) == "table" then

            local patch =
                Materializer.materialize(
                    "board_prices",
                    ctx.target,
                    {
                        ok         = true,
                        capability = "board_prices",
                        result     = result
                    }
                )

            if patch then

                PatchValidator.validate_patch(patch)

                Mutator.apply(
                    ctx.target.batch,
                    { patch }
                )

                log("[execution] pricing mutation applied")

            end
        end

        log("[execution] END")

        final_result = result
    end

    ctx.result = final_result
    ctx.status = "complete"

    return final_result
end

return Runner
