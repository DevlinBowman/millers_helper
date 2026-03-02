-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller

---@class AppCompareService
local Compare = {}
Compare.__index = Compare

function Compare.new(app)
    return setmetatable({
        __app = app
    }, Compare)
end

------------------------------------------------------------
-- Run Compare From Runtime
------------------------------------------------------------
-- Uses:
--   user job batch
--   system vendor batches
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return CompareResult
function Compare:run(selector, opts)

    local data    = self.__app:data()
    local runtime = data:runtime()

    --------------------------------------------------------
    -- Load user job
    --------------------------------------------------------

    local user_rt = runtime:require("user", "job", selector)

    assert(type(user_rt.batch) == "function",
        "[compare.service] runtime job missing batch()")

    local user_batch = user_rt:batch()

    --------------------------------------------------------
    -- Load all system vendors
    --------------------------------------------------------

    local vendor_descriptors = data:resources():get("system", "vendor") or {}
    local vendor_batches = {}

    for i = 1, #vendor_descriptors do
        local rt = runtime:require("system", "vendor", i)
        vendor_batches[#vendor_batches + 1] = rt:batch()
    end

    --------------------------------------------------------
    -- Domain Strict Execution
    --------------------------------------------------------

    return CompareDomain.run_strict(
        user_batch,
        vendor_batches,
        opts
    )
end

return Compare
