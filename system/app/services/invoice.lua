-- system/app/services/invoice.lua

local InvoiceDomain = require("core.domain.invoice").controller

---@class AppInvoiceService
local Invoice = {}
Invoice.__index = Invoice

function Invoice.new(app)
    return setmetatable({
        __app = app
    }, Invoice)
end

------------------------------------------------------------
-- Run Invoice From Runtime Batch
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Invoice:run(selector, opts)

    local runtime = self.__app:data():runtime()

    local batch = runtime:require("user", "job", selector)

    assert(type(batch.batch) == "function",
        "[invoice.service] runtime job missing batch()")

    local raw = batch:batch()

    return InvoiceDomain.run_strict(raw, opts)
end

return Invoice
