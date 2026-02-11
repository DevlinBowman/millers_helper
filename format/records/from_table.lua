-- format/records/from_table.lua
--
-- Structural projection: table → records
--
-- Contract:
--   • Input is codec-native table data (NOT IO envelope)
--   • No mutation
--   • No IO metadata
--   • Pure transformation

local FromTable = {}

--- Convert tabular data into records.
--- Each row becomes a record keyed by header values.
---
---@param table_data { header: string[], rows: string[][] }
---@return table result
function FromTable.run(table_data)
    assert(type(table_data) == "table", "table_data required")
    assert(type(table_data.header) == "table", "missing header")
    assert(type(table_data.rows) == "table", "missing rows")

    local header  = table_data.header
    local rows    = table_data.rows

    local records = {}

    for _, row in ipairs(rows) do
        local record = {}
        for i, key in ipairs(header) do
            record[key] = row[i]
        end
        records[#records + 1] = record
    end

    return {
        kind = "records",
        data = records,
        meta = {
            input_fields = header,
            source_shape = "table",
            lossy        = false,
        }
    }
end

return FromTable
