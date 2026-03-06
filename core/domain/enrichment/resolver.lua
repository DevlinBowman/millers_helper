-- core/domain/enrichment/resolver.lua

local Resolver = require("core.schema.engine.runtime.resolver")

local FieldResolver = {}

------------------------------------------------
-- fields by group
------------------------------------------------

function FieldResolver.fields_for_group(domain, group)

    local out = {}

    local fields = Resolver.domain_fields(domain)

    if not fields then
        return out
    end

    for _, name in ipairs(fields) do
        local f = Resolver.field(domain, name)

        if f and f.groups then
            for _, g in ipairs(f.groups) do

                if g == group then
                    out[#out + 1] = f.name
                end
            end
        end

    end

    return out
end

------------------------------------------------
-- field metadata
------------------------------------------------

function FieldResolver.field(domain, name)
    return Resolver.field(domain, name)
end

return FieldResolver
