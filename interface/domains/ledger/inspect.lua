-- interface/domains/ledger/inspect.lua
--
-- Ledger inspection command adapter.
--
-- Responsibilities:
--   • Define the CLI interface for `ledger inspect`
--   • Expose inspection modes and flags (--keys, --describe)
--   • Delegate execution to the ledger controller
--
-- This file performs no inspection itself.
-- It is a pure interface definition.

local M = {}

M.help = {
    summary = "Inspect ledger contents",
    usage   = "ledger inspect <ledger> [options]",
    options = {
        { "-k, --keys",        "Show board and ledger key surface" },
        { "-d, --describe",    "Describe all fields or a single field" },
        { "    --describe <f>","Describe a specific field" },
    },
    examples = {
        "ledger inspect data/ledger.lua",
        "ledger inspect data/ledger.lua --keys",
        "ledger inspect data/ledger.lua --describe bf_price",
    },
}

function M.run(ctx, controller)
    return controller:inspect(ctx)
end

return M
