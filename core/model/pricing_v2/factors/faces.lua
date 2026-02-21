-- core/model/pricing_v2/factors/faces.lua

local FacesFactor = {}
FacesFactor.id = "faces"

local Width      = require("core.model.pricing_v2.factors.width")
local Height     = require("core.model.pricing_v2.factors.height")
local WasteFaces = require("core.model.pricing_v2.factors.waste_faces")

local function safe_number(value, fallback)
  local n = tonumber(value)
  if n == nil then return fallback end
  return n
end

function FacesFactor.evaluate(face, opts)
  local w_in = safe_number((face or {}).w or (face or {}).width_in, nil)
  local h_in = safe_number((face or {}).h or (face or {}).height_in, nil)

  local w_res = Width.evaluate(w_in)
  local h_res = Height.evaluate(h_in)
  local waste_res = WasteFaces.evaluate({ h = h_in, w = w_in }, opts)

  local total =
      safe_number(w_res.multiplier_total, 1.0)
    * safe_number(h_res.multiplier_total, 1.0)
    * safe_number(waste_res.multiplier, 1.0)

  return {
    ok =
      (w_res.ok ~= false)
      and (h_res.ok ~= false)
      and (waste_res.ok ~= false),

    input = {
      width_in = w_in,
      height_in = h_in,
    },

    width  = w_res,
    height = h_res,
    waste  = waste_res,

    multiplier_total = total,
  }
end

return FacesFactor
