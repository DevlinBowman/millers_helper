-- core/identity/api/board.lua
--
-- Board identity API surface.

local Context = require("core.identity.board.context")
local Parse   = require("core.identity.board.label.parse")
local Normalize = require("core.identity.board.label.normalize")

local Board = {}

------------------------------------------------
-- label builder
------------------------------------------------

---Create board label builder context.
---
---@param board table
---@return table
function Board.label(board)
    return Context.new(board)
end

------------------------------------------------
-- label parsing
------------------------------------------------

---Parse board label string into specification table.
---
---Example:
---`ID.board.parse("1x6x12n x19 RW CC KD")`
---
---@param label string
---@return table spec
function Board.parse(label)
    return Parse.run(label)
end

------------------------------------------------
-- label normalization
------------------------------------------------

function Board.normalize(label)
    return Normalize.run(label)
end

return Board
