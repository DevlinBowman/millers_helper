local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")
local FromLines = require("ingestion.normalization.from_lines")
local BoardRec  = require("ingestion.normalization.reconcile_board")
local Hydrate   = require("ingestion.hydrate.board")

local ParserCapture = require('parsers.text_pipeline.capture')
local Stages    = require("tools.inspection.stages")
local Capture   = require("tools.inspection.capture")

local Inspector = {}

---@param path string
---@param opts table|nil
-- opts = {
--   stop_at = Stages.*,
--   capture = Capture,
-- }
function Inspector.run(path, opts)
    opts = opts or {}
    local cap = opts.capture

    local state = {}

    ----------------------------------------------------------------
    -- READ
    ----------------------------------------------------------------
    local raw = assert(Read.read(path))
    state.read = raw
    Capture.record(cap, Stages.READ, raw)

    if opts.stop_at == Stages.READ then
        return state
    end

    ----------------------------------------------------------------
    -- TEXT PARSE
    ----------------------------------------------------------------
    if raw.kind == "lines" then
        -- parser-specific capture (line-indexed)
        local parser_cap = ParserCapture.new()

        local records = FromLines.run(raw, {
            capture = parser_cap, -- ✅ correct object for parser
        })

        state.text_parse = records

        -- record inspection snapshot (stage-oriented)
        Capture.record(cap, Stages.TEXT_PARSE, {
            records = records,      -- canonical ingestion records
            parser  = parser_cap.lines, -- full parser internals
        })

        if opts.stop_at == Stages.TEXT_PARSE then
            return state
        end

        raw = records
    end

    ----------------------------------------------------------------
    -- NORMALIZE (CSV / JSON)
    ----------------------------------------------------------------
    if raw.kind == "table" then
        raw = Normalize.table(raw)
        state.normalize = raw
        Capture.record(cap, Stages.NORMALIZE, raw)

        if opts.stop_at == Stages.NORMALIZE then
            return state
        end
    elseif raw.kind == "json" then
        raw = Normalize.json(raw)
        state.normalize = raw
        Capture.record(cap, Stages.NORMALIZE, raw)

        if opts.stop_at == Stages.NORMALIZE then
            return state
        end
    end

    ----------------------------------------------------------------
    -- RECONCILE
    ----------------------------------------------------------------
    local specs = BoardRec.run(raw)
    state.reconcile = specs
    Capture.record(cap, Stages.RECONCILE, specs)

    if opts.stop_at == Stages.RECONCILE then
        return state
    end

    ----------------------------------------------------------------
    -- HYDRATE
    ----------------------------------------------------------------
    local boards = Hydrate.boards(specs)
    state.hydrate = boards
    Capture.record(cap, Stages.HYDRATE, boards)

    return state
end

return Inspector
