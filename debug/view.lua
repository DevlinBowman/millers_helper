-- debug/view.lua
--
-- Targeted inspection facade (INGESTION V2 SAFE)
--
-- Responsibilities:
--   • Run inspection router to a named target
--   • Extract ctx.state slices (read-only)
--   • Project / filter output
--   • Display with strong visual framing
--
-- This layer MUST reflect actual inspection targets.
-- It must NOT invent new semantics.

local Router  = require("tools.inspection.router")
local Context = require("tools.inspection.context")
local I       = require("inspector")

local View = {}

----------------------------------------------------------------
-- Visual framing
----------------------------------------------------------------
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
-- VALID inspection targets (authoritative)
--
-- These MUST mirror tools/inspection/targets.lua
----------------------------------------------------------------
View.targets = {
    ["io"]          = true,
    ["records"]     = true,
    ["text.parser"] = true,
    ["ingest"]      = true,
}

----------------------------------------------------------------
-- Target → ctx.state mapping
----------------------------------------------------------------
local STATE_KEY = {
    ["io"]          = "io",
    ["records"]     = "records",
    ["text.parser"] = "text_parser",
    ["ingest"]      = "ingest",
}

----------------------------------------------------------------
-- Core entry
----------------------------------------------------------------
---@param target string
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
    print_view_block(target, payload)

    return payload
end

----------------------------------------------------------------
-- Ergonomic aliases (OPTIONAL, not authoritative)
----------------------------------------------------------------
function View.io(path)
    return View.run("io", path)
end

function View.text(path, opts)
    return View.run("text", path, opts)
end

function View.records(path)
    return View.run("records", path)
end

function View.parser(path)
    return View.run("text.parser", path)
end

function View.ingest(path)
    return View.run("ingest", path)
end

function View.boards(path)
    local ingest = View.run("ingest", path)
    return ingest.boards
end

return View
