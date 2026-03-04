-- core/schema/fields/transaction.lua
--
-- Transaction Meta Definition Space
--
-- Authoritative semantic definition for canonical transaction objects.
-- Pure structural + semantic governance.
-- No ingestion logic.
-- No workflow routing.
-- No persistence logic.

local Transaction = {}

---@type table<string, FieldRecord>
Transaction.FIELD = {

    ------------------------------------------------------------
    -- Identity
    ------------------------------------------------------------

    TRANSACTION_ID = {
        kind        = "field",
        domain      = "transaction",
        name        = "transaction_id",
        type        = "symbol",
        required    = true,
        default     = nil,
        authority   = "system",
        mutable     = false,
        groups      = { "identity" },
        description = "Unique transaction identifier.",
    },

    ------------------------------------------------------------
    -- Classification
    ------------------------------------------------------------

    TYPE = {
        kind        = "field",
        domain      = "transaction",
        name        = "type",
        type        = "symbol",
        required    = true,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        reference   = "transaction.type",
        groups      = { "classification" },
        description = "Transaction classification.",
    },

    DATE = {
        kind        = "field",
        domain      = "transaction",
        name        = "date",
        type        = "string",
        required    = true,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        groups      = { "temporal" },
        description = "Transaction date.",
    },

    ------------------------------------------------------------
    -- References
    ------------------------------------------------------------

    ORDER_ID = {
        kind        = "field",
        domain      = "transaction",
        name        = "order_id",
        type        = "symbol",
        required    = false,
        default     = nil,
        authority   = "system",
        mutable     = true,
        groups      = { "relationship" },
        description = "Associated order identifier.",
    },

    CLIENT_ID = {
        kind        = "field",
        domain      = "transaction",
        name        = "client_id",
        type        = "symbol",
        required    = false,
        default     = nil,
        authority   = "system",
        mutable     = true,
        groups      = { "relationship" },
        description = "Associated client identifier.",
    },

    INVOICE_ID = {
        kind        = "field",
        domain      = "transaction",
        name        = "invoice_id",
        type        = "symbol",
        required    = false,
        default     = nil,
        authority   = "system",
        mutable     = true,
        groups      = { "relationship" },
        description = "Associated invoice identifier.",
    },

    ITEM_IDS = {
        kind        = "field",
        domain      = "transaction",
        name        = "item_ids",
        type        = "table",
        required    = false,
        default     = nil,
        authority   = "system",
        mutable     = true,
        groups      = { "composition" },
        description = "List of related board identifiers.",
    },

    ------------------------------------------------------------
    -- Financial
    ------------------------------------------------------------

    VALUE = {
        kind        = "field",
        domain      = "transaction",
        name        = "value",
        type        = "number",
        required    = true,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "usd",
        precision   = 2,
        groups      = { "financial", "metrics" },
        description = "Transaction monetary value (USD).",
    },

    TOTAL_BF = {
        kind        = "field",
        domain      = "transaction",
        name        = "total_bf",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "derived",
        mutable     = false,
        unit        = "board_feet",
        precision   = 3,
        groups      = { "metrics", "volume" },
        description = "Total board feet affected.",
    },

    ------------------------------------------------------------
    -- Metadata
    ------------------------------------------------------------

    NOTES = {
        kind        = "field",
        domain      = "transaction",
        name        = "notes",
        type        = "string",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        groups      = { "annotation" },
        description = "Optional transaction notes.",
    },

    SNAPSHOT = {
        kind        = "field",
        domain      = "transaction",
        name        = "snapshot",
        type        = "table",
        required    = false,
        default     = nil,
        authority   = "archival",
        mutable     = false,
        groups      = { "archival" },
        description = "Structured snapshot of contextual data.",
    },

}

return Transaction
