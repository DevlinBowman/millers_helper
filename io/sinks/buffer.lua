-- io/sinks/buffer.lua
--
-- In-memory sink for capturing output.
-- Useful for tests and programmatic inspection.

---@class BufferSink
---@field lines string[]   -- collected output lines
local BufferSink = {}
BufferSink.__index = BufferSink

--- Create a new buffer sink.
---
---@return BufferSink
function BufferSink.new()
    return setmetatable({ lines = {} }, BufferSink)
end

--- Append a line to the buffer.
--- Does NOT coerce to string automatically.
---
---@param line any
---@return nil
function BufferSink:write(line)
    self.lines[#self.lines + 1] = line
end

return BufferSink
