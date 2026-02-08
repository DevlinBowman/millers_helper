-- file_handler/sinks/buffer.lua

local BufferSink = {}
BufferSink.__index = BufferSink

function BufferSink.new()
    return setmetatable({ lines = {} }, BufferSink)
end

function BufferSink:write(line)
    self.lines[#self.lines + 1] = line
end

return BufferSink
