-- parsers/pipelines/text.lua
--
-- Public contract wrapper for the text pipeline.

local RawText    = require("platform.parsers.raw_text").controller
local TextEngine = require("platform.parsers.pipelines.text_engine").controller

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

    -- Only mark unparsed if semantic head existed
    if next(resolved) == nil and (line.head and line.head ~= "") then
        diag.ok = false
        diag.signals[#diag.signals + 1] = {
            kind   = "unparsed_line",
            detail = "no usable structure recognized",
        }
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

    -- board fields
    if r.h   ~= nil then out.base_h = r.h end
    if r.w   ~= nil then out.base_w = r.w end
    if r.l   ~= nil then out.l      = r.l end
    if r.ct  ~= nil then out.ct     = r.ct end
    if r.tag ~= nil then out.tag    = r.tag end

    -- propagate picked claims
    for _, claim in ipairs(line._picked or {}) do
        if claim.field and claim.value ~= nil and out[claim.field] == nil then
            out[claim.field] = claim.value
        end
    end

    -- preserve structural tail assignments
    for k, v in pairs(line) do
        if type(k) == "string"
            and not k:match("^_")
            and not k:match("^__")
            and out[k] == nil
        then
            out[k] = v
        end
    end

    -- preserve origin info
    out.raw   = line.raw
    out.head  = line.head
    out.index = line.index

    return out
end

----------------------------------------------------------------
-- Structural Classification
----------------------------------------------------------------

local BOARD_FIELDS = {
    base_h = true,
    base_w = true,
    l      = true,
    ct     = true,
    tag    = true,
    h      = true,
    w      = true,
}

local SYSTEM_FIELDS = {
    raw   = true,
    head  = true,
    index = true,
    kind  = true,
}

local function classify_record(record)

    local has_board_signal =
        record.base_h ~= nil
        or record.base_w ~= nil
        or record.l ~= nil

    local has_required_dims =
        record.base_h ~= nil
        and record.base_w ~= nil
        and record.l ~= nil

    local has_context = false

    for k, _ in pairs(record) do
        if not BOARD_FIELDS[k]
           and not SYSTEM_FIELDS[k]
        then
            has_context = true
            break
        end
    end

    if not has_board_signal and not has_context then
        return "empty"
    end

    if not has_board_signal and has_context then
        return "context_only"
    end

    if has_board_signal and not has_required_dims then
        return "dead_board"
    end

    if has_required_dims and not has_context then
        return "board_only"
    end

    if has_required_dims and has_context then
        return "mixed"
    end

    return "context_only"
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
    -- 1. Structural extraction
    ----------------------------------------------------------------
    local structural_records = RawText.run(lines)

    ----------------------------------------------------------------
    -- 2. Semantic parsing
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

        contexts[i] = context

        -- Only dead boards become unknown
        if context == "dead_board" then
            data[i] = {
                kind  = "unknown",
                raw   = record.raw,
                head  = record.head,
                index = record.index,
            }
        else
            record.kind = context
            data[i] = record
        end

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
