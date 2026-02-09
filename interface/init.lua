-- interface/init.lua

local Interface = {}

function Interface.run(argv, opts)
    opts = opts or {}

    local mode = opts.mode or "cli"

    if mode == "tui" then
        local shell = require("interface.shells.tui.init")
        return shell.run(argv)
    end

    local shell = require("interface.shells.cli.init")
    return shell.run(argv)
end

return Interface
