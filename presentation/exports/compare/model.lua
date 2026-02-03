-- presentation/exports/compare/model.lua
--
-- Builds ComparisonModel.
-- No formatting. No math. No normalization.

local CompareContract        = require("presentation.exports.compare.contract")
local BoardMatcher           = require("presentation.exports.compare.matcher")

local ComparisonModelBuilder = {}

function ComparisonModelBuilder.build(input)
    CompareContract.validate(input)

    local model = {
        order_id = input.order.id,
        rows     = {},
        totals   = {},
    }

    for _, src in ipairs(input.sources) do
        model.totals[src.name] = {
            total_price = 0,
            total_bf    = 0,
            total_pcs   = 0,
        }
    end

    for _, ob in ipairs(input.order.boards) do
        local row = {
            order_board = ob,
            offers = {},
        }

        for _, src in ipairs(input.sources) do
            local matched, match_type =
                BoardMatcher.match(ob, src.boards)

            if matched then
                local pricing = matched.pricing or {}

                row.offers[src.name] = {
                    matched_offer = {
                        id      = matched.id,
                        h       = matched.h,
                        w       = matched.w,
                        l       = matched.l,
                        grade   = matched.grade,
                        surface = matched.surface,
                    },
                    pricing       = pricing,
                    units         = {
                        bf_per_piece = ob.bf_ea,
                        length_ft    = ob.l,
                        count        = ob.ct or 1,
                    },
                    meta          = {
                        match_type = match_type,
                    }
                }

                model.totals[src.name].total_price =
                    model.totals[src.name].total_price +
                    (pricing.total or 0)

                model.totals[src.name].total_bf =
                    model.totals[src.name].total_bf +
                    (ob.bf_batch or 0)

                model.totals[src.name].total_pcs =
                    model.totals[src.name].total_pcs + (ob.ct or 1)
            else
                row.offers[src.name] = {
                    matched_offer = nil,
                    pricing = {},
                    units = {},
                    meta = { match_type = "none" }
                }
            end
        end

        table.insert(model.rows, row)
    end

    return model
end

return ComparisonModelBuilder
