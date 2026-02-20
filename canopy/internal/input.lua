-- canopy/internal/input.lua

local Input = {}

function Input.handle_enter(state, node)
    if not node then
        return nil
    end

    local ctx = {
        api     = state.context and state.context.api,
        state   = state.context and state.context.state,
        context = state.context,
    }

    ------------------------------------------------------------
    -- Expand / Collapse
    ------------------------------------------------------------

    if node.children then
        node.collapsed = not node.collapsed
        return "rerender"
    end

    ------------------------------------------------------------
    -- Declarative Action
    ------------------------------------------------------------

    if type(node.action) == "function" then
        node.action(ctx)
        return "rerender"
    end

    ------------------------------------------------------------
    -- Declarative Navigation (legacy)
    ------------------------------------------------------------

    if type(node.next) == "function" then
        local next_spec = node.next(ctx)

        if next_spec and type(next_spec) == "table" then
            state.tree = next_spec.nodes or {}
            state.title = next_spec.title or state.title
            return "rerender"
        end
    end

    ------------------------------------------------------------
    -- Legacy Action Map
    ------------------------------------------------------------

    if state.actions and state.actions[node.id] then
        state.actions[node.id](node, state.context)
        return "rerender"
    end

    ------------------------------------------------------------
    -- Editable Fallback
    ------------------------------------------------------------

    if node.editable and state.actions and state.actions.edit then
        state.actions.edit(node, state.context)
        return "rerender"
    end

    return nil
end

return Input
