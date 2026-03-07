-- core/identity/schema.lua
--
-- Identity ↔ Schema bridge utilities.
-- Centralizes schema access for identity logic.

local S = require("core.schema")

local Schema = {}

------------------------------------------------
-- field default
------------------------------------------------

---@param domain string
---@param field string
---@return any
function Schema.default(domain, field)

    local f = S.schema.field(domain, field)

    if not f then
        error(
            string.format(
                "[identity.schema] unknown field %s.%s",
                tostring(domain),
                tostring(field)
            ),
            2
        )
    end

    return f.default
end

------------------------------------------------
-- enum membership
------------------------------------------------

---@param domain string
---@param value string
---@return boolean
function Schema.is_value(domain, value)

    if value == nil then
        return false
    end

    return S.schema.value(domain, value) ~= nil
end

return Schema
