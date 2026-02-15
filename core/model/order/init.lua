-- core/model/order/init.lua
--
-- Public module surface.

local Controller = require("core.model.order.controller")
local Registry   = require("core.model.order.registry")

return {
    controller = Controller,
    registry   = Registry,
}
