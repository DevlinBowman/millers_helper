-- core/domain/vendor_reference/internal/merge.lua
--
-- Pure merge logic:
-- - append if key missing
-- - update price if differs
-- - keep existing otherwise

local Merge = {}

local function index_by_key(rows, Key)
    local idx = {}
    for i = 1, #rows do
        local row = rows[i]
        idx[Key.build(row)] = i
    end
    return idx
end

function Merge.merge(existing_rows, incoming_rows, Key)
    local merged = {}
    for i = 1, #existing_rows do
        merged[i] = existing_rows[i]
    end

    local existing_index = index_by_key(merged, Key)

    local report = {
        inserts   = {},
        updates   = {},
        unchanged = {},
    }

    for i = 1, #incoming_rows do
        local in_row = incoming_rows[i]
        local key = Key.build(in_row)

        local at = existing_index[key]
        if not at then
            merged[#merged + 1] = in_row
            existing_index[key] = #merged
            report.inserts[#report.inserts + 1] = { key = key, price = in_row.price }
        else
            local cur = merged[at]
            if cur.price ~= in_row.price then
                local old_price = cur.price
                cur.price = in_row.price
                report.updates[#report.updates + 1] = { key = key, from = old_price, to = in_row.price }
            else
                report.unchanged[#report.unchanged + 1] = { key = key, price = in_row.price }
            end
        end
    end

    return merged, report
end

return Merge
