-- core/domain/vendor_reference/init.lua

local Controller = require("core.domain.vendor_reference.controller")
local Registry   = require("core.domain.vendor_reference.registry")
local Result     = require("core.domain.vendor_reference.result")

return {
    controller = Controller,
    registry   = Registry,
    result     = Result,
}
