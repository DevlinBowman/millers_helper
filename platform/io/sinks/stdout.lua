-- io/sinks/stdout.lua
--
-- Sink that writes lines to stdout.
-- Stateless. No buffering. No close operation.

---@class StdoutSink
local StdoutSink = {}

--- Write a single line to stdout.
--- Newline handling is delegated to print().
---
---@param line any
---@return nil
function StdoutSink:write(line)
    print(line)
end

return StdoutSink
