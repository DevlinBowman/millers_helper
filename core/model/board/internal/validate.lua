-- core/model/board/validate.lua

local Validate = {}

function Validate.run(board)
    assert(type(board) == "table", "Board.validate(): board required")

    assert(type(board.base_h) == "number" and board.base_h > 0, "base_h must be > 0")
    assert(type(board.base_w) == "number" and board.base_w > 0, "base_w must be > 0")
    assert(type(board.l) == "number" and board.l > 0, "l must be > 0")
    assert(type(board.ct) == "number" and board.ct > 0, "ct must be > 0")

    return board
end

return Validate
