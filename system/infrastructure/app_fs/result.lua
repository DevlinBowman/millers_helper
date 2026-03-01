-- system/infrastructure/app_fs/result.lua
--
-- AppFSResult is a semantic façade over an app-owned filesystem location.
-- It wraps a resolved absolute path and delegates inspection to platform.io.query.
--
-- Design:
--   • Traversal methods are primary (files, dirs, entries, file, dir)
--   • Evaluation + metadata live under :inspect()
--   • Traversal is strict by default
--   • No require_* methods exposed publicly

local IOQuery = require("platform.io.query").controller

----------------------------------------------------------------
-- Types
----------------------------------------------------------------

---@class AppFSInspection
---@field exists fun():boolean              -- true if path exists
---@field is_directory fun():boolean        -- true if path is directory
---@field is_file fun():boolean             -- true if path is file
---@field is_missing fun():boolean          -- true if path missing
---@field size fun():integer|nil            -- file size in bytes (file only)
---@field hash fun():string|nil             -- file hash (file only)

---@class AppFSResult
---@field private __path string
local AppFSResult = {}
AppFSResult.__index = AppFSResult

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---Create new AppFSResult for absolute path.
---@param absolute_path string
---@return AppFSResult
function AppFSResult.new(absolute_path)
    assert(
        type(absolute_path) == "string" and #absolute_path > 0,
        "[app_fs] absolute_path required"
    )

    return setmetatable({
        __path = absolute_path
    }, AppFSResult)
end

----------------------------------------------------------------
-- Core
----------------------------------------------------------------

---Return absolute filesystem path string.
---@return string
function AppFSResult:path()
    return self.__path
end


---@private
---@return QueryResult
function AppFSResult:query()
    return IOQuery.query_strict(self.__path)
end

----------------------------------------------------------------
-- Traversal (Primary Surface)
----------------------------------------------------------------

---Return file paths within directory (strict).
---@return string[]
function AppFSResult:files()
    local q = self:query()
    assert(q:is_directory(), "[fs] expected directory: " .. self:path())
    return q:files()
end

---Return subdirectory paths within directory (strict).
---@return string[]
function AppFSResult:dirs()
    local q = self:query()
    assert(q:is_directory(), "[fs] expected directory: " .. self:path())
    return q:dirs()
end

---Return raw directory entry names (strict).
---@return string[]
function AppFSResult:entries()
    local q = self:query()
    assert(q:is_directory(), "[fs] expected directory: " .. self:path())
    return q:entries()
end

---Return file path at given index (directory only).
---@param index integer
---@return string|nil
function AppFSResult:file(index)
    local files = self:files()
    return files[index]
end

---Return directory path at given index (directory only).
---@param index integer
---@return string|nil
function AppFSResult:dir(index)
    local dirs = self:dirs()
    return dirs[index]
end

----------------------------------------------------------------
-- Evaluation / Metadata (Grouped)
----------------------------------------------------------------

---Return inspection helpers for existence and metadata.
---@return AppFSInspection
function AppFSResult:inspect()
    local q = self:query()

    ---@type AppFSInspection
    local inspection = {
        exists = function()
            return q:exists()
        end,

        is_directory = function()
            return q:is_directory()
        end,

        is_file = function()
            return q:is_file()
        end,

        is_missing = function()
            return q:is_missing()
        end,

        size = function()
            assert(q:is_file(), "[fs] expected file: " .. self:path())
            return q:size()
        end,

        hash = function()
            assert(q:is_file(), "[fs] expected file: " .. self:path())
            return q:hash()
        end,
    }

    return inspection
end

return AppFSResult
