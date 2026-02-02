-- core/board/board.lua
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

local Label     = require("core.board.label")
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
---@field _bf number
---@field _bf_per_lf number
---@field _ea_price number|nil
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

            -- Hard failure: schema says this must be coercible
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
-- Derived cache computation (authoritative)
----------------------------------------------------------------

---@param board Board
local function recalc_cached(board)
    -- Resolve working face (ALWAYS)
    board.h, board.w = Normalize.face_from_tag(
        board.base_h,
        board.base_w,
        board.tag
    )

    -- Physical quantities
    board._bf        = Convert.bf(board)
    board._bf_per_lf = Convert.bf_per_lf(board)
    board.batch_bf   = Util.round_number(board._bf * board.ct, 2)

    -- Pricing (derived, optional)
    board._ea_price  = nil
    if board.bf_price ~= nil then
        board._ea_price = Convert.bf_price_to_ea_price(board)
    end

    -- Nominal delta (only meaningful for nominal boards)
    board.n_delta_vol = nil
    if board.tag == "n" then
        local nominal = Normalize.nominal_bf(
            board.base_h,
            board.base_w,
            board.l
        )

        board.n_delta_vol = (nominal > 0)
            and Util.round_number(board._bf / nominal, 2)
            or 1.0
    end
end

----------------------------------------------------------------
-- Constructor (single authoritative boundary)
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
    -- 1) Initialize schema universe (semantic density)
    ------------------------------------------------------------
    -- NOTE: assigning nil does not create physical keys;
    -- this establishes intent, not runtime presence.
    for field in pairs(Schema.fields) do
        board[field] = nil
    end

    ------------------------------------------------------------
    -- 2) Declared invariants (authoritative inputs)
    ------------------------------------------------------------
    board.base_h = base_h
    board.base_w = base_w
    board.l      = spec.l
    board.ct     = tonumber(spec.ct) or 1

    -- Default interpretation: NOMINAL
    board.tag    = spec.tag or "n"

    ------------------------------------------------------------
    -- 3) Copy all provided data (lossless ingest)
    ------------------------------------------------------------
    for k, v in pairs(spec) do
        board[k] = v
    end

    ------------------------------------------------------------
    -- 3.25) Strip derived inputs (schema-driven)
    ------------------------------------------------------------
    for field, def in pairs(Schema.fields) do
        if def.role == Schema.ROLES.DERIVED then
            board[field] = nil
        end
    end

    ------------------------------------------------------------
    -- 3.5) Apply schema coercions (authoritative)
    ------------------------------------------------------------
    apply_schema_coercions(board)

    ------------------------------------------------------------
    -- 4) Identity (physical snapshot)
    ------------------------------------------------------------
    board.label = Label.generate(board)
    board.id    = board.label

    ------------------------------------------------------------
    -- 5) Derived caches (always)
    ------------------------------------------------------------
    recalc_cached(board)

    return setmetatable(board, Board)
end

----------------------------------------------------------------
-- Recalculation boundary (explicit)
----------------------------------------------------------------

---@return Board
function Board:recalc()
    recalc_cached(self)
    return self
end

----------------------------------------------------------------
-- Accessors (stable, intentional)
----------------------------------------------------------------

---@return number
function Board:bf()
    return self._bf
end

-- ---@return number
-- function Board:batch_bf()
--     return self._bf * self.ct
-- end

---@return number|nil
function Board:ea_price()
    return self._ea_price
end

----------------------------------------------------------------
-- Schema-aware safe getter
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
