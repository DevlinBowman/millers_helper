-- core/domain/enrichment/services.lua

local Services = {}

local registry = {
    pricing = require("core.domain.enrichment.services.pricing"),
}

function Services.get(name)
    return registry[name]
end

function Services.list()
    local out = {}

    for name in pairs(registry) do
        out[#out + 1] = name
    end

    table.sort(out)

    return out
end

return Services
