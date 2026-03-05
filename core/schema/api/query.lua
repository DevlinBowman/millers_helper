-- core/schema/api/query.lua
--
-- Schema Query API
--
-- Provides cross-domain lookup and search functionality.
-- Operates on the flattened schema catalog produced by the engine.
--
-- Concept Space
--
--   Catalog items include:
--       • field definitions
--       • enum symbol definitions
--       • schema metadata objects
--
-- Example
--
--   local S = require("core.schema")
--
--   local item = S.query.get("board.grade")
--   local fields = S.query.list({ kind = "field", domain = "board" })
--
--   local domains = S.query.domains()

local Engine = require("core.schema.engine.core")

---@class SchemaQueryAPI
local Query = {}

------------------------------------------------
-- catalog access
------------------------------------------------

---Return catalog instance used for cross-schema queries.
---
---Example
---  local catalog = Query.catalog()
---  local items = catalog:list({ kind = "value" })
---
---@return table
function Query.catalog()
    return Engine.catalog()
end

------------------------------------------------
-- get item by canonical name
------------------------------------------------

---Lookup schema item by canonical name.
---
---Examples
---  Query.get("board.grade")
---  Query.get("allocation.scope.board")
---  Query.get("order")
---
---@param name string
---@return table|nil
function Query.get(name)
    return Engine.get(name)
end

------------------------------------------------
-- list items by filter
------------------------------------------------

---Return catalog items matching filter.
---
---Examples
---  Query.list({ kind = "field" })
---  Query.list({ domain = "board.grade" })
---  Query.list({ kind = "value", domain = "allocation.scope" })
---
---@param filter table|nil
---@return table[]
function Query.list(filter)
    return Engine.list(filter)
end

------------------------------------------------
-- list domains (from catalog)
------------------------------------------------

---Return list of all schema domains detected in catalog.
---
---Example
---  Query.domains()
---
---@return string[]
function Query.domains()
    local catalog = Engine.catalog()
    return catalog:domains()
end

------------------------------------------------
-- list field-domain names
------------------------------------------------

---Return list of canonical field domains.
---
---Example
---  Query.domain_names()
---
---@return SchemaFieldDomain[]
function Query.domain_names()
    return Engine.domain_names()
end

------------------------------------------------
-- print domain overview
------------------------------------------------

---Print domain grouping overview to console.
---Primarily used for debugging or schema exploration.
---
---Example
---  Query.print_domains()
function Query.print_domains()
    return Engine.print_domains()
end

return Query
