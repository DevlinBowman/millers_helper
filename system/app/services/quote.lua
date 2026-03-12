-- system/app/services/quote.lua

local QuoteDomain = require("core.domain.quote").controller

---@class AppQuoteService
---@field private __app Surface
local Quote = {}
Quote.__index = Quote

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppQuoteService
function Quote.new(app)
    return setmetatable({
        __app = app
    }, Quote)
end

------------------------------------------------------------
-- Run Quote
------------------------------------------------------------

---@param ctx table|nil
---@return table
function Quote:run(ctx)

    local data =
        self.__app:data()

    local runtime =
        data:runtime()

    ------------------------------------------------------------
    -- Resolve job batch
    ------------------------------------------------------------

    local job_batch

    if ctx and ctx.env and ctx.env.job then
        job_batch = ctx.env.job:batch()
    else
        job_batch = runtime:require("user","job"):batch()
    end

    assert(type(job_batch) == "table",
        "[quote.service] job batch missing")

    assert(type(job_batch.boards) == "table",
        "[quote.service] job batch boards missing")

    ------------------------------------------------------------
    -- Domain execution
    ------------------------------------------------------------

    return QuoteDomain.run_strict(
        job_batch.boards,
        ctx and ctx.opts or {}
    )
end

return Quote
