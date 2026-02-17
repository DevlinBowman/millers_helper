-- tools/trace.lua
--
-- Runtime Boundary Trace Visualizer
-- Modes:
--   "stream"   → immediate print
--   "collapse" → buffered + sibling aggregation
-- Shape Modes:
--   "contract" → declared contract shape (default)
--   "runtime"  → shallow runtime structure
--
-- Minimal Implementation Example
-- function Controller.read(path)
--     Trace.contract_enter("io.controller.read")
--
--     Trace.contract_in({ path = path })
--     Contract.assert({ path = path }, Controller.CONTRACT.read.in_)
--
--     local ok, result_or_err = pcall(function()
--
--         local result = Registry.read.read(path)
--
--         Contract.assert(result, Controller.CONTRACT.read.out)
--
--         Trace.contract_out(result, "registry.read", "caller")
--
--         return result
--     end)
--
--     Trace.contract_leave()
--
--     if not ok then
--         error(result_or_err, 0)
--     end
--
--     return result_or_err
-- end

local Trace   = {}

local ENABLED = false
local MODE    = "stream"
local SHAPE_MODE = "contract"
local SHAPE_DEPTH = 1

----------------------------------------------------------------
-- ANSI
----------------------------------------------------------------

local function ansi(code)
    return "\27[" .. code .. "m"
end

local RESET = "\27[0m"

local COLORS = {
    contract = ansi("38;5;213"),
    boundary = ansi("38;5;141"),
    input    = ansi("38;5;81"),
    output   = ansi("38;5;114"),
    arrow    = ansi("38;5;214"),
    meta     = ansi("38;5;240"),

    key      = ansi("38;5;110"),
    value    = ansi("38;5;180"),
}

local function paint(color, text)
    return color .. text .. RESET
end

----------------------------------------------------------------
-- Public control
----------------------------------------------------------------

function Trace.set(enabled)
    ENABLED = not not enabled
end

function Trace.set_mode(mode)
    assert(mode == "stream" or mode == "collapse")
    MODE = mode
end

function Trace.set_shape_mode(mode)
    assert(mode == "contract" or mode == "runtime")
    SHAPE_MODE = mode
end

----------------------------------------------------------------
-- Shape helpers
----------------------------------------------------------------

