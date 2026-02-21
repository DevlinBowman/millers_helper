-- parsers/pipelines/text_engine/init.lua
--
-- Module entrypoint for text_engine.
-- PURPOSE:
--   • Stable import surface
--   • Expose controller + registry only (arc-schema)

local Registry   = require("platform.parsers.pipelines.text_engine.registry")
local Controller = require("platform.parsers.pipelines.text_engine.controller")

return {
    controller = Controller,
    registry   = Registry,
}
