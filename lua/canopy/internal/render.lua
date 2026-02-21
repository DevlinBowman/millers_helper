-- canopy/internal/render.lua
--
-- Tree → display transformation with affordance markers.

local Renderer = {}

local ICONS = {
    collapsed = "▸",
    expanded  = "▾",
    navigate  = "➤",
    editable  = "✎",
    plain     = "•",
}


local function marker_for(node)
    -- dropdown / navigable (legacy children OR spec has_children flag)
    if node.children or node.__has_children then
        if node.collapsed then
            return ICONS.collapsed
        else
            return ICONS.expanded
        end
    end

    -- navigation context switch (legacy)
    if node.navigates then
        return ICONS.navigate
    end

    -- editable leaf
    if node.editable then
        return ICONS.editable
    end

    return ICONS.plain
end

local function render_nodes(nodes, depth, lines, line_map)
    depth = depth or 0

    for _, node in ipairs(nodes or {}) do
        local indent = string.rep("  ", depth)
        local marker = marker_for(node)

        local label = node.label or node.id or "?"

        local line = indent .. marker .. " " .. label

        if node.value ~= nil then
            line = line .. " = " .. tostring(node.value)
        end

        table.insert(lines, line)
        line_map[#lines] = node

        if node.children and not node.collapsed then
            render_nodes(node.children, depth + 1, lines, line_map)
        end
    end
end

function Renderer.render(state)
    local lines = {}
    local line_map = {}

    table.insert(lines, state.title)
    table.insert(lines, string.rep("─", #state.title))
    table.insert(lines, "")

    render_nodes(state.tree, 0, lines, line_map)

    return {
        lines = lines,
        highlights = {},
        line_map = line_map,
    }
end

return Renderer
