-- application/runtime/format.lua
--
-- Application-level format entrypoint.
-- Thin re-export of format.controller.

local Controller = require("format.controller")

local Format = {}

Format.to_records        = Controller.to_records
Format.to_records_strict = Controller.to_records_strict

return Format
