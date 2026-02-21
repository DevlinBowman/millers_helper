-- parsers/controller.lua

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local TextPipeline      = require("platform.parsers.pipelines.text")
local BoardLinePipeline = require("platform.parsers.pipelines.board_line")

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {
    parse_text = {
        in_  = { lines = true, opts = false },
        out  = { data = true, meta = true, diagnostic = true },
    },
    parse_board_line = {
        in_  = { raw = true, opts = false },
        out  = { data = true },
    },
}

----------------------------------------------------------------
-- Parse freeform text → canonical records
----------------------------------------------------------------

function Controller.parse_text(lines, opts)

    Trace.contract_enter("parsers.controller.parse_text")
    Trace.contract_in(Controller.CONTRACT.parse_text.in_)

    local function run()
        Contract.assert(
            { lines = lines, opts = opts },
            Controller.CONTRACT.parse_text.in_
        )

        local result = TextPipeline.run(lines, opts)

        Contract.assert(result, Controller.CONTRACT.parse_text.out)
        Trace.contract_out(Controller.CONTRACT.parse_text.out)

        return result
    end

    local ok, result = pcall(run)

    Trace.contract_leave()

    if not ok then
        error(result, 0)
    end

    return result
end

----------------------------------------------------------------
-- Parse single board line
----------------------------------------------------------------

function Controller.parse_board_line(raw, opts)

    Trace.contract_enter("parsers.controller.parse_board_line")
    Trace.contract_in(Controller.CONTRACT.parse_board_line.in_)

    local function run()
        Contract.assert(
            { raw = raw, opts = opts },
            Controller.CONTRACT.parse_board_line.in_
        )

        local result = BoardLinePipeline.run(raw, opts)

        Contract.assert(result, Controller.CONTRACT.parse_board_line.out)
        Trace.contract_out(Controller.CONTRACT.parse_board_line.out)

        return result
    end

    local ok, result = pcall(run)

    Trace.contract_leave()

    if not ok then
        error(result, 0)
    end

    return result
end

return Controller
