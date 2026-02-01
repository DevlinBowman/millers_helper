-- tools/inspection/helpers.lua
local Helpers = {}

function Helpers.find_frame(frames, stage)
    for _, frame in ipairs(frames or {}) do
        if frame.stage == stage then
            return frame
        end
    end
    return nil
end

return Helpers
