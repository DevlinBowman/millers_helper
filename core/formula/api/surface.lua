-- core/formula/api/surface.lua

---@diagnostic disable: unused-local
local _types = require("core.formula.api.types_generated")

--
-- Formula Public API Surface
--
-- Responsibilities
--   • expose formula domains
--   • provide stable LSP surface
--
-- Domains
--
--   board   → board dimensional formulas
--   math    → generic mathematical helpers

---@class FormulaAPI
---@field board FormulaBoardSurface
---@field math FormulaMathAPI
local Surface = {}

Surface.board = require("core.formula.board.api.surface")
Surface.math  = require("core.formula.math.api.surface")

return Surface
