-- core/identity/board/helpers.lua

--
-- Mechanical helpers for board label encoding/decoding.

local Helpers = {}

------------------------------------------------
-- formatting
------------------------------------------------

function Helpers.format_number(n)
    return string.format("%.15g", n)
end

------------------------------------------------
-- tokenize
------------------------------------------------

function Helpers.tokenize(label)

    local tokens = {}

    for tok in label:gmatch("%S+") do
        tokens[#tokens + 1] = tok
    end

    return tokens
end

------------------------------------------------
-- dimension token
------------------------------------------------

function Helpers.format_dimension(spec)

    assert(spec.base_h, "base_h required")
    assert(spec.base_w, "base_w required")
    assert(spec.l, "length required")

    return string.format(
        "%sx%sx%s%s",
        Helpers.format_number(spec.base_h),
        Helpers.format_number(spec.base_w),
        Helpers.format_number(spec.l),
        spec.tag or ""
    )
end

function Helpers.parse_dimension(token)

    local bh, bw, l, tag =
        token:match("^([%d%.]+)x([%d%.]+)x([%d%.]+)([a-zA-Z]?)$")

    assert(bh, "invalid dimension token: " .. token)

    return {
        base_h = tonumber(bh),
        base_w = tonumber(bw),
        l      = tonumber(l),
        ct     = 1,
        tag    = tag ~= "" and tag or nil
    }
end

------------------------------------------------
-- token classification
------------------------------------------------

function Helpers.is_count(tok)
    return tok:match("^x%d+$") ~= nil
end

function Helpers.is_surface(tok)
    return tok:match("^[A-Z][A-Z0-9]+$") and not tok:match("^[A-Z]{2}$")
end

function Helpers.is_commercial(tok)
    return tok:match("^[A-Z]{2}$") ~= nil
end

return Helpers
