-- tools/inspection/capture.lua
local Capture = {}

function Capture.new(opts)
    return {
        enabled = true,
        opts = opts or {},
        frames = {},   -- ordered snapshots
    }
end

function Capture.record(cap, stage, payload)
    if not (cap and cap.enabled) then return end

    cap.frames[#cap.frames + 1] = {
        stage   = stage,
        payload = payload,
    }
end

return Capture
