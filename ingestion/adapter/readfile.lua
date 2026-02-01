-- ingestion/adapter/readfile.lua
--
-- INGESTION ADAPTER (CONTRACT GATE)
--
-- EXACT RESPONSIBILITY:
--   • This is the FINAL gate before data leaves ingestion.
--   • No data becomes authoritative unless it passes through Board.new().
--   • Bad inputs MUST NOT crash ingestion.
--   • Bad inputs MUST surface as structured, explicit rejections.
--
-- CONTRACT:
--   records
--     → attempt board_specs
--         → success → boards[]
--         → failure → rejected_lines[]
--
-- NOTE FOR FUTURE:
--   Rejected lines indicate either malformed input or parser coverage gaps.
--   Please update the input line OR extend parser rules to handle these cases.

local Pipeline = require("ingestion.pipeline")
local BoardRec = require("ingestion.normalization.reconcile_board")
local Board    = require("core.board.board")

local Adapter = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function classify_missing_dimensions(spec)
    local missing = {}

    if not spec.base_h then missing[#missing + 1] = "base_h" end
    if not spec.base_w then missing[#missing + 1] = "base_w" end
    if not spec.l      then missing[#missing + 1] = "l"      end

    return missing
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param path string
---@param opts table|nil
---@param debug_opts table|nil
---@return table|nil ingest_result
---@return string|nil error
function Adapter.ingest(path, opts, debug_opts)
    opts = opts or {}
    debug_opts = debug_opts or {}

    -- ------------------------------------------------------------
    -- Stage 1: File → Records (single normalized entry point)
    -- ------------------------------------------------------------
    local records, err = Pipeline.run_file(path, opts, debug_opts)
    if not records then
        return nil, err
    end

    assert(
        records.kind == "records",
        "Adapter.ingest(): pipeline must return kind='records'"
    )

    local boards = {}
    local rejected = {}

    -- ------------------------------------------------------------
    -- Stage 2: Record-by-record reconciliation + hydration
    -- ------------------------------------------------------------
    for index, record in ipairs(records.data) do
        -- Attempt to reconcile record → board spec
        local ok_spec, spec_or_err = pcall(BoardRec.record_to_spec, record)

        if not ok_spec then
            -- Structural failure before board creation
            rejected[#rejected + 1] = {
                index   = index,
                reason  = "invalid_board_spec",
                message = "Missing required board dimensions",
                missing = classify_missing_dimensions(record),
                head    = record.head,
                record  = record,
                note    = "Please update the line or address your parser rules to handle this in the future.",
            }
            goto continue
        end

        local spec = spec_or_err

        -- Explicit missing-dimension classification
        local missing = classify_missing_dimensions(spec)
        if #missing > 0 then
            rejected[#rejected + 1] = {
                index   = index,
                reason  = "missing_required_dimensions",
                missing = missing,
                head    = record.head,
                record  = record,
                note    = "Please update the line or address your parser rules to handle this in the future.",
            }
            goto continue
        end

        -- Attempt to hydrate spec → Board (authoritative)
        local ok_board, board_or_err = pcall(Board.new, spec)
        if not ok_board then
            rejected[#rejected + 1] = {
                index   = index,
                reason  = "board_hydration_failed",
                error   = board_or_err,
                head    = record.head,
                record  = record,
                note    = "Please update the line or address your parser rules to handle this in the future.",
            }
            goto continue
        end

        boards[#boards + 1] = board_or_err

        ::continue::
    end

    -- ------------------------------------------------------------
    -- Final ingestion result (NON-AMBIGUOUS)
    -- ------------------------------------------------------------
    return {
        kind = "ingest_result",

        boards = {
            kind = "boards",
            data = boards,
        },

        rejected_lines = rejected,

        meta = {
            source_path = path,
            total_records = #records.data,
            boards_created = #boards,
            rejected_count = #rejected,
            parser = records.meta and records.meta.parser,
        },
    }, nil
end

return Adapter
