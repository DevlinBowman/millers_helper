-- io/validate/input.lua

local FS = require("platform.io.helpers.fs")

local Validate = {}

function Validate.read(input)
    if type(input) ~= "table" then
        return nil, "input must be table"
    end

    if input.mode ~= "read" then
        return nil, "invalid mode for read"
    end

    local src = input.source
    if not src or src.kind ~= "path" then
        return nil, "read requires path source"
    end

    if type(src.value) ~= "string" then
        return nil, "path must be string"
    end

    if FS.is_dir(src.value) then
        return true
    end

    if not FS.get_extension(src.value) then
        return nil, "path must have extension"
    end

    if not FS.file_exists(src.value) then
        return nil, "file does not exist"
    end

    return true
end

function Validate.write(input)
    if type(input) ~= "table" then
        return nil, "input must be table"
    end

    if input.mode ~= "write" then
        return nil, "invalid mode for write"
    end

    local src = input.source
    if not src or src.kind ~= "path" then
        return nil, "write requires path source"
    end

    if not FS.get_extension(src.value) then
        return nil, "output path must have extension"
    end

    local data = input.data
    if data == nil then
        return nil, "write requires data"
    end

    return true
end

return Validate
