local RuntimeDomain = require("core.domain.runtime.controller")
local Storage       = require("system.infrastructure.storage.controller")

local RuntimeContext = {}
RuntimeContext.__index = RuntimeContext

function RuntimeContext.new(state)
    return setmetatable({
        state = state
    }, RuntimeContext)
end

------------------------------------------------------------
-- Resolve Order
------------------------------------------------------------

function RuntimeContext:resolve_order()

    local res = self.state.resources.order
    if not res then
        return nil, "order resource not configured"
    end

    if res.runtime then
        return res.runtime
    end

    if res.cache_path then
        local runtime = RuntimeDomain.load(res.cache_path)
        res.runtime = runtime
        res.status = "loaded"
        return runtime
    end

    if res.source_path then
        local runtime = RuntimeDomain.load(res.source_path)
        res.runtime = runtime
        res.status = "loaded"
        return runtime
    end

    return nil, "order resource missing source_path"
end

return RuntimeContext
