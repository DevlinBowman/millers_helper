-- ingestion/normalization/from_lines.lua
-- Adapt raw text lines into canonical records

local TextParser = require("parsers.text_pipeline")

local FromLines = {}

---@param lines { kind: "lines", data: string[], meta: table }
---@param opts table|nil -- { capture = Capture? }
---@return { kind: "records", data: table[], meta: table }
function FromLines.run(lines, opts)
    assert(lines.kind == "lines", "expected kind='lines'")
    opts = opts or {}

    local records = TextParser.run(lines.data, {
        capture = opts.capture
    })

    assert(
        type(records) == "table" and records.kind == "records",
        "text parser must return kind='records'"
    )

    records.meta = records.meta or {}
    records.meta.source = "text"
    records.meta.input  = lines.meta

    return records
end

return FromLines
