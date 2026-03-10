-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller
local Contracts     = require("core.domain.compare.contracts")

local Compatibility = require("system.compatibility.controller")
local Enrichment    = require("system.enrichment.controller")

---@class AppCompareService
---@field private __app Surface
local Compare = {}
Compare.__index = Compare

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppCompareService
function Compare.new(app)
    return setmetatable({
        __app = app
    }, Compare)
end

------------------------------------------------------------
-- Internal: Load user batch
------------------------------------------------------------

---@param selector integer|string|nil
---@return table
function Compare:_load_user_batch(selector)
    local runtime = self.__app:data():runtime()
    local user_runtime = runtime:require("user", "job", selector)

    assert(type(user_runtime) == "table",
        "[compare.service] runtime user job envelope missing")

    assert(type(user_runtime.batch) == "function",
        "[compare.service] runtime job missing batch()")

    local batch = user_runtime:batch()

    assert(type(batch) == "table",
        "[compare.service] runtime job batch missing")

    assert(type(batch.boards) == "table",
        "[compare.service] runtime job batch missing boards")

    return batch
end

------------------------------------------------------------
-- Internal: Load vendor batches
------------------------------------------------------------

---@return table
function Compare:_load_vendor_batches()
    local data = self.__app:data()
    local runtime = data:runtime()

    local vendor_descriptors = data:resources():get("system", "vendor") or {}
    local vendor_batches = {}

    for index = 1, #vendor_descriptors do
        local vendor_runtime = runtime:require("system", "vendor", index)

        assert(type(vendor_runtime) == "table",
            "[compare.service] runtime system vendor envelope missing at index " .. tostring(index))

        assert(type(vendor_runtime.batch) == "function",
            "[compare.service] runtime vendor missing batch() at index " .. tostring(index))

        local batch = vendor_runtime:batch()

        assert(type(batch) == "table",
            "[compare.service] runtime vendor batch missing at index " .. tostring(index))

        vendor_batches[#vendor_batches + 1] = batch
    end

    return vendor_batches
end

------------------------------------------------------------
-- Internal: Build compare environment
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Compare:_build_env(selector, opts)
    local user_batch = self:_load_user_batch(selector)
    local vendor_batches = self:_load_vendor_batches()

    local env = Contracts.build_env(user_batch, vendor_batches, opts or {})

    assert(type(env) == "table",
        "[compare.service] contracts.build_env() must return table")

    return env
end

------------------------------------------------------------
-- Internal: Compatibility check
------------------------------------------------------------

---@param env table
---@return table
function Compare:_check_compatibility(env)
    return Compatibility.check("compare", "default", env)
end

------------------------------------------------------------
-- Internal: Resolve missing capabilities
------------------------------------------------------------

---@param selector integer|string|nil
---@param env table
---@param opts table
---@param compat table
---@return table
function Compare:_resolve_missing(selector, env, opts, compat)
    return Enrichment.resolve(self.__app, selector, {
        service  = "compare",
        strategy = "default",
        missing  = compat.missing or {},
        env      = env,
        opts     = opts or {},
        target   = env.job,
    })
end

------------------------------------------------------------
-- Internal: Domain execution
------------------------------------------------------------

---@param env table
---@param opts table|nil
---@return CompareResult
function Compare:_run_domain(env, opts)
    return CompareDomain.run_strict(
        env.job,
        env.vendors,
        opts
    )
end

------------------------------------------------------------
-- Public: Run Compare
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return CompareResult|table
function Compare:run(selector, opts)
    opts = opts or {}

    --------------------------------------------------------
    -- 1. Build current compare context from system runtime
    --------------------------------------------------------

    local env = self:_build_env(selector, opts)

    --------------------------------------------------------
    -- 2. Validate compatibility once at service boundary
    --------------------------------------------------------

    local compatibility_result = self:_check_compatibility(env)

    --------------------------------------------------------
    -- 3. If missing capabilities exist, let system enrichment
    --    resolve them and mutate runtime through system-owned
    --    mutation authority
    --------------------------------------------------------

    if not compatibility_result.ok then
        local enrichment_result =
            self:_resolve_missing(selector, env, opts, compatibility_result)

        if not enrichment_result.ok then
            return {
                ok         = false,
                error      = "compatibility_mismatch",
                service    = "compare",
                strategy   = "default",
                missing    = compatibility_result.missing or {},
                enrichment = enrichment_result,
            }
        end

        ----------------------------------------------------
        -- 4. Rebuild env from runtime after enrichment
        ----------------------------------------------------

        env = self:_build_env(selector, opts)
        compatibility_result = self:_check_compatibility(env)

        if not compatibility_result.ok then
            return {
                ok       = false,
                error    = "compatibility_mismatch_after_enrichment",
                service  = "compare",
                strategy = "default",
                missing  = compatibility_result.missing or {},
            }
        end
    end

    --------------------------------------------------------
    -- 5. Run pure domain compare once context is compatible
    --------------------------------------------------------

    return self:_run_domain(env, opts)
end

return Compare
