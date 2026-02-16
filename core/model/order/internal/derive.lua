local Derive = {}

--- Derive recalculable order fields.
--- Rules for value:
---   • If order.value is a non-zero number → keep it.
---   • Else, if boards exist → sum batch_price.
---   • Ensure final value is numeric (default 0).
---
--- @param order table
--- @param boards table[]|nil
--- @return table order
function Derive.run(order, boards)

    assert(type(order) == "table", "Order.derive(): order table required")

    ------------------------------------------------------------
    -- 1. Keep explicit non-zero numeric value
    ------------------------------------------------------------

    if type(order.value) == "number" and order.value ~= 0 then
        return order
    end

    ------------------------------------------------------------
    -- 2. Attempt board-based calculation
    ------------------------------------------------------------

    local total = 0
    local found = false

    if type(boards) == "table" then
        for _, board in ipairs(boards) do
            if board and type(board.batch_price) == "number" then
                total = total + board.batch_price
                found = true
            end
        end
    end

    if found then
        order.value = total
        return order
    end

    ------------------------------------------------------------
    -- 3. Fallback: ensure numeric
    ------------------------------------------------------------

    if type(order.value) ~= "number" then
        order.value = 0
    end

    return order
end

return Derive
