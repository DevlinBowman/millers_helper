-- canopy/runtime/adapter.lua
--
-- Converts arbitrary Lua tables into canopy tree nodes.

local Adapter = {}

local function is_table(value)
    return type(value) == "table"
end

local function build_node(key, value, parent, path)
    path = path or {}
    local current_path = { unpack(path) }
    table.insert(current_path, key)

    if is_table(value) then
        local children = {}
        for k, v in pairs(value) do
            table.insert(children, build_node(k, v, value, current_path))
        end

        table.sort(children, function(a, b)
            return tostring(a.label) < tostring(b.label)
        end)

        return {
            id = tostring(key),
            label = tostring(key),
            children = children,
            __path = current_path,
        }
    else
        return {
            id = tostring(key),
            label = tostring(key),
            value = value,
            editable = true,
            __path = current_path,
        }
    end
end

function Adapter.from_model(model)
    local root = {}

    for k, v in pairs(model or {}) do
        table.insert(root, build_node(k, v))
    end

    table.sort(root, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)

    return root
end

return Adapter
