local Compare = require("system.app.surface.compare")
local Quote   = require("system.app.surface.quote")
local Invoice = require("system.app.surface.invoice")
local Ingest  = require("system.app.surface.ingest")

local Services = {}
Services.__index = Services

function Services.new(surface)
    local self = setmetatable({}, Services)

    self.compare = Compare.new(surface)
    self.quote   = Quote.new(surface)
    self.invoice = Invoice.new(surface)
    self.ingest  = Ingest.new(surface)

    return self
end

return Services
