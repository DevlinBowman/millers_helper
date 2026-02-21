-- core/model/pricing/internal/format.lua
--
-- Pure string formatter for pricing suggestions (per-board model).

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

local function fmt_grade(info)
    if type(info) ~= "table" then return "n/a" end
    return string.format(
        "key=%s  source=%s  factor=%s",
        tostring(info.input_key),
        tostring(info.source),
        fmt(info.factor)
    )
end

----------------------------------------------------------------
-- Main Formatter
----------------------------------------------------------------

function Format.suggestion(s)

    assert(type(s) == "table", "Format.suggestion(): suggestion required")

    local out = {}

    out[#out + 1] = "\n=============================="
    out[#out + 1] = "PRICE SUGGESTION"
    out[#out + 1] = "==============================\n"

    kv(out, "Profile", tostring(s.profile_id))
    kv(out, "Cost floor ($/bf)", fmt(s.cost_floor_per_bf))

    out[#out + 1] = ""
    kv(out, "Opts.waste_ratio", tostring(s.opts and s.opts.waste_ratio))
    kv(out, "Opts.rush_level", tostring(s.opts and s.opts.rush_level))
    kv(out, "Opts.market_target_discount", tostring(s.opts and s.opts.market_target_discount))

    out[#out + 1] = "\nPer-board analysis:"

    for _, b in ipairs(s.per_board or {}) do

        out[#out + 1] = "\n----------------------------------------"
        out[#out + 1] = "BOARD: " .. tostring(b.label)

        local dims = b.factors and b.factors.inputs
        out[#out + 1] = string.format(
            "area=%s  length=%s  min_face=%s  grade=%s",
            tostring(dims and dims.area_in2 or "?"),
            tostring(dims and dims.length_ft or "?"),
            tostring(dims and dims.min_face_in or "?"),
            tostring(dims and dims.grade or "?")
        )

        --------------------------------------------------------
        -- Cost Math
        --------------------------------------------------------

        local m = b.math or {}

        out[#out + 1] = ""
        kv(out, "Cost floor ($/bf)", fmt(m.cost_floor_per_bf))
        kv(out, "Final price ($/bf)", fmt(m.final_price_per_bf))

        --------------------------------------------------------
        -- Factors
        --------------------------------------------------------

        local f = b.factors or {}

        out[#out + 1] = "\nFactors:"
        kv(out, "Grade", fmt_grade(f.grade))
        kv(out, "Size", fmt_piecewise(f.size))
        kv(out, "Length", fmt_piecewise(f.length))

        if f.custom and f.custom.enabled then
            kv(out, "Waste", fmt_piecewise(f.custom.waste))
            kv(out, "Rush", fmt_piecewise(f.custom.rush))
            kv(out, "Small piece", fmt_piecewise(f.custom.small))
        else
            kv(out, "Custom", "disabled")
        end

        kv(out, "Multiplier total", fmt(f.multiplier_total))

        --------------------------------------------------------
        -- Market
        --------------------------------------------------------

        local market = b.market

        out[#out + 1] = "\nMarket:"

        if market and market.match then
            kv(out, "Matched vendor", tostring(market.match))
            kv(out, "Match signal", tostring(market.signal))
            kv(out, "Retail ($/bf)", fmt(market.retail_bf_price))

            if type(market.ladder) == "table" then
                local keys = {}
                for d in pairs(market.ladder) do keys[#keys + 1] = d end
                table.sort(keys)

                for _, d in ipairs(keys) do
                    out[#out + 1] = string.format(
                        "  %3d%% off -> %8s",
                        d,
                        fmt(market.ladder[d])
                    )
                end
            end
        else
            out[#out + 1] = "  no match"
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
