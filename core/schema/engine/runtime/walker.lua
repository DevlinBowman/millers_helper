local Resolver = require("core.schema.engine.runtime.resolver")
local State    = require("core.schema.engine.runtime.state")

local Walker = {}

function Walker.walk(domain, obj, visitor, depth)

    depth = depth or 0

    local fields = Resolver.domain_fields(domain)
    if not fields then return end

    for _, name in ipairs(fields) do

        local f = Resolver.field(domain, name)
        local v = obj and obj[f.name]

        visitor(domain, f, v, depth)

        if v ~= nil and f.reference then

            ------------------------------------------------
            -- object domain
            ------------------------------------------------

            if State.fields[f.reference] then

                if type(v) == "table" and v[1] == nil then
                    Walker.walk(f.reference, v, visitor, depth + 1)

                elseif type(v) == "table" then
                    for _, item in ipairs(v) do
                        Walker.walk(f.reference, item, visitor, depth + 1)
                    end
                end

            end
        end
    end
end

return Walker
