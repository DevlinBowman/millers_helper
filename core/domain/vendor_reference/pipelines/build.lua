-- core/domain/vendor_reference/pipelines/build.lua
--
-- Build canonical rows from arbitrary board-like items.
-- No trace. No validation of input shape beyond simple type usage.

local Registry = require("core.domain.vendor_reference.registry")

local Build = {}

function Build.run(boards, vendor_name)

    local Signals = Registry.signals
    local Schema  = Registry.schema

    local sig = Signals.new()

    if type(boards) ~= "table" then
        Signals.err(sig, "invalid_boards", "boards must be table", {
            got = type(boards)
        })
        return { rows = {}, signals = sig }
    end

    sig.stats.input_count = #boards

    local rows = {}

    for i = 1, #boards do
        local board = boards[i]

        --------------------------------------------------------
        -- Canonical Board Invariants
        --------------------------------------------------------

        if type(board) ~= "table" then
            Signals.warn(sig, "board_excluded", "invalid_type", { index = i })
            sig.stats.invalid_count = sig.stats.invalid_count + 1
            goto continue
        end

        if not board.base_h or not board.base_w or not board.l then
            Signals.warn(sig, "board_excluded", "missing_dims", { index = i })
            sig.stats.invalid_count = sig.stats.invalid_count + 1
            goto continue
        end

        if not board.grade then
            Signals.warn(sig, "board_excluded", "missing_grade", { index = i })
            sig.stats.invalid_count = sig.stats.invalid_count + 1
            goto continue
        end

        if not (board.ea_price or board.bf_price or board.lf_price) then
            Signals.warn(sig, "board_excluded", "missing_price", { index = i })
            sig.stats.invalid_count = sig.stats.invalid_count + 1
            goto continue
        end

        --------------------------------------------------------
        -- Minimal Vendor Projection
        --------------------------------------------------------

        rows[#rows + 1] = {
            vendor   = vendor_name,
            label    = board.label or board.id,
            base_h   = board.base_h,
            base_w   = board.base_w,
            l        = board.l,
            ct       = board.ct or 1,
            tag      = board.tag,
            species  = board.species,
            grade    = board.grade,
            moisture = board.moisture,
            surface  = board.surface,
            ea_price = board.ea_price,
            bf_price = board.bf_price,
            lf_price = board.lf_price,
        }

        ::continue::
    end

    local valid_rows = Schema.validate_rows(rows, sig, Signals)

    return {
        rows    = valid_rows,
        signals = sig,
    }
end

return Build
