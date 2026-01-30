-- parsers/text_pipeline.lua
--
-- Orchestrates the full text → board-attribute pipeline
-- RESPONSIBILITIES:
--   • Run preprocessing
--   • Tokenize and chunk
--   • Attribute attribution + resolution
--   • Conditionally apply structural repair (chunk condense)
--   • Freeze high-certainty explicit matches ("stable spans")
--   • Attach inspection artifacts to records
--
-- NON-RESPONSIBILITIES:
--   • No parsing logic
--   • No inference rules
--   • No structural heuristics beyond gating repair

local Preprocess           = require("parsers.raw_text.preprocess")
local Tokenize             = require("parsers.board_data.lex.tokenize")
local ChunkBuilder         = require("parsers.board_data.chunk.chunk_builder")
local ChunkCondense        = require("parsers.board_data.chunk.chunk_condense")
local AttributeRules       = require("parsers.board_data.rules")
local AttributeAttribution = require("parsers.board_data.attribute_attribution")
local ClaimResolver        = require("parsers.board_data.claims.claim_resolver")

local TextPipeline         = {}

-- "Stop fucking with it" threshold:
-- anything explicitly claimed at/above this certainty becomes stable.
local STABLE_CERTAINTY     = 0.95

----------------------------------------------------------------
-- Formatting helpers (inspection only)
----------------------------------------------------------------

