-- parsers/pipelines/text_engine/controller.lua
--
-- Public control surface for text_engine.
-- PURPOSE:
--   • Define boundary + contract
--   • Delegate to pipeline
--   • No internal requires

local Pipeline = require("parsers.pipelines.text_engine.pipeline")

local Controller = {}

Controller.CONTRACT = {
    run = {
        in_ = {
            lines = "string|table", -- string | string[] | record[]
            opts  = "table|nil",
        },
        out = {
            kind = "string",
            data = "table",
            meta = "table",
        },
    },
}

---@param lines string|table
---@param opts table|nil
---@return table result
function Controller.run(lines, opts)
    -- Contract enforcement can plug into your core.contract here.
    -- Keeping it minimal since you didn’t include core.contract in this snippet.
    return Pipeline.run(lines, opts)
end

return Controller
