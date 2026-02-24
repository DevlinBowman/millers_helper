-- platform/io/query/internal/classify.lua
--
-- Pure classification logic.

local Classify = {}

function Classify.kind(fs, path)
    if fs.is_dir(path) then
        return "directory"
    end

    if fs.file_exists(path) then
        return "file"
    end

    return "missing"
end

return Classify
