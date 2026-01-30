-- parsers/text_pipeline.lua

local Preprocess           = require("parsers.raw_text.preprocess")
local Tokenize             = require("parsers.board_data.lex.tokenize")
local ChunkBuilder         = require("parsers.board_data.chunk.chunk_builder")
local ChunkCondense        = require("parsers.board_data.chunk.chunk_condense")
local AttributeRules       = require("parsers.board_data.rules")
local AttributeAttribution = require("parsers.board_data.attribute_attribution")
local ClaimResolver        = require("parsers.board_data.claims.claim_resolver")

local TextPipeline = {}

local function format_resolved(resolved)
    local keys = { "h", "w", "l", "ct", "tag" }
    local out = {}
    for _, k in ipairs(keys) do
        if resolved[k] ~= nil then
            out[#out + 1] = string.format("{%s=%s}", k, tostring(resolved[k]))
        end
    end
    return table.concat(out, " ")
end

local function missing_required_dims(resolved)
    return not (resolved and resolved.h and resolved.w and resolved.l)
end

---@param lines string[]
---@return { kind: "records", data: table[], meta: table }
function TextPipeline.run(lines)
    assert(type(lines) == "table", "TextPipeline.run(): lines must be table")

    local pre = Preprocess.run(lines)

    for _, record in ipairs(pre) do
        record._tokens = Tokenize.run(record.head)

        -- baseline chunks
        local chunks = ChunkBuilder.build(record._tokens)
        record._chunks = chunks
        record._chunk_view = ChunkBuilder.format(chunks)

        local lex, labels = Tokenize.format_tokens(record._tokens)
        record._token_lex   = lex
        record._token_kinds = labels

        local function run_pass(pass_chunks, pass_tag)
            local claims = AttributeAttribution.run({
                tokens = record._tokens,
                chunks = pass_chunks,
            }, AttributeRules)

            local resolved, picked = ClaimResolver.resolve(claims)
            return claims, resolved, picked, pass_tag
        end

        -- Pass 1
        local claims, resolved = run_pass(record._chunks, "base")
        record._claims = claims
        record._resolved = resolved
        record._resolved_view = format_resolved(resolved)

        -- Failsafe Pass 2: condense + retry if missing h/w/l
        if missing_required_dims(resolved) then
            local condensed = ChunkCondense.run(record._tokens, record._chunks)

            -- overwrite as "real" for now (your request)
            record._chunks = condensed
            record._chunk_view = ChunkBuilder.format(condensed)

            local claims2, resolved2 = run_pass(record._chunks, "condensed")
            record._claims = claims2
            record._resolved = resolved2
            record._resolved_view = format_resolved(resolved2)
            record._condensed = true
        end
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
