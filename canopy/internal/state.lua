-- canopy/internal/state.lua
--
-- Pure state container (no vim).

local State = {}
State.__index = State

function State.new(opts)
    opts = opts or {}

    return setmetatable({
        title     = opts.title or "Canopy",
        tree      = opts.tree or {},
        actions   = opts.actions or {},
        context   = opts.context or {},

        folds     = {},     -- reserved for later (per-node fold state)
        focus_id  = nil,    -- reserved for later (cursor restore)
        line_map  = {},     -- line_no -> node
    }, State)
end

function State:set_tree(tree)
    self.tree = tree or {}
end

function State:set_line_map(map)
    self.line_map = map or {}
end

function State:get_node_by_line(line)
    if not line then
        return nil
    end
    return self.line_map[line]
end

return State
