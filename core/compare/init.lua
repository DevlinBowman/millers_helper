-- core/compare/index.lua

local Input  = require("core.compare.input")   -- later
local Model  = require("core.compare.model")

local Compare = {}

--- @param input table  -- validated compare input contract
--- @return table model -- ComparisonModel
function Compare.run(input)
    return Model.build(input)
end

return Compare
