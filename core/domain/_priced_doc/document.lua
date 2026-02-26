-- core/domain/_priced_doc/document.lua
--
-- PricedDocument façade.
--
-- Wraps a priced document DTO and provides:
--   • Semantic accessors
--   • Totals meaning view
--   • Rendering helpers
--   • Export helpers
--
-- This is a domain-level meaning object.

local Format = require("core.domain._priced_doc.internal.format_text")

----------------------------------------------------------------
-- TotalsView
----------------------------------------------------------------
-- Meaning-layer view over aggregate totals for a priced document.
----------------------------------------------------------------

---@class PricedDocumentTotalsView
---@field private __data table
local TotalsView = {}
TotalsView.__index = TotalsView

--- Creates a new totals view from raw totals data.
---@param data table|nil
---@return PricedDocumentTotalsView
function TotalsView.new(data)
    return setmetatable({ __data = data or {} }, TotalsView)
end

--- Returns the total quantity across all line items.
---@return number
function TotalsView:quantity()
    return self.__data.count or 0
end

--- Returns the total board feet across all line items.
---@return number
function TotalsView:board_feet()
    return self.__data.bf or 0
end

--- Returns the total price for the entire document.
---@return number
function TotalsView:price()
    return self.__data.price or 0
end

----------------------------------------------------------------
-- PricedDocument
----------------------------------------------------------------

---@class PricedDocument
---@field private __data table
local Document = {}
Document.__index = Document

--- Creates a new priced document façade from a DTO.
---@param dto table
---@return PricedDocument
function Document.new(dto)
    assert(type(dto) == "table", "PricedDocument requires DTO")
    return setmetatable({ __data = dto }, Document)
end

----------------------------------------------------------------
-- Semantic Accessors
----------------------------------------------------------------

--- Returns the document identifier.
---@return string|nil
function Document:id()
    return self.__data.id
end

--- Returns the document generation timestamp.
---@return string|nil
function Document:generated_at()
    return self.__data.generated_at
end

--- Returns the document header metadata.
---@return table|nil
function Document:header()
    return self.__data.header
end

--- Returns raw row data for this document.
---@return table[]
function Document:rows()
    return self.__data.rows or {}
end

--- Returns a semantic totals view for this document.
---@return PricedDocumentTotalsView
function Document:totals()
    return TotalsView.new(self.__data.totals)
end

----------------------------------------------------------------
-- Rendering
----------------------------------------------------------------

--- Returns the rendered document structure.
---@param opts table|nil
---@return table
function Document:render_text(opts)
    return Format.render(self.__data, opts)
end

--- Returns rendered lines for this document.
---@param opts table|nil
---@return string[]
function Document:lines(opts)
    local rendered = Format.render(self.__data, opts)
    return rendered.lines
end

--- Prints the rendered document to stdout.
---@param opts table|nil
---@return PricedDocument
function Document:print(opts)
    for _, line in ipairs(self:lines(opts)) do
        print(line)
    end
    return self
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

--- Returns raw row data for external export.
---@return table[]
function Document:export_rows()
    return self.__data.rows or {}
end

--- Returns raw totals data for external export.
---@return table
function Document:export_totals()
    return self.__data.totals or {}
end

----------------------------------------------------------------

return Document
