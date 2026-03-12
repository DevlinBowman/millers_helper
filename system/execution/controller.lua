-- system/execution/controller.lua

local Planner = require("system.execution.planner")
local Runner  = require("system.execution.runner")

local Executor = {}

---@param app Surface
---@param service_name string
---@param opts table|nil
---@return any
function Executor.run(app, service_name, opts)
    opts = opts or {}

    assert(type(app) == "table", "[execution] app required")
    assert(type(service_name) == "string" and service_name ~= "", "[execution] service_name required")

    local data = app:data()
    local ctx_controller = data:context()

    local seed_ctx = Planner.build(app, service_name, opts)
    local ctx = ctx_controller:create("execution", seed_ctx)

    local result = Runner.execute(app, ctx)

    ctx_controller:clear("execution")
    return result
end

return Executor
