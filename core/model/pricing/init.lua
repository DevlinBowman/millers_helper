-- core/model/pricing/init.lua
--
-- Public model surface.

local Controller = require("core.model.pricing.controller")
local Result     = require("core.model.pricing.result")
local Registry   = require("core.model.pricing.registry")

return {
    controller = Controller,
    result     = Result,
    registry   = Registry,
}
