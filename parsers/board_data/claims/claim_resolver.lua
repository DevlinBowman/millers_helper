-- parsers/board_data/claims/claim_resolver.lua
local Resolver = {}

local OUTPUT_FIELDS = {
    h   = true,
    w   = true,
    l   = true,
    ct  = true,
    tag = true,
}

local function expand_claim(claim)
    local out = {}

    if claim.slot == "dimensions" then
        local d = claim.value or {}

        if d.height then
            out[#out + 1] = { field="h", value=d.height, certainty=claim.certainty, span=claim.span, rule=claim.rule }
        end
        if d.width then
            out[#out + 1] = { field="w", value=d.width, certainty=claim.certainty, span=claim.span, rule=claim.rule }
        end
        if d.length then
            out[#out + 1] = { field="l", value=d.length, certainty=claim.certainty, span=claim.span, rule=claim.rule }
        end
        if d.tag then
            out[#out + 1] = { field="tag", value=d.tag, certainty=claim.certainty, span=claim.span, rule=claim.rule }
        end

    elseif claim.slot == "count" then
        out[#out + 1] = { field="ct", value=claim.value, certainty=claim.certainty, span=claim.span, rule=claim.rule }

    elseif claim.slot == "length" then
        out[#out + 1] = { field="l", value=claim.value, certainty=claim.certainty, span=claim.span, rule=claim.rule }

    elseif claim.slot == "tag" then
        out[#out + 1] = { field="tag", value=claim.value, certainty=claim.certainty, span=claim.span, rule=claim.rule }
    end

    return out
end

local function spans_overlap(a, b)
    if not a or not b then return false end
    return not (a.to < b.from or b.to < a.from)
end

---@param claims table[]
---@return table resolved, table picked
function Resolver.resolve(claims)
    assert(type(claims) == "table", "Resolver.resolve(): claims must be table")

    local candidates = {}
    for _, claim in ipairs(claims) do
        for _, e in ipairs(expand_claim(claim)) do
            candidates[#candidates + 1] = e
        end
    end

    table.sort(candidates, function(a, b)
        if a.certainty ~= b.certainty then return a.certainty > b.certainty end
        return tostring(a.rule) < tostring(b.rule)
    end)

    local resolved   = {}
    local picked     = {}
    local used_spans = {}

    for _, c in ipairs(candidates) do
        if OUTPUT_FIELDS[c.field] and resolved[c.field] == nil then
            local overlap = false
            for _, s in ipairs(used_spans) do
                if spans_overlap(c.span, s) then
                    overlap = true
                    break
                end
            end

            -- Allow h/w/l and tag to overlap dimension spans.
            -- Only ct is overlap-restricted (to avoid stealing inside dimension chains).
            if overlap and c.field == "ct" then
                goto continue
            end

            resolved[c.field] = c.value
            picked[#picked + 1] = c
            used_spans[#used_spans + 1] = c.span
        end
        ::continue::
    end

    return resolved, picked
end

return Resolver
