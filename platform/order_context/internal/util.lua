-- order_context/internal/util.lua
--
-- Pure helpers.

local Util = {}

--- Normalize common US-style date formats to YYYY-MM-DD.
--- Accepts:
---   9/10/2025
---   9/10/25
--- Returns canonical string or original if not parseable.
function Util.normalize_date(value)
    if type(value) ~= "string" then
        return value
    end

    value = value:match("^%s*(.-)%s*$") -- trim whitespace

    local m, d, y = value:match("^(%d%d?)/(%d%d?)/(%d%d%d?%d?)$")
    if not m then
        return value
    end

    m = tonumber(m)
    d = tonumber(d)
    y = tonumber(y)

    if y < 100 then
        y = 2000 + y
    end

    return string.format("%04d-%02d-%02d", y, m, d)
end

function Util.normalize_identity(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

function Util.is_numeric(value)
    if type(value) == "number" then
        return true
    end
    if type(value) ~= "string" then
        return false
    end
    return tonumber(value) ~= nil
end

--- True if EVERY board row has bf_price present (non-nil).
--- @param rows table[]
--- @return boolean
function Util.boards_have_bf_price(rows)
    for _, row in ipairs(rows) do
        local board = row.board or {}
        if board.bf_price == nil then
            return false
        end
    end
    return true
end

--- Collect distinct stringified non-empty values for a given order field across rows.
--- Applies optional normalizer before comparison.
--- @param rows table[]
--- @param field string
--- @param normalizer function|nil
--- @return string[] values
function Util.collect_order_field_values(rows, field, normalizer)
    local values = {}
    local seen = {}

    for _, row in ipairs(rows) do
        local order_part = row.order or {}
        local v = order_part[field]

        if v ~= nil and v ~= "" then
            if normalizer then
                v = normalizer(v)
            end

            v = tostring(v)

            if not seen[v] then
                seen[v] = true
                values[#values + 1] = v
            end
        end
    end

    table.sort(values)
    return values
end

--- Collect all order fields present in rows (stable sorted list).
--- @param rows table[]
--- @return string[] fields
function Util.collect_order_fields(rows)
    local index = {}
    for _, row in ipairs(rows) do
        for k in pairs(row.order or {}) do
            index[k] = true
        end
    end

    local fields = {}
    for k in pairs(index) do
        fields[#fields + 1] = k
    end
    table.sort(fields)
    return fields
end

return Util
