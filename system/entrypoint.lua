-- system/entrypoint.lua

local Backend = require("system.backend")

local Entrypoint = {}
Entrypoint.__index = Entrypoint

------------------------------------------------------------
-- Boot Application
------------------------------------------------------------

function Entrypoint.new(opts)
    opts = opts or {}

    local instance = opts.instance or "default"

    local surface = Backend.run(instance)

    local self = setmetatable({
        surface = surface,
        api     = surface:api(),
    }, Entrypoint)

    return self
end

------------------------------------------------------------
-- Handle API Request
------------------------------------------------------------

function Entrypoint:handle(request)
    local ok, result = pcall(function()
        return self.api:handle(request)
    end)

    if not ok then
        return {
            ok = false,
            error = "internal_error",
            message = tostring(result)
        }
    end

    return result
end

return Entrypoint
