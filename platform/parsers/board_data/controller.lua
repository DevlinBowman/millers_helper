-- parsers/board_data/controller.lua
--
-- Public boundary for board_data domain.

local ParseLinePipeline =
    require("platform.parsers.board_data.pipelines.parse_line")

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local Controller = {}

Controller.CONTRACT = {
    parse_line = {
        in_ = {
            raw  = true,
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

    Trace.contract_enter("parsers.board_data.controller.parse_line")
    Trace.contract_in(Controller.CONTRACT.parse_line.in_)

    Contract.assert(
        { raw = raw, opts = opts },
        Controller.CONTRACT.parse_line.in_
    )

    local ok, result = pcall(function()
        return ParseLinePipeline.run(raw, opts)
    end)

    if not ok then
        Trace.contract_leave()
        error(result, 2)
    end

    Contract.assert(result, Controller.CONTRACT.parse_line.out)

    Trace.contract_out(
        Controller.CONTRACT.parse_line.out,
        "parsers.board_data",
        "caller"
    )

    Trace.contract_leave()

    return result
end

return Controller
