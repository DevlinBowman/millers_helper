-- parsers/pipelines/board_line.lua
--
-- Pipeline: single board line parse
--
-- Responsibilities:
--   • Delegate to board_data submodule controller
--   • Provide domain boundary adapter
--
-- Forbidden:
--   • Contracts
--   • Trace
--   • Validation
--   • Cross-module orchestration

local BoardLineController =
    require("platform.parsers.board_data.controller")

local BoardLinePipeline = {}

---@param raw string
---@param opts table|nil
---@return table result
function BoardLinePipeline.run(raw, opts)
    return BoardLineController.parse_line(raw, opts)
end

return BoardLinePipeline
