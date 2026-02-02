-- cli/core/render.lua
--
-- Rendering dispatcher.
--
-- Responsibilities:
--   • Route output based on render mode
--   • Provide a stable interface for future TUI/JSON rendering
--
-- Currently supports:
--   • text
--   • struct (Inspector-backed)

local Printer = require("cli.core.printer")

local Render = {}

function Render.text(msg)
    Printer.text(msg)
end

function Render.struct(data)
    Printer.struct(data)
end

return Render
