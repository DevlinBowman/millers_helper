-- parsers/raw_text/registry.lua
--
-- Capability surface for raw_text.
-- ARC-SCHEMA COMPLIANT:
--   • No logic
--   • No orchestration
--   • Only internal exposure

local Registry = {}

Registry.internal = {
    preprocess = require("platform.parsers.raw_text.internal.preprocess"),
}

return Registry
