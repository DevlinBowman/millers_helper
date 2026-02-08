-- cli/domains/boards/controller.lua
--
-- Boards domain controller.
--
-- Responsibilities:
--   • Load board data from files
--   • Produce BoardCapture
--   • Invoke core systems
--   • Select output sinks
--
-- NO ledger logic.
-- NO mutation.
-- NO formatting.

local Capture = require("ingestion_v2.board_capture")
local Report  = require("ingestion_v2.report")
local Printer = require("cli.core.printer")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({}, Controller)
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function select_sink(ctx)
    if ctx.flags.output or ctx.flags.o then
        local FileSink = require("file_handler.sinks.file")
        return FileSink.new(ctx.flags.output or ctx.flags.o)
    end

    return require("file_handler.sinks.stdout")
end

local function emit_lines(sink, lines)
    for _, line in ipairs(lines or {}) do
        sink:write(line)
    end

    if type(sink.close) == "function" then
        sink:close()
    end
end

----------------------------------------------------------------
-- Load
----------------------------------------------------------------

function Controller:load(ctx)
    if #ctx.positionals < 1 then
        return ctx:usage()
    end

    local capture = Capture.load(ctx.positionals)

    -- structured inspector output
    if ctx.flags.struct or ctx.flags.s then
        Printer.struct(capture)
        return
    end

    -- per-source ingestion reports
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

    local Boards = require("app.controller.boards")

    local format =
        ctx.flags.format
        or ctx.flags.f
        or "text"

    local ok, result = pcall(
        Boards.compare,
        order_path,
        offer_paths,
        { format = format }
    )

    if not ok then
        ctx:die(result)
    end

    local sink = select_sink(ctx)

    if result.kind == "text" then
        emit_lines(sink, result.lines)

    elseif result.kind == "json" then
        local JsonWriter = require("file_handler.writers.json")
        JsonWriter.write(
            ctx.flags.output or ctx.flags.o or "/dev/stdout",
            result.data
        )

    else
        ctx:die("unknown output kind: " .. tostring(result.kind))
    end
end

----------------------------------------------------------------
-- Invoice
----------------------------------------------------------------
-- NOTE:
-- Invoice still uses printer-based output.
-- It should be migrated to the same format + sink flow
-- when you are ready to unify output behavior.


function Controller:invoice(ctx)
    if #ctx.positionals ~= 1 then
        return ctx:usage()
    end

    local Boards = require("app.controller.boards")
    local path   = ctx.positionals[1]

    local format =
        ctx.flags.format
        or ctx.flags.f
        or "text"

    local ok, result = pcall(
        Boards.invoice,
        path,
        { format = format }
    )

    if not ok then
        ctx:die(result)
    end

    local sink = select_sink(ctx)

    if result.kind == "text" then
        emit_lines(sink, result.lines)

    elseif result.kind == "json" then
        local JsonWriter = require("file_handler.writers.json")
        JsonWriter.write(
            ctx.flags.output or ctx.flags.o or "/dev/stdout",
            result.data
        )

    else
        ctx:die("unknown output kind: " .. tostring(result.kind))
    end
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
        kind    = "boards_summary",
        sources = {},
        totals  = capture.meta,
    }

    for _, src in ipairs(capture.sources) do
        out.sources[#out.sources + 1] = {
            source   = src.source_id,
            boards   = #src.boards.data,
            errors   = #src.signals.errors,
            warnings = #src.signals.warnings,
        }
    end

    Printer.struct(out)
end

return Controller
