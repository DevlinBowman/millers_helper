-- parsers/text_pipeline/pipeline.lua
--
-- Orchestrates text → attribute pipeline
-- CONTRACT-CORRECT IMPLEMENTATION

local Preprocess     = require("parsers.raw_text.preprocess")
local Tokenize       = require("parsers.board_data.lex.tokenize")
local ChunkBuilder   = require("parsers.board_data.chunk.chunk_builder")
local ChunkCondense  = require("parsers.board_data.chunk.chunk_condense")
local Attribution    = require("parsers.board_data.attribute_attribution")
local AttributeRules = require("parsers.board_data.rules")
local ClaimResolver  = require("parsers.board_data.claims.claim_resolver")

local TokenUsage     = require("parsers.text_pipeline.token_usage")
local StableSpans    = require("parsers.text_pipeline.stable_spans")
local RepairGate     = require("parsers.text_pipeline.repair_gate")
local Diagnostics    = require("parsers.text_pipeline.diagnostics")

local Pipeline = {}

----------------------------------------------------------------
-- Internal pass runner
----------------------------------------------------------------

local function run_pass(record, chunks)
    TokenUsage.init(record)

    local claims = Attribution.run({
        tokens       = record._tokens,
        chunks       = chunks,
        stable_spans = record._stable_spans,
        resolved     = record._resolved,
    }, AttributeRules)

    TokenUsage.update(record, claims)

    local resolved, picked = ClaimResolver.resolve(claims)

    TokenUsage.mark_picked(record, picked)

    return resolved, picked
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Pipeline.run(lines, opts)
    opts = opts or {}

    local records = Preprocess.run(lines)

    for _, line in ipairs(records) do
        -- tokenize
        line._tokens = Tokenize.run(line.head)
        line._token_lex, line._token_kinds =
            Tokenize.format_tokens(line._tokens)

        TokenUsage.init(line)

        -- chunk
        line._chunks     = ChunkBuilder.build(line._tokens)
        line._chunk_view = ChunkBuilder.format(line._chunks)
        line._condensed  = false
        line._stable_spans = nil

        -- pass 1
        line._resolved, line._picked =
            run_pass(line, line._chunks)

        StableSpans.collect(line)

        -- conditional repair
        if RepairGate.needs_repair(line) then
            local condensed = ChunkCondense.run(
                line._tokens,
                line._chunks,
                { stable_spans = line._stable_spans }
            )

            if condensed ~= line._chunks then
                line._chunks     = condensed
                line._chunk_view = ChunkBuilder.format(condensed)
                line._condensed  = true

                line._resolved, line._picked =
                    run_pass(line, condensed)

                StableSpans.collect(line)
            end
        end

        -- diagnostics
        line._unused_groups    = Diagnostics.find_unused_groups(line)
        line._contested_groups = Diagnostics.find_contested_groups(line)
    end

    return {
        kind = "records",
        data = records,
        meta = {
            parser = "text_pipeline",
            count  = #records,
        },
    }
end

return Pipeline
