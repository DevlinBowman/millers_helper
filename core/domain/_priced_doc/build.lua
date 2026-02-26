-- core/domain/_priced_doc/build.lua
--
-- Mechanical priced document builder.
-- Pure transformation of boards → rows + totals.
-- No formatting. No printing. No IO.

local Build = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function safe_number(value)
    return type(value) == "number" and value or 0
end

----------------------------------------------------------------
-- Row Construction
----------------------------------------------------------------

---@param boards table[]|nil
---@return table[]
local function build_rows(boards)
    local rows = {}

    for _, board in ipairs(boards or {}) do
        local quantity   = safe_number(board.ct or 1)
        local board_feet = safe_number(board.bf_batch)
        local rate       = safe_number(board.bf_price)

        rows[#rows + 1] = {
            ct          = quantity,
            label       = board.label,
            bf_total    = board_feet,
            bf_price    = rate,
            total_price = board_feet * rate,
        }
    end

    return rows
end

----------------------------------------------------------------
-- Totals Construction
----------------------------------------------------------------

---@param rows table[]
---@return table
local function build_totals(rows)
    local totals = {
        count = 0,
        bf    = 0,
        price = 0,
    }

    for _, row in ipairs(rows or {}) do
        totals.count = totals.count + safe_number(row.ct)
        totals.bf    = totals.bf + safe_number(row.bf_total)
        totals.price = totals.price + safe_number(row.total_price)
    end

    return totals
end

----------------------------------------------------------------
-- Public Entry
----------------------------------------------------------------

---@param args table
---@return table
function Build.run(args)
    assert(type(args) == "table", "_priced_doc.build requires args table")
    assert(type(args.boards) == "table", "_priced_doc.build requires boards")

    local rows = build_rows(args.boards)

    return {
        id           = args.id,
        generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        header       = args.header or {},
        rows         = rows,
        totals       = build_totals(rows),
    }
end

----------------------------------------------------------------

return Build
