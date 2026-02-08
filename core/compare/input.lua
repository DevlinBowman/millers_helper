-- presentation/exports/compare/input.lua
--
-- Adapts BoardCapture into Compare input contract.
-- Ensures boards are in the same grouped Board shape used by invoice.

local M = {}

local function ensure_grouped_board(b)
    if type(b) ~= "table" then return b end
    if type(b.physical) == "table" and type(b.pricing) == "table" then
        return b
    end

    local Board = require("core.board.board")
    return Board.new(b)
end

local function ensure_grouped_boards(list)
    local out = {}
    for _, b in ipairs(list or {}) do
        out[#out + 1] = ensure_grouped_board(b)
    end
    return out
end

function M.build_input(capture, order, opts)
    opts = opts or {}

    assert(type(capture) == "table", "capture required")
    assert(type(order) == "table", "order required")
    assert(type(order.boards) == "table", "order.boards required")

    local sources = {}

    for _, src in ipairs(capture.sources or {}) do
        sources[#sources + 1] = {
            name   = (opts.name_map and opts.name_map[src.source_id]) or src.source_id,
            boards = ensure_grouped_boards((src.boards and src.boards.data) or {}),
        }
    end

    return {
        order = {
            id     = order.id,
            boards = ensure_grouped_boards(order.boards),
        },
        sources = sources,
    }
end

return M
