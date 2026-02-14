-- classify/init.lua

local Controller = require("classify.controller")
local Registry   = require("classify.registry")

return {
    controller = Controller,
    registry   = Registry,
}
