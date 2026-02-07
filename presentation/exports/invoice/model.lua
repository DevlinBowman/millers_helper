-- presentation/exports/invoice/model.lua
--
-- Builds invoice view-model rows from authoritative Board (grouped output).
-- Uses Signals for debug and non-fatal fault tolerance:
--   - invalid boards are skipped with a signal instead of crashing.

local Contract = require("presentation.exports.invoice.contract")
local Signals  = require("core.diagnostics.signals")

local M        = {}

local function safe_number(x)
    return type(x) == "number" and x or nil
end

function M.build(input)
    local sig = Contract.validate(input)

    local rows = {}
    local totals = { count = 0, bf = 0, price = 0 }

    if type(input) ~= "table" or type(input.boards) ~= "table" then
        Signals.error(sig, "INPUT_INVALID", "invoice.input", "cannot build invoice: invalid input shape", nil)
        return { rows = {}, totals = totals, signals = sig }
    end

    for i, b in ipairs(input.boards) do
        local base_path = ("boards[%d]"):format(i)

        if type(b) ~= "table" then
            Signals.error(sig, "ROW_SKIPPED", base_path, "skipping non-table board", { got = type(b) })
        elseif type(b.physical) ~= "table" or type(b.pricing) ~= "table" then
            Signals.error(sig, "ROW_SKIPPED", base_path, "skipping board missing physical/pricing", {
                has_physical = type(b.physical),
                has_pricing  = type(b.pricing),
            })
        else
            local p        = b.physical
            local pr       = b.pricing

            -- Minimal requirements to produce a row safely
            local h        = safe_number(p.h)
            local w        = safe_number(p.w)
            local l        = safe_number(p.l)
            local ct       = safe_number(p.ct)
            local bf_each  = safe_number(p.bf_ea)
            local bf_total = safe_number(p.bf_batch)

            if not (type(b.id) == "string" and h and w and l and ct and bf_each and bf_total) then
                Signals.error(sig, "ROW_SKIPPED", base_path, "skipping board due to missing required fields", {
                    id = b.id,
                    h = p.h,
                    w = p.w,
                    l = p.l,
                    ct = p.ct,
                    bf_ea = p.bf_ea,
                    bf_batch = p.bf_batch,
                })
            else
                local total_price = safe_number(pr.batch_price) or 0

                rows[#rows + 1]   = {
                    id          = b.id,
                    label       = b.label or b.id,

                    h           = h,
                    w           = w,
                    l           = l,
                    ct          = ct,

                    grade       = p.grade,
                    surface     = p.surface,
                    note        = (type(b.context) == "table" and b.context.note) or nil,

                    bf_each     = bf_each,
                    bf_total    = bf_total,

                    ea_price    = safe_number(pr.ea_price),
                    bf_price    = safe_number(pr.bf_price),
                    total_price = total_price,
                }

                totals.count      = totals.count + ct
                totals.bf         = totals.bf + bf_total
                totals.price      = totals.price + total_price
            end
        end
    end

    -- Merge any signals coming from capture/build_input if present
    if type(input.signals) == "table" and type(input.signals.items) == "table" then
        Signals.merge(sig, input.signals)
    end

    if #rows == 0 then
        Signals.warn(sig, "NO_ROWS", "invoice.rows",
            "no invoice rows were produced (all boards skipped or none provided)", nil)
    end

    return { rows = rows, totals = totals, signals = sig }
end

return M
