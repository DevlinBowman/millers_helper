-- core/compare/model.lua
--
-- Builds ComparisonModel.
--
-- Economic model:
--   • Order board defines volume
--   • Source board defines $/BF
--   • All prices are projected onto order geometry
--
-- This is NOT invoicing.
-- This is normalized comparison.

local CompareContract = require("core.compare.contract")
local BoardMatcher    = require("core.compare.matcher")

local Model = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
---
local function floor_cents(n)
    return math.floor((n or 0) * 100) / 100
end

local function order_metrics(board)
    local p = board.physical or {}
    assert(type(p.bf_ea) == "number", "missing physical.bf_ea")

    local ct = p.ct or 1
    local l  = p.l or 0

    return {
        bf_ea    = p.bf_ea,
        bf_total = p.bf_ea * ct,
        ct       = ct,
        l        = l,
    }
end

local function project_pricing(bf_price, metrics)
    assert(type(bf_price) == "number", "bf_price required")

    -- EA is authoritative rounding point
    local ea_raw = bf_price * metrics.bf_ea
    local ea     = floor_cents(ea_raw)

    -- LF is informational (do not re-round)
    local lf = (metrics.l > 0) and (ea / metrics.l) or nil

    -- TOTAL derived from EA, not raw math
    local total = floor_cents(ea * metrics.ct)

    return {
        bf    = bf_price,
        ea    = ea,
        lf    = lf,
        total = total,
    }
end

----------------------------------------------------------------
-- Builder
----------------------------------------------------------------

function Model.build(input)
    CompareContract.validate(input)

    local model = {
        rows   = {},
        totals = {},
    }

    -- init totals
    model.totals["input"] = { total = 0 }
    for _, src in ipairs(input.sources) do
        model.totals[src.name] = { total = 0 }
    end

    ----------------------------------------------------------------
    -- Build rows
    ----------------------------------------------------------------

    for _, ob in ipairs(input.order.boards) do
        local metrics = order_metrics(ob)

        local row = {
            order_board = ob,
            offers      = {},
        }

        ------------------------------------------------------------
        -- INPUT (baseline)
        ------------------------------------------------------------

        local input_bf = ob.pricing and ob.pricing.bf_price
        assert(type(input_bf) == "number", "order missing pricing.bf_price")

        local input_pr = project_pricing(input_bf, metrics)

        row.offers["input"] = {
            pricing = input_pr,
            meta    = { match_type = "INPUT" },
        }

        model.totals["input"].total =
            model.totals["input"].total + input_pr.total

        ------------------------------------------------------------
        -- SOURCES (normalized projection)
        ------------------------------------------------------------

        for _, src in ipairs(input.sources) do
            local matched, sig = BoardMatcher.match(ob, src.boards)

            if matched and matched.pricing and type(matched.pricing.bf_price) == "number" then
                local pr = project_pricing(matched.pricing.bf_price, metrics)

                row.offers[src.name] = {
                    pricing = pr,
                    meta    = {
                        match_type = sig,
                        label      = matched.id,
                    },
                }

                model.totals[src.name].total =
                    model.totals[src.name].total + pr.total
            else
                row.offers[src.name] = {
                    pricing = {},
                    meta    = { match_type = sig or "none" },
                }
            end
        end

        model.rows[#model.rows + 1] = row
    end

    return model
end

return Model