local function collect_declared_keys(tbl)
    local keys = {}
    for k in next, tbl do
        keys[#keys + 1] = k
    end
    return keys
end

local function contract_shape(shape)
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

function Trace.set_shape_depth(n)
    assert(type(n) == "number" and n >= 0)
    SHAPE_DEPTH = n
end

local function runtime_shape(value, depth)
    depth = depth or 0

    if type(value) ~= "table" then
        return tostring(value)
    end

    if depth >= SHAPE_DEPTH then
        if #value > 0 then
            return "[" .. #value .. "]"
        end
        return "{ ... }"
    end

    local parts = {}

    for k, v in pairs(value) do
        if type(v) == "table" then
            parts[#parts + 1] =
                tostring(k) .. " = " .. runtime_shape(v, depth + 1)
        else
            parts[#parts + 1] =
                tostring(k) .. " = " .. tostring(v)
        end
    end

    return "{ " .. table.concat(parts, ", ") .. " }"
end

local function render_shape(shape)
    if SHAPE_MODE == "runtime" then
        return runtime_shape(shape, 0)
    end
    return contract_shape(shape)
end

----------------------------------------------------------------
-- STREAM MODE
----------------------------------------------------------------

local STREAM_STACK = {}

local function stream_depth()
    return #STREAM_STACK
end

local function stream_push(name)
    STREAM_STACK[#STREAM_STACK + 1] = name
end

local function stream_pop()
    STREAM_STACK[#STREAM_STACK] = nil
end

local function indent(is_last)
    local d = stream_depth()
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

----------------------------------------------------------------
-- COLLAPSE MODE
----------------------------------------------------------------

local ROOT = nil
local NODE_STACK = {}

local function new_node(name)
    return {
        name = name,
        in_shape  = nil,
        out_shape = nil,
        arrow     = nil,
        children  = {},
    }
end

local function tree_depth()
    return #NODE_STACK
end

local function tree_push(node)
    NODE_STACK[#NODE_STACK + 1] = node
end

local function tree_pop()
    NODE_STACK[#NODE_STACK] = nil
end

local function current_node()
    return NODE_STACK[#NODE_STACK]
end

----------------------------------------------------------------
-- Collapse render helpers
----------------------------------------------------------------

local function same_signature(a, b)
    return a.name == b.name
       and a.in_shape == b.in_shape
       and a.out_shape == b.out_shape
       and a.arrow == b.arrow
end

local function collapse_children(children)
    local out = {}
    local i = 1

    while i <= #children do
        local base = children[i]
        local count = 1

        while true do
            local next_node = children[i + count]
            if not next_node then break end
            if same_signature(base, next_node) then
                count = count + 1
            else
                break
            end
        end

        out[#out + 1] = { node = base, count = count }
        i = i + count
    end

    return out
end

local function render_node(node, depth, is_root)
    local prefix = ""

    if not is_root then
        for i = 1, depth - 1 do
            prefix = prefix .. "│  "
        end
        prefix = prefix .. "├─ "
    end

    if is_root then
        io.stderr:write(
            paint(COLORS.contract, "[contract] "),
            paint(COLORS.boundary, node.name),
            "\n"
        )
    else
        io.stderr:write(
            prefix,
            paint(COLORS.boundary, node.name),
            "\n"
        )
    end

    if node.in_shape then
        io.stderr:write(
            prefix .. "│  ",
            paint(COLORS.input, "in   "),
            node.in_shape,
            "\n"
        )
    end

    if node.out_shape then
        io.stderr:write(
            prefix .. "│  ",
            paint(COLORS.output, "out  "),
            node.out_shape,
            node.arrow or "",
            "\n"
        )
    end

    local collapsed = collapse_children(node.children)

    for _, entry in ipairs(collapsed) do
        render_node(entry.node, depth + 1, false)

        if entry.count > 1 then
            local collapse_prefix = ""
            for i = 1, depth do
                collapse_prefix = collapse_prefix .. "│  "
            end

            io.stderr:write(
                collapse_prefix,
                paint(COLORS.meta, "×" .. entry.count),
                "\n"
            )
        end
    end
end

----------------------------------------------------------------
-- Boundary API
----------------------------------------------------------------

function Trace.contract_enter(name)
    if not ENABLED then return end

    if MODE == "stream" then
        if stream_depth() == 0 then
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
        stream_push(name)
        return
    end

    local node = new_node(name)

    if tree_depth() == 0 then
        ROOT = node
    else
        current_node().children[#current_node().children + 1] = node
    end

    tree_push(node)
end

function Trace.contract_in(shape)
    if not ENABLED then return end

    local display = render_shape(shape)

    if MODE == "stream" then
        io.stderr:write(
            indent(false),
            paint(COLORS.input, "in   "),
            display,
            "\n"
        )
        return
    end

    current_node().in_shape = display
end

function Trace.contract_out(shape, from, to)
    if not ENABLED then return end

    local display = render_shape(shape)

    if MODE == "stream" then
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
            display,
            arrow,
            "\n"
        )
        return
    end

    current_node().out_shape = display

    if from and to then
        current_node().arrow =
            "  "
            .. paint(COLORS.arrow, "[" .. from .. "]")
            .. " → "
            .. paint(COLORS.arrow, "[" .. to .. "]")
    end
end

function Trace.contract_leave()
    if not ENABLED then return end

    if MODE == "stream" then
        stream_pop()
        if stream_depth() == 0 then
            io.stderr:write("\n")
        end
        return
    end

    tree_pop()

    if tree_depth() == 0 and ROOT then
        render_node(ROOT, 0, true)
        io.stderr:write("\n")
        ROOT = nil
    end
end

return Trace
