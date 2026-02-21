-- format/init.lua
--
-- Format module entrypoint.
-- Pure structural codec-shape conversion layer.

return {
    controller = require("platform.format.controller"),
    registry   = require("platform.format.registry"),
}
