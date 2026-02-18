-- core/model/allocations/internal/cost.lua
--
-- Pure cost surface expansion.
-- NO revenue. NO profit distribution.

local Cost = {}

----------------------------------------------------------------
-- Compute Cost Surface
----------------------------------------------------------------

function Cost.compute(order, boards, profile)

    assert(type(profile) == "table", "Cost.compute(): profile required")
    assert(type(boards) == "table", "Cost.compute(): boards required")

    local total_bf = 0

    for _, b in ipairs(boards) do
        total_bf = total_bf + (b.bf_batch or 0)
    end

    local board_cost = 0
    local order_cost = 0

    local party_totals = {}
    local category_totals = {}
    local line_items = {}

    for _, entry in ipairs(profile.allocations or {}) do

        --------------------------------------------------------
        -- BOARD SCOPE
        --------------------------------------------------------

        if entry.scope == "board" and entry.basis == "per_bf" then

            local cost = entry.amount * total_bf

            board_cost = board_cost + cost

            party_totals[entry.party] =
                (party_totals[entry.party] or 0) + cost

            category_totals[entry.category] =
                (category_totals[entry.category] or 0) + cost

            table.insert(line_items, {
                scope    = entry.scope,
                party    = entry.party,
                category = entry.category,
                basis    = entry.basis,
                rate     = entry.amount,
                quantity = total_bf,
                total    = cost,
            })

        --------------------------------------------------------
        -- ORDER SCOPE
        --------------------------------------------------------

        elseif entry.scope == "order" and entry.basis == "fixed" then

            local cost = entry.amount

            order_cost = order_cost + cost

            party_totals[entry.party] =
                (party_totals[entry.party] or 0) + cost

            category_totals[entry.category] =
                (category_totals[entry.category] or 0) + cost

            table.insert(line_items, {
                scope    = entry.scope,
                party    = entry.party,
                category = entry.category,
                basis    = entry.basis,
                rate     = entry.amount,
                quantity = 1,
                total    = cost,
            })
        end
    end

    local total_cost = board_cost + order_cost

    local cost_per_bf = 0
    if total_bf > 0 then
        cost_per_bf = total_cost / total_bf
    end

    return {
        total_bf        = total_bf,
        board_cost      = board_cost,
        order_cost      = order_cost,
        total_cost      = total_cost,
        cost_per_bf     = cost_per_bf,
        party_totals    = party_totals,
        category_totals = category_totals,
        line_items      = line_items,
    }
end

return Cost
