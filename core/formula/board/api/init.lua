-- core/formula/board/init.lua
--
-- Canonical board formula entrypoint.
--
-- Exposes:
--   • board.api.surface
--
-- Example:
--
--   local Formula = require("core.formula")
--   local f = Formula.board(board)

return require("core.formula.board.api.surface")
