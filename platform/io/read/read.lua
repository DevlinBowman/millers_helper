-- io/read.lua
--
-- Unified read entrypoint.
-- Dispatches to codecs based on file extension.
--
-- Contract:
--   • Codecs THROW on failure
--   • This module CATCHES and returns (nil, err)
--   • Successful reads return codec + result

local FS        = require("platform.io.helpers.fs")

local Text      = require("platform.io.codecs.text")
local Delimited = require("platform.io.codecs.delimited")
local Json      = require("platform.io.codecs.json")
local Lua       = require("platform.io.codecs.lua")


local Read = {}

----------------------------------------------------------------
-- Dispatch table (codecs THROW)
----------------------------------------------------------------

---@type table<string, fun(path:string):table>
local DISPATCH = {
    json = function(path)
        return Json.read(path)
    end,

    csv = function(path)
        return Delimited.read(path)
    end,

    tsv = function(path)
        return Delimited.read(path)
    end,

    txt = function(path)
        return Text.read(path)
    end,

    lua = function(path)
        return Lua.read(path)
    end,
}

----------------------------------------------------------------
-- Public API (boundary)
----------------------------------------------------------------

---@param path string
---@return { codec:string, data:any }|nil result
---@return string|nil err
function Read.read(path)
    assert(type(path) == "string", "path required")

    local ext = FS.get_extension(path)
    if not ext then
        return nil, "input file must have extension"
    end

    local reader = DISPATCH[ext:lower()]
    if not reader then
        return nil, "unsupported file type: " .. tostring(ext)
    end

    local ok, result = pcall(reader, path)
    if not ok then
        return nil, result
    end

    -- Defensive structural guarantee at boundary
    if type(result) ~= "table"
        or type(result.codec) ~= "string"
        or result.data == nil
    then
        return nil, "invalid codec result structure"
    end

    return result
end

return Read
