-- core/model/pricing/internal/format.lua
--
-- Pure string formatter for pricing suggestions.

local Format = {}

local function fmt(n)
    if type(n) ~= "number" then return "n/a" end
    return string.format("%.2f", n)
end

local function kv(out, k, v)
    out[#out + 1] = string.format("%-24s %s", k .. ":", v)
end

function Format.suggestion(s)
    assert(type(s) == "table", "Format.suggestion(): suggestion required")

    local out = {}

    out[#out + 1] = "\n=============================="
    out[#out + 1] = "PRICE SUGGESTION"
    out[#out + 1] = "==============================\n"

    kv(out, "Profile", tostring(s.profile_id))
    kv(out, "Cost floor ($/bf)", fmt(s.cost and s.cost.cost_floor_per_bf))
    kv(out, "Recommended ($/bf)", fmt(s.recommendation and s.recommendation.recommended_price_per_bf))
    kv(out, "Mode", tostring(s.recommendation and s.recommendation.mode))

    if s.recommendation and s.recommendation.basis then
        local b = s.recommendation.basis
        if b.market_target_discount then
            kv(out, "Market target discount", tostring(b.market_target_discount) .. "%")
            kv(out, "Market target ($/bf)", fmt(b.market_target_bf))
        end
    end

    out[#out + 1] = "\nMarket Ladder ($/bf):"
    if s.market and s.market.discounts then
        -- print sorted discount points
        local keys = {}
        for d in pairs(s.market.discounts) do keys[#keys + 1] = d end
        table.sort(keys)
        for _, d in ipairs(keys) do
            out[#out + 1] = string.format("  %3d%% off  -> %8s", d, fmt(s.market.discounts[d]))
        end
    else
        out[#out + 1] = "  n/a"
    end

    out[#out + 1] = "\nPer-board suggestions:"
    for _, b in ipairs(s.per_board or {}) do
        out[#out + 1] = string.format(
            "  %-20s $/bf=%8s  ea=%8s  mult=%s  grade=%s  (%sx%sx%s)",
            tostring(b.label),
            fmt(b.suggested_price_per_bf),
            fmt(b.suggested_ea_price),
            fmt(b.markup_multiplier),
            tostring(b.grade or "n/a"),
            tostring(b.dims and b.dims.h or "?"),
            tostring(b.dims and b.dims.w or "?"),
            tostring(b.dims and b.dims.l or "?")
        )
    end

    if s.diagnostics and #s.diagnostics > 0 then
        out[#out + 1] = "\nDiagnostics:"
        for _, d in ipairs(s.diagnostics) do
            out[#out + 1] = "  - " .. tostring(d)
        end
    end

    out[#out + 1] = "\n==============================\n"

    return table.concat(out, "\n")
end

return Format
