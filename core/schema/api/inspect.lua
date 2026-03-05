-- core/schema/api/inspect.lua
--
-- Schema Inspection API
--
-- Provides introspection tools for exploring schema structure.

local Engine = require("core.schema.engine.core")

---@class SchemaInspectAPI
local Inspect = {}

------------------------------------------------
-- structured inspection
------------------------------------------------

---Return structured schema metadata.
---
---Example
---  Inspect.domain("board")
---
---@param domain SchemaFieldDomain|SchemaValueDomain|nil
---@return table
function Inspect.domain(domain)
    return Engine.inspect(domain)
end

------------------------------------------------
-- compact view
------------------------------------------------

---Return compact textual schema representation.
---
---Example
---  Inspect.print("board")
---
---@param domain SchemaFieldDomain|SchemaValueDomain|nil
---@return string
function Inspect.print(domain)
    return Engine.inspect_compact(domain)
end

return Inspect
