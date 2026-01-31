-- tools/inspection/targets.lua
--
-- Inspection targets.
-- Each target:
--   • declares dependencies
--   • mutates ctx.state
--   • never returns values

local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")
local FromLines = require("ingestion.normalization.from_lines")

local BoardRec  = require("ingestion.normalization.reconcile_board")
local Hydrate   = require("ingestion.hydrate.board")
local Adapter   = require("ingestion.adapter.readfile")

local ParserCapture = require("parsers.text_pipeline.capture")

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
-- TEXT → CANONICAL RECORDS (records contract, before reconcile)
----------------------------------------------------------------
Targets["text"] = {
    requires = { "io" },
    run = function(ctx)
        local raw = ctx.state.io

        if raw.kind == "lines" then
            ctx.state.text = FromLines.run(raw) -- returns kind="records"
        else
            -- CSV/JSON: keep raw; normalize target will convert
            ctx.state.text = raw
        end
    end
}

----------------------------------------------------------------
-- TEXT PARSER INTERNALS (tokens/chunks/claims/spans)
----------------------------------------------------------------
Targets["text.parser"] = {
    requires = { "io" },
    run = function(ctx)
        local raw = ctx.state.io
        assert(raw.kind == "lines", "text.parser only valid for line input")

        local cap = ParserCapture.new()

        FromLines.run(raw, {
            capture = cap,
        })

        ctx.state.text_parser = cap.lines
    end
}

----------------------------------------------------------------
-- NORMALIZE (CSV/JSON → records); pass-through if already records
----------------------------------------------------------------
Targets["normalize"] = {
    requires = { "text" },
    run = function(ctx)
        local val = ctx.state.text

        if val.kind == "table" then
            ctx.state.normalize = Normalize.table(val)
        elseif val.kind == "json" then
            ctx.state.normalize = Normalize.json(val)
        else
            -- already canonical records
            ctx.state.normalize = val
        end

        assert(ctx.state.normalize and ctx.state.normalize.kind == "records", "normalize must produce kind='records'")
    end
}

----------------------------------------------------------------
-- RECONCILE (inspection-safe): board_specs + errors (no crash)
----------------------------------------------------------------
Targets["reconcile"] = {
    requires = { "normalize" },
    run = function(ctx)
        local records = ctx.state.normalize
        assert(records and records.kind == "records", "reconcile expects kind='records'")

        local specs = {}
        local errors = {}
        local meta = records.meta or {}

        -- inspection-safe: convert record_to_spec per row
        for i, record in ipairs(records.data or {}) do
            local ok, spec_or_err = pcall(BoardRec.record_to_spec, record)
            if ok then
                specs[#specs + 1] = spec_or_err
            else
                errors[#errors + 1] = {
                    index  = i,
                    error  = spec_or_err,
                    record = record,
                }
            end
        end

        ctx.state.reconcile = {
            kind   = "board_specs",
            data   = specs,
            meta   = meta,
            errors = errors, -- inspection-only, but very useful
        }
    end
}

----------------------------------------------------------------
-- HYDRATE (inspection-only): hydrate valid specs; keep errors
----------------------------------------------------------------
Targets["hydrate"] = {
    requires = { "reconcile" },
    run = function(ctx)
        local specs = ctx.state.reconcile
        assert(specs and specs.kind == "board_specs", "hydrate expects kind='board_specs'")

        local hydrated = Hydrate.boards({
            kind = "board_specs",
            data = specs.data,
            meta = specs.meta,
        })

        -- attach reconcile errors for visibility
        hydrated.errors = specs.errors

        ctx.state.hydrate = hydrated
    end
}

----------------------------------------------------------------
-- FULL INGESTION (production path): call Adapter.ingest directly
----------------------------------------------------------------
Targets["ingest"] = {
    run = function(ctx)
        ctx.state.ingest = assert(Adapter.ingest(ctx.path))
    end
}

return Targets