local function format_resolved(resolved)
    local keys = { "h", "w", "l", "ct", "tag" }
    local out  = {}

    for _, k in ipairs(keys) do
        if resolved and resolved[k] ~= nil then
            out[#out + 1] = string.format("{%s=%s}", k, tostring(resolved[k]))
        end
    end

    return table.concat(out, " ")
end

local function missing_required_dims(resolved)
    return not (resolved and resolved.h and resolved.w and resolved.l)
end

----------------------------------------------------------------
-- Stable spans
-- Stable spans are token ranges that produced high-certainty claims.
-- They are kept in-context, but future passes must not "re-assign" them,
-- and condense should not merge across them.
----------------------------------------------------------------

local function span_overlaps(a, b)
    if not a or not b then return false end
    return not (a.to < b.from or b.to < a.from)
end

local function mark_stable_spans(record)
    record._stable_spans = {}

    for _, p in ipairs(record._picked or {}) do
        if p and p.span and p.certainty and p.certainty >= STABLE_CERTAINTY then
            record._stable_spans[#record._stable_spans + 1] = {
                field     = p.field,
                span      = { from = p.span.from, to = p.span.to },
                certainty = p.certainty,
                rule      = p.rule,
            }
        end
    end
end

local function token_is_in_stable_span(tok, stable_spans)
    if not tok or not tok.index or not stable_spans then return false end
    for _, s in ipairs(stable_spans) do
        if tok.index >= s.span.from and tok.index <= s.span.to then
            return true
        end
    end
    return false
end

local function chunk_overlaps_any_stable(chunk, stable_spans)
    if not chunk or not chunk.span or not stable_spans then return false end
    for _, s in ipairs(stable_spans) do
        if span_overlaps(chunk.span, s.span) then
            return true
        end
    end
    return false
end

----------------------------------------------------------------
-- Structural repair gate
-- Determines whether chunk condensation is justified
----------------------------------------------------------------

local function needs_structural_repair(record)
    local stable_spans = record._stable_spans or {}

    -- ------------------------------------------------------------
    -- 1. Any numeric tokens not covered by any picked claim span,
    --    excluding numeric tokens already inside stable spans.
    -- ------------------------------------------------------------
    do
        local covered_spans = {}
        for _, p in ipairs(record._picked or {}) do
            if p and p.span then
                covered_spans[#covered_spans + 1] = p.span
            end
        end

        for _, t in ipairs(record._tokens or {}) do
            if t.traits and t.traits.numeric then
                if not token_is_in_stable_span(t, stable_spans) then
                    local used = false
                    for _, s in ipairs(covered_spans) do
                        if t.index >= s.from and t.index <= s.to then
                            used = true
                            break
                        end
                    end
                    if not used then
                        return true
                    end
                end
            end
        end
    end

    -- ------------------------------------------------------------
    -- 2. Adjacent chunks both carry numeric-related structure,
    --    and the boundary is not inside/overlapping any stable span.
    -- ------------------------------------------------------------
    local chunks = record._chunks or {}
    for i = 1, #chunks - 1 do
        local a, b = chunks[i], chunks[i + 1]

        local a_struct = a and (a.has_num or a.has_unit or a.has_infix)
        local b_struct = b and (b.has_num or b.has_unit or b.has_infix)

        if a_struct and b_struct then
            -- If either side overlaps stable spans, we should not repair/condense here.
            if not chunk_overlaps_any_stable(a, stable_spans)
                and not chunk_overlaps_any_stable(b, stable_spans)
            then
                return true
            end
        end
    end

    return false
end

----------------------------------------------------------------
-- Condense only if it will not touch stable spans
----------------------------------------------------------------

-- parsers/text_pipeline.lua

local function condense_if_safe(record)
    -- Stable spans must act as BARRIERS, not disable condensation.
    -- Condense can still happen inside unstable regions.
    return ChunkCondense.run(record._tokens, record._chunks, {
        stable_spans = record._stable_spans,
    })
end

----------------------------------------------------------------
-- Internal pass runner
-- Passes stable_spans through ctx so attribution can optionally skip stable spans.
----------------------------------------------------------------

local function run_pass(record, chunks, pass_tag)
    local claims = AttributeAttribution.run({
        tokens       = record._tokens,
        chunks       = chunks,
        stable_spans = record._stable_spans,
        resolved     = record._resolved, -- ADD THIS
    }, AttributeRules)

    local resolved, picked = ClaimResolver.resolve(claims)

    return {
        tag      = pass_tag,
        claims   = claims,
        resolved = resolved,
        picked   = picked,
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string[]
---@return { kind: "records", data: table[], meta: table }
function TextPipeline.run(lines)
    assert(type(lines) == "table", "TextPipeline.run(): lines must be table")

    local records = Preprocess.run(lines)

    for _, record in ipairs(records) do
        -- --------------------------------------------------------
        -- Tokenization
        -- --------------------------------------------------------
        record._tokens        = Tokenize.run(record.head)

        local lex, labels     = Tokenize.format_tokens(record._tokens)
        record._token_lex     = lex
        record._token_kinds   = labels

        -- --------------------------------------------------------
        -- Initial chunking
        -- --------------------------------------------------------
        record._chunks        = ChunkBuilder.build(record._tokens)
        record._chunk_view    = ChunkBuilder.format(record._chunks)
        record._condensed     = false

        -- --------------------------------------------------------
        -- Pass 1: baseline attribution
        -- --------------------------------------------------------
        local pass1           = run_pass(record, record._chunks, "base")

        record._claims        = pass1.claims
        record._resolved      = pass1.resolved
        record._picked        = pass1.picked
        record._resolved_view = format_resolved(pass1.resolved)

        -- --------------------------------------------------------
        -- Commit stable spans from high-certainty picks
        -- --------------------------------------------------------
        mark_stable_spans(record)

        -- --------------------------------------------------------
        -- Pass 2: structural repair (conditional + stable-safe)
        -- --------------------------------------------------------
        if missing_required_dims(pass1.resolved)
            and needs_structural_repair(record)
        then
            local condensed    = condense_if_safe(record)

            -- Only proceed if condensation actually changed something meaningful
            -- (avoid rerunning pass2 if condense became a no-op due to stability)
            local changed      = (condensed ~= record._chunks) or (ChunkBuilder.format(condensed) ~= record._chunk_view)

            record._chunks     = condensed
            record._chunk_view = ChunkBuilder.format(condensed)
            record._condensed  = changed and true or record._condensed

            if changed then
                local pass2 = run_pass(record, condensed, "condensed")

                -- Preserve stable resolved fields from pass1
                local merged_resolved = {}

                -- 1) carry forward stable fields
                for _, s in ipairs(record._stable_spans or {}) do
                    merged_resolved[s.field] = record._resolved[s.field]
                end

                -- 2) overlay new pass2 results
                for k, v in pairs(pass2.resolved or {}) do
                    merged_resolved[k] = v
                end

                -- 3) merge picked (stable + new)
                local merged_picked = {}
                for _, p in ipairs(record._picked or {}) do
                    merged_picked[#merged_picked + 1] = p
                end
                for _, p in ipairs(pass2.picked or {}) do
                    merged_picked[#merged_picked + 1] = p
                end

                record._claims        = pass2.claims
                record._resolved      = merged_resolved
                record._picked        = merged_picked
                record._resolved_view = format_resolved(merged_resolved)

                -- Update stable spans again after pass2, in case it produced
                -- additional high-certainty commits.
                mark_stable_spans(record)
            end
        end
    end

    return {
        kind = "records",
        data = records,
        meta = {
            source       = "text",
            record_count = #records,
            pipeline     = "text_pipeline",
        }
    }
end

return TextPipeline
