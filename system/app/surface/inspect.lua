-- system/app/surface/inspect.lua

local Inspect = {}
Inspect.__index = Inspect

function Inspect.new(surface)
    local self = setmetatable({}, Inspect)
    self._surface = surface
    return self
end

function Inspect:get()
    local state = self._surface.state

    return {
        context   = state:context_table(),
        resources = state:resources_table(),
        results   = state.results,
    }
end

return Inspect
