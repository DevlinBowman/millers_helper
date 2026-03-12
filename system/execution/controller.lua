-- system/execution/controller.lua
-- function: Executor.run

local Compatibility  = require("system.compatibility.controller")
local Enrichment     = require("system.enrichment.controller")
local Materializer   = require("system.capability.materializer")
local PatchValidator = require("system.capability.patch_validator")
local Mutator        = require("system.runtime.mutator")

local Executor       = {}

local function load_service(app, service_name)
    local services = app:services()

    local constructor =
        services[service_name]

    assert(type(constructor) == "function",
        "[execution] unknown service: " .. tostring(service_name))

    local service =
        constructor(services)

    assert(type(service) == "table",
        "[execution] service instance required")

    return service
end

local function build_env(service, selector, opts)
    assert(type(service._build_env) == "function",
        "[execution] service._build_env() required")

    local built =
        service:_build_env(selector, opts or {})

    assert(type(built) == "table",
        "[execution] service._build_env() must return table")

    return built
end

function Executor.run(app, service_name, opts)
    opts = opts or {}

    local selector = nil

    print("\n[execution] BEGIN")
    print("[execution] service:", service_name)
    print("[execution] selector:", selector)

    ------------------------------------------------
    -- load service
    ------------------------------------------------

    local service =
        load_service(app, service_name)

    print("[execution] service loaded")

    ------------------------------------------------
    -- build env
    ------------------------------------------------

    local built =
        build_env(service, selector, opts)

    print("[execution] env built")

    local strategy =
        built.strategy or "default"

    local env =
        built.env or built

    local target =
        built.target

    print("[execution] strategy:", strategy)
    print("[execution] target present:", type(target) == "table")

    assert(type(env) == "table",
        "[execution] env required")

    assert(type(target) == "table",
        "[execution] target required")

    ------------------------------------------------
    -- compatibility check
    ------------------------------------------------

    print("[execution] running compatibility check")

    local compat =
        Compatibility.check(
            service_name,
            strategy,
            env
        )

    print("[execution] compatibility ok:", compat.ok)

    if compat.missing and #compat.missing > 0 then
        print("[execution] missing capabilities:")
        for _, cap in ipairs(compat.missing) do
            print("   -", cap)
        end
    end

    ------------------------------------------------
    -- enrichment resolution
    ------------------------------------------------

    local force =
        opts and opts.force == true

    local missing_caps =
        compat.missing or {}

    if not compat.ok or force then

        if force then
            print("[execution] enrichment forced")
        else
            print("[execution] enrichment required")
        end

        ------------------------------------------------
        -- determine capabilities to resolve
        ------------------------------------------------

        if force then
            missing_caps = {}

            local provider_registry =
                require("system.enrichment.providers")

            for capability, _ in pairs(provider_registry) do
                missing_caps[#missing_caps + 1] = capability
            end
        end

        local enrichment =
            Enrichment.resolve(app, selector, {
                service  = service_name,
                strategy = strategy,
                missing  = missing_caps,
                env      = env,
                opts     = opts,
                target   = target,
            })

        print("[execution] enrichment result ok:", enrichment.ok)

        if enrichment.unresolved and #enrichment.unresolved > 0 then
            print("[execution] unresolved capabilities:")
            for _, u in ipairs(enrichment.unresolved) do
                print("   -", u.capability, u.reason)
            end
        end

        if not enrichment.ok then
            print("[execution] enrichment FAILED")
            return {
                ok         = false,
                error      = "compatibility_mismatch",
                service    = service_name,
                strategy   = strategy,
                missing    = missing_caps,
                enrichment = enrichment,
            }
        end

        ------------------------------------------------
        -- execution owns materialization + patch validation
        ------------------------------------------------

        local patches = {}

        for _, capability in ipairs(missing_caps) do
            local provider_result =
                enrichment.results and enrichment.results[capability]

            if provider_result then
                local patch =
                    Materializer.materialize(
                        capability,
                        target,
                        provider_result
                    )

                if patch then
                    PatchValidator.validate_patch(patch)
                    patches[#patches + 1] = patch
                else
                    print("[execution] materializer produced NO patch:", capability)
                end
            else
                print("[execution] no provider result to materialize:", capability)
            end
        end

        ------------------------------------------------
        -- execution owns mutation
        ------------------------------------------------

        if #patches > 0 then
            print("[execution] applying patches:", #patches)

            for i, patch in ipairs(patches) do
                print("[execution] patch", i)
                for k, v in pairs(patch) do
                    print("   ", k, type(v))
                end
            end

            Mutator.apply(target, patches)
        else
            print("[execution] NO patches produced from enrichment results")
        end

        ------------------------------------------------
        -- rebuild env after mutation
        ------------------------------------------------

        print("[execution] rebuilding env after mutation")

        built =
            build_env(service, selector, opts)

        strategy =
            built.strategy or "default"

        env =
            built.env or built

        target =
            built.target

        print("[execution] env rebuilt")

        compat =
            Compatibility.check(
                service_name,
                strategy,
                env
            )

        print("[execution] compatibility after enrichment:", compat.ok)

        if not compat.ok then
            print("[execution] compatibility STILL failing")

            return {
                ok       = false,
                error    = "compatibility_mismatch_after_enrichment",
                service  = service_name,
                strategy = strategy,
                missing  = compat.missing or {},
            }
        end
    end

    ------------------------------------------------
    -- domain execution
    ------------------------------------------------

    local result

    if type(service.run_with_env) == "function" then
        result = service:run_with_env(built, opts)
    else
        result = service:run(selector, opts)
    end

    print("[execution] END")

    if type(result) == "table" then
        return result
    end

    return {
        ok = true,
        result = result
    }
end

return Executor
