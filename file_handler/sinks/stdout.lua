-- file_handler/sinks/stdout.lua

local StdoutSink = {}

function StdoutSink:write(line)
    print(line)
end

return StdoutSink
