-- core/domain/compare/internal/input_single.lua
--
-- Adapter: single board → compare input
-- No order context.
-- Produces canonical compare input envelope.

local M = {}

--- @param order_board table  -- canonical runtime board
--- @param sources table[]    -- { { name=string, boards=table[] } }
--- @return table compare_input
function M.from_single(order_board, sources)
    assert(type(order_board) == "table", "order_board required")
    assert(type(sources) == "table", "sources table required")

    local normalized_sources = {}

    for i, src in ipairs(sources) do
        assert(type(src) == "table", "sources[" .. i .. "] must be table")
        assert(type(src.name) == "string", "sources[" .. i .. "].name required")
        assert(type(src.boards) == "table", "sources[" .. i .. "].boards required")

        normalized_sources[#normalized_sources + 1] = {
            name   = src.name,
            boards = src.boards,
        }
    end

    return {
        order = {
            id     = order_board.id or "single",
            boards = { order_board }, -- <-- wrapped as 1-item list
        },
        sources = normalized_sources,
    }
end

return M
