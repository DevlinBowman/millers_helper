-- core/board/board.lua
-- Authoritative board constructor + invariant boundary
--
-- BOARD-FIRST / FLAT FACT RECORD
--   - Board is the universal ledger record.
--   - Schema defines the authoritative field universe.
--   - Board enforces invariants + derived fields only.
--   - Boards are DENSE: every schema field exists (nil if empty).
--   - Unknown fields are preserved (lossless ingest).

local Label     = require("core.board.label")
local Convert   = require("core.board.attr_conversion")
local Normalize = require("core.board.normalize")
local Util      = require("core.board.utils.helpers")
local Schema    = require("core.board.schema")

---@class Board
local Board = {}
Board.__index = Board

----------------------------------------------------------------
-- Invariant helpers
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
-- Derived cache computation
----------------------------------------------------------------

local function recalc_cached(board)
    -- working face
    board.h, board.w = Normalize.face_from_tag(
        board.base_h,
        board.base_w,
        board.tag
    )

    -- physicals
    board._bf        = Convert.bf(board)
    board._bf_per_lf = Convert.bf_per_lf(board)

    -- pricing
    board._ea_price = nil
    if board.bf_price ~= nil then
        board._ea_price = Convert.bf_price_to_ea_price(board)
    end

    -- nominal delta
    board.n_delta_vol = nil
    if board.tag == "n" then
        local nominal = Normalize.nominal_bf(
            board.base_h,
            board.base_w,
            board.l
        )
        board.n_delta_vol = nominal > 0
            and Util.round_number(board._bf / nominal, 2)
            or 1.0
    end
end

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param spec table
---@return Board
function Board.new(spec)
    assert(type(spec) == "table", "Board.new(): spec table required")

    local base_h, base_w = resolve_declared_dims(spec)
    assert_posnum(spec.l, "l")

    ---@type Board
    local board = {}

    ------------------------------------------------------------
    -- 1) Initialize dense schema frame
    ------------------------------------------------------------
    for field in pairs(Schema.fields) do
        board[field] = nil
    end

    ------------------------------------------------------------
    -- 2) Required declared invariants
    ------------------------------------------------------------
    board.base_h = base_h
    board.base_w = base_w
    board.l      = spec.l
    board.ct     = tonumber(spec.ct or 1)
    board.tag    = spec.tag

    ------------------------------------------------------------
    -- 3) Copy all provided data (schema or not)
    ------------------------------------------------------------
    for k, v in pairs(spec) do
        board[k] = v
    end

    ------------------------------------------------------------
    -- 4) Identity (derived, authoritative)
    ------------------------------------------------------------
    board.label = Label.generate(board)
    board.id    = board.label

    ------------------------------------------------------------
    -- 5) Derived caches
    ------------------------------------------------------------
    recalc_cached(board)

    return setmetatable(board, Board)
end

----------------------------------------------------------------
-- Recalculation boundary
----------------------------------------------------------------

---@return Board
function Board:recalc()
    recalc_cached(self)
    return self
end

----------------------------------------------------------------
-- Accessors
----------------------------------------------------------------

---@return number
function Board:bf()
    return self._bf
end

---@return number
function Board:bf_total()
    return self._bf * self.ct
end

---@return number|nil
function Board:ea_price()
    return self._ea_price
end

--- Schema-aware safe getter
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
