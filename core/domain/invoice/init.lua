-- core/domain/invoice/init.lua

local Controller = require("core.domain.invoice.controller")
local Registry   = require("core.domain.invoice.registry")

return {
    controller = Controller,
    registry   = Registry,
}
