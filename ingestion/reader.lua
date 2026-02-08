-- ingestion_v2/reader.lua
--
-- Responsibility:
--   Read a file and return raw structured data.
--   NO validation, NO board logic.

local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")
local TextParser = require("parsers.text_pipeline")

local Reader = {}

---@param path string
---@param opts table|nil
---@return { kind: "records", data: table[], meta: table }
function Reader.read(path, opts)
    opts = opts or {}

    local raw, err = Read.read(path)
    assert(raw, err)

    local records

    if raw.kind == "lines" then
        records = TextParser.run(raw.data, opts)
    elseif raw.kind == "table" then
        records = Normalize.table(raw)
    elseif raw.kind == "json" then
        records = Normalize.json(raw)
    else
        error("unsupported input kind: " .. tostring(raw.kind))
    end

    assert(records.kind == "records", "reader must return kind='records'")

    records.meta = records.meta or {}
    records.meta.source_path = path
    records.meta.input_kind  = raw.kind

    return records
end

return Reader
