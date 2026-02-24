-- platform/io/query/internal/enumerate.lua
--
-- Deterministic enumeration logic.

local Enumerate = {}

function Enumerate.directory(fs, path)
    local entries, err = fs.list_entries(path)
    if not entries then
        return nil, err
    end

    table.sort(entries)

    local files = {}
    local dirs  = {}

    for _, name in ipairs(entries) do
        local full = fs.join(path, name)

        if fs.is_dir(full) then
            dirs[#dirs + 1] = full
        elseif fs.file_exists(full) then
            files[#files + 1] = full
        end
    end

    table.sort(files)
    table.sort(dirs)

    return {
        entries = entries,
        files   = files,
        dirs    = dirs,
    }
end

return Enumerate
