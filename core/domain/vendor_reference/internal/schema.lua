-- core/domain/vendor_reference/internal/schema.lua
--
-- Canonical row schema + validation.

local Schema = {}

local function is_number(x)
    return type(x) == "number" and x > 0
end

local function is_string(x)
    return type(x) == "string" and x ~= ""
end

function Schema.validate_row(row)

    if type(row) ~= "table" then
        return false, "row_not_table"
    end

    if not is_number(row.base_h) then
        return false, "invalid_base_h"
    end

    if not is_number(row.base_w) then
        return false, "invalid_base_w"
    end

    if not is_number(row.l) then
        return false, "invalid_length"
    end

    if not is_string(row.grade) then
        return false, "invalid_grade"
    end

    if not (row.ea_price or row.bf_price or row.lf_price) then
        return false, "invalid_price"
    end

    return true, nil
end

function Schema.validate_rows(rows, sig, Signals)

    local valid = {}

    for i = 1, #rows do
        local ok, code = Schema.validate_row(rows[i])
        if ok then
            valid[#valid + 1] = rows[i]
        else
            Signals.warn(sig, "row_invalid", code, { index = i })
            sig.stats.invalid_count = sig.stats.invalid_count + 1
        end
    end

    sig.stats.valid_count = #valid

    return valid
end

return Schema
