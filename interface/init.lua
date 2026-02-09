-- interface/init.lua

local Interface = {}

function Interface.run(argv)
    -- default to CLI for now
    local shell = require("interface.shells.cli.init")
    return shell.run(argv)
end

return Interface
