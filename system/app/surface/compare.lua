-- system/app/surface/compare.lua

local CompareSvc = require("system.services.compare_service")

local Compare = {}
Compare.__index = Compare

function Compare.new(surface)
    local self = setmetatable({}, Compare)
    self._surface = surface
    return self
end

function Compare:run(opts)
    return CompareSvc.handle({
        state = self._surface.state,
        hub   = self._surface.hub,
        opts  = opts
    })
end

return Compare
