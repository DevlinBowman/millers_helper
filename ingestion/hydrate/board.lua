-- ingestion/hydrate/board.lua
local Board = require("core.board.board")

local Hydrate = {}

function Hydrate.boards(board_specs)
    assert(
        board_specs.kind == "board_specs",
        "Hydrate.boards(): expected kind 'board_specs'"
    )

    local out = {}

    for i, spec in ipairs(board_specs.data) do
        local ok, board = pcall(Board.new, spec)
        if not ok then
            error(string.format(
                "Board hydration failed at index %d: %s",
                i,
                board
            ))
        end
        out[#out + 1] = board
    end

    return {
        kind = "boards",
        data = out,
        meta = board_specs.meta,
    }
end

return Hydrate
