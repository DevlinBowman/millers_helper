-- core/values/transaction/type.lua
--
-- Canonical transaction Transaction Types

local TransactionType = {}

TransactionType.VALUE = {

    SALE = {
        kind   = "value",
        domain = "transaction.type",
        name   = "sale",
        type   = "symbol",
        description = "Sale transaction reducing inventory and increasing revenue.",
    },

    PERSONAL = {
        kind   = "value",
        domain = "transaction.type",
        name   = "personal",
        type   = "symbol",
        description = "Personal use transaction.",
    },

    GIFT = {
        kind   = "value",
        domain = "transaction.type",
        name   = "gift",
        type   = "symbol",
        description = "Gift transaction.",
    },

    WASTE = {
        kind   = "value",
        domain = "transaction.type",
        name   = "waste",
        type   = "symbol",
        description = "Inventory loss or waste.",
    },

    TRANSFER = {
        kind   = "value",
        domain = "transaction.type",
        name   = "transfer",
        type   = "symbol",
        description = "Internal inventory transfer.",
    },

    ADJUSTMENT = {
        kind   = "value",
        domain = "transaction.type",
        name   = "adjustment",
        type   = "symbol",
        description = "Manual correction adjustment.",
    },

    PURCHASE = {
        kind   = "value",
        domain = "transaction.type",
        name   = "purchase",
        type   = "symbol",
        description = "Acquisition transaction increasing inventory.",
    },

    REFUND = {
        kind   = "value",
        domain = "transaction.type",
        name   = "refund",
        type   = "symbol",
        description = "Refund transaction reversing prior sale.",
    },
}

return TransactionType
