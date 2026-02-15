-- parsers/controller.lua
--
-- Public control surface for parsers domain.
--
-- Boundary responsibilities only:
--   • Define contracts
--   • Delegate to pipelines
--   • No internal requires
--   • No composition logic

local TextPipeline      = require("parsers.pipelines.text")
local BoardLinePipeline = require("parsers.pipelines.board_line")

local Controller = {}

----------------------------------------------------------------
-- Parse freeform text → canonical records
----------------------------------------------------------------

---@param lines string[]
---@param opts table|nil
---@return table result -- { data, meta, diagnostic }
function Controller.parse_text(lines, opts)
    return TextPipeline.run(lines, opts)
end

----------------------------------------------------------------
-- Parse single board line (semantic only)
----------------------------------------------------------------

---@param raw string
---@param opts table|nil
---@return table result
function Controller.parse_board_line(raw, opts)
    return BoardLinePipeline.run(raw, opts)
end

return Controller
