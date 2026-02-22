local Fmt = require("core.model.fmt").controller

local Build = {}

local function safe_number(n)
    return type(n) == "number" and n or 0
end

local function build_rows(boards)
    local rows = {}

    for _, board in ipairs(boards or {}) do
        local count    = safe_number(board.ct or 1)
        local bf_total = safe_number(board.bf_batch)
        local rate     = safe_number(board.bf_price)

        rows[#rows + 1] = {
            ct          = count,
            label       = Fmt.format(board, "board_label_no_ct"),
            bf_total    = bf_total,
            bf_price    = rate,
            total_price = bf_total * rate,
        }
    end

    return rows
end

local function build_totals(rows)
    local totals = { count = 0, bf = 0, price = 0 }

    for _, r in ipairs(rows) do
        totals.count = totals.count + safe_number(r.ct)
        totals.bf    = totals.bf + safe_number(r.bf_total)
        totals.price = totals.price + safe_number(r.total_price)
    end

    return totals
end

function Build.run(args)
    assert(type(args.boards) == "table", "_priced_doc.build requires boards")

    local rows   = build_rows(args.boards)
    local totals = build_totals(rows)

    return {
        id           = args.id,
        generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        header       = args.header or {},
        rows         = rows,
        totals       = totals,
    }
end

return Build
