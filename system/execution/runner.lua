-- system/execution/runner.lua

local Compatibility  = require("system.pipeline.compatibility.controller")
local Enrichment     = require("system.pipeline.enrichment.controller")
local Materializer   = require("system.pipeline.capability.materializer")
local PatchValidator = require("system.pipeline.capability.patch_validator")
local Mutator        = require("system.pipeline.runtime.mutator")

local Runner         = {}

local function load_service(app, service_name)
    local services = app:services()
    local ctor = services[service_name]
    assert(type(ctor) == "function", "[execution] unknown service: " .. tostring(service_name))
    local service = ctor(services)
    assert(type(service) == "table", "[execution] service instance required")
    assert(type(service.run) == "function", "[execution] service.run() required")
    return service
end

local function resolve_capability_list(missing, force)
    local out, seen = {}, {}
    for _, cap in ipairs(missing or {}) do
        if not seen[cap] then
            seen[cap] = true
            out[#out + 1] = cap
        end
    end
    if not force then return out end

    local registry = require("system.pipeline.enrichment.providers")
    for cap, _ in pairs(registry) do
        if not seen[cap] then
            seen[cap] = true
            out[#out + 1] = cap
        end
    end
    return out
end


---@param app Surface
---@param ctx table
---@return any
function Runner.execute(app, ctx)
    ctx.depth = (ctx.depth or 0)
    local indent = string.rep("  ", ctx.depth)

    local function log(msg)
        print(indent .. msg)
    end

    local plan = ctx.plan or { ctx.service }

    local final_result

    for _, service_name in ipairs(plan) do
        log("[execution] BEGIN")
        log(string.format("[execution] service:  %s", tostring(service_name)))

        ------------------------------------------------
        -- Context info
        ------------------------------------------------

        if service_name ~= "pricing" then
            local resource = ctx.job_resource_selector or 1
            local batch    = (ctx.job_resolved_selector and ctx.job_resolved_selector.batch) or "?"

            log(string.format(
                "[execution] target:   job[%s] -> batch[%s]",
                tostring(resource),
                tostring(batch)
            ))

            if ctx.target and ctx.target.boards then
                log(string.format("[execution] boards:   %d", #ctx.target.boards))
            end
        else
            if ctx.env and ctx.env.vendors then
                log(string.format("[execution] vendors:  %d", #ctx.env.vendors))
            end

            if ctx.strategy then
                log(string.format("[execution] strategy: %s", tostring(ctx.strategy)))
            end
        end

        ------------------------------------------------
        -- Load service
        ------------------------------------------------

        local service = load_service(app, service_name)

        -- update execution context for this step
        ctx.service   = service_name
        ctx.status    = "running"

        local result  = service:run(ctx)

        ------------------------------------------------
        -- Capability materialization
        ------------------------------------------------

        if service_name == "pricing" and type(result) == "table" then
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
                Mutator.apply(ctx.target, { patch })
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
