-- ingestion_v2/record_builder.lua
--
-- Responsibility:
--   Convert parser output → clean record suitable for Board.new()
--   Strip ALL parser internals.
--   Preserve human fields (head, notes, etc.)

local Builder = {}

local function is_internal_key(k)
    return type(k) == "string" and (k:match("^_") or k:match("^__"))
end

---@param record table
---@return table
function Builder.build(record)
    local out = {}

    for k, v in pairs(record) do
        if not is_internal_key(k) then
            out[k] = v
        end
    end

    return out
end

return Builder
