-- io/write.lua
--
-- Unified write entrypoint.
-- Dispatches to codecs based on declared data kind.
--
-- Contract:
--   • Codecs THROW on failure
--   • This module CATCHES and returns (nil, err)
--   • Successful writes return metadata only

local FS = require("io.fs")

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

    FS.ensure_parent_dir(path)

    -- Codec boundary: catch throws
    local ok, thrown = pcall(writer, path, data, ext:lower())
    if not ok then
        return nil, thrown
    end

    ---@type IOWriteMeta
    return {
        path       = path,
        ext        = ext:lower(),
        size_bytes = FS.file_size(path),
        hash       = FS.file_hash(path),
        write_time = tostring(os.date("%Y-%m-%d %H:%M:%S")),
    }
end

return Write
