-- core/model/board/pipelines/build.lua
--
-- Build pipeline for Board model.
-- Aggressively asserts internal invariants (programmer errors)
-- and emits Signals for data errors (bad/missing input).

local Registry = require("core.model.board.registry")
local Signals  = require("core.signal")

local Build = {}

local Board = {}
Board.__index = Board

----------------------------------------------------------------
-- Hard assertions (programmer errors)
----------------------------------------------------------------

local function assert_type(v, t, msg)
    assert(type(v) == t, msg .. " (got " .. type(v) .. ")")
end

local function assert_table(v, msg) assert_type(v, "table", msg) end
local function assert_string(v, msg) assert_type(v, "string", msg) end
local function assert_function(v, msg) assert_type(v, "function", msg) end

local function assert_registry()
    assert_table(Registry, "core.model.board.registry must be table")

    assert_table(Registry.schema, "Registry.schema must exist")
    assert_table(Registry.schema.fields, "Registry.schema.fields must exist")
    assert_table(Registry.schema.ROLES, "Registry.schema.ROLES must exist")
    assert(Registry.schema.ROLES.DERIVED ~= nil, "Registry.schema.ROLES.DERIVED must exist")

    assert_table(Registry.coerce, "Registry.coerce must exist")
    assert_function(Registry.coerce.run, "Registry.coerce.run must exist")

    assert_table(Registry.validate, "Registry.validate must exist")
    assert_function(Registry.validate.run, "Registry.validate.run must exist")

    assert_table(Registry.derive, "Registry.derive must exist")
    assert_function(Registry.derive.run, "Registry.derive.run must exist")

    assert_table(Registry.label, "Registry.label must exist")
    assert_function(Registry.label.generate, "Registry.label.generate must exist")
end

----------------------------------------------------------------
-- Signals helpers (data errors)
----------------------------------------------------------------

local function push_error(signals, code, message, context)
    Signals.push(signals, Signals.new(
        code,
        Signals.LEVEL.ERROR,
        message,
        {
            module  = "core.model.board",
            stage   = "build",
            context = context or {},
        }
    ))
end

local function validate_posnum(v, name, signals)
    if type(v) ~= "number" or v <= 0 then
        push_error(
            signals,
            "board.invalid_dimension",
            name .. " must be > 0",
            { field = name, value = v }
        )
        return false
    end
    return true
end

local function safe_stage(stage, fn, signals, context)
    assert_string(stage, "safe_stage(stage): stage must be string")
    assert_function(fn, "safe_stage(fn): fn must be function")
    assert_table(signals, "safe_stage(signals): signals must be table")

    local ok, result_or_err = pcall(fn)
    if not ok then
        Signals.push(signals, Signals.new(
            "board." .. stage .. "_failure",
            Signals.LEVEL.ERROR,
            tostring(result_or_err),
            {
                module  = "core.model.board",
                stage   = stage,
                context = context or {},
            }
        ))
        return false, nil
    end

    return true, result_or_err
end

local function recalc_cached(board, signals)
    assert_table(board, "recalc_cached(board): board must be table")
    assert_table(signals, "recalc_cached(signals): signals must be table")

    local ok = safe_stage("derive", function()
        Registry.derive.run(board)
        return true
    end, signals, { board = board })

    return ok
end

----------------------------------------------------------------
-- Initialization helpers
----------------------------------------------------------------

local function init_schema_surface()
    local board = {}
    for field in pairs(Registry.schema.fields) do
        board[field] = nil
    end
    return board
end

local function clear_derived_fields(board)
    for field, def in pairs(Registry.schema.fields) do
        if def and def.role == Registry.schema.ROLES.DERIVED then
            board[field] = nil
        end
    end
end

local function resolve_required_dimensions(spec)
    -- Support a couple common aliases (defensive), but prefer canonical.
    local base_h = spec.base_h
    if base_h == nil then base_h = spec.h end
    if base_h == nil then base_h = spec.H end

    local base_w = spec.base_w
    if base_w == nil then base_w = spec.w end
    if base_w == nil then base_w = spec.W end

    local len = spec.l
    if len == nil then len = spec.L end
    if len == nil then len = spec.len end
    if len == nil then len = spec.length end

    -- Coerce string numbers early so dimension validation is meaningful.
    if type(base_h) == "string" then base_h = tonumber(base_h) end
    if type(base_w) == "string" then base_w = tonumber(base_w) end
    if type(len) == "string" then len = tonumber(len) end

    return base_h, base_w, len
end

