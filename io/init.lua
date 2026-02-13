-- io/init.lua
--
-- IO module entrypoint.
--
-- Exposes:
--   • controller : public control surface (external callers)
--   • registry   : internal capability facade (domain systems)
--
-- No logic. No re-exports of internals.

return {
    controller = require("io.controller"),
    registry   = require("io.registry"),
}
