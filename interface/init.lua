-- interface/init.lua

local Interface = {}

function Interface.run(argv)
    local CLI = require("interface.shells.cli.init")
    return CLI.run(argv or {})
end

return Interface
