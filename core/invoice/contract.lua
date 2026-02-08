-- presentation/exports/invoice/contract.lua
--
-- Validates invoice input shape using Signals (non-fatal).
-- Does not compute or derive domain facts (Board is authoritative).

local Signals = require("core.diagnostics.signals")

local M = {}

local function is_num(x)
    return type(x) == "number"
end

--- @param input table
--- @return SignalBag signals
function M.validate(input)
    local sig = Signals.new()

    if type(input) ~= "table" then
        Signals.error(sig, "INPUT_NOT_TABLE", "invoice.input", "invoice input must be a table", { got = type(input) })
        return sig
    end

    if type(input.boards) ~= "table" then
        Signals.error(sig, "BOARDS_MISSING", "invoice.input.boards", "invoice.boards required", { got = type(input.boards) })
        return sig
    end

    for i, b in ipairs(input.boards) do
        local base_path = ("boards[%d]"):format(i)

        if type(b) ~= "table" then
            Signals.error(sig, "BOARD_NOT_TABLE", base_path, "board must be a table", { got = type(b) })
        else
            if type(b.id) ~= "string" then
                Signals.error(sig, "BOARD_ID_MISSING", base_path .. ".id", "board.id required", { got = type(b.id) })
            end

            if type(b.physical) ~= "table" then
                Signals.error(sig, "PHYSICAL_MISSING", base_path .. ".physical", "board.physical required", { got = type(b.physical) })
            end

            if type(b.pricing) ~= "table" then
                Signals.error(sig, "PRICING_MISSING", base_path .. ".pricing", "board.pricing required", { got = type(b.pricing) })
            end

            local p = b.physical
            if type(p) == "table" then
                if not is_num(p.h) then Signals.error(sig, "BAD_H", base_path .. ".physical.h", "physical.h must be a number", { got = p.h }) end
                if not is_num(p.w) then Signals.error(sig, "BAD_W", base_path .. ".physical.w", "physical.w must be a number", { got = p.w }) end
                if not is_num(p.l) then Signals.error(sig, "BAD_L", base_path .. ".physical.l", "physical.l must be a number", { got = p.l }) end
                if not is_num(p.ct) then
                    Signals.error(sig, "BAD_CT", base_path .. ".physical.ct", "physical.ct must be a number", { got = p.ct })
                elseif p.ct < 1 then
                    Signals.error(sig, "CT_LT_1", base_path .. ".physical.ct", "physical.ct must be >= 1", { got = p.ct })
                end

                if not is_num(p.bf_ea) then Signals.error(sig, "BAD_BF_EA", base_path .. ".physical.bf_ea", "physical.bf_ea must be a number", { got = p.bf_ea }) end
                if not is_num(p.bf_batch) then Signals.error(sig, "BAD_BF_BATCH", base_path .. ".physical.bf_batch", "physical.bf_batch must be a number", { got = p.bf_batch }) end
            end

            local pr = b.pricing
            if type(pr) == "table" then
                if pr.bf_price ~= nil and not is_num(pr.bf_price) then
                    Signals.error(sig, "BAD_BF_PRICE", base_path .. ".pricing.bf_price", "pricing.bf_price must be a number when present", { got = pr.bf_price })
                end
                if pr.ea_price ~= nil and not is_num(pr.ea_price) then
                    Signals.error(sig, "BAD_EA_PRICE", base_path .. ".pricing.ea_price", "pricing.ea_price must be a number when present", { got = pr.ea_price })
                end
                if pr.batch_price ~= nil and not is_num(pr.batch_price) then
                    Signals.error(sig, "BAD_BATCH_PRICE", base_path .. ".pricing.batch_price", "pricing.batch_price must be a number when present", { got = pr.batch_price })
                end
            end
        end
    end

    return sig
end

return M
