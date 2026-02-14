-- core/model/board/build.lua
--
-- Pure board domain builder.
-- Consumes already-classified board context.

local Coerce   = require("core.model.board.coerce")
local Validate = require("core.model.board.validate")
local Derive   = require("core.model.board.derive")
local Identity = require("core.model.board.identity")

local Build = {}

function Build.run(ctx)
    assert(type(ctx) == "table", "Board.build(): context table required")

    local board = Coerce.run(ctx)
    Validate.run(board)
    board = Derive.run(board)

    local id, label = Identity.generate(board)
    board.id    = id
    board.label = label

    return board
end

return Build
