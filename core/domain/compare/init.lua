-- core/domain/compare/init.lua
--
-- Public module surface (arc-spec).
--
-- Exposes:
--   compare.controller
--   compare.registry

local Controller = require("core.domain.compare.controller")
local Registry   = require("core.domain.compare.registry")

return {
    controller = Controller,
    registry   = Registry,
}
