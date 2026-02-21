-- io/sinks/file.lua
--
-- Sink that writes lines to a file.
-- Owns the file handle lifecycle.

---@class FileSink
---@field fh file*   -- open file handle
local FileSink = {}
FileSink.__index = FileSink

--- Create a new file sink.
--- Opens file immediately and truncates existing contents.
---
---@param path string
---@return FileSink
function FileSink.new(path)
    local fh, err = io.open(path, "w")
    if not fh then
        error(err)
    end

    return setmetatable({ fh = fh }, FileSink)
end

--- Write a single line to the file.
--- Always appends a newline.
---
---@param line any
---@return nil
function FileSink:write(line)
    self.fh:write(tostring(line), "\n")
end

--- Close the underlying file handle.
--- Must be called by owner when finished.
---
---@return nil
function FileSink:close()
    self.fh:close()
end

return FileSink
