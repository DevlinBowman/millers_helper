-- core/formula/volume.lua
--
-- Pure board volume math (board feet)

local Volume = {}

function Volume.bf(height_in, width_in, length_ft)
    return (height_in * width_in * length_ft) / 12
end

function Volume.bf_per_lf(height_in, width_in)
    return (height_in * width_in) / 12
end

function Volume.batch_bf(height_in, width_in, length_ft, count)
    return Volume.bf(height_in, width_in, length_ft) * (count or 1)
end

return Volume
