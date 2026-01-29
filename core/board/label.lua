-- core/label/label.lua

local Label = {}

local function fmt_num(n)
    return string.format("%.15g", n)
end

-- ============================================================
-- Label generation (authoritative)
-- ============================================================

-- Label dimensions encode DECLARED dimensions:
--   base_h x base_w x l [tag]
-- Where base_* may be nominal (tag="n") or actual/freeform (tag=nil/"f").
---@param spec table
---@return string
function Label.generate(spec)
    assert(type(spec) == "table", "spec required")
    assert(spec.base_h and spec.base_w and spec.l, "missing declared dimensions")

    local tokens = {}

    -- dimensions
    local tag = spec.tag or ""
    tokens[#tokens + 1] = string.format(
        "%sx%sx%s%s",
        fmt_num(spec.base_h),
        fmt_num(spec.base_w),
        fmt_num(spec.l),
        tag
    )

    -- count
    if spec.ct and spec.ct > 1 then
        tokens[#tokens + 1] = "x" .. tostring(spec.ct)
    end

    -- commercial codes
    if spec.species then
        tokens[#tokens + 1] = spec.species
    end
    if spec.grade then
        tokens[#tokens + 1] = spec.grade
    end
    if spec.moisture then
        tokens[#tokens + 1] = spec.moisture
    end

    -- surface
    if spec.surface then
        tokens[#tokens + 1] = spec.surface
    end

    return table.concat(tokens, " ")
end

-- ============================================================
-- Label hydration (spec object)
-- ============================================================
---@param label string
---@return table
function Label.hydrate(label)
    assert(type(label) == "string", "label must be string")

    local tokens = {}
    for tok in label:gmatch("%S+") do
        tokens[#tokens + 1] = tok
    end
    assert(#tokens >= 1, "invalid label: missing dimensions")

    -- --------------------------------------------------------
    -- Parse dimensions (always first)
    -- --------------------------------------------------------
    local bh, bw, l, tag = tokens[1]:match(
        "^([%d%.]+)x([%d%.]+)x([%d%.]+)([a-zA-Z]?)$"
    )
    assert(bh, "invalid dimension token: " .. tokens[1])

    local spec = {
        base_h = tonumber(bh),
        base_w = tonumber(bw),
        l      = tonumber(l),
        ct     = 1,
        tag    = tag ~= "" and tag or nil,
    }

    -- --------------------------------------------------------
    -- Remaining tokens (shape-typed)
    -- --------------------------------------------------------
    local commercial_order = { "species", "grade", "moisture" }
    local commercial_index = 1

    for i = 2, #tokens do
        local tok = tokens[i]

        -- count
        if tok:match("^x%d+$") then
            spec.ct = tonumber(tok:sub(2))

        -- surface (alphanumeric, not 2-letter)
        elseif tok:match("^[A-Z][A-Z0-9]+$") and not tok:match("^[A-Z]{2}$") then
            spec.surface = tok

        -- commercial 2-letter tokens
        elseif tok:match("^[A-Z]{2}$") then
            local key = commercial_order[commercial_index]
            if not key then
                error("too many commercial tokens in label: " .. label)
            end
            spec[key] = tok
            commercial_index = commercial_index + 1

        else
            error("unrecognized label token: " .. tok)
        end
    end

    return spec
end

return Label
