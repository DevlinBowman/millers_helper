-- core/schema/api/schema.lua
--
-- Schema Structural Access API
--
-- Provides direct access to schema metadata.
--
-- Concept Space
--
--   Field domains
--       "board"
--       "order"
--
--   Value domains
--       "board.grade"
--       "board.surface"
--       "allocation.scope"

local Engine = require("core.schema.engine.core")

---@class SchemaStructureAPI
local Schema = {}

------------------------------------------------
-- field lookup
------------------------------------------------

---Return field definition from a field-domain.
---
---Example
---  Schema.field("board","grade")
---

---@param domain SchemaFieldDomain
---@param name string
---@return FieldRecord|nil
function Schema.field(domain, name)
    return Engine.field(domain, name)
end

------------------------------------------------
-- value lookup
------------------------------------------------


---Return value record from a value-domain.
---
---Example
---  Schema.value("board.grade","CA")
---
---@param domain SchemaValueDomain
---@param key string
---@return StandardRecord|nil
function Schema.value(domain, key)
    return Engine.value(domain, key)
end

------------------------------------------------
-- domain fields
------------------------------------------------

---Return ordered list of canonical field names.
---
---Example
---  Schema.fields("board")
---
---@param domain SchemaFieldDomain
---@return string[]|nil
function Schema.fields(domain)
    return Engine.domain_fields(domain)
end

------------------------------------------------
-- value universe
------------------------------------------------

---Return all allowed values for a value-domain.
---
---Example
---  Schema.values("board.grade")
---
---@param domain SchemaValueDomain
---@return StandardRecord[]|nil
function Schema.values(domain)
    return Engine.domain_values(domain)
end

------------------------------------------------
-- reference resolution
------------------------------------------------

---Resolve reference name to a concrete value-domain.
---
---Example
---  Schema.reference("grade","board")
---  → "board.grade"
---
---@param reference string
---@param context SchemaFieldDomain
---@return string|nil
function Schema.reference(reference, context)
    return Engine.reference(reference, context)
end

return Schema
