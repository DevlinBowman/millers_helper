-- core/domain/quote/controller.lua
--
-- Quote Domain Controller
--
-- Provides:
--   run_raw(boards)    -> QuoteDTO
--   run(boards)        -> QuoteResult
--   run_strict(boards) -> QuoteResult (throws)
--
-- Responsibility:
--   • Validate input
--   • Call pipeline
--   • Wrap DTO in Result
--   • Enforce strict policy

local Registry = require("core.domain.quote.registry")
local Result   = require("core.domain.quote.result")
local Signals  = require("core.signal")

local Controller = {}

----------------------------------------------------------------
-- RAW ENTRY (Structure Layer)
----------------------------------------------------------------

---@param boards table[]
---@param opts table|nil { id?:string }
---@return table|nil, string|nil
function Controller.run_raw(boards, opts)
    assert(type(boards) == "table", "quote.run requires boards")

    opts = opts or {}

    local signals = Signals.list()

    -- Non-blocking validation for missing prices
    for _, board in ipairs(boards) do
        if board.bf_price == nil then
            Signals.push(signals, Signals.new(
                "QUOTE_MISSING_PRICE",
                Signals.LEVEL.WARN,
                "Missing price for board: " .. tostring(board.id or board.label or "?")
            ))
        end
    end

    local dto = Registry.pipeline.run({
        id     = opts.id,
        boards = boards,
    })

    return {
        document = dto,
        signals  = signals,
    }
end

----------------------------------------------------------------
-- FAÇADE ENTRY (Meaning Layer)
----------------------------------------------------------------

---@param boards table[]
---@param opts table|nil
---@return QuoteResult|nil, string|nil
function Controller.run(boards, opts)
    local result, err = Controller.run_raw(boards, opts)
    if not result then
        return nil, err
    end

    return Result.new(result.document, result.signals)
end

----------------------------------------------------------------
-- STRICT ENTRY (Policy Layer)
----------------------------------------------------------------

---@param boards table[]
---@param opts table|nil
---@return QuoteResult
function Controller.run_strict(boards, opts)
    local result = Controller.run(boards, opts)
    return result:require_no_errors()
end

return Controller
