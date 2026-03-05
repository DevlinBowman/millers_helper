-- core/domain/pricing/init.lua
--
-- Public module surface (arc-spec).

local Controller = require("core.domain.pricing.controller")
local Registry   = require("core.domain.pricing.registry")
local Result     = require("core.domain.pricing.result")

return {
    controller = Controller,
    registry   = Registry,
    result     = Result,
}
