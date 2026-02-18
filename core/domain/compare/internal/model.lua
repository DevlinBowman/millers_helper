-- core/domain/compare/internal/model.lua
--
-- Comparison model operating directly on canonical
-- ingestion board shape (flat fields).
--
-- Pure logic.

local BoardMatcher = require("core.domain.compare.internal.matcher")

local Model = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function floor_cents(n)
    return math.floor((n or 0) * 100) / 100
end

local function order_metrics(board)
    assert(type(board.bf_ea) == "number", "missing bf_ea")

    local count  = board.ct or 1
    local length = board.l or 0

    return {
        bf_ea    = board.bf_ea,
        bf_total = board.bf_ea * count,
        ct       = count,
        l        = length,
    }
end

local function project_pricing(bf_price, metrics)
    assert(type(bf_price) == "number", "bf_price required")

    local ea_raw = bf_price * metrics.bf_ea
    local ea     = floor_cents(ea_raw)

    local lf     = (metrics.l > 0) and (ea / metrics.l) or nil

    local total  = floor_cents(ea * metrics.ct)

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

    ------------------------------------------------------------
    -- Helpers
    ------------------------------------------------------------

    local function resolve_bf_price(board)
        if type(board.bf_price) == "number" then
            return board.bf_price
        end

        if type(board.ea_price) == "number"
        and type(board.bf_ea) == "number"
        and board.bf_ea > 0 then
            return board.ea_price / board.bf_ea
        end

        if type(board.batch_price) == "number"
        and type(board.bf_batch) == "number"
        and board.bf_batch > 0 then
            return board.batch_price / board.bf_batch
        end

        return nil
    end

    ------------------------------------------------------------

    local model = {
        rows   = {},
        totals = {},
    }

    model.totals["input"] = { total = 0 }

    for _, src in ipairs(input.sources or {}) do
        model.totals[src.name] = { total = 0 }
    end

    ------------------------------------------------------------
    -- Build Rows (ALL boards, not just priced)
    ------------------------------------------------------------

    for _, order_board in ipairs((input.order and input.order.boards) or {}) do

        local metrics = order_metrics(order_board)

        local row = {
            order_board = order_board,
            offers      = {},
        }

        ------------------------------------------------------------
        -- INPUT BASELINE (optional)
        ------------------------------------------------------------

        local base_bf = resolve_bf_price(order_board)

        if type(base_bf) == "number" then
            local input_pr = project_pricing(base_bf, metrics)

            row.offers["input"] = {
                pricing = input_pr,
                meta    = { match_type = "INPUT" },
            }

            model.totals["input"].total =
                model.totals["input"].total + input_pr.total
        else
            row.offers["input"] = {
                pricing = {},
                meta    = { match_type = "NO_PRICE" },
            }
        end

        ------------------------------------------------------------
        -- SOURCES
        ------------------------------------------------------------

        for _, src in ipairs(input.sources or {}) do

            local matched, sig =
                BoardMatcher.match(order_board, src.boards or {})

            if matched then
                local vendor_bf = resolve_bf_price(matched)

                if type(vendor_bf) == "number" then
                    local pr = project_pricing(vendor_bf, metrics)

                    row.offers[src.name] = {
                        pricing = pr,
                        meta    = {
                            match_type = sig,
                            label      = matched.id or matched.label,
                        },
                    }

                    model.totals[src.name].total =
                        model.totals[src.name].total + pr.total
                else
                    row.offers[src.name] = {
                        pricing = {},
                        meta    = { match_type = "VENDOR_NO_PRICE" },
                    }
                end
            else
                row.offers[src.name] = {
                    pricing = {},
                    meta    = { match_type = "NO_MATCH" },
                }
            end
        end

        model.rows[#model.rows + 1] = row
    end

    return model
end

return Model
