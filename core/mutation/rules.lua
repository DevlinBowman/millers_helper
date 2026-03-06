-- core/mutation/rules.lua

local S = require("core.schema")

local Rules = {}

function Rules.immutable_from_schema(domain)

    local immutable = {}

    local field_names = S.schema.fields(domain)

    if not field_names then
        return immutable
    end

    for _, name in ipairs(field_names) do

        local field = S.schema.field(domain, name)

        if field then
            if field.mutable == false or field.authority == "derived" then
                immutable[name] = true
            end
        end
    end

    return immutable
end

return Rules
