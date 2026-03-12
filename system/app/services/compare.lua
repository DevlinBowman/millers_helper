-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller

---@class AppCompareService
---@field private __app Surface
local Compare   = {}
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

    local data =
        self.__app:data()

    local runtime =
        data:runtime()

    ------------------------------------------------
    -- Resolve job batch
    ------------------------------------------------

    local job_batch

    if ctx and ctx.env and ctx.env.job then

        job_batch =
            ctx.env.job:batch()

    else

        job_batch =
            runtime:require("user", "job"):batch()

    end

    assert(type(job_batch) == "table",
        "[compare.service] job batch missing")

    assert(type(job_batch.boards) == "table",
        "[compare.service] job batch boards missing")

    ------------------------------------------------
    -- Resolve vendor batches (canonical runtime API)
    ------------------------------------------------

    local vendor_batches =
        runtime:batches("system", "vendor")

    assert(type(vendor_batches) == "table",
        "[compare.service] vendor batches missing")

    ------------------------------------------------
    -- Options
    ------------------------------------------------

    local opts =
        ctx and ctx.opts or {}

    ------------------------------------------------
    -- Domain execution
    ------------------------------------------------

    return CompareDomain.run_strict(
        job_batch,
        vendor_batches,
        opts
    )
end

return Compare
