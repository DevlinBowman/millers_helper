-- parsers/board_data/controller.lua
--
-- Public control surface for board_data domain.
-- PURPOSE:
--   • Define boundary
--   • Delegate to pipeline
--   • No internal requires
--   • No composition

local ParseLinePipeline = require("parsers.board_data.pipelines.parse_line")

local Controller = {}

---@param raw string
---@param opts table|nil
---@return table result
function Controller.parse_line(raw, opts)
    return ParseLinePipeline.run(raw, opts)
end

return Controller
