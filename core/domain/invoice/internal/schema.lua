-- core/domain/invoice/internal/schema.lua

local Signals = require("core.signal")

local Schema = {}

Schema.contract = {
    input = {
        boards = "table[]",
        order  = "table|nil",
    },
    model = {
        kind    = "invoice_model",
        header  = "table|nil",
        rows    = "table[]",
        totals  = "table",
        signals = "table[]", -- list of signal objects
    }
}

local function is_tbl(x) return type(x) == "table" end
local function is_num(x) return type(x) == "number" end

----------------------------------------------------------------
-- Signal List Helpers
----------------------------------------------------------------

function Schema.new_signals()
    return Signals.list()
end

function Schema.has_errors(list)
    return Signals.has_errors(list)
end

----------------------------------------------------------------
-- Empty Model
----------------------------------------------------------------

function Schema.empty_model(sig)
    return {
        kind    = "invoice_model",
        header  = nil,
        rows    = {},
        totals  = { count = 0, bf = 0, price = 0 },
        signals = sig,
    }
end

----------------------------------------------------------------
-- Input Validation
----------------------------------------------------------------

function Schema.validate_input(input, sig)
    if not is_tbl(input) then
        Signals.push(sig, Signals.new(
            "INPUT_NOT_TABLE",
            Signals.LEVEL.ERROR,
            "invoice input must be a table",
            { module = "invoice", stage = "validate_input" }
        ))
        return
    end

    if not is_tbl(input.boards) then
        Signals.push(sig, Signals.new(
            "BOARDS_MISSING",
            Signals.LEVEL.ERROR,
            "invoice.boards required",
            { module = "invoice", stage = "validate_input" }
        ))
    end
end

----------------------------------------------------------------
-- Output Validation
----------------------------------------------------------------

function Schema.validate_model(model, sig)
    if not is_tbl(model) then
        Signals.push(sig, Signals.new(
            "MODEL_NOT_TABLE",
            Signals.LEVEL.ERROR,
            "invoice model must be a table",
            { module = "invoice", stage = "validate_model" }
        ))
        return
    end

    if not is_tbl(model.rows) then
        Signals.push(sig, Signals.new(
            "ROWS_MISSING",
            Signals.LEVEL.ERROR,
            "invoice rows required",
            { module = "invoice", stage = "validate_model" }
        ))
    end

    if not is_tbl(model.totals) then
        Signals.push(sig, Signals.new(
            "TOTALS_MISSING",
            Signals.LEVEL.ERROR,
            "invoice totals required",
            { module = "invoice", stage = "validate_model" }
        ))
        return
    end

    if not is_num(model.totals.count) then
        Signals.push(sig, Signals.new(
            "TOTALS_BAD_COUNT",
            Signals.LEVEL.ERROR,
            "invoice totals.count must be number",
            { module = "invoice", stage = "validate_model" }
        ))
    end
end

return Schema
