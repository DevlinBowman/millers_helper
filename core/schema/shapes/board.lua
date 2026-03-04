-- core/shapes/board.lua
--
-- Board Shape
-- Membership only.
-- No structure definitions.

local Board = {}

Board.SHAPE = {
    domain = "board",
    fields = {
        "base_h",
        "base_w",
        "l",
        "ct",
        "grade",
        "species",
        "moisture",
        "surface",
        "tag",
        "bf_ea",
        "bf_batch",
        "bf_per_lf",
        "bf_price",
        "ea_price",
        "lf_price",
    }
}

return Board
