-- core/domain/invoice/result.lua
--
-- InvoiceResult façade.
--
-- Wraps Invoice DTO and provides:
--   • Semantic accessors
--   • Totals meaning view
--   • Rendering helpers
--   • Policy helpers

local Format = require("core.domain._priced_doc.internal.format_text")

----------------------------------------------------------------
-- TotalsView
----------------------------------------------------------------
-- Meaning-layer view over invoice aggregate totals.
----------------------------------------------------------------

---@class InvoiceTotalsView
---@field private __data table
local TotalsView = {}
TotalsView.__index = TotalsView

---@param data table|nil
---@return InvoiceTotalsView
----------------------------------------------------------------
-- TotalsView
----------------------------------------------------------------

---@class InvoiceTotalsView
local TotalsView = {}
TotalsView.__index = TotalsView

---@param data table|nil
---@return InvoiceTotalsView
function TotalsView.new(data)
    local raw = data or {}

    -- copy raw values directly onto instance
    local instance = {
        bf    = raw.bf    or 0,
        count = raw.count or 0,
        price = raw.price or 0,
    }

    return setmetatable(instance, TotalsView)
end

function TotalsView:quantity()
    return self.count
end

function TotalsView:board_feet()
    return self.bf
end

function TotalsView:price()
    return self.price
end

----------------------------------------------------------------
-- InvoiceResult
----------------------------------------------------------------

---@class InvoiceResult
---@field private __data table
local InvoiceResult = {}
InvoiceResult.__index = InvoiceResult

---@param dto table
---@return InvoiceResult
function InvoiceResult.new(dto)
    assert(type(dto) == "table", "InvoiceResult requires DTO")
    return setmetatable({ __data = dto }, InvoiceResult)
end

----------------------------------------------------------------
-- Semantic Accessors
----------------------------------------------------------------

function InvoiceResult:id()
    return self.__data.id
end

function InvoiceResult:header()
    return self.__data.header
end

function InvoiceResult:lines(opts)
    local rendered = Format.render(self.__data, opts)
    return rendered.lines
end

--- Returns a semantic totals view
---@return InvoiceTotalsView
function InvoiceResult:totals()
    return TotalsView.new(self.__data.totals)
end

----------------------------------------------------------------
-- Rendering
----------------------------------------------------------------

function InvoiceResult:render_text(opts)
    return Format.render(self.__data, opts)
end

function InvoiceResult:print(opts)
    local rendered = Format.render(self.__data, opts)
    for _, line in ipairs(rendered.lines) do
        print(line)
    end
    return self
end

----------------------------------------------------------------
-- Policy
----------------------------------------------------------------

function InvoiceResult:is_priced()
    for _, row in ipairs(self.__data.rows or {}) do
        if row.bf_price == nil or row.bf_price == 0 then
            return false
        end
    end
    return true
end

function InvoiceResult:require_priced()
    assert(self:is_priced(), "[invoice] invoice requires priced boards")
    return self
end

----------------------------------------------------------------

return InvoiceResult
