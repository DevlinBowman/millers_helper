-- format/records/from_json.lua
--
-- Structural projection: JSON → records
--
-- Contract:
--   • Accepts decoded JSON data ONLY
--   • No mutation
--   • No IO metadata
--   • Explicit about ambiguity

local FromJson = {}

--- Convert JSON data into records.
--- Supports:
---   • array-of-objects → records
---   • single object    → singleton record array
---
---@param json_data table
---@return table|nil result
---@return string|nil err
function FromJson.run(json_data)
    if type(json_data) ~= "table" then
        return nil, "json root must be table"
    end

    local records = {}
    local input_fields = {}

    local function collect_keys(obj)
        for k in pairs(obj) do
            input_fields[k] = true
        end
    end

    -- array-of-objects
    if #json_data > 0 then
        for _, obj in ipairs(json_data) do
            if type(obj) ~= "table" then
                return nil, "json array elements must be objects"
            end
            collect_keys(obj)
            records[#records + 1] = obj
        end
    else
        -- single object
        collect_keys(json_data)
        records = { json_data }
    end

    local fields = {}
    for k in pairs(input_fields) do
        fields[#fields + 1] = k
    end
    table.sort(fields)

    return {
        kind = "records",
        data = records,
        meta = {
            input_fields = fields,
            source_shape = "json",
            lossy        = false,
        }
    }
end

return FromJson
