-- interface/domains/boards/inspect.lua
--
-- Inspect board capture summary.

local M = {}

M.help = {
    summary = "Inspect board data without committing",
    usage   = "boards inspect <file...>",
    examples = {
        "boards inspect orders/job_12.csv",
    },
}

function M.run(ctx, controller)
    return controller:inspect(ctx)
end

return M
