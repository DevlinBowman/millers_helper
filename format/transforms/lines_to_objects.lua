-- format/transforms/lines_to_objects.lua
--
-- Policy:
--   Freeform text -> objects is parser-owned.
--   Format layer does not guess semantics.

local M = {}

function M.run(_lines)
    return nil, "lines_to_objects is parser-owned (format will not infer objects from freeform text)"
end

return M
