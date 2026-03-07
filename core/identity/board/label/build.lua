local Tokens = require("core.identity.board.label.tokens")
local Schema = require("core.identity.schema")

local Build = {}

local function push(t,v)
    if v then t[#t+1] = v end
end

------------------------------------------------
-- canonical full
------------------------------------------------

function Build.full(board)

    local t = {}

    push(t, Tokens.dimension(board))
    push(t, Tokens.count(board))
    push(t, board.species)
    push(t, board.grade)
    push(t, board.moisture)
    push(t, board.surface or Schema.default("board","surface"))

    return table.concat(t," ")
end

------------------------------------------------
-- shorthand
------------------------------------------------

function Build.short(board)
    return Tokens.dimension(board)
end

------------------------------------------------
-- dimension + count
------------------------------------------------

function Build.count(board)

    return table.concat({
        Tokens.dimension(board),
        Tokens.count(board)
    }," ")
end

------------------------------------------------
-- full label without count
------------------------------------------------

function Build.no_count(board)

    local t = {}

    push(t, Tokens.dimension(board))
    push(t, board.species)
    push(t, board.grade)
    push(t, board.moisture)
    push(t, board.surface or Schema.default("board","surface"))

    return table.concat(t, " ")
end

------------------------------------------------
-- dimension + species
------------------------------------------------

function Build.species(board)

    local t = {}

    push(t, Tokens.dimension(board))
    push(t, board.species)

    return table.concat(t," ")
end

------------------------------------------------
-- commercial
------------------------------------------------

function Build.commercial(board)

    local t = {}

    push(t, Tokens.dimension(board))
    push(t, Tokens.count(board))
    push(t, board.species)
    push(t, board.grade)
    push(t, board.moisture)

    return table.concat(t," ")
end

------------------------------------------------
-- delivered
------------------------------------------------

function Build.delivered(board)

    local t = {}

    push(t, Tokens.dimension_delivered(board))
    push(t, Tokens.count(board))
    push(t, board.species)
    push(t, board.grade)
    push(t, board.moisture)
    push(t, board.surface or Schema.default("board","surface"))

    return table.concat(t," ")
end

------------------------------------------------
-- custom token builder
------------------------------------------------

function Build.custom(board, tokens)

    local t = {}

    for _,token in ipairs(tokens) do

        if token == "dimension" then
            push(t, Tokens.dimension(board))

        elseif token == "dimension_delivered" then
            push(t, Tokens.dimension_delivered(board))

        elseif token == "count" then
            push(t, Tokens.count(board))

        else
            push(t, board[token])
        end
    end

    return table.concat(t," ")
end

return Build
