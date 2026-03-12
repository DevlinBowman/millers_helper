-- system/execution/runner.lua

local Compatibility  = require("system.compatibility.controller")
local Enrichment     = require("system.enrichment.controller")
local Materializer   = require("system.capability.materializer")
local PatchValidator = require("system.capability.patch_validator")
local Mutator        = require("system.runtime.mutator")

local Runner = {}

local function load_service(app, service_name)
    local services = app:services()
    local ctor = services[service_name]
    assert(type(ctor)=="function","[execution] unknown service: "..tostring(service_name))
    local service = ctor(services)
    assert(type(service)=="table","[execution] service instance required")
    assert(type(service.run)=="function","[execution] service.run() required")
    return service
end

local function resolve_capability_list(missing, force)
    local out, seen = {},{}
    for _,cap in ipairs(missing or {}) do
        if not seen[cap] then seen[cap]=true out[#out+1]=cap end
    end
    if not force then return out end

    local registry = require("system.enrichment.providers")
    for cap,_ in pairs(registry) do
        if not seen[cap] then seen[cap]=true out[#out+1]=cap end
    end
    return out
end

---@param app Surface
---@param ctx table
---@return any
---@param app Surface
---@param ctx table
---@return any
function Runner.execute(app, ctx)

    ------------------------------------------------
    -- execution depth / indentation
    ------------------------------------------------

    ctx.depth = (ctx.depth or 0)
    local indent = string.rep("  ", ctx.depth)

    local function log(msg)
        print(indent .. msg)
    end

    log("[execution] BEGIN")
    log(string.format("[execution] service:  %s", tostring(ctx.service)))

    ------------------------------------------------
    -- service-relevant context
    ------------------------------------------------

    if ctx.service ~= "pricing" then
        local resource = ctx.job_resource_selector or 1
        local batch = (ctx.job_resolved_selector and ctx.job_resolved_selector.batch) or "?"
        log(string.format("[execution] target:   job[%s] -> batch[%s]", tostring(resource), tostring(batch)))

        if ctx.target and ctx.target.boards then
            log(string.format("[execution] boards:   %d", #ctx.target.boards))
        end
    end

    if ctx.service == "pricing" then
        if ctx.env and ctx.env.vendors then
            log(string.format("[execution] vendors:  %d", #ctx.env.vendors))
        end
        if ctx.strategy then
            log(string.format("[execution] strategy: %s", tostring(ctx.strategy)))
        end
    end

    ------------------------------------------------
    -- load service
    ------------------------------------------------

    assert(type(ctx.target)=="table","[execution] target batch required")

    local service = load_service(app, ctx.service)
    ctx.status="service_loaded"

    ------------------------------------------------
    -- compatibility
    ------------------------------------------------

    local compat =
        Compatibility.check(ctx.service, ctx.strategy, ctx.env)

    ctx.compat = compat
    log("[execution] compatibility ok: " .. tostring(compat.ok))

    if compat.missing and #compat.missing > 0 then
        log("[execution] missing capabilities:")
        for _, cap in ipairs(compat.missing) do
            log("   - " .. tostring(cap))
        end
    end

    ------------------------------------------------
    -- enrichment
    ------------------------------------------------

    local opts = ctx.opts or {}
    local force = opts.force == true

    local capabilities =
        resolve_capability_list(compat.missing or {}, force)

    ------------------------------------------------
    -- pricing intent expansion
    ------------------------------------------------

    local intent =
        ctx.env and ctx.env.intent

    local pricing_intent =
        intent and intent.get and intent:get("pricing")

    if pricing_intent then

        local exists = false

        for _, cap in ipairs(capabilities) do
            if cap == "board_prices" then
                exists = true
                break
            end
        end

        if not exists then
            capabilities[#capabilities + 1] = "board_prices"
        end

    end

    ------------------------------------------------

    if force then
        log("[execution] enrichment forced")
    end

    if force or not compat.ok then

        ctx.status="enrichment_resolving"

        local enrichment =
            Enrichment.resolve(app, ctx.job_resource_selector,{
                service  = ctx.service,
                strategy = ctx.strategy,
                missing  = capabilities,
                env      = ctx.env,
                opts     = opts,
                target   = ctx.target,
                depth    = ctx.depth + 1
            })

        ctx.enrichment = enrichment
        log("[execution] enrichment ok: " .. tostring(enrichment.ok))

        if enrichment.unresolved and #enrichment.unresolved > 0 then
            log("[execution] unresolved capabilities:")
            for _, item in ipairs(enrichment.unresolved) do
                log("   - " .. tostring(item.capability) .. " " .. tostring(item.reason))
            end
        end

        if not enrichment.ok then
            ctx.status="failed_enrichment"
            return { ok=false, error="compatibility_mismatch", service=ctx.service, missing=capabilities }
        end

        local patches = {}

        for cap, result in pairs(enrichment.results or {}) do
            local patch = Materializer.materialize(cap, ctx.target, result)
            if patch then
                PatchValidator.validate_patch(patch)
                patches[#patches+1] = patch
            end
        end

        ctx.patches = patches

        if #patches > 0 then
            log("[execution] applying patches: " .. tostring(#patches))
            Mutator.apply(ctx.target, patches)
        else
            log("[execution] no patches produced")
        end
    end

    ------------------------------------------------
    -- service run
    ------------------------------------------------

    ctx.status="running"

    local result = service:run(ctx)

    ------------------------------------------------
    -- materialize service capability result
    ------------------------------------------------

    local service_capability_map = {
        pricing = "board_prices"
    }

    local capability = service_capability_map[ctx.service]

    if capability and type(result) == "table" then
        local patch =
            Materializer.materialize(
                capability,
                ctx.target,
                {
                    ok = true,
                    capability = capability,
                    result = result
                }
            )

        if patch then
            PatchValidator.validate_patch(patch)
            Mutator.apply(ctx.target, { patch })
        end
    end

    ctx.result = result
    ctx.status = "complete"

    log("[execution] END")

    return result
end

return Runner
