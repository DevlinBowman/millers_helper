-- parsers/init.lua
--
-- Domain entrypoint for parsers.

local Registry = require("platform.parsers.registry")

return {
    controller = require("platform.parsers.controller"),
    registry   = Registry,

    -- stable convenience exports
    raw_text   = Registry.raw_text,
    board_data = Registry.board_data,
}
