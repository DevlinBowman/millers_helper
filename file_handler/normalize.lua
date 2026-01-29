-- file_handler/normalize.lua

local Normalize = {}

-- ----------------------------
-- Tabular → records
-- ----------------------------
function Normalize.table(result)
    local header = result.data.header
    local rows   = result.data.rows

    local records = {}

    for _, row in ipairs(rows) do
        local rec = {}
        for i, key in ipairs(header) do
            rec[key] = row[i]
        end
        records[#records + 1] = rec
    end

    return {
        kind = "records",
        data = records,
        meta = {
            input_fields = header,
        }
    }
end

-- ----------------------------
-- JSON → records
-- ----------------------------
function Normalize.json(result)
    local v = result.data
    if type(v) ~= "table" then
        return nil, "json root must be object or array"
    end

    local records = {}
    local input_fields = {}

    local function collect_keys(obj)
        for k in pairs(obj) do
            input_fields[k] = true
        end
    end

    if #v > 0 then
        for _, obj in ipairs(v) do
            collect_keys(obj)
            records[#records + 1] = obj
        end
    else
        collect_keys(v)
        records = { v }
    end

    local keys = {}
    for k in pairs(input_fields) do
        keys[#keys + 1] = k
    end
    table.sort(keys)

    return {
        kind = "records",
        data = records,
        meta = {
            input_fields = keys,
        }
    }
end

return Normalize
