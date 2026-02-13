-- format/registry.lua
--
-- Canonical hub registry.
--
-- Architecture:
--   codec → objects  (decode)
--   objects → codec  (encode)
--
-- No graph.
-- No chaining.
-- No pathfinding.
-- Explicit direction only.

local Registry = {}

----------------------------------------------------------------
-- Decode (codec → canonical objects)
----------------------------------------------------------------

Registry.decode = {
    delimited = require("format.transforms.delimited_to_objects"),
    json      = require("format.transforms.json_to_objects"),
    lines     = require("format.transforms.lines_to_objects"),
}

----------------------------------------------------------------
-- Encode (canonical objects → codec)
----------------------------------------------------------------

Registry.encode = {
    delimited = require("format.transforms.objects_to_delimited"),
    json      = require("format.transforms.objects_to_json"),
    lines     = require("format.transforms.objects_to_lines"),
}

----------------------------------------------------------------
-- Validation
----------------------------------------------------------------

Registry.validate = {
    shape = require("format.validate.shape"),
}

----------------------------------------------------------------
-- Normalization
----------------------------------------------------------------

Registry.normalize = {
    clean = require("format.normalize.clean"),
}

return Registry
