-- system/app/api/controller.lua

---@class AppAPI
---@field private __app Surface
local API = {}
API.__index = API

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppAPI
function API.new(app)
    assert(type(app) == "table", "[api] app required")
    return setmetatable({ __app = app }, API)
end

------------------------------------------------------------
-- Command Router
------------------------------------------------------------

---@param request table
---@return table
function API:handle(request)

    assert(type(request) == "table", "[api] request must be table")

    local cmd  = request.command
    local args = request.args or {}

    --------------------------------------------------------
    -- ping
    --------------------------------------------------------

    if cmd == "ping" then
        return { ok = true, status = "alive" }
    end

    --------------------------------------------------------
    -- inspect state
    --------------------------------------------------------

    if cmd == "state" then
        return {
            ok = true,
            state = self.__app:data():inspect()
        }
    end

    --------------------------------------------------------
    -- submit input
    --------------------------------------------------------

    if cmd == "submit" then
        return self.__app:data():submit(
            args.role,
            args.payload
        )
    end

    --------------------------------------------------------
    -- run service (delegated)
    --------------------------------------------------------

    if cmd == "run" then
        local services = self.__app:services()
        local ctor = services[args.service]

        assert(type(ctor) == "function",
            "[api] unknown service: " .. tostring(args.service))

        local service = ctor(services)

        return service:run(
            args.selector,
            args.opts or {}
        )
    end

    --------------------------------------------------------

    return {
        ok = false,
        error = "unknown_command"
    }
end

return API
