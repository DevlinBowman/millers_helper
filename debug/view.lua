-- debug/view.lua
--
-- Targeted inspection facade.
-- Responsibilities:
--   • Run inspection router to a named target
--   • Extract the correct ctx.state slice
--   • Project / filter output (no mutation)
--   • Print with a strong visual boundary
--
-- Router  = control flow
-- Targets = state mutation
-- View    = projection / display only

local Router  = require("tools.inspection.router")
local Context = require("tools.inspection.context")
local I       = require("inspector")

local View = {}

----------------------------------------------------------------
-- Visual framing (single responsibility)
----------------------------------------------------------------

---@param title string
---@param payload any
local function print_view_block(title, payload)
    print("\n" .. string.rep("=", 78))
    print("VIEW START ▶ " .. title)
    print(string.rep("-", 78))

    if payload == nil then
        print("(no data)")
    else
        I.print(payload)
    end

    print(string.rep("=", 78))
    print("VIEW END ▶ " .. title)
    print(string.rep("=", 78) .. "\n")
end

----------------------------------------------------------------
-- Target definitions (LSP-visible)
----------------------------------------------------------------

---@alias ViewTarget
---| "io"            -- Raw file IO (Read.read output)
---| "text"          -- Text parser canonical records
---| "text.parser"  -- Full text parser internals
---| "reconcile"    -- Board specs (pre-hydration)
---| "hydrate"      -- Hydrated boards (inspection-only)
---| "ingest"       -- Full ingestion pipeline

--- Canonical target strings (autocomplete-safe)
View.targets = {
    io        = "io",
    text      = "text",
    parser    = "text.parser",
    reconcile = "reconcile",
    hydrate   = "hydrate",
    ingest    = "ingest",
}

----------------------------------------------------------------
-- View options (LSP-visible)
----------------------------------------------------------------

---@class ViewOptions
---@field index? number                      -- Show a single item (1-based index)
---@field range? { [1]:number, [2]:number }  -- Inclusive range {from, to}
---@field limit? number                      -- Show first N items only

----------------------------------------------------------------
-- Target → ctx.state key mapping (explicit + centralized)
----------------------------------------------------------------
-- This is the ONLY place that binds a View target
-- to materialized inspection state.

local STATE_KEY = {
    ["io"]          = "io",
    ["text"]        = "text",
    ["text.parser"] = "text_parser",
    ["reconcile"]   = "reconcile",
    ["hydrate"]     = "hydrate",
    ["ingest"]      = "ingest",
}

----------------------------------------------------------------
-- Index / range projection helpers
----------------------------------------------------------------

---@param arr table
---@param from number|nil
---@param to number|nil
---@return table
local function slice_array(arr, from, to)
    local out = {}
    local len = #arr

    from = math.max(1, from or 1)
    to   = math.min(len, to or len)

    for i = from, to do
        out[#out + 1] = arr[i]
    end

    return out
end

---@param payload any
---@param opts ViewOptions|nil
---@return any
local function apply_index_filter(payload, opts)
    if not opts or type(payload) ~= "table" then
        return payload
    end

    -- Operate on payload.data if present, otherwise payload itself
    local target = payload.data or payload
    if type(target) ~= "table" then
        return payload
    end

    local filtered = target

    if opts.index then
        filtered = target[opts.index] and { target[opts.index] } or {}
    elseif opts.range then
        filtered = slice_array(target, opts.range[1], opts.range[2])
    elseif opts.limit then
        filtered = slice_array(target, 1, opts.limit)
    end

    -- Preserve envelope shape if payload had metadata
    if payload.data then
        local copy = {}
        for k, v in pairs(payload) do
            copy[k] = v
        end
        copy.data = filtered
        return copy
    end

    return filtered
end

----------------------------------------------------------------
-- Core entry point
----------------------------------------------------------------

---@param target ViewTarget
---@param path string
---@param opts ViewOptions|nil
---@return any
function View.run(target, path, opts)
    assert(type(target) == "string", "View.run: target required")
    assert(type(path) == "string", "View.run: path required")

    local ctx = Context.new(path)
    Router.run(target, ctx)

    local state_key = STATE_KEY[target]
    assert(
        state_key,
        "View.run: no state mapping for target '" .. tostring(target) .. "'"
    )

    local payload = ctx.state[state_key]
    payload = apply_index_filter(payload, opts)

    print_view_block(target, payload)
    return payload
end

----------------------------------------------------------------
-- Ergonomic aliases (still LSP-safe)
----------------------------------------------------------------

---@param path string
---@param opts ViewOptions|nil
function View.io(path, opts)
    return View.run(View.targets.io, path, opts)
end

---@param path string
---@param opts ViewOptions|nil
function View.text(path, opts)
    return View.run(View.targets.text, path, opts)
end

---@param path string
---@param opts ViewOptions|nil
function View.parser(path, opts)
    return View.run(View.targets.parser, path, opts)
end

---@param path string
---@param opts ViewOptions|nil
function View.reconcile(path, opts)
    return View.run(View.targets.reconcile, path, opts)
end

---@param path string
---@param opts ViewOptions|nil
function View.boards(path, opts)
    return View.run(View.targets.hydrate, path, opts)
end

---@param path string
---@param opts ViewOptions|nil
function View.ingest(path, opts)
    return View.run(View.targets.ingest, path, opts)
end

return View
