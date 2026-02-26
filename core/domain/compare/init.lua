-- core/domain/compare/init.lua
--
-- Public module surface (arc-spec).
--
-- Exposes:
--   compare.controller
--   compare.registry
--   compare.result

local Controller = require("core.domain.compare.controller")
local Registry   = require("core.domain.compare.registry")
local Result     = require("core.domain.compare.result")

return {
    controller = Controller,
    registry   = Registry,
    result     = Result,
}
