-- cli/domains/ledger/ingest.lua
--
-- Ledger ingest command adapter.
--
-- Responsibilities:
--   • Define the CLI interface for `ledger ingest`
--     (args, flags, help text, examples)
--   • Delegate execution to the ledger controller
--
-- This file contains NO ingestion logic.
-- It exists solely to describe the user-facing interface.

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

function M.run(ctx, controller)
    return controller:ingest(ctx)
end

return M
