-- tools/trace/debug.lua
--
-- Lightweight structured debug formatter.
-- No domain logic.
-- No side effects except print when enabled.

local Debug = {}

local ENABLED = false

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

local function get_table_count(value)
    if type(value) ~= "table" then
        return 0
    end
    return #value
end

local function get_sample_keys(value)
    if type(value) ~= "table" then
        return nil
    end

    local first = value[1]
    if type(first) ~= "table" then
        return nil
    end

    local keys = {}
    for k in pairs(first) do
        keys[#keys + 1] = tostring(k)
    end

    table.sort(keys)
    return table.concat(keys, ", ")
end

local function format_line(stage, label, value)
    local value_type = type(value)
    local count = get_table_count(value)

    local base = string.format(
        "[%-10s] %-15s | type=%-8s | count=%s",
        stage:upper(),
        label,
        value_type,
        tostring(count)
    )

    local keys = get_sample_keys(value)
    if keys then
        base = base .. " | keys=" .. keys
    end

    return base
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Debug.enable(state)
    ENABLED = not not state
end

function Debug.log(stage, label, value)
    if not ENABLED then
        return
    end

    print(format_line(stage, label, value))
end

return Debug
