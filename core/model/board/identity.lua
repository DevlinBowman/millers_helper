-- core/model/board/identity.lua

local Label = require("core.model.board.label.init")

local Identity = {}

function Identity.generate(board)
    local label = Label.generate(board)
    return label, label
end

return Identity
