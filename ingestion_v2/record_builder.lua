-- ingestion_v2/record_builder.lua

local Schema = require("core.board.schema")

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
            -- keep only canonical schema fields or aliases
            local canonical = Schema.alias_index[k] or k
            if Schema.fields[canonical] then
                out[canonical] = v
            end
        end
    end

    return out
end

return Builder
