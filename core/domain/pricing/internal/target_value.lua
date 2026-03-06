local TargetValue = {}

local function first_number(...)
    local values = { ... }

    for i = 1, #values do
        if type(values[i]) == "number" then
            return values[i]
        end
    end

    return nil
end

function TargetValue.resolve(source, opts)
    opts = opts or {}

    local explicit_value = opts.target_total_value
    if type(explicit_value) == "number" then
        return explicit_value, "opts.target_total_value"
    end

    if type(source) ~= "table" then
        return nil, "[pricing.reverse_order_value] source table required"
    end

    local order = source.order
    if type(order) ~= "table" then
        return nil, "[pricing.reverse_order_value] source.order required when opts.target_total_value is absent"
    end

    local resolved_value = first_number(
        order.value,
        order.total_value,
        order.amount,
        order.total,
        order.price
    )

    if type(resolved_value) ~= "number" then
        return nil, "[pricing.reverse_order_value] unable to resolve order total value"
    end

    return resolved_value, "source.order"
end

return TargetValue
