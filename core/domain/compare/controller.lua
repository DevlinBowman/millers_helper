-- core/domain/compare/controller.lua
--
-- Boundary + contracts + tracing (arc-spec).

local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local Registry = require("core.domain.compare.registry")

local Pipelines = {
    build_model = require("core.domain.compare.pipelines.build_model"),
    format_text = require("core.domain.compare.pipelines.format_text"),
}

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {

    build_input = {
        in_ = {
            bundle        = true,
            vendor_boards = false,
            opts          = false,
        },
        out = {
            input = true,
        },
    },

    run = {
        in_ = {
            input = true,
        },
        out = {
            model = true,
        },
    },

    format_text = {
        in_ = {
            model = true,
            opts  = false,
        },
        out = {
            result = true,
        },
    },
}

----------------------------------------------------------------
-- Pricing Resolution (Boundary Rule)
----------------------------------------------------------------

local function resolve_bf_price(board)
    if type(board.bf_price) == "number" then
        return board.bf_price
    end

    if type(board.ea_price) == "number"
    and type(board.bf_ea) == "number"
    and board.bf_ea > 0 then
        return board.ea_price / board.bf_ea
    end

    if type(board.batch_price) == "number"
    and type(board.bf_batch) == "number"
    and board.bf_batch > 0 then
        return board.batch_price / board.bf_batch
    end

    return nil
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Controller.build_input(bundle, vendor_boards, opts)
    Trace.contract_enter("core.domain.compare.controller.build_input")
    Trace.contract_in(Controller.CONTRACT.build_input.in_)

    Contract.assert(
        { bundle = bundle, vendor_boards = vendor_boards, opts = opts },
        Controller.CONTRACT.build_input.in_
    )

    local input = Registry.input.from_bundle(bundle, vendor_boards, opts)

    local ok, err = Registry.shape.validate_input(input)
    if not ok then
        error("[compare.controller] invalid input: " .. tostring(err), 2)
    end

    local out = { input = input }

    Contract.assert(out, Controller.CONTRACT.build_input.out)
    Trace.contract_out(Controller.CONTRACT.build_input.out)
    Trace.contract_leave("core.domain.compare.controller.build_input")

    return out
end

----------------------------------------------------------------

function Controller.run(input)
    Trace.contract_enter("core.domain.compare.controller.run")
    Trace.contract_in(Controller.CONTRACT.run.in_)

    Contract.assert({ input = input }, Controller.CONTRACT.run.in_)

    local ok, err = Registry.shape.validate_input(input)
    if not ok then
        error("[compare.controller] invalid input: " .. tostring(err), 2)
    end

    ------------------------------------------------------------
    -- Business Rule: Compare requires order pricing
    ------------------------------------------------------------


    ------------------------------------------------------------

    local model = Pipelines.build_model.run(input)

    local out = { model = model }

    Contract.assert(out, Controller.CONTRACT.run.out)
    Trace.contract_out(Controller.CONTRACT.run.out)
    Trace.contract_leave("core.domain.comparea.controller.run")

    return out
end

----------------------------------------------------------------

function Controller.format_text(model, opts)
    Trace.contract_enter("core.domain.compare.controller.format_text")
    Trace.contract_in(Controller.CONTRACT.format_text.in_)

    Contract.assert({ model = model, opts = opts }, Controller.CONTRACT.format_text.in_)

    local ok, err = Registry.shape.validate_model(model)
    if not ok then
        error("[compare.controller] invalid model: " .. tostring(err), 2)
    end

    local formatted = Pipelines.format_text.run(model, opts)

    local out = { result = formatted }

    Contract.assert(out, Controller.CONTRACT.format_text.out)
    Trace.contract_out(Controller.CONTRACT.format_text.out)
    Trace.contract_leave("core.domain.compare.controller.format_text")

    return out
end

----------------------------------------------------------------

function Controller.compare(bundle, vendor_boards, opts)
    Trace.contract_enter("core.domain.compare.controller.compare")

    local input_res  = Controller.build_input(bundle, vendor_boards, opts)
    local model_res  = Controller.run(input_res.input)
    local format_res = Controller.format_text(model_res.model, opts)

    local out = {
        result = format_res.result,
        model  = model_res.model,
    }

    Trace.contract_leave("core.domain.compare.controller.compare")
    return out
end

----------------------------------------------------------------

return Controller
