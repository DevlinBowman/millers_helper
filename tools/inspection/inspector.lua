-- tools/inspection/inspector.lua
--
-- Inspection orchestrator (INGESTION V2)
--
-- Guarantees:
--   • NO mutation
--   • NO enforcement
--   • Single source of truth = ingestion_v2
--   • Stable state keys for debug.view

local Read       = require("file_handler")
local Normalize  = require("file_handler.normalize")
local TextParser = require("parsers.text_pipeline")
local Capture    = require("parsers.text_pipeline.capture")

local IngestV2   = require("ingestion_v2.adapter")
local Stages     = require("tools.inspection.stages")

local Inspector = {}

---@param path string
---@param opts table|nil
---@return table state
function Inspector.run(path, opts)
    opts = opts or {}

    local state = {}

    ----------------------------------------------------------------
    -- READ
    ----------------------------------------------------------------
    local raw = assert(Read.read(path))
    state.read = raw

    if opts.stop_at == Stages.READ then
        return state
    end

    ----------------------------------------------------------------
    -- RECORDS (canonical)
    ----------------------------------------------------------------
    local records

    if raw.kind == "lines" then
        local parser_cap
        if opts.parser_capture then
            parser_cap = Capture.new()
        end

        records = TextParser.run(raw.data, {
            capture = parser_cap,
        })

        if parser_cap then
            state.text_parser = parser_cap.lines
        end
    elseif raw.kind == "table" then
        records = Normalize.table(raw)
    elseif raw.kind == "json" then
        records = Normalize.json(raw)
    else
        error("Unsupported input kind: " .. tostring(raw.kind))
    end

    assert(records.kind == "records", "records stage must produce kind='records'")
    state.records = records

    if opts.stop_at == Stages.RECORDS then
        return state
    end

    if opts.stop_at == Stages.TEXT_PARSER then
        return state
    end

    ----------------------------------------------------------------
    -- INGEST (authoritative)
    ----------------------------------------------------------------
    state.ingest = IngestV2.ingest(path)

    return state
end

return Inspector
