-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller
local Contracts     = require("core.domain.compare.contracts")

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

    local envelope =
        runtime:require("user", "job", selector)

    assert(type(envelope) == "table",
        "[compare.service] runtime user job envelope missing")

    assert(type(envelope.batch) == "function",
        "[compare.service] runtime job missing batch()")

    local batch =
        envelope:batch()

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

    local vendor_descriptors =
        data:resources():get("system", "vendor") or {}

    local vendor_batches = {}

    for index = 1, #vendor_descriptors do

        local vendor_runtime =
            runtime:require("system", "vendor", index)

        assert(type(vendor_runtime) == "table",
            "[compare.service] runtime system vendor envelope missing at index " .. tostring(index))

        assert(type(vendor_runtime.batch) == "function",
            "[compare.service] runtime vendor missing batch() at index " .. tostring(index))

        local batch =
            vendor_runtime:batch()

        assert(type(batch) == "table",
            "[compare.service] runtime vendor batch missing at index " .. tostring(index))

        vendor_batches[#vendor_batches + 1] = batch
    end

    return vendor_batches
end

------------------------------------------------------------
-- Build compare environment
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
-- system/app/services/compare.lua
-- function: Compare:_build_env

function Compare:_build_env(selector, opts)

    local user_batch =
        self:_load_user_batch(selector)

    local vendor_batches =
        self:_load_vendor_batches()

    local env =
        Contracts.build_env(
            user_batch,
            vendor_batches,
            opts or {}
        )

    assert(type(env) == "table",
        "[compare.service] contracts.build_env() must return table")

    ------------------------------------------------------------
    -- Return execution envelope
    ------------------------------------------------------------

    return {
        strategy = "default",
        env      = env,
        target   = user_batch
    }
end

------------------------------------------------------------
-- Domain execution
------------------------------------------------------------

---@param env table
---@param opts table|nil
---@return CompareResult
function Compare:run_with_env(built, opts)

    opts = opts or {}

    assert(type(built) == "table",
        "[compare.service] built envelope required")

    local env = built.env or built

    assert(type(env) == "table",
        "[compare.service] env required")

    assert(type(env.job) == "table",
        "[compare.service] env.job missing")

    assert(type(env.vendors) == "table",
        "[compare.service] env.vendors missing")

    return CompareDomain.run_strict(
        env.job,
        env.vendors,
        opts
    )
end

------------------------------------------------------------
-- Public run (fallback if execution doesn't pass env)
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return CompareResult
function Compare:run(selector, opts)

    local env =
        self:_build_env(selector, opts)

    return self:run_with_env(env, opts)
end

return Compare
