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
    delimited = require("platform.format.transforms.delimited_to_objects"),
    json      = require("platform.format.transforms.json_to_objects"),
    lines     = require("platform.format.transforms.lines_to_objects"),
}

----------------------------------------------------------------
-- Encode (canonical objects → codec)
----------------------------------------------------------------

Registry.encode = {
    delimited = require("platform.format.transforms.objects_to_delimited"),
    json      = require("platform.format.transforms.objects_to_json"),
    lines     = require("platform.format.transforms.objects_to_lines"),
}

----------------------------------------------------------------
-- Validation
----------------------------------------------------------------

-- format/registry.lua

Registry.validate = {
    shape      = require("platform.format.validate.shape"),
    parser_gate = require("platform.format.validate.parser_gate"),
}

----------------------------------------------------------------
-- Normalization
----------------------------------------------------------------

Registry.normalize = {
    clean = require("platform.format.normalize.clean"),
}

return Registry
