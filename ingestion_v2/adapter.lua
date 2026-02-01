-- ingestion_v2/adapter.lua
--
-- FINAL CONTRACT GATE
--
-- file
--   → records
--     → diagnostics (signals only)
--     → Board.new(record)
--         → boards[]
--         → error / warning signals[]
--
-- GUARANTEES:
--   • Board.new() is the ONLY enforcement boundary
--   • No bad input crashes ingestion
--   • All problems are surfaced as explicit signals
--   • No parser artifacts escape ingestion

local Reader    = require("ingestion_v2.reader")
local Hygiene   = require("ingestion_v2.record_hygiene")
local Builder   = require("ingestion_v2.record_builder")
local Premap    = require("ingestion_v2.record_board_dimension_premap")
local Validator = require("ingestion_v2.record_validator")
local Board     = require("core.board.board")

local Adapter = {}

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

local function push_all(dst, src)
    for i = 1, #src do
        dst[#dst + 1] = src[i]
    end
end

local function has_error_for_index(errors, index, code)
    for _, e in ipairs(errors) do
        if e.index == index and (code == nil or e.code == code) then
            return true
        end
    end
    return false
end

local function classify_board_failure(record, index, head, board_err)
    local missing = Validator.missing_dimensions(record)

    if #missing > 0 then
        return {
            level   = "error",
            code    = "board.missing_required_dimensions",
            index   = index,
            head    = head,
            missing = missing,
            message = "Missing required board dimensions: " .. table.concat(missing, ", "),
            error   = tostring(board_err),
            note    = "Please update this line or extend parser rules to handle this case.",
        }
    end

    return {
        level   = "error",
        code    = "board.construction_failed",
        index   = index,
        head    = head,
        message = "Board construction failed",
        error   = tostring(board_err),
        note    = "Please review this line or extend parser rules to handle this case.",
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param path string
---@param opts table|nil
---@return table ingest_result
function Adapter.ingest(path, opts)
    opts = opts or {}

    ----------------------------------------------------------------
    -- Stage 1: Read file → records (NO board logic)
    ----------------------------------------------------------------
    local records = Reader.read(path, opts)

    local boards  = {}
    local signals = {
        errors   = {},
        warnings = {},
    }

    -- allowlist for “extra” record keys you explicitly tolerate
    local extra_allowed = opts.allowed_extra_fields or {
        "note", "notes",
        "usage", "useage",
        "source", "category",
    }

    ----------------------------------------------------------------
    -- Stage 2: Record-by-record processing
    ----------------------------------------------------------------
for index, raw in ipairs(records.data) do
    ------------------------------------------------------------
    -- 2a) Hygiene (silent, mechanical)
    ------------------------------------------------------------
    Hygiene.apply(raw)

    ------------------------------------------------------------
    -- 2b) Builder + dimension pre-map
    ------------------------------------------------------------
    local record = Builder.build(raw)
    Premap.apply(record)
    local head = record.head

    ------------------------------------------------------------
    -- 2c) Validation signals (NON-FATAL)
    ------------------------------------------------------------
    push_all(signals.errors,   Validator.check_missing_dimensions(record, index, head))
    push_all(signals.warnings, Validator.check_unmapped_fields(record, index, head, extra_allowed))

    ------------------------------------------------------------
    -- 2d) Attempt authoritative board construction
    ------------------------------------------------------------
    if not has_error_for_index(signals.errors, index, "board.missing_required_dimensions") then
        local ok, board_or_err = pcall(Board.new, record)
        if ok then
            boards[#boards + 1] = board_or_err
        else
            signals.errors[#signals.errors + 1] =
                classify_board_failure(record, index, head, board_or_err)
        end
    end
end

    ----------------------------------------------------------------
    -- Final, explicit ingestion result
    ----------------------------------------------------------------
    local meta = {
        source_path    = path,
        total_records  = #records.data,
        boards_created = #boards,
        error_count    = #signals.errors,
        warning_count  = #signals.warnings,
    }

    return {
        kind = "ingest_result",

        boards = {
            kind = "boards",
            data = boards,
        },

        -- preferred
        signals = signals,

        -- compatibility / convenience
        errors   = signals.errors,
        warnings = signals.warnings,

        meta = meta,
    }
end

return Adapter
