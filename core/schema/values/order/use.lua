-- core/values/order_use.lua
--
-- Canonical order intent classifications.

local Use = {}

---@type StandardRecord[]
Use.VALUE = {

    SALE = {
        kind        = "value",
        domain      = "order.use",
        name        = "sale",
        type        = "symbol",
        description = "Standard commercial transaction generating revenue.",
        aliases     = { "SALE" },
    },

    PERSONAL = {
        kind        = "value",
        domain      = "order.use",
        name        = "personal",
        type        = "symbol",
        description = "Internal or personal use without revenue intent.",
        aliases     = { "PERSONAL" },
    },

    GIFT = {
        kind        = "value",
        domain      = "order.use",
        name        = "gift",
        type        = "symbol",
        description = "Material transferred without financial compensation.",
        aliases     = { "GIFT" },
    },

    WASTE = {
        kind        = "value",
        domain      = "order.use",
        name        = "waste",
        type        = "symbol",
        description = "Material written off due to defect or loss.",
        aliases     = { "WASTE" },
    },

    TRANSFER = {
        kind        = "value",
        domain      = "order.use",
        name        = "transfer",
        type        = "symbol",
        description = "Internal transfer between accounts or ledgers.",
        aliases     = { "TRANSFER" },
    },

    ADJUSTMENT = {
        kind        = "value",
        domain      = "order.use",
        name        = "adjustment",
        type        = "symbol",
        description = "Manual correction or ledger adjustment entry.",
        aliases     = { "ADJUST", "ADJUSTMENT" },
    },
}

return Use
