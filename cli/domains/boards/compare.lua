-- cli/domains/boards/compare.lua
--
-- Compare an order against one or more offer files.

local M = {}

M.help = {
    summary = "Compare an order against vendor offers",
    usage   = "boards compare <order.csv> <offer.csv> <offer.csv> ...",
    examples = {
        "boards compare order.csv vendor_a.csv vendor_b.csv",
    },
}

function M.run(ctx, controller)
    return controller:compare(ctx)
end

return M
