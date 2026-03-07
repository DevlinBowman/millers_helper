-- core/formula/board/internal/nominal_map.lua
--
-- Board Nominal Dimension Map
--
-- Resolve declared board dimensions into nominal dressed dimensions.

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

------------------------------------------------
-- single dimension
------------------------------------------------

---Resolve one declared dimension through the nominal face map.
---
---@param size number
---@return number
function NominalMap.resolve(size)
    return NominalMap.FACE[size] or size
end

------------------------------------------------
-- pair
------------------------------------------------

---Resolve declared dimension pair through the nominal face map.
---
---@param base_h number
---@param base_w number
---@return number nominal_h
---@return number nominal_w
function NominalMap.resolve_pair(base_h, base_w)
    return NominalMap.resolve(base_h), NominalMap.resolve(base_w)
end

return NominalMap
