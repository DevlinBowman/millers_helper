-- parsers/board_data/internal/claims/format_claims.lua

local FormatClaims = {}

local function format_value(slot, value)
    if type(value) ~= "table" then
        return tostring(value)
    end

    if slot == "dimensions" then
        local h = value.height or "?"
        local w = value.width  or "?"
        local l = value.length or "?"
        return string.format("%sx%sx%s", h, w, l)
    end

    -- fallback table rendering
    local parts = {}
    for k, v in pairs(value) do
        parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

---@param claims table[]
---@param opts table|nil
---@return string
function FormatClaims.format(claims, opts)
    opts = opts or {}
    local show_rule      = opts.show_rule ~= false
    local show_certainty = opts.show_certainty == true

    if not claims or #claims == 0 then
        return "{}"
    end

    local out = {}

    for _, c in ipairs(claims) do
        local val = format_value(c.slot, c.value)
        local s = c.slot .. "=" .. val

        if show_rule and c.rule then
            s = s .. "@" .. c.rule
        end

        if show_certainty and c.certainty then
            s = s .. string.format("(%.2f)", c.certainty)
        end

        out[#out + 1] = "{" .. s .. "}"
    end

    return table.concat(out, " ")
end

return FormatClaims
