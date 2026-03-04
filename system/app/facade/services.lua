-- system/app/facade/services.lua

local VendorService  = require("system.app.services.vendor")
local InvoiceService = require("system.app.services.invoice")
local QuoteService   = require("system.app.services.quote")
local CompareService = require("system.app.services.compare")
local LedgerService  = require("system.app.services.ledger")

---@class AppServicesFacade
---@field private __app Surface
---@field private __vendor AppVendorService|nil
---@field private __invoice AppInvoiceService|nil
---@field private __quote AppQuoteService|nil
local Services = {}
Services.__index = Services

function Services.new(app)
    return setmetatable({
        __app     = app,
        __vendor  = nil,
        __invoice = nil,
        __quote   = nil,
        __compare = nil,
        __ledger  = nil,
    }, Services)
end

------------------------------------------------------------
-- Vendor
------------------------------------------------------------

function Services:vendor()
    if not self.__vendor then
        self.__vendor = VendorService.new(self.__app)
    end
    return self.__vendor
end

------------------------------------------------------------
-- Invoice
------------------------------------------------------------

function Services:invoice()
    if not self.__invoice then
        self.__invoice = InvoiceService.new(self.__app)
    end
    return self.__invoice
end

------------------------------------------------------------
-- Quote
------------------------------------------------------------

function Services:quote()
    if not self.__quote then
        self.__quote = QuoteService.new(self.__app)
    end
    return self.__quote
end


function Services:compare()
    if not self.__compare then
        self.__compare = CompareService.new(self.__app)
    end
    return self.__compare
end

function Services:ledger()
    if not self.__ledger then
        self.__ledger = LedgerService.new(self.__app)
    end
    return self.__ledger
end

function Services:inspect()
    return {
        capabilities = { "vendor", "invoice", "quote", "compare", "ledger" }
    }
end

return Services
