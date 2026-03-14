-- system/app/services/invoice.lua

local InvoiceDomain = require("core.domain.invoice").controller

---@class AppInvoiceService
---@field private __app Surface
local Invoice = {}
Invoice.__index = Invoice

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppInvoiceService
function Invoice.new(app)
    return setmetatable({
        __app = app
    }, Invoice)
end

------------------------------------------------------------
-- Run Invoice
------------------------------------------------------------

---@param ctx table|nil
---@return table
function Invoice:run(ctx)

    local target =
        ctx and ctx.target

    assert(type(target) == "table",
        "[invoice.service] execution target missing")

    assert(type(target.batch) == "table",
        "[invoice.service] target batch missing")

    local opts =
        (ctx and ctx.env and ctx.env.opts) or {}

    return InvoiceDomain.run_strict(
        target.batch,
        opts
    )
end

return Invoice
