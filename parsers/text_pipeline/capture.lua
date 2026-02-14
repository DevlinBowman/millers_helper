-- parsers/text_pipeline/capture.lua
local Capture = {}

function Capture.new()
    return {
        enabled = true,
        lines = {},
    }
end

function Capture.record(cap, index, line)
    if not (cap and cap.enabled) then return end
    cap.lines[index] = line
end

return Capture