local function resolve_count(spec)
    local ct = spec.ct
    if ct == nil then ct = spec.Ct end
    if ct == nil then ct = spec.CT end
    if ct == nil then ct = spec.count end
    if ct == nil then ct = spec.Count end

    if ct == nil then
        return 1
    end

    if type(ct) == "string" then
        ct = tonumber(ct)
    end

    if type(ct) ~= "number" or ct <= 0 then
        return 1
    end

    -- If someone passes 3.2, treat as 3 (count should be integer-ish).
    ct = math.floor(ct)
    if ct <= 0 then ct = 1 end
    return ct
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Build one canonical Board from one input spec (1:1).
--- @param spec table
--- @return table { board=Board|nil, unknown=table, signals=table[] }
function Build.run(spec)
    assert_registry()
    assert_table(spec, "Board.build(): spec table required")

    local signals = {}

    ------------------------------------------------------------
    -- Required dimensions (hard gate for data)
    ------------------------------------------------------------

    local base_h, base_w, len = resolve_required_dimensions(spec)

    local ok_dims = true
    ok_dims = validate_posnum(base_h, "base_h", signals) and ok_dims
    ok_dims = validate_posnum(base_w, "base_w", signals) and ok_dims
    ok_dims = validate_posnum(len, "l", signals) and ok_dims

    if not ok_dims or Signals.has_errors(signals) then
        return {
            board   = nil,
            unknown = {},
            signals = signals,
        }
    end

    ------------------------------------------------------------
    -- Initialize schema surface
    ------------------------------------------------------------

    local board = init_schema_surface()

    -- Seed required canonical fields
    board.base_h = base_h
    board.base_w = base_w
    board.l      = len
    board.ct     = resolve_count(spec)
    board.tag    = spec.tag or spec.Tag or spec.flag or spec.Flag or nil

    -- Copy all input fields onto the working board surface (schema + extras),
    -- then clear derived fields to ensure derive owns them.
    for k, v in pairs(spec) do
        board[k] = v
    end

    clear_derived_fields(board)

    ------------------------------------------------------------
    -- Coerce (flat return required)
    ------------------------------------------------------------

    local ok_coerce, coerce_result = safe_stage(
        "coerce",
        function()
            return Registry.coerce.run(board)
        end,
        signals,
        { input = spec }
    )

    if not ok_coerce then
        return {
            board   = nil,
            unknown = {},
            signals = signals,
        }
    end

    assert_table(coerce_result, "Board.build(): coerce must return table")
    assert_table(coerce_result.value, "Board.build(): coerce_result.value must be table")
    assert_table(coerce_result.unknown, "Board.build(): coerce_result.unknown must be table")

    board = coerce_result.value
    local unknown = coerce_result.unknown

    ------------------------------------------------------------
    -- Validate
    ------------------------------------------------------------

    local ok_validate = safe_stage(
        "validate",
        function()
            Registry.validate.run(board)
            return true
        end,
        signals,
        { board = board }
    )

    if not ok_validate then
        return {
            board   = nil,
            unknown = unknown,
            signals = signals,
        }
    end

    ------------------------------------------------------------
    -- Identity
    ------------------------------------------------------------

    local ok_identity = safe_stage(
        "identity",
        function()
            local label = Registry.label.generate(board)
            assert(type(label) == "string" and label ~= "", "label.generate must return non-empty string")
            board.label = label
            board.id    = label
            return true
        end,
        signals,
        { board = board }
    )

    if not ok_identity then
        return {
            board   = nil,
            unknown = unknown,
            signals = signals,
        }
    end

    ------------------------------------------------------------
    -- Derive
    ------------------------------------------------------------

    local ok_derive = recalc_cached(board, signals)

    if not ok_derive then
        return {
            board   = nil,
            unknown = unknown,
            signals = signals,
        }
    end

    ------------------------------------------------------------
    -- Final invariants (assert the living shit out of it)
    ------------------------------------------------------------

    assert(type(board.base_h) == "number" and board.base_h > 0, "board.base_h must be positive number after build")
    assert(type(board.base_w) == "number" and board.base_w > 0, "board.base_w must be positive number after build")
    assert(type(board.l) == "number" and board.l > 0, "board.l must be positive number after build")
    assert(type(board.ct) == "number" and board.ct >= 1, "board.ct must be number >= 1 after build")
    assert(type(board.id) == "string" and board.id ~= "", "board.id must be non-empty string after build")
    assert(type(board.label) == "string" and board.label ~= "", "board.label must be non-empty string after build")

    ------------------------------------------------------------
    -- Success
    ------------------------------------------------------------

    return {
        board   = setmetatable(board, Board),
        unknown = unknown,
        signals = signals,
    }
end

function Board:recalc()
    assert_registry()
    local signals = {}
    recalc_cached(self, signals)
    return self
end

return Build
