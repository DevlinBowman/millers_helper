-- classify/normalize.lua
--
-- String normalization utilities for alias resolution.
-- Pure string transforms only.

local Normalize = {}

----------------------------------------------------------------
-- Basic normalization
----------------------------------------------------------------

--- Lowercase, trim, collapse separators.
--- Converts:
---   "Job Number"  -> "job_number"
---   "price/bf"    -> "price_bf"
---   "Order-ID"    -> "order_id"
---
---@param key string
---@return string
function Normalize.key(key)
    assert(type(key) == "string", "Normalize.key(): string required")

    local s = key:match("^%s*(.-)%s*$") -- trim
    s = s:gsub("[/%-%s]+", "_")        -- normalize separators
    s = s:gsub("__+", "_")             -- collapse doubles
    s = s:lower()

    return s
end

return Normalize
