-- parsers/board_data/registry.lua
--
-- Capability surface only.
-- No orchestration.
-- No contracts.
-- No trace.
-- No logic.
--
-- Answers:
--   What does this module provide?

local Registry = {}

----------------------------------------------------------------
-- Lex
----------------------------------------------------------------
Registry.lex = {
    tokenize = require("parsers.board_data.internal.lex.tokenize"),
    lexer    = require("parsers.board_data.internal.lex.lexer"),
    classify = require("parsers.board_data.internal.lex.classify"),
    labeler  = require("parsers.board_data.internal.lex.labeler"),
    reduce   = require("parsers.board_data.internal.lex.reduce_fractional_number"),
    mappings = require("parsers.board_data.internal.lex.token_mappings"),
}

----------------------------------------------------------------
-- Chunk
----------------------------------------------------------------
Registry.chunk = {
    build    = require("parsers.board_data.internal.chunk.chunk_builder"),
    condense = require("parsers.board_data.internal.chunk.chunk_condense"),
    ignore   = require("parsers.board_data.internal.chunk.chunk_ignore"),
    preds    = require("parsers.board_data.internal.chunk.chunk_predicates"),
}

----------------------------------------------------------------
-- Pattern
----------------------------------------------------------------
Registry.pattern = {
    predicates = require("parsers.board_data.internal.pattern.predicates"),
    matcher    = require("parsers.board_data.internal.pattern.pattern_match"),
}

----------------------------------------------------------------
-- Rules (authoritative ordered list)
----------------------------------------------------------------
Registry.rules =
    require("parsers.board_data.internal.rules")

----------------------------------------------------------------
-- Attribution Engine
----------------------------------------------------------------
Registry.attribution =
    require("parsers.board_data.internal.attribute.attribution")

----------------------------------------------------------------
-- Claims
----------------------------------------------------------------
Registry.claims = {
    resolver = require("parsers.board_data.internal.claims.claim_resolver"),
    format   = require("parsers.board_data.internal.claims.format_claims"),
    view     = require("parsers.board_data.internal.claims.claim_view"),
}

return Registry
