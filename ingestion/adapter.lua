-- ingestion_v2/adapter.lua
--
-- FINAL CONTRACT GATE

local Reader    = require("ingestion.reader")
local Hygiene   = require("ingestion.record_hygiene")
local Builder   = require("ingestion.record_builder")
local Premap    = require("ingestion.record_board_dimension_premap")
local Validator = require("ingestion.record_validator")
local Board     = require("core.board.board")

local Adapter = {}

----------------------------------------------------------------
-- Derived field resolvers (EXPLICIT)
----------------------------------------------------------------

local DERIVED_RESOLVERS = {
    bf_batch = function(b) return b.bf_batch end,
    value = function(b)
        if b.bf_price then
            return b.bf_batch * b.bf_price
        end
        return nil
    end,
}


local function push_all(dst, src)
    for i = 1, #src do dst[#dst+1] = src[i] end
end

local function has_error_for_index(errors, index)
    for _, e in ipairs(errors) do
        if e.index == index then return true end
    end
    return false
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Adapter.ingest(path, opts)
    opts = opts or {}

    local records = Reader.read(path, opts)

    local boards = {}
    local signals = { errors = {}, warnings = {} }

    local extra_allowed = opts.allowed_extra_fields or {
        "note", "notes", "usage", "useage", "source", "category"
    }

    for index, raw in ipairs(records.data) do
        Hygiene.apply(raw)

        local record = Builder.build(raw)
        Premap.apply(record)
        local head = record.head

        push_all(signals.errors,
            Validator.check_missing_dimensions(record, index, head)
        )

        push_all(signals.warnings,
            Validator.check_unmapped_fields(record, index, head, extra_allowed)
        )

        push_all(signals.warnings,
            Validator.check_derived_field_overrides(record, index, head)
        )

        if not has_error_for_index(signals.errors, index) then
            local ok, board_or_err = pcall(Board.new, record)
            if ok then
                local board = board_or_err
                boards[#boards+1] = board

                for _, w in ipairs(signals.warnings) do
                    if w.index == index
                        and w.code == "ingest.derived_field_overridden"
                    then
                        local fn = DERIVED_RESOLVERS[w.key]
                        if fn then
                            w.outcome_value = fn(board)
                        end
                    end
                end
            else
                signals.errors[#signals.errors+1] = {
                    level   = "error",
                    code    = "board.construction_failed",
                    index   = index,
                    head    = head,
                    message = tostring(board_or_err),
                }
            end
        end
    end

    return {
        kind = "ingest_result",
        boards = { kind = "boards", data = boards },
        signals = signals,
        errors = signals.errors,
        warnings = signals.warnings,
        meta = {
            source_path    = path,
            total_records  = #records.data,
            boards_created = #boards,
            error_count    = #signals.errors,
            warning_count  = #signals.warnings,
        }
    }
end

return Adapter
