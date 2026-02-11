-- format/records/to_table.lua
--
-- Lossy projection from records to delimited table.

local M = {}

function M.run(records, opts)
    assert(type(records) == "table", "records required")

    opts = opts or {}

    local header = opts.fields
    if not header then
        header = {}
        for k in pairs(records[1] or {}) do
            header[#header + 1] = k
        end
        table.sort(header)
    end

    local rows = {}

    for _, rec in ipairs(records) do
        local row = {}
        for i, key in ipairs(header) do
            row[i] = tostring(rec[key] or "")
        end
        rows[#rows + 1] = row
    end

    return {
        header = header,
        rows   = rows,
    }
end

return M
