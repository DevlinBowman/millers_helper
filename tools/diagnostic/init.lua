-- tools/diagnostic/init.lua
--
-- Scoped diagnostic runtime layer.
--
-- Similar to tools.trace:
--   • scope_enter/scope_leave
--   • emit structured events
--   • sinks for routing (console, user-facing, etc.)
--   • inspect current scope during execution
--
-- Diagnostics are ephemeral by default and should not pollute
-- canonical domain envelopes unless explicitly exported.

local Boundary   = require("tools.diagnostic.diagnostic")
local Controller = require("tools.diagnostic.controller")

local Diagnostic = {}

-- Boundary (scoped runtime bus)
Diagnostic.set            = Boundary.set
Diagnostic.scope_enter    = Boundary.scope_enter
Diagnostic.scope_leave    = Boundary.scope_leave
Diagnostic.current        = Boundary.current
Diagnostic.peek_events    = Boundary.peek_events
Diagnostic.emit_event     = Boundary.emit_event

Diagnostic.signal         = Boundary.signal
Diagnostic.decision       = Boundary.decision
Diagnostic.debug          = Boundary.debug
Diagnostic.user_message   = Boundary.user_message

Diagnostic.add_sink       = Boundary.add_sink
Diagnostic.remove_sink    = Boundary.remove_sink
Diagnostic.clear_sinks    = Boundary.clear_sinks
Diagnostic.list_sinks     = Boundary.list_sinks

-- Controller helpers (optional)
Diagnostic.with_scope     = Controller.with_scope
Diagnostic.export         = Controller.export

return Diagnostic
