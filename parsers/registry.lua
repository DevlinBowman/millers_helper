-- parsers/registry.lua
--
-- Authoritative registry for parsers domain.
-- PURPOSE:
--   • Provide full internal public surface
--   • Avoid deep requires outside this boundary

local Registry = {}

Registry.raw_text = {
    preprocess = require("parsers.raw_text.preprocess"),
}

Registry.text_pipeline = require("parsers.pipeline")

Registry.board_data = require("parsers.board_data").registry

return Registry
