-- platform/io/query/internal/enumerate.lua
--
-- Deterministic enumeration logic.

local Enumerate = {}

-- file: platform/io/query/internal/enumerate.lua
-- function: Enumerate.directory

local function should_ignore(name)
    if name:sub(1, 1) == "." then
        return true
    end

    if name == "Thumbs.db" then
        return true
    end

    return false
end

function Enumerate.directory(fs, path)
    local entries, err = fs.list_entries(path)
    if not entries then
        return nil, err
    end

    table.sort(entries)

    local filtered = {}
    local files = {}
    local dirs  = {}

    for _, name in ipairs(entries) do
        if not should_ignore(name) then
            filtered[#filtered + 1] = name

            local full = fs.join(path, name)

            if fs.is_dir(full) then
                dirs[#dirs + 1] = full
            elseif fs.file_exists(full) then
                files[#files + 1] = full
            end
        end
    end

    table.sort(files)
    table.sort(dirs)

    return {
        entries = filtered,
        files   = files,
        dirs    = dirs,
    }
end

return Enumerate
