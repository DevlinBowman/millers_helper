-- core/invoice/model.lua
--
-- Builds InvoiceModel from authoritative Board records.
-- Fault-tolerant via Signals (rows may be skipped).

local Contract = require("core.invoice.contract")
local Signals  = require("core.diagnostics.signals")

local Model = {}

local function safe_number(x)
    return type(x) == "number" and x or nil
end

function Model.build(input)
    local sig = Contract.validate(input)

    local rows   = {}
    local totals = { count = 0, bf = 0, price = 0 }

    if type(input) ~= "table" or type(input.boards) ~= "table" then
        Signals.error(
            sig,
            "INPUT_INVALID",
            "invoice.input",
            "cannot build invoice: invalid input shape",
            nil
        )
        return { rows = rows, totals = totals, signals = sig }
    end

    for i, b in ipairs(input.boards) do
        local path = ("boards[%d]"):format(i)

        if type(b) ~= "table" then
            Signals.error(sig, "ROW_SKIPPED", path, "board is not a table", nil)
        elseif type(b.physical) ~= "table" or type(b.pricing) ~= "table" then
            Signals.error(sig, "ROW_SKIPPED", path, "missing physical or pricing", nil)
        else
            local p  = b.physical
            local pr = b.pricing

            local h        = safe_number(p.h)
            local w        = safe_number(p.w)
            local l        = safe_number(p.l)
            local ct       = safe_number(p.ct)
            local bf_each  = safe_number(p.bf_ea)
            local bf_total = safe_number(p.bf_batch)

            if not (type(b.id) == "string" and h and w and l and ct and bf_each and bf_total) then
                Signals.error(
                    sig,
                    "ROW_SKIPPED",
                    path,
                    "missing required physical fields",
                    { id = b.id }
                )
            else
                local total_price = safe_number(pr.batch_price) or 0

                rows[#rows + 1] = {
                    id          = b.id,
                    label       = b.label or b.id,

                    h           = h,
                    w           = w,
                    l           = l,
                    ct          = ct,

                    grade       = p.grade,
                    surface     = p.surface,
                    note        = type(b.context) == "table" and b.context.note or nil,

                    bf_each     = bf_each,
                    bf_total    = bf_total,

                    ea_price    = safe_number(pr.ea_price),
                    bf_price    = safe_number(pr.bf_price),
                    total_price = total_price,
                }

                totals.count = totals.count + ct
                totals.bf    = totals.bf + bf_total
                totals.price = totals.price + total_price
            end
        end
    end

    if #rows == 0 then
        Signals.warn(
            sig,
            "NO_ROWS",
            "invoice.rows",
            "no invoice rows were produced",
            nil
        )
    end

    return {
        rows    = rows,
        totals  = totals,
        signals = sig,
    }
end

return Model
