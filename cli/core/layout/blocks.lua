-- cli/core/layout/blocks.lua
--
-- Primitive layout structures for CLI output.
--
-- Responsibilities:
--   • Define semantic output blocks
--   • Provide future structure for tables, sections, lists
--
-- These are data-only helpers.
-- Rendering is handled elsewhere.

local Blocks = {}

function Blocks.section(title, body)
    return {
        kind  = "section",
        title = title,
        body  = body,
    }
end

function Blocks.list(items)
    return {
        kind  = "list",
        items = items or {},
    }
end

return Blocks
