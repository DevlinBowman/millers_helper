local Helpers = {}

function Helpers.find_frame(frames, stage)
    for _, frame in ipairs(frames) do
        if frame.stage == stage then
            return frame
        end
    end
    return nil
end

return Helpers
