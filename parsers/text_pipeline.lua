-- parsers/text_pipeline.lua
--
-- Text parser pipeline (manager only)
-- PURPOSE:
--   • Coordinate preprocessing
--   • Coordinate tokenization
--   • Enforce ingestion contract
--   • NO parsing logic

local Preprocess   = require("parsers.raw_text.preprocess")
local Tokenize     = require("parsers.board_data.tokenize")

local TextPipeline = {}

---@param lines string[]
---@return { kind: "records", data: table[], meta: table }
function TextPipeline.run(lines)
    assert(type(lines) == "table", "TextPipeline.run(): lines must be table")

    -- --------------------------------------------
    -- 1) Structural preprocess
    -- --------------------------------------------
    local pre = Preprocess.run(lines)

    -- --------------------------------------------
    -- 2) Tokenization (ephemeral parser state)
    -- --------------------------------------------
    for _, record in ipairs(pre) do
        record._tokens      = Tokenize.run(record.head)

        local lex, kinds    = Tokenize.format_tokens(record._tokens)
        record._token_lex   = lex
        record._token_kinds = kinds -- NOTE:
        -- _tokens is ephemeral
        -- parser logic will consume and delete later
    end

    return {
        kind = "records",
        data = pre,
        meta = {
            source       = "text",
            record_count = #pre,
            pipeline     = "text_pipeline",
        }
    }
end

return TextPipeline
