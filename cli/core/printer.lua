-- cli/core/printer.lua
--
-- Centralized CLI output.
--
-- Responsibilities:
--   • Provide a single output surface for controllers
--   • Distinguish structured vs plain output
--   • Abstract away direct print()/Inspector usage
--   • Serve as the future hook for TUI / JSON output
--
-- Controllers should call Printer, not print() directly.

local Inspector = require("inspector")

local Printer = {}

----------------------------------------------------------------
-- Plain text output
----------------------------------------------------------------

function Printer.text(msg)
    if msg ~= nil then
        io.stdout:write(tostring(msg))
        io.stdout:write("\n")
    end
end

----------------------------------------------------------------
-- Structured output
----------------------------------------------------------------

function Printer.struct(data)
    Inspector.print(data)
end

----------------------------------------------------------------
-- Error output
----------------------------------------------------------------

function Printer.error(msg)
    io.stderr:write("error: ")
    io.stderr:write(tostring(msg))
    io.stderr:write("\n")
end

----------------------------------------------------------------
-- Notes / warnings
----------------------------------------------------------------

function Printer.note(msg)
    io.stderr:write(tostring(msg))
    io.stderr:write("\n")
end

return Printer
