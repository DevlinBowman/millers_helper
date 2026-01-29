-- parsers/text_pipeline.lua
-- DEBUG / VERIFICATION PIPELINE
-- Purpose: prove raw text lines reach ingestion normalization intact

local TextPipeline = {}

---@param lines string[]
---@return { kind: "records", data: table[], meta: table }
function TextPipeline.run(lines)
    assert(type(lines) == "table", "TextPipeline.run(): lines must be table")

    local records = {}

    for i, line in ipairs(lines) do
        records[#records + 1] = {
            __line_no = i,
            __raw    = line,
        }
    end

    return {
        kind = "records",
        data = records,
        meta = {
            parser = "text_pipeline",
            record_count = #records,
        }
    }
end

return TextPipeline
