-- system/execution/controller.lua

local ContextCompiler = require("system.execution.context_compiler")
local Runner          = require("system.execution.runner")

local Executor = {}

---@param app Surface
---@param service_name string
---@param opts table|nil
---@return any
function Executor.run(app, service_name, opts)

    opts = opts or {}

    local data = app:data()
    local ctx_controller = data:context()

    local ctx =
        ContextCompiler.build(app, service_name, opts)

    ctx =
        ctx_controller:create("execution", ctx)

    local result =
        Runner.execute(app, ctx)

    ctx_controller:clear("execution")

    return result
end

return Executor
