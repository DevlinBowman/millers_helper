local Boundary = require("tools.trace.trace")
local Debug    = require("tools.trace.debug")

local Trace = {}

-- Boundary tracing
Trace.set            = Boundary.set
Trace.contract_enter = Boundary.contract_enter
Trace.contract_in    = Boundary.contract_in
Trace.contract_out   = Boundary.contract_out
Trace.contract_leave = Boundary.contract_leave

-- Debug tracing
Trace.debug_enable = Debug.enable
Trace.debug        = Debug.log

return Trace
