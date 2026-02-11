-- io/write/write.lua
--
-- Pure IO write primitives.
-- NO format inference. NO shape inspection.

local FS    = require("io.helpers.fs")
local Text  = require("io.codecs.text")
local Json  = require("io.codecs.json")
local Lua   = require("io.codecs.lua")

local Write = {}

local function finalize(path)
    local size = FS.file_size(path)
    if not size or size <= 0 then
        return nil, "write completed but file is missing or empty"
    end

    return {
        path       = path,
        ext        = FS.get_extension(path):lower(),
        size_bytes = size,
        hash       = FS.file_hash(path),
        write_time = os.date("%Y-%m-%d %H:%M:%S"),
    }
end

function Write.raw(path, bytes)
    local fh, err = io.open(path, "w")
    if not fh then error(err) end
    fh:write(bytes)
    fh:close()
    return true
end

function Write.lines(path, lines)
    return Text.write(path, lines)
end

function Write.json(path, value)
    return Json.write(path, value)
end

function Write.write(path, payload)
    assert(type(path) == "string", "path required")
    assert(type(payload) == "table", "payload required")
    assert(payload.kind and payload.data ~= nil, "invalid payload")

    FS.ensure_parent_dir(path)

    local ok, err
    if payload.kind == "raw" then
        ok, err = pcall(Write.raw, path, payload.data)
    elseif payload.kind == "lines" then
        ok, err = pcall(Write.lines, path, payload.data)
    elseif payload.kind == "json" then
        ok, err = pcall(Write.json, path, payload.data)
    elseif payload.kind == "lua" then
        ok, err = pcall(Lua.write, path, payload.data)
    else
        return nil, "unsupported write payload kind: " .. payload.kind
    end

    if not ok then
        return nil, err
    end

    return finalize(path)
end

return Write
