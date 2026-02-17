local Registry = require("core.domain.ledger.registry")

local FromIngest = {}

local function normalize(input)
    local batches = input

    -- envelope
    if type(batches) == "table"
        and batches.data
        and type(batches.data) == "table"
    then
        batches = batches.data
    end

    -- single group
    if type(batches) == "table"
        and batches.order
        and batches.boards
    then
        batches = { batches }
    end

    return batches
end

function FromIngest.run(input, opts)
    opts = opts or {}

    local batches = normalize(input)
    local transactions = {}

    for _, batch in ipairs(batches or {}) do
        local txn_id = Registry.identity.from_batch(batch)

        local total_bf = 0
        local item_ids = {}

        for _, b in ipairs(batch.boards or {}) do
            total_bf = total_bf + (b.bf_batch or 0)
            if b.id then
                item_ids[#item_ids + 1] = b.id
            end
        end

        local entry = Registry.build.run({
            transaction_id = txn_id,
            type           = batch.order.use or "sale",
            date           = batch.order.date,
            order_id       = batch.order.order_id,
            customer_id    = batch.order.customer_id,
            value          = batch.order.value or 0,
            total_bf       = total_bf,
            item_ids       = item_ids,
            snapshot       = {
                order_number  = batch.order.order_number,
                customer_name = batch.order.customer_name,
                customer_id   = batch.order.customer_id,
                board_count   = #batch.boards,
                board_ids     = item_ids,
                value         = batch.order.value,
            }
        })

        Registry.storage.write_bundle(
            txn_id,
            entry,
            batch.order,
            batch.boards
        )

        Registry.ledger.append(entry)

        transactions[#transactions + 1] = entry
    end

    return {
        transactions = transactions,
    }
end

return FromIngest
