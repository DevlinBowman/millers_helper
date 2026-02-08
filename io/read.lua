-- io/read.lua
--
-- Unified read entrypoint.
-- Dispatches to codecs based on file extension.
--
-- Contract:
--   • Codecs THROW on failure
--   • This module CATCHES and returns (nil, err)
--   • Successful reads return codec result + metadata

local FS = require("io.fs")

local Text      = require("io.codecs.text")
local Delimited = require("io.codecs.delimited")
local Json      = require("io.codecs.json")

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
}

----------------------------------------------------------------
-- Public API (boundary)
----------------------------------------------------------------

---@param path string
---@return table|nil result
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

    return result
end

return Read
