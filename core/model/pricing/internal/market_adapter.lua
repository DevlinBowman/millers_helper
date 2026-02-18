-- core/model/pricing/internal/market_adapter.lua
--
-- Adapts canonical board batches into pricing match bundle.

local Adapter = {}

function Adapter.from_load_batches(batches)

    assert(type(batches) == "table", "market_adapter: batches required")

    local items = {}

    for _, batch in ipairs(batches) do
        local boards = batch.boards or {}

        for _, b in ipairs(boards) do

            -- Prefer bf_price; fallback to ea_price if needed
            local retail_bf_price = b.bf_price
            local retail_ea_price = b.ea_price

            if not retail_bf_price and retail_ea_price and b.bf_ea then
                retail_bf_price = retail_ea_price / b.bf_ea
            end

            if retail_bf_price and retail_bf_price > 0 then
                table.insert(items, {
                    label = b.label,
                    retail_bf_price = retail_bf_price,
                    retail_ea_price = retail_ea_price,
                })
            end
        end
    end

    return { items = items }
end

return Adapter
