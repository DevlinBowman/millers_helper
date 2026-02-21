-- parsers/registry.lua
--
-- Authoritative registry for parsers domain.
-- PURPOSE:
--   • Provide full internal public surface
--   • Avoid deep requires outside this boundary

local Registry = {}

Registry.raw_text = {
    preprocess = require("platform.parsers.raw_text.internal.preprocess"),
}

Registry.text_pipeline = require("platform.parsers.pipelines.text")

Registry.board_data = require("platform.parsers.board_data").registry

return Registry
