-- core/domain/enrichment/internal/enums/order.lua
--
-- Canonical order enums.
-- Used by enrichment + completeness.
-- Each entry is self-describing:
--   kind        = "key" | "value"
--   domain      = logical grouping
--   value       = canonical string
--   description = semantic meaning

local OrderEnums = {}

----------------------------------------------------------------
-- Canonical Keys
----------------------------------------------------------------

OrderEnums.KEYS = {

    ORDER_ID = {
        kind = "key",
        domain = "order.identity",
        value = "order_id",
        description = "System-level unique identifier for stored order record.",
    },

    ORDER_NUMBER = {
        kind = "key",
        domain = "order.identity",
        value = "order_number",
        description = "Primary external-facing order identifier.",
    },

    CUSTOMER_ID = {
        kind = "key",
        domain = "order.identity",
        value = "customer_id",
        description = "System-level unique identifier for the customer.",
    },

    CLIENT = {
        kind = "key",
        domain = "order.parties",
        value = "client",
        description = "Receiving party or purchaser.",
    },

    CLAIMANT = {
        kind = "key",
        domain = "order.parties",
        value = "claimant",
        description = "Initiating or responsible party for the order.",
    },

    STATUS = {
        kind = "key",
        domain = "order.lifecycle",
        value = "order_status",
        description = "Lifecycle state of the order (open, closed, void).",
    },

    DATE = {
        kind = "key",
        domain = "order.lifecycle",
        value = "date",
        description = "Transaction or effective date of the order.",
    },

    USE = {
        kind = "key",
        domain = "order.intent",
        value = "use",
        description = "Declared intent of the order (sale, personal, gift, etc.).",
    },

    VALUE = {
        kind = "key",
        domain = "order.financial",
        value = "value",
        description = "Final associated total monetary value of the order.",
    },

    NOTES = {
        kind = "key",
        domain = "order.meta",
        value = "order_notes",
        description = "Free-form notes associated with the order.",
    },

    STUMPAGE_COST = {
        kind = "key",
        domain = "order.cost",
        value = "stumpage_cost",
        description = "Total raw timber cost associated with the order.",
    },

    STUMPAGE_ORIGIN = {
        kind = "key",
        domain = "order.cost",
        value = "stumpage_origin",
        description = "Source or origin of stumpage material.",
    },
}

----------------------------------------------------------------
-- Transaction Intent Values
----------------------------------------------------------------

OrderEnums.USE = {

    SALE = {
        kind = "value",
        domain = "order.intent",
        value = "sale",
        description = "Standard commercial transaction generating revenue.",
    },

    PERSONAL = {
        kind = "value",
        domain = "order.intent",
        value = "personal",
        description = "Internal or personal use without revenue intent.",
    },

    GIFT = {
        kind = "value",
        domain = "order.intent",
        value = "gift",
        description = "Material transferred without financial compensation.",
    },

    WASTE = {
        kind = "value",
        domain = "order.intent",
        value = "waste",
        description = "Material written off due to defect or loss.",
    },

    TRANSFER = {
        kind = "value",
        domain = "order.intent",
        value = "transfer",
        description = "Internal transfer between accounts or ledgers.",
    },

    ADJUST = {
        kind = "value",
        domain = "order.intent",
        value = "adjustment",
        description = "Manual correction or ledger adjustment entry.",
    },
}

----------------------------------------------------------------
-- Status Values
----------------------------------------------------------------

OrderEnums.STATUS = {

    OPEN = {
        kind = "value",
        domain = "order.lifecycle",
        value = "open",
        description = "Order is active and not finalized.",
    },

    CLOSED = {
        kind = "value",
        domain = "order.lifecycle",
        value = "closed",
        description = "Order is finalized and complete.",
    },

    VOID = {
        kind = "value",
        domain = "order.lifecycle",
        value = "void",
        description = "Order has been invalidated or canceled.",
    },
}

----------------------------------------------------------------
-- Derived Lookup Sets
----------------------------------------------------------------

OrderEnums.USE_SET = {}
for _, def in pairs(OrderEnums.USE) do
    OrderEnums.USE_SET[def.value] = true
end

OrderEnums.STATUS_SET = {}
for _, def in pairs(OrderEnums.STATUS) do
    OrderEnums.STATUS_SET[def.value] = true
end

return OrderEnums
