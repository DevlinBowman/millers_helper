-- core/model/board/brain.lua
--
-- Full board domain logic (1:1 port of original core/board/board.lua brains)
-- Board-only. No order / ledger context.

local Schema    = require("core.model.board.schema")
local Label     = require("core.model.board.label.init")
local Normalize = require("core.model.board.normalize")
local Convert   = require("core.model.board.attr_conversion")
local Util      = require("core.model.board.utils.helpers")

local Board   = {}
Board.__index = Board

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function assert_posnum(v, name)
    assert(type(v) == "number" and v > 0, name .. " must be > 0")
end

local function resolve_declared_dims(spec)
    local base_h = spec.base_h or spec.h
    local base_w = spec.base_w or spec.w

    assert_posnum(base_h, "base_h")
    assert_posnum(base_w, "base_w")

    return base_h, base_w
end

----------------------------------------------------------------
-- Schema surface initialization
----------------------------------------------------------------

local function initialize_schema_surface()
    local board = {}

    for field, def in pairs(Schema.fields) do
        if def.default ~= nil then
            board[field] = def.default
        else
            board[field] = nil
        end
    end

    return board
end

----------------------------------------------------------------
-- Coercion
----------------------------------------------------------------

local function apply_schema_coercions(board)
    for field, def in pairs(Schema.fields) do
        local value = board[field]

        if value ~= nil and def.coerce then
            local coerced = def.coerce(value)

            if coerced == nil and value ~= nil then
                error(
                    string.format(
                        "Board.new(): failed to coerce field '%s' (value=%s)",
                        field,
                        tostring(value)
                    ),
                    3
                )
            end

            board[field] = coerced
        end
    end
end

----------------------------------------------------------------
-- Pricing normalization
----------------------------------------------------------------

local function resolve_pricing(board)
    local bf_price = board.bf_price

    if bf_price == nil then
        if board.ea_price ~= nil then
            bf_price = Convert.ea_price_to_bf_price(board)
        elseif board.lf_price ~= nil then
            bf_price = Convert.lf_price_to_bf_price(board)
        end
    end

    if bf_price == nil then
        board.bf_price    = nil
        board.ea_price    = nil
        board.lf_price    = nil
        board.batch_price = nil
        return
    end

    board.bf_price = bf_price
    board.ea_price = Convert.bf_price_to_ea_price(board)
    board.lf_price = Convert.bf_price_to_lf_price(board)

    board.batch_price = Util.round_number(
        bf_price * board.bf_batch,
        2
    )
end

----------------------------------------------------------------
-- Derived computation
----------------------------------------------------------------

local function recalc_cached(board)
    board.h, board.w = Normalize.face_from_tag(
        board.base_h,
        board.base_w,
        board.tag
    )

    board.bf_ea     = Convert.bf(board)
    board.bf_per_lf = Convert.bf_per_lf(board)
    board.bf_batch  = board.bf_ea * board.ct

    resolve_pricing(board)

    board.n_delta_vol = Normalize.nominal_delta(board)
end

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function Board.new(spec)
    assert(type(spec) == "table", "Board.new(): spec table required")

    local base_h, base_w = resolve_declared_dims(spec)
    assert_posnum(spec.l, "l")

    local board = initialize_schema_surface()

    board.base_h = base_h
    board.base_w = base_w
    board.l      = spec.l
    board.ct     = tonumber(spec.ct) or 1
    board.tag    = spec.tag or "n"

    -- strict authoritative copy
    for k, v in pairs(spec) do
        if Schema.fields[k] then
            if Schema.fields[k].role == Schema.ROLES.AUTHORITATIVE then
                board[k] = v
            end
        end
    end

    apply_schema_coercions(board)

    recalc_cached(board)

    board.label = Label.generate(board)
    board.id    = board.label

    return setmetatable(board, Board)
end

----------------------------------------------------------------
-- Explicit recompute boundary
----------------------------------------------------------------

function Board:recalc()
    recalc_cached(self)
    return self
end

----------------------------------------------------------------
-- Safe getter (domain aware)
----------------------------------------------------------------

function Board:get(key)
    assert(type(key) == "string", "Board:get(): key must be string")

    if not Schema.fields[key] then
        error(
            string.format(
                "Board:get(): unknown board field '%s'",
                key
            ),
            2
        )
    end

    return rawget(self, key)
end

return Board
