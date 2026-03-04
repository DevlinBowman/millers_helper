-- core/schema/shapes/order.lua
--
-- Order Shape
-- Membership only.

local Order = {}

Order.SHAPE = {
    domain = "order",
    fields = {
        "order_id",
        "order_number",
        "client_id",
        "date",
        "order_status",
        "use",
        "value",
        "order_notes",
        "items",
    }
}

return Order
