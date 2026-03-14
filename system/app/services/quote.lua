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

    ------------------------------------------------
    -- Execution target required
    ------------------------------------------------

    local target =
        ctx and ctx.target

    assert(type(target) == "table",
        "[quote.service] execution target missing")

    assert(type(target.batch) == "table",
        "[quote.service] target batch missing")

    assert(type(target.boards) == "table",
        "[quote.service] target boards missing")

    ------------------------------------------------
    -- Domain execution
    ------------------------------------------------

    return QuoteDomain.run_strict(
        target.boards,
        (ctx and ctx.env and ctx.env.opts) or {}
    )
end

return Quote
