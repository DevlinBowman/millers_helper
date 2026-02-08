-- cli/domains/boards/compare.lua
--
-- Compare an order against one or more offer files.

local M = {}

M.help = {
    summary = "Compare an order against vendor offers",
    usage   = "boards compare <order.csv> <offer.csv...> [options]",
    options = {
        { "-o, --output <path>", "Write output to file (default: stdout)" },
        { "-f, --format <fmt>",  "Output format: text | json" },
    },
}

function M.run(ctx, controller)
    return controller:compare(ctx)
end

return M
