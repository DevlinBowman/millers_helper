-- parsers/raw_text/init.lua
--
-- Module entrypoint for raw_text.
-- ARC-SCHEMA COMPLIANT:
--   • Stable import surface
--   • Expose controller + registry only

local Registry   = require("platform.parsers.raw_text.registry")
local Controller = require("platform.parsers.raw_text.controller")

return {
    controller = Controller,
    registry   = Registry,
}
