-- parsers/pipelines/text_engine/registry.lua
--
-- Capability surface only.
-- No orchestration.

local Registry = {}

----------------------------------------------------------------
-- Internal capabilities
----------------------------------------------------------------

Registry.internal = {
    preprocess  = require("platform.parsers.pipelines.text_engine.internal.preprocess"),
    capture     = require("platform.parsers.pipelines.text_engine.internal.capture"),
    repair_gate = require("platform.parsers.pipelines.text_engine.internal.repair_gate"),
    token_usage = require("platform.parsers.pipelines.text_engine.internal.token_usage"),
    stable_spans= require("platform.parsers.pipelines.text_engine.internal.stable_spans"),
    diagnostics = require("platform.parsers.pipelines.text_engine.internal.diagnostics"),
}

return Registry
