-- cli/domains/ledger/export.lua
--
-- Ledger export command adapter.
--
-- Responsibilities:
--   • Define the CLI interface for `ledger export`
--   • Declare expected arguments and help text
--   • Delegate execution to the ledger controller
--
-- All export behavior lives in the controller and ledger services.

local M = {}

M.help = {
    summary = "Export ledger board data to CSV",
    usage   = "ledger export <ledger> <csv>",
    examples = {
        "ledger export data/ledger.lua out.csv",
    },
}

function M.run(ctx, controller)
    return controller:export(ctx)
end

return M
