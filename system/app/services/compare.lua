-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller

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
-- Public Run
------------------------------------------------------------

---@param ctx table|nil
---@return CompareResult
function Compare:run(ctx)

    local target =
        ctx and ctx.target

    assert(type(target) == "table",
        "[compare.service] execution target missing")

    assert(type(target.batch) == "table",
        "[compare.service] target batch missing")

    assert(type(target.boards) == "table",
        "[compare.service] target boards missing")

    local vendor_batches =
        ctx and ctx.env and ctx.env.vendors

    assert(type(vendor_batches) == "table",
        "[compare.service] vendor batches missing")

    local opts =
        (ctx and ctx.env and ctx.env.opts) or {}

    ------------------------------------------------
    -- Domain execution
    ------------------------------------------------

    return CompareDomain.run_strict(
        target,
        vendor_batches,
        opts
    )
end

return Compare
