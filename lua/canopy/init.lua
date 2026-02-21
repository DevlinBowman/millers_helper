-- canopy/init.lua
--
-- Self-register canopy root so internal requires always work
do
    local source = debug.getinfo(1, "S").source
    local filepath = source:sub(2)
    local root = filepath:match("(.*/)")
    if root then
        package.path =
            root .. "?.lua;" ..
            root .. "?/init.lua;" ..
            package.path
    end
end

local Controller = require("canopy.controller")
local Registry   = require("canopy.registry")

local Canopy = {}

Canopy.controller = Controller
Canopy.registry   = Registry

-- Construct only (does NOT run)
function Canopy.new(opts)
    return Controller.new(opts)
end

-- Construct + run
function Canopy.open(opts)
    return Controller.open(opts)
end

return Canopy
