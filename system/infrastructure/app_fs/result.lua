-- system/infrastructure/app_fs/result.lua
--
-- AppFSResult is a semantic façade over an app-owned filesystem location.
-- It wraps a resolved absolute path and delegates inspection to platform.io.query.

local IOQuery = require("platform.io.query").controller

---@class AppFSResult
---@field private __path string
local AppFSResult = {}
AppFSResult.__index = AppFSResult

---@param absolute_path string
---@return AppFSResult
function AppFSResult.new(absolute_path)
    assert(type(absolute_path) == "string" and #absolute_path > 0, "[app_fs] absolute_path required")
    return setmetatable({ __path = absolute_path }, AppFSResult)
end

------------------------------------------------------------
-- Meaning Layer (semantic access)
------------------------------------------------------------

function AppFSResult:path()
    return self.__path
end

function AppFSResult:query()
    -- Returns QueryResult façade (platform/io/query/controller.lua)
    return IOQuery.query_strict(self.__path)
end

function AppFSResult:exists()
    return self:query():exists()
end

function AppFSResult:is_directory()
    return self:query():is_directory()
end

function AppFSResult:is_file()
    return self:query():is_file()
end

------------------------------------------------------------
-- Directory helpers (normalized)
------------------------------------------------------------

function AppFSResult:files()
    return self:query():require_directory():files()
end

function AppFSResult:dirs()
    return self:query():require_directory():dirs()
end

function AppFSResult:entries()
    return self:query():require_directory():entries()
end

function AppFSResult:file(index)
    local files = self:files()
    return files[index]
end

function AppFSResult:dir(index)
    local dirs = self:dirs()
    return dirs[index]
end

------------------------------------------------------------
-- File helpers (normalized)
------------------------------------------------------------

function AppFSResult:size()
    return self:query():require_file():size()
end

function AppFSResult:hash()
    return self:query():require_file():hash()
end

------------------------------------------------------------
-- Policy helpers (strictness)
------------------------------------------------------------

function AppFSResult:require_exists()
    self:query():require_exists()
    return self
end

function AppFSResult:require_directory()
    self:query():require_directory()
    return self
end

function AppFSResult:require_file()
    self:query():require_file()
    return self
end

return AppFSResult
