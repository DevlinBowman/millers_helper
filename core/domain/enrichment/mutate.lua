-- core/domain/enrichment/mutate.lua

local Formula = require("core.formula")

local Mutator = {}

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function round2(value)
    return math.floor((value * 100) + 0.5) / 100
end

local function apply_board_patch(board, fields)

    for key, value in pairs(fields or {}) do
        board[key] = value
    end

    ------------------------------------------------
    -- pricing derived fields
    ------------------------------------------------

    if fields.bf_price ~= nil then

        local f = Formula.board(board)

        -- normalize base price
        board.bf_price = round2(board.bf_price)

        -- derive prices from normalized bf
        board.ea_price = round2(f:bf_to_ea(board.bf_price))
        board.lf_price = round2(f:bf_to_lf(board.bf_price))

        -- batch totals
        board.batch_price =
            round2(board.ea_price * (board.ct or 1))

    end

end

local function apply_patch(object, patch)
    local changes = patch.changes or {}

    --------------------------------------------------------
    -- boards
    --------------------------------------------------------

    if changes.boards then
        for index, fields in pairs(changes.boards) do
            local board = object.boards and object.boards[index]

            if board then
                apply_board_patch(board, fields)
            end
        end
    end

    --------------------------------------------------------
    -- generic top-level fields
    --------------------------------------------------------

    for key, value in pairs(changes) do
        if key ~= "boards" then
            object[key] = value
        end
    end
end

------------------------------------------------------------
-- public
------------------------------------------------------------

function Mutator.apply(object, patches)
    for _, patch in ipairs(patches or {}) do
        apply_patch(object, patch)
    end
end

return Mutator
