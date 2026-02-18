-- app/api/runtime.lua
--
-- Application API: Runtime
--
-- Responsibilities:
--   • Expose canonical runtime loading surface
--   • Orchestrate core runtime domain
--   • Return stable structured result
--
-- No IO
-- No printing
-- No CLI logic
-- No prompting

local RuntimeDomain = require("core.domain.runtime.controller")

local RuntimeAPI = {}

----------------------------------------------------------------
-- Load arbitrary input into canonical batches
--
-- @param input string|table
-- @return table { batches = { {order=..., boards=...}[] } }
----------------------------------------------------------------

function RuntimeAPI.load(input)
    assert(input ~= nil, "RuntimeAPI.load(): input required")

    local result = RuntimeDomain.load(input)

    assert(
        type(result) == "table"
        and type(result.batches) == "table",
        "RuntimeAPI.load(): invalid runtime response"
    )

    return result
end

return RuntimeAPI
