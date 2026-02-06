-- ingestion_v2/report.lua
--
-- Responsibility:
--   Human-readable, client-facing ingestion reporting.
--   Provides clear guidance for remediation.
--
-- MODES:
--   • default (verbose): full explanatory output WITH value diffs
--   • compact: single-line, scan-friendly output
--
-- NO logic. NO mutation. NO inference.
--

---@class ReportPrintOpts
---@field compact boolean|nil -- Use compact, scan-friendly warning output

local Report = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function join(list, sep)
    if type(list) ~= "table" then return "" end
    return table.concat(list, sep or ", ")
end

local function out(msg)
    io.stderr:write(msg .. "\n")
end

local function get_errors(result)
    if type(result.signals) == "table" and type(result.signals.errors) == "table" then
        return result.signals.errors
    end
    return result.errors or {}
end

local function get_warnings(result)
    if type(result.signals) == "table" and type(result.signals.warnings) == "table" then
        return result.signals.warnings
    end
    return result.warnings or {}
end

local function action_block(source_path)
    out("")
    out("  Action:")
    out("    • Review this line in: " .. tostring(source_path))
    out("    • Correct the input OR extend your parser rules/schema to support this case")
end

----------------------------------------------------------------
-- Signal normalization (make compact+verbose robust)
--
-- The pipeline signals may carry either:
--   • legacy fields: field/value/original_value/computed_value
--   • structured fields: key/input_value/outcome_value/action/role
--
-- This adapter makes BOTH formats print consistently.
----------------------------------------------------------------

local function normalize_signal(sig)
    -- input side
    local input_key = sig.input_key or sig.field or sig.key
    local input_val =
        (sig.input_value ~= nil and sig.input_value)
        or (sig.original_value ~= nil and sig.original_value)
        or sig.value

    -- outcome side
    local outcome_key = sig.outcome_key or input_key
    local outcome_val =
        (sig.outcome_value ~= nil and sig.outcome_value)
        or (sig.computed_value ~= nil and sig.computed_value)

    -- role/action
    local role   = sig.role or "unknown"
    local action = sig.action

    -- best-effort default action, by code
    if action == nil then
        if sig.code == "ingest.derived_field_overridden" then
            action = "recomputed"
        elseif sig.code == "ingest.unmapped_field" then
            action = "ignored"
        end
    end

    return {
        index         = sig.index,
        code          = sig.code,
        head          = sig.head,
        message       = sig.message,
        note          = sig.note,

        role          = role,
        action        = action,

        input_key     = input_key,
        input_value   = input_val,

        outcome_key   = outcome_key,
        outcome_value = outcome_val,
    }
end

----------------------------------------------------------------
-- Compact formatting
----------------------------------------------------------------
-- Format:
-- [record#] [role] >> input_key input_val -> action -> outcome_key outcome_val

----------------------------------------------------------------
-- Compact formatting (table-like, bracketed)
----------------------------------------------------------------
-- Columns:
-- [rec] [role] [input] [action] [outcome]

local function pad(s, n)
    s = tostring(s)
    if #s >= n then return s end
    return s .. string.rep(" ", n - #s)
end

local function fmt_kv(k, v)
    if k == nil then return "[?]" end
    if v == nil then
        return "[ " .. tostring(k) .. " ]"
    end
    return "[ " .. tostring(k) .. " = " .. tostring(v) .. " ]"
end

local function print_compact_warnings(warnings)
    out("")
    out("Warnings (compact)")
    out("--------------------------------------------------")
    out("[rec] [role]     [input]                     [action]      [outcome]")
    out("--------------------------------------------------")

    for _, raw in ipairs(warnings) do
        local w = normalize_signal(raw)

        local rec   = "[" .. tostring(w.index or "?") .. "]"
        local role  = "[" .. tostring(w.role or "unknown") .. "]"

        local input   = fmt_kv(w.input_key, w.input_value)
        local action  = "[" .. tostring(w.action or "ignored") .. "]"
        local outcome = fmt_kv(w.outcome_key or w.input_key, w.outcome_value)

        out(string.format(
            "%s %s  %s  %s  %s",
            pad(rec, 5),
            pad(role, 10),
            pad(input, 24),
            pad(action, 14),
            outcome
        ))
    end
end

----------------------------------------------------------------
-- Verbose formatting (default)
----------------------------------------------------------------

local function print_error(err, source_path)
    out("")
    out("ERROR: " .. tostring(err.message or "Ingestion error"))
    if err.code then out("  Code:       " .. tostring(err.code)) end
    if err.index then out("  Record #:   " .. tostring(err.index)) end
    if err.head then out("  Input line: " .. tostring(err.head)) end

    if err.missing and type(err.missing) == "table" and #err.missing > 0 then
        out("  Missing:    " .. join(err.missing))
    end

    if err.fields and type(err.fields) == "table" and #err.fields > 0 then
        out("  Fields:     " .. join(err.fields))
    end

    if err.error then
        out("  Detail:     " .. tostring(err.error))
    end

    if err.note then
        out("")
        out("  Note:")
        out("    • " .. tostring(err.note))
    end

    action_block(source_path)
end

local function print_warning(raw_warn, source_path)
    local warn = normalize_signal(raw_warn)

    out("")
    out("WARNING: " .. tostring(warn.message or "Ingestion warning"))
    if warn.code then out("  Code:       " .. tostring(warn.code)) end
    if warn.index then out("  Record #:   " .. tostring(warn.index)) end
    if warn.head then out("  Input line: " .. tostring(warn.head)) end

    if warn.input_key then out("  Field:      " .. tostring(warn.input_key)) end

    if warn.input_value ~= nil then
        out("  Original:   " .. tostring(warn.input_value))
    end

    if warn.action then
        out("  Action:     " .. tostring(warn.action))
    end

    if warn.outcome_value ~= nil then
        out("  Result:     " .. tostring(warn.outcome_value))
    end

    if warn.note then
        out("")
        out("  Note:")
        out("    • " .. tostring(warn.note))
    else
        out("")
        out("  Note:")
        out("    • This warning is non-blocking, but may indicate lost data")
    end

    action_block(source_path)
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param ingest_result table
---@param opts ReportPrintOpts|nil
function Report.print(ingest_result, opts)
    assert(type(ingest_result) == "table", "report.print(): ingest_result required")
    opts = opts or {}

    local meta        = ingest_result.meta or {}
    local source_path = meta.source_path or "<unknown file>"

    local errors   = get_errors(ingest_result)
    local warnings = get_warnings(ingest_result)

    out("")
    out("Ingestion summary")
    out("--------------------------------------------------")
    out("Source file:     " .. tostring(source_path))
    out("Records read:    " .. tostring(meta.total_records or "?"))
    out("Boards created:  " .. tostring(meta.boards_created or "?"))
    out("Errors:          " .. tostring(#errors))
    out("Warnings:        " .. tostring(#warnings))

    if #errors > 0 then
        out("")
        out("Blocking issues (must be resolved)")
        out("--------------------------------------------------")
        for _, err in ipairs(errors) do
            print_error(err, source_path)
        end
    end

    if #warnings > 0 then
        if opts.compact then
            print_compact_warnings(warnings)
        else
            out("")
            out("Non-blocking issues (review recommended)")
            out("--------------------------------------------------")
            for _, warn in ipairs(warnings) do
                print_warning(warn, source_path)
            end
        end
    end

    out("")
end

return Report
