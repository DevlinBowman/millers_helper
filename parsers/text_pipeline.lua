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

    -- ------------------------------------------------------------
    -- Structural fields (authoritative, from resolver)
    -- ------------------------------------------------------------
    local r = line._resolved or {}
    if r.h ~= nil then out.base_h = r.h end
    if r.w ~= nil then out.base_w = r.w end
    if r.l ~= nil then out.l = r.l end
    if r.ct ~= nil then out.ct = r.ct end
    if r.tag ~= nil then out.tag = r.tag end

    -- ------------------------------------------------------------
    -- Resolved tail claims → promoted fields
    -- Mirrors CSV normalization behavior
    -- ------------------------------------------------------------
    for _, claim in ipairs(line._picked or {}) do
        local field = claim.field
        local value = claim.value

        if field
            and value ~= nil
            and out[field] == nil
        then
            out[field] = value
        end
    end

    -- ------------------------------------------------------------
    -- Raw tail passthrough (explicit key=value lines, metadata)
    -- ------------------------------------------------------------
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
---@param opts table|nil -- { capture = Capture? }
---@return table -- { kind="records", data=..., meta=..., diagnostic? }
function TextPipeline.run(lines, opts)
    opts = opts or {}

    local Capture = require("parsers.text_pipeline.capture")

    -- ------------------------------------------------------------
    -- Run internal pipeline (produces full parser state per line)
    -- ------------------------------------------------------------
    local pipeline_out = InternalPipeline.run(lines, opts)

    assert(
        type(pipeline_out) == "table" and pipeline_out.kind == "records",
        "text pipeline internal must return kind='records'"
    )
    assert(type(pipeline_out.data) == "table", "text pipeline internal: missing data")

    local line_records = pipeline_out.data

    -- ------------------------------------------------------------
    -- Gate into canonical output (NO behavior change)
    -- ------------------------------------------------------------
    local data       = {}
    local diagnostic = {}

    for i, line in ipairs(line_records) do
        -- canonical ingestion record
        data[i] = build_ingestion_record(line)

        -- stable diagnostics
        diagnostic[i] = build_diagnostic(line)

        -- OPTIONAL: capture full internal parser state
        if opts.capture then
            Capture.record(opts.capture, i, line)
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

    result.meta.count = #data

    return result
end

return TextPipeline
