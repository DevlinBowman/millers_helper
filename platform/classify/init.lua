-- classify/init.lua

local Controller = require("platform.classify.controller")
local Registry   = require("platform.classify.registry")

return {
    controller = Controller,
    registry   = Registry,
}
