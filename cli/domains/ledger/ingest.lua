-- cli/domains/ledger/ingest.lua

local Adapter = require("ingestion_v2.adapter")
local Report  = require("ingestion_v2.report")

local Ledger  = require("ledger")
local Store   = Ledger.store
local Ingest  = Ledger.ingest

local M = {}

M.help = {
    summary = "Ingest board data into a ledger",
    usage   = "ledger ingest <target> <ledger> [options]",
    options = {
        { "-c, --commit", "Commit results to ledger" },
        { "-n, --dry",    "Dry-run only (default)" },
        { "--compact",    "Compact output" },
    },
    examples = {
        "ledger ingest data/input.csv data/ledger.lua",
        "ledger ingest data/input.csv data/ledger.lua -c",
    },
}

function M.run(ctx)
    local target      = ctx.positionals[1]
    local ledger_path = ctx.positionals[2]

    if not target or not ledger_path then
        ctx:die(M.help.usage)
    end

    local commit = (ctx.flags.commit or ctx.flags.c) and true or false
    local dry    = (ctx.flags.dry or ctx.flags.n) and true or false

    if dry then commit = false end

    local ingest_result = Adapter.ingest(target)

    -- existing reporting stays for now
    Report.print(ingest_result, { compact = ctx.flags.compact and true or false })

    if not commit then
        ctx:note("note: dry-run (use --commit / -c to commit)")
        return
    end

    local ledger = Store.load(ledger_path)
    local boards = ingest_result.boards.data

    Ingest.run(
        ledger,
        { kind = "boards", data = boards },
        { path = target }
    )

    Store.save(ledger_path, ledger)
end

return M
