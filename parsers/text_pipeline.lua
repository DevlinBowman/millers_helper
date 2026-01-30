-- parsers/text_pipeline.lua
--
-- Public contract wrapper for the text pipeline.
-- PURPOSE:
--   • Run the internal pipeline (inspection artifacts)
--   • Gate output into canonical records contract
--
-- CONTRACT:
--   return {
--     kind = "records",
--     data = table[],          -- canonical records ONLY
--     meta = table,
--     diagnostic = table[]?,   -- optional, stable structure
--     debug = table[]?         -- ONLY when opts.debug == true
--   }

local InternalPipeline = require("parsers.text_pipeline.pipeline")

local TextPipeline = {}

----------------------------------------------------------------
-- Diagnostics (user-facing, stable)
----------------------------------------------------------------

local function build_diagnostic(line)
    local diag = {
        ok      = true,
        signals = {},
    }

    local resolved = line._resolved or {}

    if next(resolved) == nil then
        diag.ok = false
        diag.signals[#diag.signals + 1] = {
            kind   = "unparsed_line",
            detail = "no usable structure recognized",
        }
        return diag
    end

    local leftovers = line._unused_groups or {}
    if #leftovers > 0 then
        diag.signals[#diag.signals + 1] = {
            kind   = "unrecognized_input",
            detail = leftovers,
        }
    end

    local contested = line._contested_groups or {}
    if #contested > 0 then
        diag.signals[#diag.signals + 1] = {
            kind   = "unclassified_but_considered",
            detail = contested,
        }
    end

    return diag
end

----------------------------------------------------------------
-- SACRED: canonical record extraction
----------------------------------------------------------------

local function build_ingestion_record(line)
    local out = {}

    local r = line._resolved or {}
    if r.h   ~= nil then out.h   = r.h end
    if r.w   ~= nil then out.w   = r.w end
    if r.l   ~= nil then out.l   = r.l end
    if r.ct  ~= nil then out.ct  = r.ct end
    if r.tag ~= nil then out.tag = r.tag end

    -- Tail passthrough (authoritative user data):
    -- Keep only non-internal keys from the preprocess record.
    for k, v in pairs(line) do
        if type(k) == "string"
            and not k:match("^_")
            and not k:match("^__")
            and out[k] == nil
        then
            out[k] = v
        end
    end

    return out
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string[]
---@param opts table|nil -- { debug = boolean }
---@return table -- { kind="records", data=..., meta=..., diagnostic?, debug? }
function TextPipeline.run(lines, opts)
    opts = opts or {}

    -- Run internal pipeline (produces inspection artifacts per line)
    local pipeline_out = InternalPipeline.run(lines, opts)

    assert(
        type(pipeline_out) == "table" and pipeline_out.kind == "records",
        "text pipeline internal must return kind='records'"
    )
    assert(type(pipeline_out.data) == "table", "text pipeline internal: missing data")

    local line_records = pipeline_out.data

    -- Gate into output tiers
    local data       = {}
    local diagnostic = {}
    local debug      = nil

    if opts.debug then
        debug = {}
    end

    for i, line in ipairs(line_records) do
        data[i]       = build_ingestion_record(line)
        diagnostic[i] = build_diagnostic(line)

        if opts.debug then
            debug[i] = line
        end
    end

    local result = {
        kind       = "records",
        data       = data,
        diagnostic = diagnostic,
        meta       = pipeline_out.meta or {
            parser = "text_pipeline",
            count  = #data,
        },
    }

    -- Ensure meta.count stays correct for canonical records
    result.meta = result.meta or {}
    result.meta.count = #data

    if opts.debug then
        result.debug = debug
    end

    return result
end

return TextPipeline
