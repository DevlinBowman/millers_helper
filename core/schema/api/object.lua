-- core/schema/api/object.lua
--
-- Schema Object Operations API
--
-- Provides runtime operations that operate on schema-bound objects.
--
-- Responsibilities
--
--   • DTO creation
--   • structural existence checks
--   • semantic validation
--   • strict validation gate
--   • deep schema audit
--   • dataset auditing
--
-- These operations work against **field-domains** such as:
--
--   "board"
--   "order"
--   "transaction"
--   "batch"
--
-- Example
--
--   local S = require("core.schema")
--
--   local dto = S.object.dto("board", { grade = "CA" })
--
--   local ok = S.object.check("board", obj)
--
--   local audit = S.object.audit("board", obj)
--   audit.tree()

local Engine = require("core.schema.engine.core")

---@class SchemaObjectAPI
local Object = {}

------------------------------------------------
-- DTO creation
------------------------------------------------

---Create a DTO wrapper enforcing schema rules.
---
---DTO responsibilities:
---  • alias → canonical key resolution
---  • mutability enforcement
---  • primitive type validation
---  • optional enum validation
---
---Example
---  Object.dto("board", { grade = "CA" })
---
---@param domain SchemaFieldDomain
---@param data table|nil
---@return table DTO
function Object.dto(domain, data)
    return Engine.dto(domain, data)
end

------------------------------------------------
-- structural existence check
------------------------------------------------

---Check structural membership of object against schema.
---
---Verifies:
---  • required fields present
---  • unknown keys rejected
---
---Example
---  Object.exists("board", obj)
---
---@param domain SchemaFieldDomain
---@param obj table
---@return boolean ok
---@return table report
function Object.exists(domain, obj)
    return Engine.exists(domain, obj)
end

------------------------------------------------
-- semantic validation
------------------------------------------------

---Validate object against schema rules.
---
---Checks:
---  • primitive type correctness
---  • enum reference validity
---
---Example
---  Object.validate("board", obj)
---
---@param domain SchemaFieldDomain
---@param obj table
---@return boolean ok
---@return table errors
function Object.validate(domain, obj)
    return Engine.validate(domain, obj)
end

------------------------------------------------
-- strict validation gate
------------------------------------------------

---Strict validation gate.
---
---Returns:
---  ok=true if object passes all checks
---  ok=false with structured report otherwise
---
---Example
---  local ok, report = Object.check("board", obj)
---
---@param domain SchemaFieldDomain
---@param obj table
---@return boolean ok
---@return table|nil report
function Object.check(domain, obj)
    return Engine.check(domain, obj)
end

------------------------------------------------
-- object audit
------------------------------------------------

---Run deep schema audit against object.
---
---Returns an audit handle with operations:
---
---  audit.report        → structured audit report
---  audit.deep()        → deep traversal result
---  audit.tree()        → print audit tree
---  audit.table()       → print tabular audit
---  audit.diff()        → diff vs schema
---  audit.compare(obj)  → compare two objects
---
---Example
---  local audit = Object.audit("board", obj)
---
---  audit.tree()
---  audit.table()
---
---@param domain SchemaFieldDomain
---@param obj table
---@return table audit
function Object.audit(domain, obj)
    return Engine.audit(domain, obj)
end

------------------------------------------------
-- dataset audit
------------------------------------------------

---Audit dataset of objects against schema.
---
---Useful for validating collections or batch inputs.
---
---Example
---  local result = Object.audit_dataset("board", boards)
---
---@param domain SchemaFieldDomain
---@param list table[]
---@return table dataset_report
function Object.audit_dataset(domain, list)
    return Engine.audit_dataset(domain, list)
end

return Object
