-- platform/io/query/controller.lua
--
-- Filesystem Query Controller
--
-- Intent:
--   Provides a stable entrypoint for inspecting filesystem paths.
--   Classifies a path as "file", "directory", or "missing" and
--   returns structured metadata about it.
--
-- Design:
--   • `query_raw(path)` returns a validated structural table.
--   • `query(path)` wraps the raw result in a QueryResult façade
--     exposing semantic accessors.
--   • `query_strict(path)` throws on failure.
--
-- This module separates:
--   • Structural representation (pipeline output)
--   • Semantic consumption (QueryResult methods)
--
-- Use raw mode for tooling and internal pipelines.
-- Use façade mode for application/domain logic.
--
-- This controller does not perform IO directly.
-- It delegates inspection to the query pipeline.

local Pipeline   = require("platform.io.query.pipelines.inspect")
local Contract   = require("core.contract")
local Trace      = require("tools.trace.trace")
local Diagnostic = require("tools.diagnostic")

local Controller = {}

----------------------------------------------------------------
-- CONTRACT (for raw structural output)
----------------------------------------------------------------

Controller.CONTRACT = {
    in_ = {
        path = true,
    },
    out = {
        path   = true,
        exists = true,
        kind   = true,
        entries = false,
        files   = false,
        dirs    = false,
        size    = false,
        hash    = false,
    },
}

----------------------------------------------------------------
-- QueryResult (Façade)
----------------------------------------------------------------

---@class QueryResult
---@field private __data table
local QueryResult = {}
QueryResult.__index = QueryResult

---@param data table
---@return QueryResult
function QueryResult.new(data)
    return setmetatable({ __data = data }, QueryResult)
end

----------------------------------------------------------------
-- BASIC INTENT
----------------------------------------------------------------

--- Returns the queried path.
---@return string
function QueryResult:path()
    return self.__data.path
end

--- Returns true if the path exists.
---@return boolean
function QueryResult:exists()
    return self.__data.exists
end

--- Returns true if this is a directory.
---@return boolean
function QueryResult:is_directory()
    return self.__data.kind == "directory"
end

--- Returns true if this is a file.
---@return boolean
function QueryResult:is_file()
    return self.__data.kind == "file"
end

--- Returns true if this path is missing.
---@return boolean
function QueryResult:is_missing()
    return self.__data.kind == "missing"
end

----------------------------------------------------------------
-- DIRECTORY ACCESS
----------------------------------------------------------------

--- Returns full file paths inside this directory.
--- Errors if not a directory.
---@return string[]
function QueryResult:files()
    assert(self:is_directory(), "[query] not a directory")
    return self.__data.files
end

--- Returns subdirectory paths.
---@return string[]
function QueryResult:dirs()
    assert(self:is_directory(), "[query] not a directory")
    return self.__data.dirs
end

--- Returns raw directory entry names.
---@return string[]
function QueryResult:entries()
    assert(self:is_directory(), "[query] not a directory")
    return self.__data.entries
end

----------------------------------------------------------------
-- FILE ACCESS
----------------------------------------------------------------

--- Returns file size in bytes.
---@return integer|nil
function QueryResult:size()
    assert(self:is_file(), "[query] not a file")
    return self.__data.size
end

--- Returns file hash.
---@return string|nil
function QueryResult:hash()
    assert(self:is_file(), "[query] not a file")
    return self.__data.hash
end

----------------------------------------------------------------
-- STRICT HELPERS
----------------------------------------------------------------

---@return QueryResult
function QueryResult:require_exists()
    assert(self:exists(), "[query] path does not exist: " .. self:path())
    return self
end

---@return QueryResult
function QueryResult:require_directory()
    assert(self:is_directory(), "[query] expected directory: " .. self:path())
    return self
end

---@return QueryResult
function QueryResult:require_file()
    assert(self:is_file(), "[query] expected file: " .. self:path())
    return self
end

----------------------------------------------------------------
-- RAW ENTRYPOINT
----------------------------------------------------------------

--- Returns raw structural query result.
--- Use this only for low-level tooling.
---@param path string
---@return table|nil, string|nil
function Controller.query_raw(path)
    Trace.contract_enter("io.query_raw")
    Trace.contract_in({ path = path })

    Contract.assert({ path = path }, Controller.CONTRACT.in_)

    Diagnostic.scope_enter("io.query_raw")

    local result, err = Pipeline.run(path)

    if not result then
        Diagnostic.user_message(err or "query failed", "error")
        Diagnostic.scope_leave()
        Trace.contract_leave()
        return nil, err
    end

    Contract.assert(result, Controller.CONTRACT.out)

    Diagnostic.scope_leave()
    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- FAÇADE ENTRYPOINT
----------------------------------------------------------------

--- Returns a QueryResult façade.
---@param path string
---@return QueryResult|nil, string|nil
function Controller.query(path)
    local raw, err = Controller.query_raw(path)
    if not raw then
        return nil, err
    end
    return QueryResult.new(raw)
end

----------------------------------------------------------------
-- STRICT FAÇADE
----------------------------------------------------------------

---@param path string
---@return QueryResult
function Controller.query_strict(path)
    local result, err = Controller.query(path)
    if not result then
        error(err, 2)
    end
    return result
end

return Controller
