local Schema = {}

function Schema.validate(batch)
    assert(type(batch.boards) == "table", "Invoice requires boards")
    assert(type(batch.order) == "table", "Invoice requires order")
    assert(batch.transaction_id, "Invoice requires transaction_id")
end

return Schema
