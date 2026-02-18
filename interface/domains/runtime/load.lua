-- interface/domains/runtime/load.lua

local M = {}

M.help = {
    usage = "runtime load <path>"
}

function M.run(ctx, controller)
    return controller:load(ctx)
end

return M
