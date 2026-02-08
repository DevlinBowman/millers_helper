-- tools/inspection/targets.lua
--
-- Inspection targets.
-- Each target:
--   • declares dependencies
--   • mutates ctx.state
--   • never returns values

local Read       = require("file_handler")
local ReaderV2   = require("ingestion.reader")
local AdapterV2  = require("ingestion.adapter")

local ParserCapture = require("parsers.text_pipeline.capture")
local TextParser    = require("parsers.text_pipeline")

local Targets = {}

----------------------------------------------------------------
-- RAW FILE IO
----------------------------------------------------------------
Targets["io"] = {
    run = function(ctx)
        ctx.state.io = assert(Read.read(ctx.path))
    end
}

----------------------------------------------------------------
-- CANONICAL RECORDS (production reader contract)
--   file → ingestion_v2.reader.read → kind="records"
----------------------------------------------------------------
Targets["records"] = {
    run = function(ctx)
        ctx.state.records = ReaderV2.read(ctx.path)
        assert(ctx.state.records and ctx.state.records.kind == "records", "records must be kind='records'")
    end
}

----------------------------------------------------------------
-- TEXT PARSER INTERNALS (tokens/chunks/claims/spans)
--   Only valid for raw line input.
--   This target is *inspection-only* and does not replace reader/adapter.
----------------------------------------------------------------
Targets["text.parser"] = {
    requires = { "io" },
    run = function(ctx)
        local raw = ctx.state.io
        assert(raw and raw.kind == "lines", "text.parser only valid for line input")

        local cap = ParserCapture.new()
        TextParser.run(raw.data, { capture = cap })

        ctx.state.text_parser = cap.lines
    end
}

----------------------------------------------------------------
-- FULL INGESTION (production path): call ingestion_v2.adapter.ingest
----------------------------------------------------------------
Targets["ingest"] = {
    run = function(ctx)
        ctx.state.ingest = AdapterV2.ingest(ctx.path)
        assert(ctx.state.ingest and ctx.state.ingest.kind == "ingest_result", "ingest must return kind='ingest_result'")
    end
}

return Targets
