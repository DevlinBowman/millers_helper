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
function Runner.execute(app, ctx)

    print("\n[execution] BEGIN")
    print("[execution] service:",ctx.service)
    print("[execution] job_resource_selector:",tostring(ctx.job_resource_selector))
    print("[execution] job_batch_selector:",tostring(ctx.job_batch_selector))
    print("[execution] vendor_selector:",tostring(ctx.vendor_selector))
    print("[execution] strategy:",tostring(ctx.strategy))

    assert(type(ctx.target)=="table","[execution] target batch required")

    local service = load_service(app, ctx.service)
    ctx.status="service_loaded"

    local compat =
        Compatibility.check(ctx.service, ctx.strategy, ctx.env)

    ctx.compat=compat
    print("[execution] compatibility ok:",compat.ok)

    if compat.missing and #compat.missing>0 then
        print("[execution] missing capabilities:")
        for _,cap in ipairs(compat.missing) do
            print("   -",cap)
        end
    end

    local opts = ctx.opts or {}
    local force = opts.force==true
    local capabilities = resolve_capability_list(compat.missing or {}, force)

    if force then print("[execution] enrichment forced") end

    if force or not compat.ok then

        ctx.status="enrichment_resolving"

        local enrichment =
            Enrichment.resolve(app, ctx.job_resource_selector,{
                service=ctx.service,
                strategy=ctx.strategy,
                missing=capabilities,
                env=ctx.env,
                opts=opts,
                target=ctx.target
            })

        ctx.enrichment=enrichment
        print("[execution] enrichment ok:",enrichment.ok)

        if enrichment.unresolved and #enrichment.unresolved>0 then
            print("[execution] unresolved capabilities:")
            for _,item in ipairs(enrichment.unresolved) do
                print("   -",tostring(item.capability),tostring(item.reason))
            end
        end

        if not enrichment.ok then
            ctx.status="failed_enrichment"
            return { ok=false, error="compatibility_mismatch", service=ctx.service, missing=capabilities }
        end

        local patches={}

        for cap,result in pairs(enrichment.results or {}) do
            local patch = Materializer.materialize(cap, ctx.target, result)
            if patch then
                PatchValidator.validate_patch(patch)
                patches[#patches+1]=patch
            end
        end

        ctx.patches=patches

        if #patches>0 then
            print("[execution] applying patches:",#patches)
            Mutator.apply(ctx.target,patches)
        else
            print("[execution] no patches produced")
        end
    end

    ctx.status="running"

    local result = service:run(ctx)

    ctx.result=result
    ctx.status="complete"

    print("[execution] END")

    return result
end

return Runner
