-- cli/domains/boards/invoice.lua
--
-- Generate an invoice from a board file.

local M = {}

M.help = {
    summary = "Generate an invoice from a board file",
    usage   = "boards invoice <file.csv>",
    examples = {
        "boards invoice order.csv",
    },
}

function M.run(ctx, controller)
    return controller:invoice(ctx)
end

return M
