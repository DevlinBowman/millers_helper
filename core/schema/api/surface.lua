-- core/schema/api/surface.lua

---@diagnostic disable: unused-local
local _types = require("core.schema.api.types_generated")
--
-- Schema Public API Surface
--
-- This file defines the canonical entrypoint used by consumers.
--
-- Responsibilities
--   • Provide stable namespace for schema capabilities
--   • Group operations by conceptual space
--   • Provide discoverable LSP surface
--
-- Concept Spaces
--
--   schema   → structural schema metadata
--   query    → cross-schema search
--   inspect  → schema introspection
--   object   → object validation + DTO + audit
--
-- Example
--
--   local S = require("core.schema")
--
--   local f = S.schema.field("board","grade")
--   local v = S.schema.value("board.grade","CA")
--
--   local item = S.query.get("board.grade")
--
--   local audit = S.object.audit("board", obj)

---@class SchemaAPI
---@field schema SchemaStructureAPI
---@field query SchemaQueryAPI
---@field inspect SchemaInspectAPI
---@field object SchemaObjectAPI
local Surface = {}

Surface.schema  = require("core.schema.api.schema")
Surface.query   = require("core.schema.api.query")
Surface.inspect = require("core.schema.api.inspect")
Surface.object  = require("core.schema.api.object")

return Surface
