-- file_handler/sinks/file.lua

local FileSink = {}
FileSink.__index = FileSink

function FileSink.new(path)
    local fh, err = io.open(path, "w")
    if not fh then error(err) end

    return setmetatable({ fh = fh }, FileSink)
end

function FileSink:write(line)
    self.fh:write(tostring(line), "\n")
end

function FileSink:close()
    self.fh:close()
end

return FileSink
