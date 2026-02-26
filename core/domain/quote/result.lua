-- core/domain/quote/result.lua
--
-- QuoteResult façade.
--
-- Wraps Quote DTO and provides:
--   • Semantic accessors
--   • Totals meaning view
--   • Rendering helpers
--   • Policy helpers

local Format  = require("core.domain._priced_doc.internal.format_text")
local Signals = require("core.signal")

----------------------------------------------------------------
-- TotalsView
----------------------------------------------------------------
-- Meaning-layer view over quote aggregate totals.
-- Provides semantic access to quote-level numeric aggregates.
----------------------------------------------------------------

----------------------------------------------------------------
-- TotalsView
----------------------------------------------------------------

---@class QuoteTotalsView
local TotalsView = {}
TotalsView.__index = TotalsView

---@param data table|nil
---@return QuoteTotalsView
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
-- QuoteResult
----------------------------------------------------------------
-- Meaning-layer façade for a quote document.
-- Encapsulates raw DTO structure and exposes semantic access.
----------------------------------------------------------------

---@class QuoteResult
---@field private __doc table
---@field private __signals table
local QuoteResult = {}
QuoteResult.__index = QuoteResult

--- Creates a new quote result from a DTO and signal list.
---@param document table
---@param signals table|nil
---@return QuoteResult
function QuoteResult.new(document, signals)
    assert(type(document) == "table", "QuoteResult requires DTO")
    return setmetatable({
        __doc     = document,
        __signals = signals or Signals.list(),
    }, QuoteResult)
end

----------------------------------------------------------------
-- Semantic Accessors
----------------------------------------------------------------

--- Returns the quote identifier.
---@return string|nil
function QuoteResult:id()
    return self.__doc.id
end

--- Returns the rendered quote lines as formatted text.
---@param opts table|nil
---@return string[]
function QuoteResult:lines(opts)
    local rendered = Format.render(self.__doc, opts)
    return rendered.lines
end

--- Returns a semantic totals view for this quote.
---@return QuoteTotalsView
function QuoteResult:totals()
    return TotalsView.new(self.__doc.totals)
end

--- Returns validation signals associated with this quote.
---@return table
function QuoteResult:signals()
    return self.__signals
end

--- Returns true if validation errors exist.
---@return boolean
function QuoteResult:has_errors()
    return Signals.has_errors(self.__signals)
end

----------------------------------------------------------------
-- Rendering
----------------------------------------------------------------

--- Returns the fully rendered quote document structure.
---@param opts table|nil
---@return table
function QuoteResult:render_text(opts)
    return Format.render(self.__doc, opts)
end

--- Prints the rendered quote to stdout.
---@param opts table|nil
---@return QuoteResult
function QuoteResult:print(opts)
    local rendered = Format.render(self.__doc, opts)
    for _, line in ipairs(rendered.lines) do
        print(line)
    end
    return self
end

----------------------------------------------------------------
-- Policy
----------------------------------------------------------------

--- Throws an error if validation errors are present.
---@return QuoteResult
function QuoteResult:require_no_errors()
    assert(not self:has_errors(), "[quote] validation failed")
    return self
end

----------------------------------------------------------------

return QuoteResult
