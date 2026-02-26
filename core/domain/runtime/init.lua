-- core/domain/runtime/init.lua
--
-- Public module surface (arc-spec).
--
-- Exposes:
--   runtime.controller
--   runtime.result

local Controller = require("core.domain.runtime.controller")
local Result     = require("core.domain.runtime.result")

return {
    controller = Controller,
    result     = Result,
}
