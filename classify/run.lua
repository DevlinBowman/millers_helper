-- classify/run.lua
--
-- Orchestrator for classification system.

local Partition = require("classify.partition")

local Run = {}

--- Classify a decoded row.
--- @param row table
--- @return table { board, order, unknown, meta }
function Run.row(row)
    return Partition.run(row)
end

return Run
