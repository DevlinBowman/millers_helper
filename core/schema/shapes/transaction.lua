-- core/shapes/transaction.lua
--
-- transaction Shape Declaration

local Transaction = {}

Transaction.SHAPE = {
    domain = "transaction",
    fields = {
        "transaction_id",
        "type",
        "date",
        "order_id",
        "client_id",
        "invoice_id",
        "item_ids",
        "value",
        "total_bf",
        "notes",
        "snapshot",
    }
}

return Transaction
