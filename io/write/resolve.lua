-- io/write/resolve.lua
--
-- Resolves write kind from output path extension only.

local FS = require("io.helpers.fs")

local Resolve = {}

function Resolve.kind(path)
    local ext = FS.get_extension(path)
    if not ext then
        return nil, "output path must have extension"
    end

    ext = ext:lower()

    if ext == "csv" or ext == "tsv" then
        return "table"
    end

    if ext == "txt" then
        return "lines"
    end

    if ext == "json" then
        return "json"
    end

    if ext == "lua" then
        return "lua"
    end

    return nil, "unsupported output extension: " .. ext
end

return Resolve
