-- parsers/board_data/registry.lua
--
-- Authoritative registry for board_data domain.
-- PURPOSE:
--   • Expose full internal public surface
--   • Provide stable import contract for other domains

local Registry = {}

----------------------------------------------------------------
-- Lex layer
----------------------------------------------------------------

Registry.lex = {
    tokenize  = require("parsers.board_data.lex.tokenize"),
    lexer     = require("parsers.board_data.lex.lexer"),
    classify  = require("parsers.board_data.lex.classify"),
    labeler   = require("parsers.board_data.lex.labeler"),
    reduce    = require("parsers.board_data.lex.reduce_fractional_number"),
    mappings  = require("parsers.board_data.lex.token_mappings"),
}

----------------------------------------------------------------
-- Chunk layer
----------------------------------------------------------------

Registry.chunk = {
    build    = require("parsers.board_data.chunk.chunk_builder"),
    condense = require("parsers.board_data.chunk.chunk_condense"),
    ignore   = require("parsers.board_data.chunk.chunk_ignore"),
    preds    = require("parsers.board_data.chunk.chunk_predicates"),
}

----------------------------------------------------------------
-- Pattern layer
----------------------------------------------------------------

Registry.pattern = {
    predicates = require("parsers.board_data.pattern.predicates"),
    matcher    = require("parsers.board_data.pattern.pattern_match"),
}

----------------------------------------------------------------
-- Rules
----------------------------------------------------------------

Registry.rules = require("parsers.board_data.rules")

----------------------------------------------------------------
-- Attribution
----------------------------------------------------------------

Registry.attribution = require("parsers.board_data.attribute_attribution")

----------------------------------------------------------------
-- Claims
----------------------------------------------------------------

Registry.claims = {
    resolver = require("parsers.board_data.claims.claim_resolver"),
    format   = require("parsers.board_data.claims.format_claims"),
    view     = require("parsers.board_data.claims.claim_view"),
}

return Registry
