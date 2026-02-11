-- format/records/from_lines.lua
--
-- Explicit non-implementation.
-- Text → records is parser-owned, not formatter-owned.

local FromLines = {}

---@param _ any
---@return nil
---@return string err
function FromLines.run(_)
    return nil, "text-to-records formatting is parser-owned"
end

return FromLines
