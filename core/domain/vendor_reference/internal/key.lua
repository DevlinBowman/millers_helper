-- core/domain/vendor_reference/internal/key.lua
--
-- Key helpers for vendor snapshot rows.
-- Identity key is label.

local Key = {}

local function is_nonempty_string(x)
    return type(x) == "string" and x ~= ""
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Key.build(row)
    if type(row) ~= "table" then return nil end

    local label = row.label
    if not is_nonempty_string(label) then return nil end

    label = trim(label)
    if label == "" then return nil end

    return label
end

return Key
