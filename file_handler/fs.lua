-- file_handler/fs.lua
local FS = {}

function FS.get_extension(path)
    return path:match("^.+%.([^/\\]+)$")
end

function FS.get_filename(path)
    return path:match("([^/\\]+)$")
end

function FS.file_exists(path)
    local ok = os.rename(path, path)
    if not ok then return false end
    local ok_dir = os.rename(path .. "/.", path .. "/.")
    return not ok_dir
end

function FS.ensure_parent_dir(path)
    local dir = path:match("^(.*)[/\\]")
    if dir then
        os.execute(string.format("mkdir -p %q", dir))
    end
end

function FS.file_size(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local size = fh:seek("end")
    fh:close()
    return size
end

-- simple, stable hash (FNV-1a, 32-bit)
function FS.file_hash(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end

    local hash = 2166136261
    for byte in fh:read("*a"):gmatch(".") do
        hash = hash ~ byte:byte()
        hash = (hash * 16777619) % 2^32
    end
    fh:close()

    return string.format("%08x", hash)
end

return FS
