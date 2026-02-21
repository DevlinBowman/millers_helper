-- parsers/pipelines/text_engine/pipeline.lua
--
-- Orchestrates text → attribute pipeline
-- Pipeline layer: orchestration only (no contracts, no trace)

local Registry = require("platform.parsers.pipelines.text_engine.registry")

-- external module registries/controllers (NOT their internals)
local BoardData = require("platform.parsers.board_data") -- expects { controller, registry }

local Pipeline = {}

----------------------------------------------------------------
-- Internal pass runner
----------------------------------------------------------------

local function run_pass(record, chunks)
    local TokenUsage  = Registry.internal.token_usage
    local Attribution = BoardData.registry.attribution
    local Rules       = BoardData.registry.rules
    local Resolver    = BoardData.registry.claims.resolver

    TokenUsage.init(record)

    local claims = Attribution.run({
        tokens       = record._tokens,
        chunks       = chunks,
        stable_spans = record._stable_spans,
        resolved     = record._resolved,
    }, Rules)

    TokenUsage.update(record, claims)

    local resolved, picked = Resolver.resolve(claims)

    TokenUsage.mark_picked(record, picked)

    return claims, resolved, picked
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string|table
---@param opts table|nil
---@return table result
function Pipeline.run(lines, opts)
    opts                = opts or {}

    local Preprocess    = Registry.internal.preprocess
    local RepairGate    = Registry.internal.repair_gate
    local StableSpans   = Registry.internal.stable_spans
    local Diagnostics   = Registry.internal.diagnostics

    local Tokenize      = BoardData.registry.lex.tokenize
    local ChunkBuilder  = BoardData.registry.chunk.build
    local ChunkCondense = BoardData.registry.chunk.condense

    local records       = Preprocess.run(lines)

    for _, rec in ipairs(records) do
        -- tokenize
        rec._tokens                             = Tokenize.run(rec.head or "")
        rec._token_lex, rec._token_kinds        = Tokenize.format_tokens(rec._tokens)

        -- chunk
        rec._chunks                             = ChunkBuilder.build(rec._tokens)
        rec._chunk_view                         = ChunkBuilder.format(rec._chunks)
        rec._condensed                          = false
        rec._stable_spans                       = nil

        -- pass 1
        rec._claims, rec._resolved, rec._picked =
            run_pass(rec, rec._chunks)

        StableSpans.collect(rec)

        -- repair (chunk condensation)
        if RepairGate.needs_repair(rec) then
            local condensed = ChunkCondense.run(
                rec._tokens,
                rec._chunks,
                { stable_spans = rec._stable_spans }
            )

            if condensed ~= rec._chunks then
                rec._chunks                             = condensed
                rec._chunk_view                         = ChunkBuilder.format(condensed)
                rec._condensed                          = true

                rec._claims, rec._resolved, rec._picked =
                    run_pass(rec, condensed)

                StableSpans.collect(rec)
            end
        end

        -- diagnostics
        rec._unused_groups    = Diagnostics.find_unused_groups(rec)
        rec._contested_groups = Diagnostics.find_contested_groups(rec)
    end

    return {
        kind = "records",
        data = records,
        meta = {
            parser = "text_engine",
            count  = #records,
        },
    }
end

return Pipeline
