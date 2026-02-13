-- format/init.lua
--
-- Format module entrypoint.
-- Pure structural codec-shape conversion layer.

return {
    controller = require("format.controller"),
    registry   = require("format.registry"),
}
