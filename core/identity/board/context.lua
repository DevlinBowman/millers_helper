-- core/identity/board/context.lua

local Build = require("core.identity.board.label.build")

local Context = {}
Context.__index = Context

------------------------------------------------
-- constructor
------------------------------------------------

function Context.new(board)

    assert(type(board) == "table", "Identity.board.label(): board table required")

    return setmetatable({
        board = board
    }, Context)
end

------------------------------------------------
-- helpers
------------------------------------------------

local function require_field(board, field, method)

    if board[field] == nil then
        error(
            string.format(
                "Identity.board.label(): %s requires board.%s",
                method,
                field
            ),
            3
        )
    end
end

------------------------------------------------
-- full canonical label
------------------------------------------------

---Build full canonical board label.
---
---Output:
---`1x6x12n x19 RW CC KD S4S`
---
---@return string
function Context:full()

    require_field(self.board, "base_h", "full()")
    require_field(self.board, "base_w", "full()")
    require_field(self.board, "l", "full()")

    return Build.full(self.board)
end

------------------------------------------------
-- shorthand
------------------------------------------------

---Build shorthand dimension label.
---
---Output:
---`1x6x12n`
---
---@return string
function Context:short()

    require_field(self.board, "base_h", "short()")
    require_field(self.board, "base_w", "short()")
    require_field(self.board, "l", "short()")

    return Build.short(self.board)
end

------------------------------------------------
-- dimension + count
------------------------------------------------

---Build dimension + count label.
---
---Output:
---`1x6x12n x19`
---
---@return string
function Context:count()

    require_field(self.board, "ct", "count()")

    return Build.count(self.board)
end

------------------------------------------------
-- full label without count
------------------------------------------------

---Build full canonical label excluding count.
---
---Output:
---`1x6x12n RW CC KD S4S`
---
---@return string
function Context:no_count()

    require_field(self.board, "base_h", "no_count()")
    require_field(self.board, "base_w", "no_count()")
    require_field(self.board, "l", "no_count()")

    return Build.no_count(self.board)
end

------------------------------------------------
-- dimension + species
------------------------------------------------

---Build dimension + species label.
---
---Output:
---`1x6x12n RW`
---
---@return string
function Context:species()

    require_field(self.board, "species", "species()")

    return Build.species(self.board)
end

------------------------------------------------
-- commercial label
------------------------------------------------

---Build commercial label (dimension + count + commercial codes).
---
---Output:
---`1x6x12n x19 RW CC KD`
---
---@return string
function Context:commercial()

    return Build.commercial(self.board)
end

------------------------------------------------
-- delivered label
------------------------------------------------

---Build delivered dimension label (uses h/w instead of base_h/base_w).
---
---Output:
---`0.75x5.5x12 x19 RW CC KD S4S`
---
---@return string
function Context:delivered()

    require_field(self.board, "h", "delivered()")
    require_field(self.board, "w", "delivered()")
    require_field(self.board, "l", "delivered()")

    return Build.delivered(self.board)
end

------------------------------------------------
-- custom builder
------------------------------------------------

---Build custom label from token list.
---
---Example:
---```lua
---label:custom{
---    "dimension",
---    "species"
---}
---```
---
---@param tokens string[]
---@return string
function Context:custom(tokens)

    assert(type(tokens) == "table",
        "Identity.board.label(): custom() requires token list")

    return Build.custom(self.board, tokens)
end

return Context
