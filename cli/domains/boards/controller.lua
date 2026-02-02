-- cli/domains/boards/controller.lua
--
-- Boards domain controller.
--
-- Responsibilities:
--   • Load board data from files
--   • Produce BoardCapture
--   • Select output shape (summary vs struct)
--
-- NO ledger logic.
-- NO mutation.

local Capture = require("ingestion_v2.board_capture")
local Report  = require("ingestion_v2.report")
local Printer = require("cli.core.printer")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({}, Controller)
end

----------------------------------------------------------------
-- Load
----------------------------------------------------------------

function Controller:load(ctx)
    if #ctx.positionals < 1 then
        return ctx:usage()
    end

    local paths = ctx.positionals

    local capture = Capture.load(paths)

    -- default: structured output (Inspector)
    if ctx.flags.struct or ctx.flags.s then
        Printer.struct(capture)
        return
    end

    -- otherwise: show per-source ingestion reports
    for _, src in ipairs(capture.sources) do
        Report.print({
            meta     = src.meta,
            boards   = src.boards,
            signals  = src.signals,
            errors   = src.signals.errors,
            warnings = src.signals.warnings,
        }, {
            compact = ctx.flags.compact or ctx.flags.c,
        })
    end
end

----------------------------------------------------------------
-- Compare
----------------------------------------------------------------

function Controller:compare(ctx)
    if #ctx.positionals < 2 then
        return ctx:usage()
    end

    local order_path  = ctx.positionals[1]
    local offer_paths = {}

    for i = 2, #ctx.positionals do
        offer_paths[#offer_paths + 1] = ctx.positionals[i]
    end

    local Capture = require("ingestion_v2.board_capture")

    local CompareInput = require(
        "presentation.exports.compare.from_capture"
    )
    local CompareModel = require(
        "presentation.exports.compare.model"
    )
    local ComparePrinter = require(
        "presentation.exports.compare.printer"
    )

    -- Load order (single source)
    local order_capture = Capture.load(order_path)

    if #order_capture.sources ~= 1 then
        ctx:die("order capture must contain exactly one source")
    end

    local order_source = order_capture.sources[1]

    -- Load offers (multiple sources)
    local offers_capture = Capture.load(offer_paths)

    local compare_input = CompareInput.build_input(
        offers_capture,
        {
            id     = order_path,
            boards = order_source.boards.data,
        }
    )

    local model = CompareModel.build(compare_input)

    ComparePrinter.print(model)
end

----------------------------------------------------------------
-- Invoice
----------------------------------------------------------------

function Controller:invoice(ctx)
    if #ctx.positionals ~= 1 then
        return ctx:usage()
    end

    local path = ctx.positionals[1]

    local Capture = require("ingestion_v2.board_capture")

    local InvoiceInput = require(
        "presentation.exports.invoice.from_capture"
    )
    local InvoiceModel = require(
        "presentation.exports.invoice.model"
    )
    local InvoicePrinter = require(
        "presentation.exports.invoice.printer"
    )

    local capture = Capture.load(path)

    if #capture.sources ~= 1 then
        ctx:die("invoice requires exactly one input source")
    end

    local input = InvoiceInput.build_input(capture)

    local invoice = InvoiceModel.build(input)

    InvoicePrinter.print(invoice)
end

----------------------------------------------------------------
-- Inspect (summary only)
----------------------------------------------------------------

function Controller:inspect(ctx)
    if #ctx.positionals < 1 then
        return ctx:usage()
    end

    local capture = Capture.load(ctx.positionals)

    local out = {
        kind = "boards_summary",
        sources = {},
        totals  = capture.meta,
    }

    for _, src in ipairs(capture.sources) do
        out.sources[#out.sources + 1] = {
            source = src.source_id,
            boards = #src.boards.data,
            errors = #src.signals.errors,
            warnings = #src.signals.warnings,
        }
    end

    Printer.struct(out)
end

return Controller
