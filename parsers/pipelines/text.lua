-- parsers/pipelines/text.lua
--
-- Public contract wrapper for the text pipeline.
--
-- PURPOSE:
--   • Run the internal pipeline (inspection artifacts)
--   • Gate output into canonical ingestion shape
--   • Classify structural context per record
--
-- CONTRACT:
--   return {
--     data       = object[],
--     meta       = table,      -- meta.io preserved, meta.parse appended
--     diagnostic = table[]?,
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
-- Canonical record extraction
----------------------------------------------------------------

local function build_ingestion_record(line)
    local out = {}
    local r = line._resolved or {}

    if r.h ~= nil then out.base_h = r.h end
    if r.w ~= nil then out.base_w = r.w end
    if r.l ~= nil then out.l = r.l end
    if r.ct ~= nil then out.ct = r.ct end
    if r.tag ~= nil then out.tag = r.tag end

    for _, claim in ipairs(line._picked or {}) do
        local field = claim.field
        local value = claim.value

        if field and value ~= nil and out[field] == nil then
            out[field] = value
        end
    end

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
-- Structural Classification
----------------------------------------------------------------

local function classify_record(record)
    local has_board =
        record.base_h ~= nil
        or record.base_w ~= nil
        or record.l ~= nil
        or record.ct ~= nil
        or record.tag ~= nil

    local has_context = false

    for k, _ in pairs(record) do
        if k ~= "base_h"
            and k ~= "base_w"
            and k ~= "l"
            and k ~= "ct"
            and k ~= "tag"
        then
            has_context = true
            break
        end
    end

    if has_board and not has_context then
        return "board_only"
    elseif not has_board and has_context then
        return "context_only"
    elseif has_board and has_context then
        return "mixed"
    else
        return "context_only"
    end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string[]
---@param opts table|nil
---@return table result
function TextPipeline.run(lines, opts)
    opts = opts or {}

    local Capture = require("parsers.text_pipeline.capture")

    local pipeline_out = InternalPipeline.run(lines, opts)

    assert(
        type(pipeline_out) == "table"
        and type(pipeline_out.data) == "table",
        "text pipeline internal must return { data = object[] }"
    )

    local line_records   = pipeline_out.data

    local data           = {}
    local diagnostic     = {}

    local context_counts = {
        board_only   = 0,
        context_only = 0,
        mixed        = 0,
    }

    local contexts       = {}

    for i, line in ipairs(line_records) do
        local record            = build_ingestion_record(line)
        local context           = classify_record(record)

        context_counts[context] = context_counts[context] + 1
        contexts[i]             = context

        data[i]                 = record
        diagnostic[i]           = build_diagnostic(line)

        if opts.capture then
            Capture.record(opts.capture, i, line)
        end
    end

    ----------------------------------------------------------------
    -- META MERGE (preserve io provenance)
    ----------------------------------------------------------------

    local meta           = pipeline_out.meta or {}

    meta.parser          = "text_pipeline"
    meta.count           = #data
    meta.contexts        = contexts
    -- meta.context_summary = context_counts

    return {
        data       = data,
        meta       = meta,
        diagnostic = diagnostic,
    }
end

return TextPipeline
