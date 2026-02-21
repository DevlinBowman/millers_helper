-- core/domain/invoice/pipelines/build.lua
--
-- Invoice build pipeline
-- Pure orchestration: transforms input -> invoice model

local Build = {}

local function safe_number(value)
    if type(value) == "number" then
        return value
    end
    return 0
end

local function build_rows(boards)
    local rows = {}

    for _, board in ipairs(boards or {}) do
        local count     = safe_number(board.count or board.ct or 1)
        local bf_each   = safe_number(board.bf or board.bf_ea)
        local bf_total  = safe_number(board.bf_total) > 0
            and board.bf_total
            or (bf_each * count)

        local rate      = safe_number(board.bf_price)
        local amount    = bf_total * rate

        rows[#rows + 1] = {
            ct          = count,
            label       = board.label or board.dimension or "BOARD",
            bf_total    = bf_total,
            bf_price    = rate,
            total_price = amount,
        }
    end

    return rows
end

local function build_totals(rows)
    local totals = {
        count = 0,
        bf    = 0,
        price = 0,
    }

    for _, r in ipairs(rows or {}) do
        totals.count = totals.count + safe_number(r.ct)
        totals.bf    = totals.bf + safe_number(r.bf_total)
        totals.price = totals.price + safe_number(r.total_price)
    end

    return totals
end

local function build_header(input)
    if not input.order then
        return nil
    end

    return {
        order_id = input.order.id,
        customer = input.order.customer,
    }
end

----------------------------------------------------------------

function Build.run(input, signals)
    local rows   = build_rows(input.boards)
    local totals = build_totals(rows)
    local header = build_header(input)

    return {
        header = header,
        rows   = rows,
        totals = totals,
    }
end

return Build
