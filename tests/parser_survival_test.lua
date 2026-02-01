
-- debug/view.lua
--
-- Targeted inspection facade (INGESTION V2 SAFE)
--
-- Responsibilities:
--   • Run inspection router to a named target
--   • Extract a VALID ctx.state slice
--   • Project / filter output (read-only)
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
    print("VIEW ▶ " .. title)
    print(string.rep("-", 78))

    if payload == nil then
        print("(no data)")
    else
        I.print(payload)
    end

    print(string.rep("=", 78))
end

----------------------------------------------------------------
-- Canonical view targets (V2)
----------------------------------------------------------------

---@alias ViewTarget
---| "io"         -- Raw file IO
---| "text"       -- Canonical records
---| "parser"     -- Text parser internals
---| "boards"     -- Authoritative boards
---| "ingest"     -- Boards + diagnostics

View.targets = {
    io     = "io",
    text   = "text",
    parser = "parser",
    boards = "boards",
    ingest = "ingest",
}

----------------------------------------------------------------
-- Target → ctx.state mapping (EXPLICIT + VALID)
----------------------------------------------------------------

local STATE_KEY = {
    io     = "io",
    text   = "records",
    parser = "text_parser",
    boards = "boards",
    ingest = "ingest",
}

----------------------------------------------------------------
-- Index / range projection helpers
----------------------------------------------------------------

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

local function apply_index_filter(payload, opts)
    if not opts or type(payload) ~= "table" then
        return payload
    end

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
---@param opts table|nil
---@return any
function View.run(target, path, opts)
    assert(View.targets[target], "View.run: invalid target '" .. tostring(target) .. "'")
    assert(type(path) == "string", "View.run: path required")

    local ctx = Context.new(path)
    Router.run(target, ctx)

    local state_key = STATE_KEY[target]
    assert(state_key, "View.run: no state mapping for target '" .. target .. "'")

    local payload = ctx.state[state_key]
    payload = apply_index_filter(payload, opts)

    print_view_block(target, payload)
    return payload
end

----------------------------------------------------------------
-- Ergonomic aliases
----------------------------------------------------------------

function View.io(path, opts)
    return View.run("io", path, opts)
end

function View.text(path, opts)
    return View.run("text", path, opts)
end

function View.parser(path, opts)
    return View.run("parser", path, opts)
end

function View.boards(path, opts)
    return View.run("boards", path, opts)
end

function View.ingest(path, opts)
    return View.run("ingest", path, opts)
end

return View
