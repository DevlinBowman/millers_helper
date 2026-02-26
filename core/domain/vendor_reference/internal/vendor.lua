-- core/domain/vendor_reference/internal/vendor.lua
--
-- Vendor name normalization/sanitization for keys/filenames.

local Vendor = {}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Vendor.normalize_name(name)
    if type(name) ~= "string" then return nil end
    name = trim(name):lower()

    -- Replace spaces with underscores
    name = name:gsub("%s+", "_")

    -- Remove unsafe characters (keep a-z 0-9 _ - .)
    name = name:gsub("[^a-z0-9_%-%._]", "")

    if name == "" then return nil end
    return name
end

return Vendor
