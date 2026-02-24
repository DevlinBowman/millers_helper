local QueryRegistry = require("platform.io.query.registry")
local IORegistry    = require("platform.io.registry")

local Inspect = {}

function Inspect.run(path)
    local fs = IORegistry.fs

    local kind = QueryRegistry.classify.kind(fs, path)

    if kind == "directory" then
        local data, err = QueryRegistry.enumerate.directory(fs, path)
        if not data then
            return nil, err
        end

        return {
            path    = path,
            exists  = true,
            kind    = "directory",
            entries = data.entries,
            files   = data.files,
            dirs    = data.dirs,
        }
    end

    if kind == "file" then
        return {
            path   = path,
            exists = true,
            kind   = "file",
            size   = fs.file_size(path),
            hash   = fs.file_hash(path),
        }
    end

    return {
        path   = path,
        exists = false,
        kind   = "missing",
    }
end

return Inspect
