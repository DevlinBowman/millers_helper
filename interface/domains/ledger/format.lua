local M = {}

function M.money(v)
    return string.format("$%.2f", tonumber(v or 0) or 0)
end

function M.order_number(order)
    order = order or {}
    return order.order_number or order.order_id or order.id or "unknown"
end

function M.print_index(txns)

    print("")
    print("ID            | DATE       | TYPE     | BF       | VALUE")
    print(string.rep("-", 60))

    for _, t in ipairs(txns) do
        print(string.format(
            "%-13s | %-10s | %-8s | %-8s | %s",
            tostring(t.transaction_id),
            tostring(t.date),
            tostring(t.type),
            tostring(t.total_bf or 0),
            M.money(t.value)
        ))
    end

    print("")
    print("transactions:", #txns)
end

return M
