-- cli/domains/ledger/controller.lua
--
-- Ledger domain controller (CLI-facing).
--
-- Responsibilities:
--   • Translate CLI intent into service calls
--   • Coordinate ledger, ingestion, analysis, and export services
--   • Interpret flags (dry-run, commit, inspect modes)
--   • Decide load / mutate / save sequencing
--   • Select and render inspection outputs
--
-- This is the ONLY place ledger behavior is orchestrated for the CLI.
-- Ledger services themselves remain pure and interface-agnostic.

local Ledger = require("ledger")

-- ledger services
local Store    = Ledger.store
local Ingest   = Ledger.ingest

-- ingestion services
local Adapter  = require("ingestion.adapter")
local Report   = require("ingestion.report")

-- export service
local Export   = require("ledger.export_csv")

-- analysis services
local Summary  = require("ledger.analysis.summary")
local Keys     = require("ledger.analysis.keys")
local Describe = require("ledger.analysis.describe")

-- CLI core output
local Printer  = require("cli.core.printer")

local Controller = {}
Controller.__index = Controller

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function Controller.new()
    return setmetatable({}, Controller)
end

----------------------------------------------------------------
-- Ingest
----------------------------------------------------------------

function Controller:ingest(ctx)
    local target      = ctx.positionals[1]
    local ledger_path = ctx.positionals[2]

    if not target or not ledger_path then
        return ctx:usage()
    end

    local commit = (ctx.flags.commit or ctx.flags.c) and true or false
    local dry    = (ctx.flags.dry or ctx.flags.n) and true or false

    if dry then
        commit = false
    end

    ----------------------------------------------------------------
    -- 1) Run ingestion adapter (source → boards)
    ----------------------------------------------------------------

    local ingest_result = Adapter.ingest(target)

    ----------------------------------------------------------------
    -- 2) Report ingestion results (always)
    ----------------------------------------------------------------

    Report.print(
        ingest_result,
        { compact = ctx.flags.compact and true or false }
    )

    ----------------------------------------------------------------
    -- 3) Dry-run exit
    ----------------------------------------------------------------

    if not commit then
        Printer.note("note: dry-run (use --commit / -c to commit)")
        return
    end

    ----------------------------------------------------------------
    -- 4) Commit to ledger
    ----------------------------------------------------------------

    local ledger = Store.load(ledger_path)
    local boards = ingest_result.boards.data

    Ingest.run(
        ledger,
        { kind = "boards", data = boards },
        { path = target }
    )

    Store.save(ledger_path, ledger)
end

----------------------------------------------------------------
-- Inspect
----------------------------------------------------------------

function Controller:inspect(ctx)
    local ledger_path = ctx.positionals[1]
    if not ledger_path then
        return ctx:usage()
    end

    local ledger = Store.load(ledger_path)

    ----------------------------------------------------------------
    -- Key surface inspection
    ----------------------------------------------------------------

    if ctx.flags.keys or ctx.flags.k then
        Printer.struct(Keys.run(ledger))
        return
    end

    ----------------------------------------------------------------
    -- Field description
    ----------------------------------------------------------------

    if ctx.flags.describe or ctx.flags.d then
        local field = ctx.positionals[2]

        if field then
            local info = Describe.field(field)
            if not info then
                ctx:die("unknown field: " .. tostring(field))
            end
            Printer.struct(info)
        else
            Printer.struct(Describe.all())
        end

        return
    end

    ----------------------------------------------------------------
    -- Default: summary
    ----------------------------------------------------------------

    Printer.struct(Summary.run(ledger))
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

function Controller:export(ctx)
    local ledger_path = ctx.positionals[1]
    local out_path    = ctx.positionals[2]

    if not ledger_path or not out_path then
        return ctx:usage()
    end

    local ledger = Store.load(ledger_path)

    local ok, err = Export.write_csv(ledger, out_path)
    if not ok then
        ctx:die(err)
    end
end

----------------------------------------------------------------
-- Export controller
----------------------------------------------------------------

return Controller
