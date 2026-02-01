-- tools/inspection/router.lua
local Targets = require("tools.inspection.targets")

local Router = {}

function Router.run(target, ctx)
    local node = Targets[target]
    assert(node, "Unknown inspection target: " .. tostring(target))

    for _, dep in ipairs(node.requires or {}) do
        Router.run(dep, ctx)
    end

    node.run(ctx)
end

return Router
