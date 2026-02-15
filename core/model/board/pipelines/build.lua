-- core/model/board/pipelines/build.lua

local Registry = require("core.model.board.registry")

local Build = {}
local Board = {}
Board.__index = Board

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

local function recalc_cached(board)
    -- Derive.run already computes h/w/bf/pricing/n_delta.
    Registry.derive.run(board)
    return board
end

--- Build one canonical Board from one input spec (1:1), returning unknown inputs separately.
--- @param spec table
--- @return table result { board=Board, unknown=table }
function Build.run(spec)
    assert(type(spec) == "table", "Board.build(): spec table required")

    local base_h, base_w = resolve_declared_dims(spec)
    assert_posnum(spec.l, "l")

    local board = {}

    -- initialize schema surface (authoritative + derived keys exist)
    for field in pairs(Registry.schema.fields) do
        board[field] = nil
    end

    -- seed declared (legacy behavior)
    board.base_h = base_h
    board.base_w = base_w
    board.l      = spec.l
    board.ct     = tonumber(spec.ct) or 1
    board.tag    = spec.tag or nil

    -- lossless ingest copy (into working table; unknown extracted by coerce)
    for k, v in pairs(spec) do
        board[k] = v
    end

    -- clear derived fields so input cannot set them
    for field, def in pairs(Registry.schema.fields) do
        if def.role == Registry.schema.ROLES.DERIVED then
            board[field] = nil
        end
    end

    -- authoritative coercion + unknown extraction
    local coerced, unknown = Registry.coerce.run(board)
    board = coerced

    Registry.validate.run(board)

    -- identity (derived/owned by model)
    board.label = Registry.label.generate(board)
    board.id    = board.label

    -- compute derived caches
    recalc_cached(board)

    return {
        board   = setmetatable(board, Board),
        unknown = unknown,
    }
end

function Board:recalc()
    recalc_cached(self)
    return self
end

return Build
