local Executor = require("system.execution.controller")

---@class AppExecutionFacade
---@field private __app Surface
local Execution = {}
Execution.__index = Execution

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppExecutionFacade
function Execution.new(app)

    return setmetatable({
        __app = app
    }, Execution)

end

------------------------------------------------------------
-- Run Execution Capability
------------------------------------------------------------

---@param service string
---@param opts table|nil
---@return any
function Execution:run(service, opts)

    return Executor.run(
        self.__app,
        service,
        opts
    )

end

return Execution
