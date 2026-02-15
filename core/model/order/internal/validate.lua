local Validate = {}

function Validate.run(order)
    assert(type(order) == "table", "Order.validate(): order required")
    return order
end

return Validate
