-- core/schema/engine/runtime/canonicalize.lua
--
-- Schema-driven symbol canonicalization.

local Resolver = require("core.schema.engine.runtime.resolver")
local State    = require("core.schema.engine.runtime.state")

local Canonicalize = {}

------------------------------------------------
-- canonicalize object
------------------------------------------------

---@param domain string
---@param obj table
---@return table
function Canonicalize.object(domain, obj)

    if type(obj) ~= "table" then
        return obj
    end

    local fields = Resolver.domain_fields(domain)

    if not fields then
        return obj
    end

    for _, fname in ipairs(fields) do

        local field = Resolver.field(domain, fname)

        if not field then
            goto continue
        end

        local ref = field.reference

        if not ref then
            goto continue
        end

        ------------------------------------------------
        -- value domain only
        ------------------------------------------------

        if not State.values[ref] then
            goto continue
        end

        local v = obj[field.name]

        if v ~= nil then

            local enum = Resolver.value(ref, v)

            if enum then
                obj[field.name] = enum.name
            end

        end

        ::continue::
    end

    return obj
end

return Canonicalize
