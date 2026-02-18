-- core/model/allocations/internal/format.lua
--
-- Pure string formatter for cost surface.
-- Returns string. Does NOT print.

local Format = {}

local function fmt(n)
    return string.format("%.2f", n or 0)
end

function Format.cost_surface(surface)

    assert(type(surface) == "table", "Format.cost_surface(): surface required")

    local out = {}

    table.insert(out, "\n==============================")
    table.insert(out, "COST SURFACE")
    table.insert(out, "==============================\n")

    table.insert(out, string.format("Total BF:      %s", fmt(surface.total_bf)))
    table.insert(out, string.format("Board Cost:    %s", fmt(surface.board_cost)))
    table.insert(out, string.format("Order Cost:    %s", fmt(surface.order_cost)))
    table.insert(out, string.format("Total Cost:    %s", fmt(surface.total_cost)))
    table.insert(out, string.format("Cost / BF:     %s\n", fmt(surface.cost_per_bf)))

    table.insert(out, "Line Items:")

    for _, line in ipairs(surface.line_items or {}) do
        table.insert(out,
            string.format(
                "  %-10s %-12s %-12s %8s × %8s = %8s",
                line.scope,
                line.party,
                line.category,
                fmt(line.rate),
                fmt(line.quantity),
                fmt(line.total)
            )
        )
    end

    table.insert(out, "\nParty Totals:")

    for party, total in pairs(surface.party_totals or {}) do
        table.insert(out,
            string.format("  %-15s %10s", party, fmt(total))
        )
    end

    table.insert(out, "\nCategory Totals:")

    for category, total in pairs(surface.category_totals or {}) do
        table.insert(out,
            string.format("  %-15s %10s", category, fmt(total))
        )
    end

    table.insert(out, "\n==============================\n")

    return table.concat(out, "\n")
end

return Format
