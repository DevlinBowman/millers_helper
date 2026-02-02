-- cli/core/layout/format.lua
--
-- Formatting helpers for CLI output.
--
-- Responsibilities:
--   • Normalize small formatting tasks
--   • Avoid duplicated string logic across the CLI
--
-- This module is intentionally small.

local Format = {}

function Format.kv(key, value)
    return string.format("%-16s %s", tostring(key), tostring(value))
end

function Format.header(title)
    return string.format("\n== %s ==\n", title)
end

return Format
