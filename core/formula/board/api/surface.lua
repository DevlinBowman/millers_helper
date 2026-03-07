-- core/formula/board/api/surface.lua

---@diagnostic disable: unused-local
local _types = require("core.formula.board.api.types_generated")
--
-- Board Formula Public API Surface
--
-- This file defines the canonical entrypoint used by consumers.
--
-- Responsibilities
--   • Provide stable namespace for board formula capabilities
--   • Bind board context to formula operations
--   • Provide discoverable LSP surface
--
-- Concept
--
--   Formula.board(board) returns a bound calculation context.
--
-- Example
--
--   local Formula = require("core.formula")
--   local f = Formula.board(board)
--
--   local bf = f:bf()
--   local ea = f:bf_to_ea(4.25)
--   local kerf = f:kerf(0.125)

local Context = require("core.formula.board.api.context")

---@class FormulaBoardSurface
local Surface = {}

------------------------------------------------
-- constructor
------------------------------------------------

---Create a bound board formula context.
---
---Example:
---  local f = Surface(board)
---
---@param board table
---@return FormulaBoardContext
function Surface.new(board)
    return Context.new(board)
end

setmetatable(Surface, {
    __call = function(_, board)
        return Surface.new(board)
    end,
})

return Surface
