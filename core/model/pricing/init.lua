-- core/model/pricing/init.lua
--
-- Public module surface.

local Controller = require("core.model.pricing.controller")
local Registry   = require("core.model.pricing.registry")

return {
    controller = Controller,
    registry   = Registry,
}
