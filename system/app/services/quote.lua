-- system/app/services/quote.lua

local QuoteDomain = require("core.domain.quote").controller

---@class AppQuoteService
local Quote = {}
Quote.__index = Quote

function Quote.new(app)
    return setmetatable({
        __app = app
    }, Quote)
end

------------------------------------------------------------
-- Run Quote From Runtime Batch
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Quote:run(selector, opts)

    local runtime = self.__app:data():runtime()

    local batch = runtime:require("user", "job", selector)

    assert(type(batch.batch) == "function",
        "[quote.service] runtime job missing batch()")

    local raw = batch:batch()

    -- strict: let domain throw if invalid
    return QuoteDomain.run_strict(raw.boards, opts)
end

return Quote
