-- tools/struct/runtime.lua

local Printer = require("tools.struct._printer")

local M = {}

----------------------------------------------------------------
-- Runtime Targets
----------------------------------------------------------------

local TARGETS = {
    ingest = function(path)
        local Ingest = require("platform.pipelines.ingestion.ingest")

        local result = Ingest.read(path)

        return result
    end,
}

----------------------------------------------------------------
-- Shape Extractor
----------------------------------------------------------------

local function sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function describe(value)
    local t = type(value)

    if t ~= "table" then
        return t
    end

    if #value > 0 then
        return "table[]"
    end

    return "table{}"
end

local function build_shape(tbl)
    if type(tbl) ~= "table" then
        return describe(tbl)
    end

    local out = {}

    for _, key in ipairs(sorted_keys(tbl)) do
        out[key] = build_shape(tbl[key])
    end

    return out
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function M.list()
    local keys = {}
    for k in pairs(TARGETS) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

function M.print(key, path)
    local fn = TARGETS[key]
    if not fn then
        print("unknown runtime target:", key)
        return
    end

    if not path then
        print("runtime target requires path argument")
        return
    end

    local result = fn(path)

    local shape = build_shape(result)

    Printer.print("RUNTIME: " .. key, shape)
end

return M
