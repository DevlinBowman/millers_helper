-- parsers/controller.lua
--
-- Public control surface for parsers domain.
-- PURPOSE:
--   • Provide stable orchestration entrypoints
--   • Delegate to appropriate subdomain
--   • Never expose internal layering details

local RawText      = require("parsers.raw_text.preprocess")
local TextPipeline = require("parsers.pipeline")
local BoardData    = require("parsers.board_data")

local Controller = {}

----------------------------------------------------------------
-- Parse freeform text → canonical records
----------------------------------------------------------------

---@param lines string[]
---@param opts table|nil
---@return table result -- { kind="records", data=..., meta=..., diagnostic? }
function Controller.parse_text(lines, opts)
    return TextPipeline.run(lines, opts)
end

----------------------------------------------------------------
-- Parse single board line directly (semantic only)
----------------------------------------------------------------

---@param raw string
---@param opts table|nil
---@return table result
function Controller.parse_board_line(raw, opts)
    return BoardData.controller.parse_line(raw, opts)
end

return Controller
