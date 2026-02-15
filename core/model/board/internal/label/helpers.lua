-- core/board/label/helpers.lua
--
-- Mechanical helpers for label encoding / decoding.
-- No domain policy lives here.

local Helpers = {}

----------------------------------------------------------------
-- Formatting
----------------------------------------------------------------

function Helpers.fmt_num(n)
    return string.format("%.15g", n)
end

----------------------------------------------------------------
-- Tokenization
----------------------------------------------------------------

function Helpers.tokenize(label)
    local tokens = {}
    for tok in label:gmatch("%S+") do
        tokens[#tokens + 1] = tok
    end
    return tokens
end

----------------------------------------------------------------
-- Dimension token
----------------------------------------------------------------

function Helpers.format_dimension(spec)
    return string.format(
        "%sx%sx%s%s",
        Helpers.fmt_num(spec.base_h),
        Helpers.fmt_num(spec.base_w),
        Helpers.fmt_num(spec.l),
        spec.tag or ""
    )
end

function Helpers.parse_dimension(token)
    local bh, bw, l, tag = token:match(
        "^([%d%.]+)x([%d%.]+)x([%d%.]+)([a-zA-Z]?)$"
    )
    assert(bh, "invalid dimension token: " .. token)

    return {
        base_h = tonumber(bh),
        base_w = tonumber(bw),
        l      = tonumber(l),
        ct     = 1,
        tag    = tag ~= "" and tag or nil,
    }
end

----------------------------------------------------------------
-- Token classifiers
----------------------------------------------------------------

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
