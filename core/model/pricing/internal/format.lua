-- core/model/pricing/internal/format.lua
--
-- Pure string formatter for pricing result (per-board).

local Format = {}

local function fmt(n)
    if type(n) ~= "number" then return "n/a" end
    return string.format("%.2f", n)
end

local function kv(out, k, v)
    out[#out + 1] = string.format("%-28s %s", k .. ":", v)
end

local function fmt_piecewise(info)
    if type(info) ~= "table" then return "n/a" end
    return string.format(
        "in=%s  match<=%s  idx=%s  factor=%s",
        tostring(info.input_value),
        tostring(info.matched_max),
        tostring(info.index),
        fmt(info.factor)
    )
end

----------------------------------------------------------------
-- Main Formatter
----------------------------------------------------------------

function Format.result(r)

    assert(type(r) == "table", "Format.result(): result required")

    local out = {}

    out[#out + 1] = "\n=============================="
    out[#out + 1] = "PRICING RESULT"
    out[#out + 1] = "==============================\n"

    kv(out, "Basis", tostring(r.basis))
    kv(out, "Profile", tostring(r.profile_id))

    if type(r.cost_floor_per_bf) == "number" then
        kv(out, "Cost floor ($/bf)", fmt(r.cost_floor_per_bf))
    end

    out[#out + 1] = "\nPer-board analysis:"

    for _, b in ipairs(r.per_board or {}) do

        out[#out + 1] = "\n----------------------------------------"
        out[#out + 1] = "BOARD: " .. tostring(b.label)

        --------------------------------------------------------
        -- Cost Math
        --------------------------------------------------------

        local m = b.math or {}
        out[#out + 1] = ""
        if m.cost_floor_per_bf ~= nil then kv(out, "Cost floor ($/bf)", fmt(m.cost_floor_per_bf)) end
        if m.final_price_per_bf ~= nil then kv(out, "Final price ($/bf)", fmt(m.final_price_per_bf)) end

        --------------------------------------------------------
        -- Factors
        --------------------------------------------------------

        local f = b.factors

        if type(f) == "table" then
            out[#out + 1] = "\nFactors:"
            if f.grade then kv(out, "Grade factor", fmt(f.grade.factor)) end
            if f.size then kv(out, "Size", fmt_piecewise(f.size)) end
            if f.length then kv(out, "Length", fmt_piecewise(f.length)) end

            if f.custom and f.custom.enabled then
                kv(out, "Waste", fmt_piecewise(f.custom.waste))
                kv(out, "Rush", fmt_piecewise(f.custom.rush))
                kv(out, "Small piece", fmt_piecewise(f.custom.small))
            end

            if f.multiplier_total ~= nil then
                kv(out, "Multiplier total", fmt(f.multiplier_total))
            end
        end

        --------------------------------------------------------
        -- Market
        --------------------------------------------------------

        local market = b.market
        if market then
            out[#out + 1] = "\nMarket:"
            if market.match then kv(out, "Matched vendor", tostring(market.match)) end
            if market.signal then kv(out, "Match signal", tostring(market.signal)) end
            if market.retail_bf_price then kv(out, "Retail ($/bf)", fmt(market.retail_bf_price)) end
            if market.requested_target then kv(out, "Target ($/bf)", fmt(market.requested_target)) end
        end

        --------------------------------------------------------
        -- Final Recommendation
        --------------------------------------------------------

        out[#out + 1] = ""
        kv(out, "Suggested ($/bf)", fmt(b.suggested_price_per_bf))
        kv(out, "Recommended ($/bf)", fmt(b.recommended_price_per_bf))
        kv(out, "Mode", tostring(b.recommendation_mode))
    end

    out[#out + 1] = "\n==============================\n"

    return table.concat(out, "\n")
end

return Format
