-- io/write.lua
--
-- Unified write entrypoint.
-- Dispatches to codecs based on declared data kind.
--
-- Contract:
--   • Codecs THROW on failure
--   • This module CATCHES and returns (nil, err)
--   • Successful writes return metadata only

local FS = require("io.helpers.fs")

local Text      = require("io.codecs.text")
local Delimited = require("io.codecs.delimited")
local Json      = require("io.codecs.json")

local Write = {}

----------------------------------------------------------------
-- Dispatch table (codecs THROW)
----------------------------------------------------------------

---@type table<IOWriteKind, fun(path:string, data:any, ext:string|nil):true>
local DISPATCH = {
    lines = function(path, data)
        return Text.write(path, data)
    end,

    table = function(path, data, ext)
        local sep = (ext == "tsv") and "\t" or ","
        return Delimited.write(path, data, { sep = sep })
    end,

    json = function(path, data)
        return Json.write(path, data)
    end,
}

----------------------------------------------------------------
-- Public API (boundary)
----------------------------------------------------------------

--- Write structured data to disk.
--- Converts codec errors into (nil, err).
---
---@param path string
---@param kind IOWriteKind
---@param data any
---@return IOWriteMeta|nil
---@return string|nil err
function Write.write(path, kind, data)
    assert(type(path) == "string", "path required")
    assert(type(kind) == "string", "kind required")

    local ext = FS.get_extension(path)
    if not ext then
        return nil, "output file must have extension"
    end

    local writer = DISPATCH[kind]
    if not writer then
        return nil, "unsupported write kind: " .. tostring(kind)
    end

    local ok_dir, dir_err = pcall(FS.ensure_parent_dir, path)
    if not ok_dir then
        return nil, "failed to ensure output directory: " .. tostring(dir_err)
    end

    local ok, result_or_err = pcall(writer, path, data, ext:lower())
    if not ok then
        return nil, result_or_err
    end

    if result_or_err ~= true then
        return nil, "writer did not signal success (returned " .. tostring(result_or_err) .. ")"
    end

    local size = FS.file_size(path)
    if not size or size <= 0 then
        return nil, "write completed but file is missing or empty"
    end

    return {
        path       = path,
        ext        = ext:lower(),
        size_bytes = size,
        hash       = FS.file_hash(path),
        write_time = os.date("%Y-%m-%d %H:%M:%S"),
    }
end

return Write
