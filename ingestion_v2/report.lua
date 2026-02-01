-- ingestion_v2/report.lua
--
-- Responsibility:
--   Human-readable, client-facing ingestion reporting.
--   Provides clear guidance for remediation.
--   NO logic. NO mutation. NO inference.

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

local function action_block(source_path)
    out("")
    out("  Action:")
    out("    • Review this line in: " .. tostring(source_path))
    out("    • Correct the input OR extend your parser rules/schema to support this case")
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

----------------------------------------------------------------
-- Formatting
----------------------------------------------------------------

local function print_error(err, source_path)
    out("")
    out("ERROR: " .. tostring(err.message or "Ingestion error"))
    if err.code then out("  Code:       " .. tostring(err.code)) end
    if err.head then out("  Input line: " .. tostring(err.head)) end
    if err.index then out("  Record #:   " .. tostring(err.index)) end

    if err.missing and type(err.missing) == "table" and #err.missing > 0 then
        out("  Missing:    " .. join(err.missing))
    end

    if err.field and type(err.field) == "string" then
        out("  Field:      " .. tostring(err.field))
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

local function print_warning(warn, source_path)
    out("")
    out("WARNING: " .. tostring(warn.message or "Ingestion warning"))
    if warn.code then out("  Code:       " .. tostring(warn.code)) end
    if warn.head then out("  Input line: " .. tostring(warn.head)) end
    if warn.index then out("  Record #:   " .. tostring(warn.index)) end
    if warn.field then out("  Field:      " .. tostring(warn.field)) end
    if warn.value ~= nil then out("  Value:      " .. tostring(warn.value)) end

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
function Report.print(ingest_result)
    assert(type(ingest_result) == "table", "report.print(): ingest_result required")

    local meta = ingest_result.meta or {}
    local source_path = meta.source_path or "<unknown file>"

    local errors = get_errors(ingest_result)
    local warnings = get_warnings(ingest_result)

    out("")
    out("Ingestion summary")
    out("--------------------------------------------------")
    out("Source file:     " .. tostring(source_path))
    out("Records read:    " .. tostring(meta.total_records or "?"))
    out("Boards created:  " .. tostring(meta.boards_created or meta.boards_created or "?"))
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
        out("")
        out("Non-blocking issues (review recommended)")
        out("--------------------------------------------------")
        for _, warn in ipairs(warnings) do
            print_warning(warn, source_path)
        end
    end

    out("")
end

return Report
