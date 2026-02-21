-- core/model/pricing_v2/factors/width.lua

local Engine     = require("core.model.pricing_v2.factors._dimension_engine")
local NominalMap = require("core.formula.board.nominal_map")

local WidthFactor = {}
WidthFactor.id = "width"

WidthFactor.config = {
  min_value = 2.0,
  baseline_value = 6.0,
  max_value = 12.0,

  min_component_multiplier = 0.75,
  max_component_multiplier = 1.30,
  min_total_multiplier = 0.85,
  max_total_multiplier = 2.50,

  components = {
    production_time = {
      enabled = true,
      below_max_bump_at_min = 0.10,
      below_power = 1.2,
      above_max_cut_at_max = 0.06,
      above_power = 1.1,
    },

    scarcity = {
      enabled = true,
      below_max_cut_at_min = 0.04,
      below_power = 1.2,
      above_max_bump_at_max = 0.55,
      above_power = 1.8,
    },

    waste_pressure = {
      enabled = false,
      below_max_bump_at_min = 0.06,
      below_power = 1.6,
      above_max_cut_at_max = 0.03,
      above_power = 1.3,
    },
  },

  nominal = {
    enabled = true,

    nominal_values = function()
      local values = {}
      for _, v in pairs(NominalMap.FACE or {}) do
        values[#values + 1] = v
      end
      table.sort(values)
      return values
    end,

    max_bump_at_max = 0.15,
    distance_power  = 1.3,
    domain_power    = 1.1,
  },
}

function WidthFactor.evaluate(width_in)
  return Engine.evaluate(width_in, WidthFactor.config)
end

return WidthFactor
