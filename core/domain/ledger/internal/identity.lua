local Identity = {}

local function stable_string(v)
    if v == nil then return "" end
    return tostring(v)
end

local function compute_signature_string(batch)
    local order = batch.order or {}
    local boards = batch.boards or {}

    local total_bf = 0
    local board_ids = {}

    for _, b in ipairs(boards) do
        total_bf = total_bf + (b.bf_batch or 0)
        if b.id then
            board_ids[#board_ids + 1] = b.id
        end
    end

    table.sort(board_ids)

    return table.concat({
        stable_string(order.order_number),
        stable_string(order.date),
        stable_string(order.use),
        stable_string(order.value),
        stable_string(total_bf),
        table.concat(board_ids, "|"),
    }, "::")
end

local function simple_hash(str)
    -- deterministic non-crypto hash (stable across runs)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + str:byte(i)) % 2^32
    end
    return string.format("txn_%08x", hash)
end

function Identity.from_batch(batch)
    local signature = compute_signature_string(batch)
    return simple_hash(signature)
end

return Identity
