-- format/registry.lua
--
-- Internal format facade.
-- Stable surface for domain systems.
-- No orchestration. No IO. No guessing.

local Registry = {}

Registry.records = {
    from_table = require("format.records.from_table"),
    from_json  = require("format.records.from_json"),
    from_lines = require("format.records.from_lines"),
}

Registry.validate = {
    input = require("format.validate.input"),
}

return Registry
