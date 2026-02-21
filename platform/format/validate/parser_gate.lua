-- format/validate/parser_gate.lua
--
-- Central validation gate for text parser output.
-- Wired at the format layer (lines -> objects transform).
--
-- Accepts either:
--   A) parser-record stream (records contain kind/index/raw) + diagnostic[]
--   B) canonical objects array + diagnostic[]
--
-- Returns:
--   parse_result, nil   on success
--   nil, err_table      on failure

local ParserGate = {}

----------------------------------------------------------------
-- Severity Rules
----------------------------------------------------------------

local FATAL_KINDS = {
    dead_board = true,
    unknown    = true,
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function collect_record_errors(record, diagnostic, fallback_index)
    local errors = {}

    local record_kind  = type(record) == "table" and record.kind or nil
    local record_index = (type(record) == "table" and record.index) or fallback_index
    local record_raw   = type(record) == "table" and record.raw or nil

    -- Fatal structural parse kinds (only if parser exposed record.kind)
    if record_kind ~= nil and FATAL_KINDS[record_kind] then
        errors[#errors + 1] = {
            type   = "invalid_board",
            index  = record_index,
            raw    = record_raw,
            reason = "Missing required dimensions (h,w,l)",
        }
    end

    -- Semantic failure (works for both record-stream and canonical objects)
    if diagnostic and diagnostic.ok == false then
        errors[#errors + 1] = {
            type    = "semantic_parse_failure",
            index   = record_index,
            raw     = record_raw,
            reason  = "Parser could not classify structure",
            signals = diagnostic.signals,
        }
    end

    return errors
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param parse_result table -- { data, meta?, diagnostic? }
---@param opts table|nil
---@return table|nil ok
---@return table|nil err
function ParserGate.validate(parse_result, opts)
    opts = opts or {}

    assert(type(parse_result) == "table", "ParserGate.validate(): parse_result required")

    local data       = parse_result.data or {}
    local diagnostic = parse_result.diagnostic or {}

    local all_errors = {}

    for i, record in ipairs(data) do
        local record_errors = collect_record_errors(record, diagnostic[i], i)
        for _, e in ipairs(record_errors) do
            all_errors[#all_errors + 1] = e
        end
    end

    if #all_errors > 0 then
        return nil, {
            kind    = "parser_validation_error",
            message = "Input contains invalid or incomplete records.",
            errors  = all_errors,
            count   = #all_errors,
        }
    end

    return parse_result, nil
end

return ParserGate
