-- core/board/board.lua
-- I.print(boards)
-- Authoritative board constructor + invariant boundary
--
-- BOARD-FIRST / FLAT FACT RECORD
--   - Board is the universal ledger record.
--   - Schema defines the authoritative field universe.
--   - Board enforces invariants + derived fields only.
--   - Unknown fields are preserved (lossless ingest).
--
-- NOTE:
--   Lua tables cannot truly be "dense" with nil values.
--   Schema density is enforced semantically via Schema.fields
--   and accessors, not via physical key presence.

local Label     = require("core.board.label.init")
local Convert   = require("core.board.attr_conversion")
local Normalize = require("core.board.normalize")
local Util      = require("core.board.utils.helpers")
local Schema    = require("core.board.schema")

---@class Board
---@field base_h number
---@field base_w number
---@field h number
---@field w number
---@field l number
---@field ct number
---@field tag string
---@field label string
---@field id string
---@field ea_price number|nil
---@field lf_price number|nil
---@field bf_price number|nil
---@field batch_price number|nil
---@field bf_ea number
---@field bf_per_lf number
---@field bf_batch number
---@field n_delta_vol number|nil

local Board     = {}
Board.__index   = Board

----------------------------------------------------------------
-- Invariant helpers
----------------------------------------------------------------

---@param v any
---@param name string
local function assert_posnum(v, name)
    assert(type(v) == "number" and v > 0, name .. " must be > 0")
end

---@param spec table
---@return number base_h
---@return number base_w
local function resolve_declared_dims(spec)
    local base_h = spec.base_h or spec.h
    local base_w = spec.base_w or spec.w

    assert_posnum(base_h, "base_h")
    assert_posnum(base_w, "base_w")

    return base_h, base_w
end

----------------------------------------------------------------
-- Schema coercion (authoritative)
----------------------------------------------------------------

---@param board table
local function apply_schema_coercions(board)
    for field, def in pairs(Schema.fields) do
        local value = board[field]
        if value ~= nil and def.coerce then
            local coerced = def.coerce(value)

            if coerced == nil and value ~= nil then
                error(string.format(
                    "Board.new(): failed to coerce field '%s' (value=%s)",
                    field,
                    tostring(value)
                ), 3)
            end

            board[field] = coerced
        end
    end
end

----------------------------------------------------------------
-- Pricing normalization (authoritative)
----------------------------------------------------------------

---@param board Board
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
-- Derived cache computation (authoritative)
----------------------------------------------------------------

---@param board Board
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
-- Output projection (authoritative)
----------------------------------------------------------------

---@param flat Board
---@return table
local function project_grouped_board(flat)
    local out = {
        physical = {},
        pricing  = {},
        context  = {},
    }

    local physical_fields = {
        "base_h", "base_w", "l", "tag",
        "h", "w",
        "ct",
        "bf_ea", "bf_per_lf", "bf_batch",
        "species", "grade", "moisture", "surface",
        "n_delta_vol",
    }

    for _, key in ipairs(physical_fields) do
        local v = flat[key]
        if v ~= nil then
            out.physical[key] = v
        end
    end

    local pricing_fields = {
        "bf_price",
        "lf_price",
        "ea_price",
        "batch_price",
    }

    for _, key in ipairs(pricing_fields) do
        local v = flat[key]
        if v ~= nil then
            out.pricing[key] = v
        end
    end

    for k, v in pairs(flat) do
        if Schema.fields[k]
            and out.physical[k] == nil
            and out.pricing[k] == nil
            and k ~= "label"
            and k ~= "id"
        then
            out.context[k] = v
        end
    end

    out.label = flat.label
    out.id    = flat.id

    return out
end

----------------------------------------------------------------
-- Constructor (single authoritative boundary)
----------------------------------------------------------------

---@param spec table
---@param opts table|nil
---@return table
function Board.new(spec, opts)
    assert(type(spec) == "table", "Board.new(): spec table required")
    opts = opts or {}

    local base_h, base_w = resolve_declared_dims(spec)
    assert_posnum(spec.l, "l")

    local board = {}

    for field in pairs(Schema.fields) do
        board[field] = nil
    end

    board.base_h = base_h
    board.base_w = base_w
    board.l      = spec.l
    board.ct     = tonumber(spec.ct) or 1
    board.tag    = spec.tag or "n"

    for k, v in pairs(spec) do
        board[k] = v
    end

    for field, def in pairs(Schema.fields) do
        if def.role == Schema.ROLES.DERIVED then
            board[field] = nil
        end
    end

    apply_schema_coercions(board)

    board.label = Label.generate(board)
    board.id    = board.label

    recalc_cached(board)

    local flat = setmetatable(board, Board)

    if opts.flat then
        return flat
    end

    return project_grouped_board(flat)
end

----------------------------------------------------------------
-- Recalculation boundary (explicit, flat only)
----------------------------------------------------------------

---@return Board
function Board:recalc()
    recalc_cached(self)
    return self
end

----------------------------------------------------------------
-- Accessors (stable, intentional, flat only)
----------------------------------------------------------------

function Board:bf_ea()
    return self.bf_ea
end

function Board:calc_bf_batch()
    return self.bf_ea * self.ct
end

---@return number|nil
function Board:ea_price()
    return self.ea_price
end

----------------------------------------------------------------
-- Schema-aware safe getter (flat only)
----------------------------------------------------------------

---@param key string
---@return any
function Board:get(key)
    assert(type(key) == "string", "Board:get(): key must be string")

    local value = rawget(self, key)
    local is_schema = Schema.fields[key] ~= nil

    if not is_schema and value == nil then
        io.stderr:write(string.format(
            "[board] unknown attribute '%s' (id=%s)\n",
            key,
            tostring(self.id)
        ))
        return nil
    end

    if is_schema and value == nil then
        io.stderr:write(string.format(
            "[board] attribute '%s' is nil (id=%s)\n",
            key,
            tostring(self.id)
        ))
    end

    return value
end

return Board
