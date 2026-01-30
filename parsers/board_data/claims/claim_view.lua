-- parsers/board_data/claims/claim_view.lua

local ClaimView = {}

local function dims_to_str(d)
    if type(d) ~= "table" then return tostring(d) end
    local h = d.height and tostring(d.height) or "?"
    local w = d.width  and tostring(d.width)  or "?"
    local l = d.length and tostring(d.length) or "?"
    local tag = d.tag and tostring(d.tag) or nil
    if tag then
        return string.format("%sx%sx%s%s", h, w, l, tag)
    end
    return string.format("%sx%sx%s", h, w, l)
end

local function value_to_str(slot, v)
    if slot == "dimensions" then
        return dims_to_str(v)
    end
    if type(v) == "table" then
        return "<table>"
    end
    return tostring(v)
end

---@param claims table[]
---@return string
function ClaimView.format_claims(claims)
    if type(claims) ~= "table" or #claims == 0 then
        return ""
    end

    local out = {}
    for _, c in ipairs(claims) do
        local v = value_to_str(c.slot, c.value)
        out[#out + 1] = string.format("{%s=%s@%s}", c.slot, v, c.rule or "?")
    end
    return table.concat(out, " ")
end

---@param resolved table
---@return string
function ClaimView.format_resolved(resolved)
    if type(resolved) ~= "table" then return "" end
    local out = {}
    for slot, v in pairs(resolved) do
        out[#out + 1] = string.format("{%s=%s}", slot, value_to_str(slot, v))
    end
    table.sort(out)
    return table.concat(out, " ")
end

return ClaimView
