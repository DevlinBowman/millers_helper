-- core/values/order_status.lua
--
-- Canonical order lifecycle statuses.

local Status = {}

---@type StandardRecord[]
Status.VALUE = {

    OPEN = {
        kind        = "value",
        domain      = "order.status",
        name        = "open",
        type        = "symbol",
        description = "Order is active and not finalized.",
        aliases     = { "OPEN" },
    },

    CLOSED = {
        kind        = "value",
        domain      = "order.status",
        name        = "closed",
        type        = "symbol",
        description = "Order is finalized and complete.",
        aliases     = { "CLOSED" },
    },

    VOID = {
        kind        = "value",
        domain      = "order.status",
        name        = "void",
        type        = "symbol",
        description = "Order has been invalidated or canceled.",
        aliases     = { "VOID", "canceled", "cancelled" },
    },
}

return Status
