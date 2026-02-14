-- io/write/resolve.lua
--
-- Resolves write codec from output path extension only.

local FS = require('io.helpers.fs')

local Resolve = {}

function Resolve.codec(path)
    local ext = FS.get_extension(path)
    if not ext then
        return nil, "output path must have extension"
    end

    ext = ext:lower()

    if ext == "csv" then
        return { codec = "delimited", opts = { sep = "," } }
    end

    if ext == "tsv" then
        return { codec = "delimited", opts = { sep = "\t" } }
    end

    if ext == "txt" then
        return { codec = "lines" }
    end

    if ext == "json" then
        return { codec = "json" }
    end

    if ext == "lua" then
        return { codec = "lua" }
    end

    return nil, "unsupported output extension: " .. ext
end

return Resolve
