-- canopy/init.lua

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
