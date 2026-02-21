-- core/formula/nominal_map.lua

local NominalMap = {}

NominalMap.FACE = {
    [1]  = 0.75,
    [2]  = 1.5,
    [3]  = 2.5,
    [4]  = 3.5,
    [6]  = 5.5,
    [8]  = 7.25,
    [10] = 9.25,
    [12] = 11.25,
}

function NominalMap.resolve(size_in)
    return NominalMap.FACE[size_in] or size_in
end

function NominalMap.resolve_pair(base_h, base_w)
    return
        NominalMap.resolve(base_h),
        NominalMap.resolve(base_w)
end

return NominalMap
