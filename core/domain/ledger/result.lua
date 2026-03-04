-- core/domain/ledger/result.lua
--
-- LedgerResult façade.
--
-- Wraps ledger output and provides:
--   • Semantic accessors
--   • Rendering helpers
--   • Policy helpers

local Printer = require("core.domain.ledger.internal.analytics_printer")

---@class LedgerResult
---@field private __data table
local LedgerResult = {}
LedgerResult.__index = LedgerResult

---@param dto table
---@return LedgerResult
function LedgerResult.new(dto)
    assert(type(dto) == "table", "LedgerResult requires DTO")
    return setmetatable({ __data = dto }, LedgerResult)
end

----------------------------------------------------------------
-- Internal DTO Resolver
----------------------------------------------------------------

---@private
---@return table
function LedgerResult:_dto()
    return self.__data.__data or self.__data
end

----------------------------------------------------------------
-- Accessors
----------------------------------------------------------------

function LedgerResult:transactions()
    return self:_dto().transactions or {}
end

function LedgerResult:transaction()
    return self:_dto().transaction
end

----------------------------------------------------------------
-- Rendering
----------------------------------------------------------------

function LedgerResult:print_analytics()
    local report = self:_dto()
    Printer.print_full(report)
    return self
end

function LedgerResult:analytics_text()
    local report = self:_dto()
    return Printer.build_full_text(report)
end

----------------------------------------------------------------
-- Policy
----------------------------------------------------------------

function LedgerResult:require_transactions()
    assert(#self:transactions() > 0, "[ledger] no transactions")
    return self
end

return LedgerResult
