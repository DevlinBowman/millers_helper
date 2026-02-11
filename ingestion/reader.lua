-- ingestion/reader.lua

local Read       = require("io.read.read")
local Format     = require("format.controller")
local TextParser = require("parsers.text_pipeline")

local Reader = {}

---@param path string
---@param opts table|nil
---@return { kind:string, data:table[], meta:table }
function Reader.read(path, opts)
    opts = opts or {}

    ----------------------------------------------------------------
    -- IO boundary
    ----------------------------------------------------------------

    local raw, err = Read.read(path)
    assert(raw, err)

    local formatted

    ----------------------------------------------------------------
    -- Structured → records
    ----------------------------------------------------------------

    if raw.kind == "table" then
        formatted = Format.to_records_strict("table", raw.data)

    elseif raw.kind == "json" then
        formatted = Format.to_records_strict("json", raw.data)

    ----------------------------------------------------------------
    -- Freeform text → parser-owned
    ----------------------------------------------------------------

    elseif raw.kind == "lines" then
        formatted = TextParser.run(raw.data, opts)

        -- normalize parser output to old envelope shape
        if formatted and formatted.records then
            formatted = {
                kind = "records",
                data = formatted.records,
                meta = formatted.meta or {},
            }
        end

    else
        error("unsupported input kind: " .. tostring(raw.kind))
    end

    assert(formatted, "formatting failed")
    assert(formatted.kind == "records", "reader must return kind='records'")
    assert(type(formatted.data) == "table", "reader must return data=array")

    ----------------------------------------------------------------
    -- Metadata enrichment
    ----------------------------------------------------------------

    formatted.meta = formatted.meta or {}
    formatted.meta.source_path = path
    formatted.meta.input_kind  = raw.kind

    return formatted
end

return Reader
