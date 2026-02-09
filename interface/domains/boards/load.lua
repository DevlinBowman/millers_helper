-- interface/domains/boards/load.lua
--
-- Load boards from one or more files.

local M = {}

M.help = {
    summary = "Load board data from files (no ledger)",
    usage   = "boards load <file...> [options]",
    options = {
        { "-c, --compact", "Compact warnings output" },
        { "-s, --struct",  "Print full BoardCapture structure" },
    },
    examples = {
        "boards load orders/job_12.csv",
        "boards load a.csv b.csv --struct",
    },
}

function M.run(ctx, controller)
    return controller:load(ctx)
end

return M
