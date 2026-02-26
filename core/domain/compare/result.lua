-- core/domain/compare/result.lua
--
-- CompareResult façade.
--
-- Wraps Compare model DTO and provides:
--   • Semantic accessors
--   • Totals meaning view
--   • Rendering + printing helpers
--   • Policy helpers (validity checks)

local Registry    = require("core.domain.compare.registry")
local FormatPipe  = require("core.domain.compare.pipelines.format_text")

----------------------------------------------------------------
-- TotalsView
----------------------------------------------------------------
-- Meaning-layer view over compare aggregate totals.
-- Provides semantic access to per-source totals (including "input").
----------------------------------------------------------------

---@class CompareTotalsView
---@field private __data table
local TotalsView = {}
TotalsView.__index = TotalsView

--- Creates a new totals view from raw totals data.
---@param data table|nil
---@return CompareTotalsView
function TotalsView.new(data)
    return setmetatable({ __data = data or {} }, TotalsView)
end

--- Returns the list of total keys (sources) in deterministic order (input first).
---@return string[]
function TotalsView:sources()
    local names = {}
    for k in pairs(self.__data or {}) do
        names[#names + 1] = k
    end

    table.sort(names, function(a, b)
        if a == "input" then return true end
        if b == "input" then return false end
        return a < b
    end)

    return names
end

--- Returns true if totals contain a source key.
---@param source string
---@return boolean
function TotalsView:has(source)
    return (self.__data[source] ~= nil)
end

--- Returns the numeric total for a given source (0 if missing).
---@param source string
---@return number
function TotalsView:total(source)
    local t = self.__data[source]
    if type(t) ~= "table" then
        return 0
    end
    return type(t.total) == "number" and t.total or 0
end

--- Returns the baseline "input" total (0 if missing).
---@return number
function TotalsView:input_total()
    return self:total("input")
end

----------------------------------------------------------------
-- CompareResult
----------------------------------------------------------------
-- Meaning-layer façade for a comparison model.
-- Encapsulates raw DTO structure and exposes semantic access.
----------------------------------------------------------------

---@class CompareResult
---@field private __data table
local CompareResult = {}
CompareResult.__index = CompareResult

--- Creates a new compare result from a model DTO.
---@param dto table
---@return CompareResult
function CompareResult.new(dto)
    assert(type(dto) == "table", "CompareResult requires DTO")
    return setmetatable({ __data = dto }, CompareResult)
end

----------------------------------------------------------------
-- Semantic Accessors
----------------------------------------------------------------

--- Returns comparison rows (one per order board).
---@return table[]
function CompareResult:rows()
    return self.__data.rows or {}
end

--- Returns the raw totals map (source -> { total = number }).
---@return table
function CompareResult:totals_raw()
    return self.__data.totals or {}
end

--- Returns a semantic totals view for this compare result.
---@return CompareTotalsView
function CompareResult:totals()
    return TotalsView.new(self.__data.totals)
end

--- Returns the underlying model DTO (escape hatch).
---@return table
function CompareResult:model()
    return self.__data
end

----------------------------------------------------------------
-- Rendering
----------------------------------------------------------------

--- Returns formatted output as text lines (does not print).
---@param opts table|nil
---@return string[]
function CompareResult:lines(opts)
    local rendered = FormatPipe.run(self.__data, opts)
    return rendered.lines or {}
end

--- Returns formatted output structure { kind="text", lines=string[] }.
---@param opts table|nil
---@return table
function CompareResult:render_text(opts)
    return FormatPipe.run(self.__data, opts)
end

--- Prints rendered output to stdout.
---@param opts table|nil
---@return CompareResult
function CompareResult:print(opts)
    for _, line in ipairs(self:lines(opts)) do
        print(line)
    end
    return self
end

----------------------------------------------------------------
-- Policy
----------------------------------------------------------------

--- Returns true if the model structure is valid per compare.shape.
---@return boolean
function CompareResult:is_valid()
    local ok = Registry.shape.validate_model(self.__data)
    return ok == true
end

--- Throws if the model structure is invalid per compare.shape.
---@return CompareResult
function CompareResult:require_valid()
    local ok, err = Registry.shape.validate_model(self.__data)
    assert(ok, "[compare] invalid model: " .. tostring(err))
    return self
end

----------------------------------------------------------------

return CompareResult
