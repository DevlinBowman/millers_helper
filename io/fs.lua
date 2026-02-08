-- io/fs.lua
--
-- Filesystem helpers.
-- Thin, synchronous wrappers around Lua + OS primitives.
--
-- This module:
--   • Does NOT throw (returns nil/false on failure)
--   • Does NOT normalize paths
--   • Assumes POSIX semantics where noted

local FS = {}

----------------------------------------------------------------
-- Type notes
----------------------------------------------------------------
-- path        : string (filesystem path)
-- extension   : string|nil
-- filename    : string|nil
-- size_bytes  : integer|nil
-- hash        : string|nil   -- 8-char hex (FNV-1a, 32-bit)

----------------------------------------------------------------
-- Path helpers
----------------------------------------------------------------

--- Extract file extension (without dot).
--- Returns nil if no extension is present.
---
---@param path string
---@return string|nil ext
function FS.get_extension(path)
    return path:match("^.+%.([^/\\]+)$")
end

--- Extract filename from a path.
---
---@param path string
---@return string|nil filename
function FS.get_filename(path)
    return path:match("([^/\\]+)$")
end

----------------------------------------------------------------
-- Existence / directory helpers
----------------------------------------------------------------

--- Check whether a file exists and is not a directory.
---
--- Uses os.rename semantics:
---   • Works for files
---   • Returns false for directories
---
---@param path string
---@return boolean exists
function FS.file_exists(path)
    local ok = os.rename(path, path)
    if not ok then
        return false
    end

    -- directories succeed on rename(path, path) but fail on "/."
    local ok_dir = os.rename(path .. "/.", path .. "/.")
    return not ok_dir
end

--- Ensure parent directory exists (mkdir -p).
--- No-op if path has no directory component.
---
---@param path string
---@return nil
function FS.ensure_parent_dir(path)
    local dir = path:match("^(.*)[/\\]")
    if dir then
        -- POSIX-dependent; acceptable per project assumptions
        os.execute(string.format("mkdir -p %q", dir))
    end
end

----------------------------------------------------------------
-- File metadata
----------------------------------------------------------------

--- Get file size in bytes.
---
---@param path string
---@return integer|nil size_bytes
function FS.file_size(path)
    local fh = io.open(path, "rb")
    if not fh then
        return nil
    end

    local size = fh:seek("end")
    fh:close()
    return size
end

--- Compute a stable file hash (FNV-1a, 32-bit).
--- Intended for change detection, not cryptographic use.
---
---@param path string
---@return string|nil hash   -- lowercase hex (8 chars)
function FS.file_hash(path)
    local fh = io.open(path, "rb")
    if not fh then
        return nil
    end

    local hash = 2166136261

    for byte in fh:read("*a"):gmatch(".") do
        hash = hash ~ byte:byte()
        hash = (hash * 16777619) % 2^32
    end

    fh:close()
    return string.format("%08x", hash)
end

return FS
