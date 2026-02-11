-- application/runtime/io.lua
--
-- Application-level IO entrypoint.
-- Thin re-export of io.controller.
-- Exists so use-cases do not depend on core infrastructure paths.

local Controller = require("io.controller")

local IO = {}

IO.read          = Controller.read
IO.read_strict   = Controller.read_strict
IO.write         = Controller.write
IO.write_strict  = Controller.write_strict
IO.stream        = Controller.stream

return IO
