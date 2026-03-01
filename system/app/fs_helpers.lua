-- file: system/app/fs_helpers.lua
--
-- App-level filesystem helpers.
-- Provides common path composition utilities so callers do not reach platform.io directly.
--
-- Accepts either:
--   • string absolute/relative paths
--   • AppFSResult (system/infrastructure/app_fs/result.lua)
--
-- Returns strings (paths). It does NOT return AppFSResult.

local IORegistry = require("platform.io.registry")
local FS = IORegistry.fs

---@class AppFSHelpers
local Helpers = {}
Helpers.__index = Helpers

---@return AppFSHelpers
function Helpers.new()
    return setmetatable({}, Helpers)
end

----------------------------------------------------------------
-- Internal
----------------------------------------------------------------

---@private
---@param base any
---@return string
local function coerce_path(base)
    if type(base) == "string" then
        return base
    end

    if type(base) == "table" and type(base.path) == "function" then
        return base:path()
    end

    error("[fs.helpers] expected string path or AppFSResult", 3)
end

---@private
---@param name any
---@return string
local function assert_filename(name)
    assert(type(name) == "string" and #name > 0, "[fs.helpers] filename required")
    -- minimal safety: disallow path traversal in a "filename"
    assert(not name:find("[/\\]"), "[fs.helpers] filename must not contain path separators: " .. name)
    return name
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---Join a base path (string or AppFSResult) with one or more segments.
---@param base any
---@param ... string
---@return string
function Helpers:join(base, ...)
    local out = coerce_path(base)

    local parts = { ... }
    for i = 1, #parts do
        local part = parts[i]
        assert(type(part) == "string" and #part > 0, "[fs.helpers] join segment required")
        out = FS.join(out, part)
    end

    return out
end

---Return child file path under base directory using a filename.
---@param base any
---@param filename string
---@return string
function Helpers:child(base, filename)
    local base_path = coerce_path(base)
    local safe = assert_filename(filename)
    return FS.join(base_path, safe)
end

---Return filename extension (without dot), or nil if none.
---@param filename string
---@return string|nil
function Helpers:ext(filename)
    assert(type(filename) == "string", "[fs.helpers] filename must be string")
    local ext = filename:match("%.([^%.]+)$")
    return ext
end

---Return filename without extension.
---@param filename string
---@return string
function Helpers:stem(filename)
    assert(type(filename) == "string", "[fs.helpers] filename must be string")
    return (filename:gsub("%.[^%.]+$", ""))
end

---Return true if a path exists (string or AppFSResult).
---@param path any
---@return boolean
function Helpers:exists(path)
    local p = coerce_path(path)
    return FS.file_exists(p) or FS.is_dir(p)
end

return Helpers
