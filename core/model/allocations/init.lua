-- core/model/allocations/init.lua
--
-- Public module surface.

local Controller = require("core.model.allocations.controller")
local Registry   = require("core.model.allocations.registry")

return {
    controller = Controller,
    registry   = Registry,
}
