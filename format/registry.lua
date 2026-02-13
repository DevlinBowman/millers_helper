-- format/registry.lua
--
-- Internal format facade.
-- Pure capability index.
-- No orchestration.
-- No lazy loading.
-- No transform chaining logic.
--
-- Structural Rule:
--   • Registry depends on children
--   • Children MUST NOT depend on registry
--   • Strict downward dependency only

local Registry = {}

----------------------------------------------------------------
-- Validation
----------------------------------------------------------------

Registry.validate = {
    shape = require("format.validate.shape"),
}

----------------------------------------------------------------
-- Transforms (codec-shape projections)
----------------------------------------------------------------

Registry.transforms = {
    table_to_object_array = require("format.transforms.table_to_object_array"),
    object_array_to_table = require("format.transforms.object_array_to_table"),
    json_to_object_array  = require("format.transforms.json_to_object_array"),
    object_array_to_lines = require("format.transforms.object_array_to_lines"),
}

----------------------------------------------------------------
-- Normalization utilities
----------------------------------------------------------------

Registry.normalize = {
    clean = require("format.normalize.clean"),
}

----------------------------------------------------------------
-- Optional helpers
----------------------------------------------------------------

-- Registry.unwrap = require("format.unwrap")

return Registry
