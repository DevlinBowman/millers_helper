-- core/model/board/init.lua
--
-- Public module surface.

local Controller = require("core.model.board.controller")
local Registry   = require("core.model.board.registry")

return {
    controller = Controller,
    registry   = Registry,
}
