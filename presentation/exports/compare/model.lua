-- presentation/exports/compare/model.lua
--
-- Builds ComparisonModel.
-- Accumulates per-source job totals based on matched pricing.

local CompareContract = require("presentation.exports.compare.contract")
local BoardMatcher    = require("presentation.exports.compare.matcher")

local M = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function bf_per_piece(b)
    local p = b.physical or {}
    if type(p.bf_ea) == "number" then return p.bf_ea end
    if p.h and p.w and p.l then
        return (p.h * p.w * p.l) / 12.0
    end
    return 0
end

local function round(n)
    return math.floor((n or 0) * 100 + 0.5) / 100
end

local function apply_bf_price(bf_price, order_board)
    local p  = order_board.physical
    local bf = bf_per_piece(order_board)
    local ct = p.ct or 1
    local l  = p.l or 0

    local ea    = round(bf_price * bf)
    local lf    = (l > 0) and round(ea / l) or 0
    local total = round(ea * ct)

    return {
        ea    = ea,
        lf    = lf,
        bf    = round(bf_price),
        total = total,
    }
end

----------------------------------------------------------------
-- Builder
----------------------------------------------------------------

function M.build(input)
    CompareContract.validate(input)

    local model = {
        rows   = {},
        totals = {},  -- per-source job totals
    }

    ----------------------------------------------------------------
    -- Initialize totals (input + each source)
    ----------------------------------------------------------------

    model.totals["input"] = { total = 0 }

    for _, src in ipairs(input.sources) do
        model.totals[src.name] = { total = 0 }
    end

    ----------------------------------------------------------------
    -- Build rows + accumulate totals
    ----------------------------------------------------------------

    for _, ob in ipairs(input.order.boards) do
        local row = {
            order_board = ob,
            offers      = {},
        }

        -- INPUT (primary)
        local input_bf = ob.pricing and ob.pricing.bf_price or 0
        local input_pr = apply_bf_price(input_bf, ob)

        row.offers["input"] = {
            pricing = input_pr,
            meta    = { match_type = "INPUT" },
        }

        model.totals["input"].total =
            model.totals["input"].total + input_pr.total

        -- SOURCES
        for _, src in ipairs(input.sources) do
            local matched, sig = BoardMatcher.match(ob, src.boards)

            if matched then
                local bf_price =
                    (matched.pricing and matched.pricing.bf_price) or 0

                local pr = apply_bf_price(bf_price, ob)

                row.offers[src.name] = {
                    pricing = pr,
                    meta    = {
                        match_type = sig,
                        label      = matched.id,
                    }
                }

                model.totals[src.name].total =
                    model.totals[src.name].total + pr.total
            else
                row.offers[src.name] = {
                    pricing = {},
                    meta    = { match_type = "none" },
                }
            end
        end

        model.rows[#model.rows + 1] = row
    end

    return model
end

return M
