-- system/app/surface/init.lua

local Persistence = require("system.app.persistence")
local RuntimeHub  = require("system.app.runtime_hub")

local Surface = {}
Surface.__index = Surface

function Surface.new(opts)
    opts = opts or {}

    local state = Persistence.load(opts.persistence)

    local self = setmetatable({}, Surface)
    self.state = state
    self.hub   = RuntimeHub.new(self.state.resources)

    return self
end

----------------------------------------------------------------
-- Inject method extensions
----------------------------------------------------------------

require("system.app.surface.resources")(Surface)
require("system.app.surface.compare")(Surface)
require("system.app.surface.quote")(Surface)
require("system.app.surface.invoice")(Surface)
require("system.app.surface.ingest")(Surface)
require("system.app.surface.vendor_reference")(Surface)
require("system.app.surface.status")(Surface)
require("system.app.surface.inspect")(Surface)

----------------------------------------------------------------
-- Core persistence
----------------------------------------------------------------

function Surface:check()
    return {
        instance  = require("system.infrastructure.storage.controller").get_instance(),
        status    = self:status(),
        resources = self.state:resources_table(),
    }
end

function Surface:save(opts)
    return Persistence.save(self.state, opts)
end

function Surface:get_state()
    return self.state
end

return Surface
