-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller
local Contracts     = require("core.domain.compare.contracts")

---@class AppCompareService
---@field private __app Surface
local Compare       = {}
Compare.__index     = Compare

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

-- system/app/services/compare.lua
-- function: Compare:_build_env

function Compare:_build_env(selector, opts)
    opts = opts or {}

    local user_batch =
        self:_load_user_batch(selector)

    local vendor_batches =
        self:_load_vendor_batches()

    local env =
        Contracts.build_env(
            user_batch,
            vendor_batches,
            opts
        )

    assert(type(env) == "table",
        "[compare.service] contracts.build_env() must return table")

    ------------------------------------------------------------
    -- pricing context assembly
    ------------------------------------------------------------

    local intent_root =
        self.__app:data():intent():all() or {}

    local pricing_intent =
        type(intent_root.pricing) == "table"
        and intent_root.pricing
        or {}

    local pricing_opts = {}

    if type(env.opts) == "table" then
        for key, value in pairs(env.opts) do
            pricing_opts[key] = value
        end
    end

    for key, value in pairs(pricing_intent) do
        if pricing_opts[key] == nil then
            pricing_opts[key] = value
        end
    end

    ------------------------------------------------------------
    -- deterministic pricing basis
    ------------------------------------------------------------

    local pricing_basis =
        pricing_opts.pricing_basis
        or pricing_opts.basis

    if not pricing_basis then
        local order = user_batch.order or {}
        local order_use = order.use
        local order_value = order.value

        if type(order_use) == "string"
            and order_use:lower() == "sale"
            and type(order_value) == "number"
            and order_value > 0
        then
            pricing_basis = "reverse_order_value"
        else
            pricing_basis = "vendor_anchor"
        end
    end

    env.pricing_basis = pricing_basis
    pricing_opts.pricing_basis = pricing_basis

    ------------------------------------------------------------
    -- deterministic target total value
    ------------------------------------------------------------

    if pricing_basis == "reverse_order_value" then
        if pricing_opts.target_total_value == nil then
            local order = user_batch.order or {}
            if type(order.value) == "number" and order.value > 0 then
                pricing_opts.target_total_value = order.value
            end
        end
    end

    ------------------------------------------------------------
    -- deterministic vendor normalization
    ------------------------------------------------------------

    local vendor_env

    if type(pricing_opts.vendor) == "table"
        and pricing_opts.vendor.kind == "vendor"
    then
        vendor_env = pricing_opts.vendor
    elseif type(env.vendor) == "table"
        and env.vendor.kind == "vendor"
    then
        vendor_env = env.vendor
    elseif type(vendor_batches) == "table"
        and #vendor_batches > 0
    then
        local first_vendor_batch = vendor_batches[1]

        if type(first_vendor_batch) == "table"
            and type(first_vendor_batch.boards) == "table"
        then
            vendor_env = {
                kind  = "vendor",
                items = first_vendor_batch.boards,
                meta  = {
                    name =
                        first_vendor_batch.id
                        or (first_vendor_batch.meta
                            and first_vendor_batch.meta.io
                            and first_vendor_batch.meta.io.source_path)
                        or "vendor_1"
                }
            }
        end
    end

    if vendor_env then
        env.vendor = vendor_env
        pricing_opts.vendor = vendor_env
    end

    env.opts = pricing_opts

    ------------------------------------------------------------
    -- capability exposure
    ------------------------------------------------------------

    local has_board_prices = false

    if type(user_batch.boards) == "table" then
        for _, board in ipairs(user_batch.boards) do
            if type(board.bf_price) == "number" and board.bf_price > 0 then
                has_board_prices = true
                break
            end
        end
    end

    if has_board_prices then
        env.board_prices = true
    end

    local has_vendor_prices = false

    if type(vendor_batches) == "table" then
        for _, batch in ipairs(vendor_batches) do
            for _, board in ipairs(batch.boards or {}) do
                if type(board.bf_price) == "number" and board.bf_price > 0 then
                    has_vendor_prices = true
                    break
                end
            end
            if has_vendor_prices then
                break
            end
        end
    end

    if has_vendor_prices then
        env.vendor_prices = true
    end

    ------------------------------------------------------------
    -- return execution envelope
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

    assert(type(built) == "table", "[compare.service] built envelope required")

    local env = built.env or built

    assert(type(env) == "table", "[compare.service] env required")
    assert(type(env.job) == "table", "[compare.service] env.job missing")
    assert(type(env.vendors) == "table", "[compare.service] env.vendors missing")

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
