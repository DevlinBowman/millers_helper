-- classify/init.lua
--
-- Public API for the standalone classifier.

local Run = require("classify.run")

local Classify = {}

--- Classify one decoded object (row).
function Classify.row(row)
    return Run.row(row)
end

return Classify
