-- parsers/board_data/init.lua
--
-- Domain entrypoint for board_data.
-- PURPOSE:
--   • Provide stable import surface
--   • Expose controller + registry
--   • Avoid deep requires from outside domain

local Registry = require("platform.parsers.board_data.registry")

return {
    controller = require("platform.parsers.board_data.controller"),
    registry   = Registry,

    -- Stable direct capability shortcuts
    lex        = Registry.lex,
    chunk      = Registry.chunk,
    rules      = Registry.rules,
    claims     = Registry.claims,
}
