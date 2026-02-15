-- parsers/board_data/controller.lua

local ParseLinePipeline =
    require("parsers.board_data.pipelines.parse_line")

local Controller = {}

Controller.CONTRACT = {
    parse_line = {
        in_ = {
            raw = true,
            opts = false,
        },
        out = {
            tokens   = true,
            chunks   = true,
            claims   = true,
            resolved = true,
            picked   = true,
        }
    }
}

---@param raw string
---@param opts table|nil
---@return table result
function Controller.parse_line(raw, opts)
    assert(type(raw) == "string", "Controller.parse_line(): raw string required")
    opts = opts or {}

    return ParseLinePipeline.run(raw, opts)
end

return Controller
