local Persistence = require("system.app.persistence")
local RuntimeHub  = require("system.app.runtime_hub")

local Services = require("system.app.surface.services")
local Resources = require("system.app.surface.resources")
local Session = require("system.app.surface.session")
local Status  = require("system.app.surface.status")
local Inspect = require("system.app.surface.inspect")

local Surface = {}
Surface.__index = Surface

function Surface.new(opts)
    opts = opts or {}

    local state = Persistence.load(opts.persistence)

    local self = setmetatable({}, Surface)

    self.state = state
    self.hub   = RuntimeHub.new(self.state.resources)

    -- Explicit composition
    self.resources = Resources.new(self)
    self.services  = Services.new(self)
    self.session   = Session.new(self)
    self.status    = Status.new(self)
    self.inspect   = Inspect.new(self)

    return self
end

return Surface
