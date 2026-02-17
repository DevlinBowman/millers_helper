-- tools/system_index/registry.lua

local Scanner = require("tools.system_index.internal.scanner")

local Registry = {}

function Registry.scan()
    return Scanner.scan_loaded_modules()
end

return Registry
