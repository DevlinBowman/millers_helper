-- core/schema/engine/runtime/audit/init.lua
--
-- Public audit surface.

local Audit    = require("core.schema.engine.runtime.audit.audit")
local Printers = require("core.schema.engine.runtime.audit.printers")
local Capabilities = require("core.schema.engine.runtime.audit.capabilities")

local Surface = {}

------------------------------------------------
-- core audit
------------------------------------------------

Surface.run     = Audit.run
Surface.deep    = Audit.deep
Surface.diff    = Audit.diff
Surface.compare = Audit.compare
Surface.dataset = Audit.dataset
Surface.capabilities = Capabilities.scan

------------------------------------------------
-- printers
------------------------------------------------

Surface.print  = Printers.print
Surface.tree   = Printers.tree
Surface.table  = Printers.table

return Surface
