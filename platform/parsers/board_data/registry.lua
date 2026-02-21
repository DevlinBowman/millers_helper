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
    tokenize = require("platform.parsers.board_data.internal.lex.tokenize"),
    lexer    = require("platform.parsers.board_data.internal.lex.lexer"),
    classify = require("platform.parsers.board_data.internal.lex.classify"),
    labeler  = require("platform.parsers.board_data.internal.lex.labeler"),
    reduce   = require("platform.parsers.board_data.internal.lex.reduce_fractional_number"),
    mappings = require("platform.parsers.board_data.internal.lex.token_mappings"),
}

----------------------------------------------------------------
-- Chunk
----------------------------------------------------------------
Registry.chunk = {
    build    = require("platform.parsers.board_data.internal.chunk.chunk_builder"),
    condense = require("platform.parsers.board_data.internal.chunk.chunk_condense"),
    ignore   = require("platform.parsers.board_data.internal.chunk.chunk_ignore"),
    preds    = require("platform.parsers.board_data.internal.chunk.chunk_predicates"),
}

----------------------------------------------------------------
-- Pattern
----------------------------------------------------------------
Registry.pattern = {
    predicates = require("platform.parsers.board_data.internal.pattern.predicates"),
    matcher    = require("platform.parsers.board_data.internal.pattern.pattern_match"),
}

----------------------------------------------------------------
-- Rules (authoritative ordered list)
----------------------------------------------------------------
Registry.rules =
    require("platform.parsers.board_data.internal.rules")

----------------------------------------------------------------
-- Attribution Engine
----------------------------------------------------------------
Registry.attribution =
    require("platform.parsers.board_data.internal.attribute.attribution")

----------------------------------------------------------------
-- Claims
----------------------------------------------------------------
Registry.claims = {
    resolver = require("platform.parsers.board_data.internal.claims.claim_resolver"),
    format   = require("platform.parsers.board_data.internal.claims.format_claims"),
    view     = require("platform.parsers.board_data.internal.claims.claim_view"),
}

return Registry
