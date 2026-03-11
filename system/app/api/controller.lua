---@class AppAPI
---@field private __app Surface
local API = {}
API.__index = API

function API.new(app)
    return setmetatable({ __app = app }, API)
end

local function apply_inputs(app, inputs)
    for _, entry in ipairs(inputs or {}) do
        assert(type(entry) == "table", "[api] input entry must be table")
        assert(type(entry.role) == "string", "[api] input entry.role required")
        assert(type(entry.payload) == "table", "[api] input entry.payload required")

        app:data():submit(entry.role, entry.payload)
    end
end

local function apply_intent(app, intent)
    for key, value in pairs(intent or {}) do
        app:data():intent():set(key, value)
    end
end

local function apply_slots(app, slots)
    for _, entry in ipairs(slots or {}) do
        assert(type(entry) == "table", "[api] slot entry must be table")
        app:data():slots():set_selection(entry.scope, entry.role, entry.value)
    end
end

local function pull_runtime_for_service(app, service_name)
    local runtime = app:data():runtime()

    if service_name == "compare" or service_name == "pricing" then
        runtime:pull("system", "vendor")
        runtime:pull("user", "job")
        return
    end

    runtime:pull("user")
    runtime:pull("system")
end

local function run_service(app, service_name, selector, opts)
    assert(type(service_name) == "string" and service_name ~= "",
        "[api] service_name required")

    local services = app:services()
    local constructor = services[service_name]

    assert(type(constructor) == "function",
        "[api] unknown service: " .. tostring(service_name))

    local service = constructor(services)
    assert(type(service) == "table", "[api] service instance required")
    assert(type(service.run) == "function",
        "[api] service.run() required for " .. tostring(service_name))

    return service:run(selector, opts or {})
end

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

    elseif command == "run_workflow" then
        apply_inputs(self.__app, args.inputs)
        apply_intent(self.__app, args.intent)
        apply_slots(self.__app, args.slots)

        local service_name = args.service
        local selector = args.selector
        local opts = args.opts or {}

        pull_runtime_for_service(self.__app, service_name)

        local result = run_service(
            self.__app,
            service_name,
            selector,
            opts
        )

        return {
            ok = true,
            service = service_name,
            result = result,
            state = self.__app:data():inspect()
        }

    else
        return {
            ok = false,
            error = "unknown_command"
        }
    end
end

return API
