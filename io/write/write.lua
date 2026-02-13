-- io/write/write.lua
--
-- Pure IO write primitives.
-- NO format inference. NO shape inspection.

local FS    = require("io.helpers.fs")
local Text  = require("io.codecs.text")
local Json  = require("io.codecs.json")
local Lua   = require("io.codecs.lua")

local Write = {}

----------------------------------------------------------------
-- Finalize metadata
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Raw helpers
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Public write boundary
----------------------------------------------------------------

---@param path string
---@param payload { codec:string, data:any }
---@return { path:string, ext:string, size_bytes:integer, hash:string, write_time:string }|nil
---@return string|nil err
function Write.write(path, payload)
    assert(type(path) == "string", "path must be string")
    assert(type(payload) == "table", "payload must be table")
    assert(type(payload.codec) == "string", "payload.codec must be string")
    assert(payload.data ~= nil, "payload.data required")

    local Resolve = require("io.write.resolve")

    ----------------------------------------------------------------
    -- Resolve expected codec from extension
    ----------------------------------------------------------------

    local spec, resolve_err = Resolve.codec(path)
    if not spec then
        return nil, resolve_err
    end

    ----------------------------------------------------------------
    -- Enforce codec ↔ extension consistency
    ----------------------------------------------------------------

    if payload.codec ~= spec.codec and payload.codec ~= "raw" then
        return nil,
            string.format(
                "codec mismatch: path expects '%s' but payload is '%s'",
                spec.codec,
                payload.codec
            )
    end

    ----------------------------------------------------------------
    -- Structural shape validation
    ----------------------------------------------------------------

    local function validate_shape(codec, data)
        if codec == "raw" then
            if type(data) ~= "string" then
                return nil, "raw codec requires string"
            end
            return true
        end

        if codec == "lines" then
            if type(data) ~= "table" then
                return nil, "lines codec requires string[]"
            end
            for i, v in ipairs(data) do
                if type(v) ~= "string" then
                    return nil, "lines[" .. i .. "] must be string"
                end
            end
            return true
        end

        if codec == "delimited" then
            if type(data) ~= "table"
                or type(data.header) ~= "table"
                or type(data.rows) ~= "table"
            then
                return nil,
                    "delimited codec requires { header=string[], rows=string[][] }"
            end
            return true
        end

        if codec == "json" then
            return true
        end

        if codec == "lua" then
            if type(data) ~= "table" then
                return nil, "lua codec requires table"
            end
            return true
        end

        return nil, "unsupported codec for validation: " .. tostring(codec)
    end

    local ok_shape, shape_err = validate_shape(payload.codec, payload.data)
    if not ok_shape then
        return nil, shape_err
    end

    ----------------------------------------------------------------
    -- Ensure directory exists
    ----------------------------------------------------------------

    FS.ensure_parent_dir(path)

    ----------------------------------------------------------------
    -- Dispatch
    ----------------------------------------------------------------

    local ok, err

    if payload.codec == "raw" then
        ok, err = pcall(Write.raw, path, payload.data)

    elseif payload.codec == "lines" then
        ok, err = pcall(Write.lines, path, payload.data)

    elseif payload.codec == "json" then
        ok, err = pcall(Write.json, path, payload.data)

    elseif payload.codec == "lua" then
        ok, err = pcall(Lua.write, path, payload.data)

    elseif payload.codec == "delimited" then
        local Delimited = require("io.codecs.delimited")
        ok, err = pcall(
            Delimited.write,
            path,
            payload.data,
            spec.opts
        )

    else
        return nil, "unsupported write payload codec: " .. payload.codec
    end

    if not ok then
        return nil, err
    end

    ----------------------------------------------------------------
    -- Finalize metadata
    ----------------------------------------------------------------

    return finalize(path)
end

return Write
