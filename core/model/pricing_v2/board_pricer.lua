-- core/model/pricing_v2/board_pricer.lua
--
-- Board pricing orchestrator.
--
-- Combines:
--   • faces factor (width × height × waste)
--   • grade factor
--   • length factor
--
-- Final price:
--   baseline_price_per_bf × total_multiplier

local Faces  = require("core.model.pricing_v2.factors.faces")
local Grade  = require("core.model.pricing_v2.factors.grade")
local Length = require("core.model.pricing_v2.factors.length")

local BoardPricer = {}
BoardPricer.__index = BoardPricer

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function BoardPricer.new(opts)
  local self = setmetatable({}, BoardPricer)

  self.config = {
    baseline_price_per_bf = (opts or {}).baseline_price_per_bf or 1.0,
  }

  return self
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function BoardPricer:evaluate(board)

  local baseline = self.config.baseline_price_per_bf

  local faces_res  = Faces.evaluate(board)
  local grade_res  = Grade.evaluate(board.grade)
  local length_res = Length.evaluate(board.l, board.grade)

  local total_multiplier =
      (faces_res.multiplier_total or 1.0)
    * (grade_res.multiplier_total or 1.0)
    * (length_res.multiplier_total or 1.0)

  local final_price_per_bf = baseline * total_multiplier

  return {
    ok =
      (faces_res.ok ~= false)
      and (grade_res.ok ~= false)
      and (length_res.ok ~= false),

    baseline_price_per_bf = baseline,

    total_multiplier = total_multiplier,
    final_price_per_bf = final_price_per_bf,

    factors = {
      faces  = faces_res,
      grade  = grade_res,
      length = length_res,
    },
  }
end

return BoardPricer
