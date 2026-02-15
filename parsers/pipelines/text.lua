-- parsers/pipelines/text.lua
--
-- Public contract wrapper for the text pipeline.
--
-- PURPOSE:
--   • Run structural extraction (raw_text)
--   • Run semantic parsing (text_engine)
--   • Gate output into canonical ingestion shape
--   • Classify structural context per record

local RawText    = require("parsers.raw_text").controller
local TextEngine = require("parsers.pipelines.text_engine").controller

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

    if r.h   ~= nil then out.base_h = r.h end
    if r.w   ~= nil then out.base_w = r.w end
    if r.l   ~= nil then out.l      = r.l end
    if r.ct  ~= nil then out.ct     = r.ct end
    if r.tag ~= nil then out.tag    = r.tag end

    for _, claim in ipairs(line._picked or {}) do
        if claim.field and claim.value ~= nil and out[claim.field] == nil then
            out[claim.field] = claim.value
        end
    end

    -- preserve structural tail assignments from raw_text
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

    ----------------------------------------------------------------
    -- 1. Structural extraction (raw_text)
    ----------------------------------------------------------------
    local structural_records = RawText.run(lines)

    ----------------------------------------------------------------
    -- 2. Semantic parsing (text_engine)
    ----------------------------------------------------------------
    local pipeline_out = TextEngine.run(structural_records, opts)

    assert(
        type(pipeline_out) == "table"
        and type(pipeline_out.data) == "table",
        "text_engine must return { data = object[] }"
    )

    local line_records = pipeline_out.data

    local data       = {}
    local diagnostic = {}
    local contexts   = {}

    for i, line in ipairs(line_records) do
        local record  = build_ingestion_record(line)
        local context = classify_record(record)

        contexts[i]   = context
        data[i]       = record
        diagnostic[i] = build_diagnostic(line)
    end

    ----------------------------------------------------------------
    -- META MERGE
    ----------------------------------------------------------------
    local meta = pipeline_out.meta or {}

    meta.parser   = "text_pipeline"
    meta.count    = #data
    meta.contexts = contexts

    return {
        data       = data,
        meta       = meta,
        diagnostic = diagnostic,
    }
end

return TextPipeline
