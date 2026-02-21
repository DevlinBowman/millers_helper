-- canopy/runtime/spec_adapter.lua
--
-- Spec -> renderable tree adapter.
-- Keeps Canopy standalone: domain logic lives in spec callbacks.

local SpecAdapter = {}

local function normalize_resolve_result(result)
    if result == nil then
        return { id = "empty", title = "Empty", nodes = {} }
    end

    -- If already a Spec-ish table
    if type(result) == "table" and (result.nodes ~= nil or result.title ~= nil or result.id ~= nil) then
        if result.nodes == nil and type(result[1]) == "table" then
            -- Treat as raw node list
            return { id = "resolved_nodes", title = result.title or "Options", nodes = result }
        end
        result.id = result.id or "resolved_spec"
        result.title = result.title or "Options"
        result.nodes = result.nodes or {}
        return result
    end

    -- If raw node list (array)
    if type(result) == "table" and type(result[1]) == "table" then
        return { id = "resolved_nodes", title = "Options", nodes = result }
    end

    -- Fallback: show as a single leaf
    return {
        id = "resolved_value",
        title = "Result",
        nodes = {
            { id = "value", label = "value", edit = function() return { value = result, set = function() end } end },
        }
    }
end

local function node_marker_flags(node_spec, ctx)
    local has_children = (node_spec.children ~= nil) or (node_spec.resolve ~= nil) or (node_spec.next ~= nil)
    local is_editable = (node_spec.edit ~= nil)

    return has_children, is_editable
end

local function build_tree_nodes(spec_nodes, ctx)
    local out = {}

    for _, node_spec in ipairs(spec_nodes or {}) do
        local has_children, is_editable = node_marker_flags(node_spec, ctx)

        local node = {
            id = tostring(node_spec.id or node_spec.label or "?"),
            label = tostring(node_spec.label or node_spec.id or "?"),
            __spec = node_spec,
        }

        if has_children then
            node.children = {} -- placeholder; expanded on enter / resolve / next
            node.collapsed = (node_spec.collapsed == true) and true or false
        end

        if is_editable then
            -- Render value if available (best-effort, no side-effects)
            local ok, edit_desc = pcall(node_spec.edit, ctx)
            if ok and type(edit_desc) == "table" then
                node.value = edit_desc.value
                node.editable = true
                node.__edit_set = edit_desc.set
            else
                node.value = nil
                node.editable = true
                node.__edit_set = nil
            end
        end

        table.insert(out, node)
    end

    table.sort(out, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)

    return out
end

function SpecAdapter.to_tree(spec, ctx)
    spec = spec or { id = "empty", title = "Empty", nodes = {} }
    spec.id = spec.id or "spec"
    spec.title = spec.title or "Canopy"
    spec.nodes = spec.nodes or {}

    return {
        title = spec.title,
        tree = build_tree_nodes(spec.nodes, ctx),
    }
end

function SpecAdapter.normalize_resolve(result)
    return normalize_resolve_result(result)
end

return SpecAdapter
