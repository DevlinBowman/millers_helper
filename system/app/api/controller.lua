---@class AppAPI
---@field private __app Surface
local API = {}
API.__index = API

function API.new(app)
    return setmetatable({ __app = app }, API)
end

------------------------------------------------------------
-- Command Dispatcher
------------------------------------------------------------

function API:handle(request)
    assert(type(request) == "table")

    local command = request.command
    local args    = request.args or {}

    if command == "ping" then
        return {
            ok = true,
            status = "alive"
        }
    elseif command == "get_state" then
        return {
            ok = true,
            state = self.__app:data():inspect()
        }
    elseif command == "submit" then
        assert(type(args.role) == "string", "[api] submit requires role")
        assert(type(args.payload) == "table", "[api] submit requires payload")
        return self.__app:data():submit(args.role, args.payload)

    elseif command == "push_vendor" then
        return self.__app:services():vendor():run(args.selector, args.opts)
    else
        return {
            ok = false,
            error = "unknown_command"
        }
    end
end

return API
