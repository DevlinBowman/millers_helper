-- tools/trace.lua
--
-- Runtime Boundary Trace Visualizer

-- To enable output; from caller
-- local Trace = require("tools.trace")
-- Trace.set(true)


local Trace   = {}

local ENABLED = false
local STACK   = {}

----------------------------------------------------------------
-- ANSI (256-color, disp.lua compatible)
----------------------------------------------------------------

local function ansi(code)
    return "\27[" .. code .. "m"
end

local RESET = "\27[0m"

-- These MUST match ANSI_FG_TO_HL in disp.lua
local COLORS = {
    contract = ansi("38;5;213"), -- Special (more distinct root)
    boundary = ansi("38;5;141"), -- Function
    input    = ansi("38;5;81"),  -- Identifier
    output   = ansi("38;5;114"), -- String
    arrow    = ansi("38;5;214"), -- Constant
    meta     = ansi("38;5;240"), -- Comment (dim accents)
}

local function paint(color, text)
    return color .. text .. RESET
end

----------------------------------------------------------------
-- Public control
----------------------------------------------------------------

---@param enabled boolean
function Trace.set(enabled)
    ENABLED = not not enabled
end

----------------------------------------------------------------
-- Stack helpers
----------------------------------------------------------------

local function push(name)
    STACK[#STACK + 1] = name
end

local function pop()
    STACK[#STACK] = nil
end

local function depth()
    return #STACK
end

----------------------------------------------------------------
-- Formatting helpers
----------------------------------------------------------------

local function indent(is_last)
    local d = depth()
    if d == 0 then return "" end

    local parts = {}

    for i = 1, d - 1 do
        parts[#parts + 1] = "│  "
    end

    if is_last then
        parts[#parts + 1] = "└─ "
    else
        parts[#parts + 1] = "├─ "
    end

    return table.concat(parts)
end

-- Preserve declaration order (no sorting)
local function collect_declared_keys(tbl)
    local keys = {}
    for k in next, tbl do
        keys[#keys + 1] = k
    end
    return keys
end

local function compact_shape(shape)
    if shape == true then
        return "{ ... }"
    end

    if type(shape) ~= "table" then
        return tostring(shape)
    end

    local keys = {}
    for _, k in ipairs(collect_declared_keys(shape)) do
        local clean = tostring(k):gsub("%?$", "")
        keys[#keys + 1] = clean
    end

    return "{ " .. table.concat(keys, ", ") .. " }"
end

----------------------------------------------------------------
-- Boundary API
----------------------------------------------------------------

---@param name string
function Trace.contract_enter(name)
    if not ENABLED then return end

    if depth() == 0 then
        io.stderr:write(
            paint(COLORS.contract, "[contract] "),
            paint(COLORS.boundary, name),
            "\n"
        )
    else
        io.stderr:write(
            indent(false),
            paint(COLORS.boundary, name),
            "\n"
        )
    end

    push(name)
end

---@param shape table|boolean
function Trace.contract_in(shape)
    if not ENABLED then return end

    io.stderr:write(
        indent(false),
        paint(COLORS.input, "in   "),
        compact_shape(shape),
        "\n"
    )
end

---@param shape table|boolean
---@param from string|nil
---@param to string|nil
function Trace.contract_out(shape, from, to)
    if not ENABLED then return end

    local arrow = ""

    if from and to then
        arrow =
            "  "
            .. paint(COLORS.arrow, "[" .. from .. "]")
            .. " → "
            .. paint(COLORS.arrow, "[" .. to .. "]")
    end

    io.stderr:write(
        indent(true),
        paint(COLORS.output, "out  "),
        compact_shape(shape),
        arrow,
        "\n"
    )
end

function Trace.contract_leave()
    if not ENABLED then return end
    pop()

    if depth() == 0 then
        io.stderr:write("\n")
    end
end

return Trace
