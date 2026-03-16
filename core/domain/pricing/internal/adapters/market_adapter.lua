-- core/model/pricing/internal/adapters/market_adapter.lua
--
-- Adapts canonical board batches into pricing match bundle.

local Adapter = {}

function Adapter.from_load_batches(batches)

    assert(type(batches) == "table",
        "market_adapter: batches required")

    local items = {}

    for _, batch in ipairs(batches) do

        local boards = batch.boards or {}

        for _, board in ipairs(boards) do

            -- vendor boards must remain canonical board objects
            items[#items + 1] = board

        end
    end

    return {
        kind  = "vendor",
        items = items
    }
end

return Adapter
