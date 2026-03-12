-- system/app/services/pricing.lua

local PricingDomain = require("core.domain.pricing").controller
local Contracts     = require("core.domain.pricing.contracts")

---@class AppPricingService
local Pricing = {}
Pricing.__index = Pricing

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppPricingService
function Pricing.new(app)
    return setmetatable({
        __app = app
    }, Pricing)
end

------------------------------------------------------------
-- Internal: Load user batch
------------------------------------------------------------

---@param selector integer|string|nil
---@return table
function Pricing:_load_user_batch(selector)

    local runtime =
        self.__app:data():runtime()

    local envelope =
        runtime:require("user", "job", selector)

    assert(type(envelope) == "table",
        "[pricing.service] runtime user job envelope missing")

    assert(type(envelope.batch) == "function",
        "[pricing.service] runtime job missing batch()")

    local batch =
        envelope:batch()

    assert(type(batch) == "table",
        "[pricing.service] runtime job batch missing")

    assert(type(batch.boards) == "table",
        "[pricing.service] runtime job batch missing boards")

    return batch
end

------------------------------------------------------------
-- Internal: Load vendor batches
------------------------------------------------------------

---@return table
function Pricing:_load_vendor_batches()

    local data    = self.__app:data()
    local runtime = data:runtime()

    local vendor_descriptors =
        data:resources():get("system", "vendor") or {}

    local vendor_batches = {}

    for index = 1, #vendor_descriptors do

        local vendor_runtime =
            runtime:require("system", "vendor", index)

        assert(type(vendor_runtime) == "table",
            "[pricing.service] runtime vendor envelope missing at index " .. tostring(index))

        assert(type(vendor_runtime.batch) == "function",
            "[pricing.service] runtime vendor missing batch() at index " .. tostring(index))

        local batch =
            vendor_runtime:batch()

        assert(type(batch) == "table",
            "[pricing.service] runtime vendor batch missing at index " .. tostring(index))

        vendor_batches[#vendor_batches + 1] = batch
    end

    return vendor_batches
end

------------------------------------------------------------
-- Build execution environment
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Pricing:_build_env(selector, opts)

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
        "[pricing.service] contracts.build_env() must return table")

    ------------------------------------------------
    -- capability exposure
    ------------------------------------------------

    local has_board_prices = false

    for _, board in ipairs(user_batch.boards or {}) do
        if type(board.bf_price) == "number" and board.bf_price > 0 then
            has_board_prices = true
            break
        end
    end

    if has_board_prices then
        env.board_prices = true
    end

    ------------------------------------------------
    -- execution envelope
    ------------------------------------------------

    return {
        strategy = env.pricing_basis or "default",
        env      = env,
        target   = user_batch
    }
end

------------------------------------------------------------
-- Domain execution
------------------------------------------------------------

---@param built table
---@param opts table|nil
---@return table
function Pricing:run_with_env(built, opts)

    opts = opts or {}

    assert(type(built) == "table",
        "[pricing.service] built envelope required")

    local env =
        built.env or built

    assert(type(env) == "table",
        "[pricing.service] env required")

    assert(type(env.job) == "table",
        "[pricing.service] env.job missing")

    return PricingDomain.run(
        env.job,
        env.pricing_basis or "vendor_anchor",
        env.opts or {}
    )
end

------------------------------------------------------------
-- Public run (fallback)
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Pricing:run(selector, opts)

    local built =
        self:_build_env(selector, opts)

    return self:run_with_env(built, opts)
end

return Pricing
