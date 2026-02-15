-- core/model/board/controller.lua

local Contract = require("core.contract")
local Trace    = require("tools.trace")

local BuildPipeline = require("core.model.board.pipelines.build")
local Registry      = require("core.model.board.registry")

local Controller = {}

Controller.CONTRACT = {
    build = {
        in_  = { spec = true },
        out  = { board = true, unknown = true },
    },
    label_generate = {
        in_  = { spec = true },
        out  = { label = true },
    },
    label_hydrate = {
        in_  = { label = true },
        out  = { spec = true },
    },
}

function Controller.build(spec)
    Trace.contract_enter("core.model.board.controller.build")
    Trace.contract_in(Controller.CONTRACT.build.in_)

    assert(type(spec) == "table", "Board.controller.build(): spec table required")
    Contract.assert({ spec = spec }, Controller.CONTRACT.build.in_)

    local result = BuildPipeline.run(spec)

    Contract.assert(result, Controller.CONTRACT.build.out)
    Trace.contract_out(Controller.CONTRACT.build.out)

    return result
end

function Controller.label_generate(spec)
    Trace.contract_enter("core.model.board.controller.label_generate")
    Trace.contract_in(Controller.CONTRACT.label_generate.in_)

    assert(type(spec) == "table", "Board.controller.label_generate(): spec table required")
    Contract.assert({ spec = spec }, Controller.CONTRACT.label_generate.in_)

    local label = Registry.label.generate(spec)

    Contract.assert({ label = label }, Controller.CONTRACT.label_generate.out)
    Trace.contract_out(Controller.CONTRACT.label_generate.out)

    return label
end

function Controller.label_hydrate(label)
    Trace.contract_enter("core.model.board.controller.label_hydrate")
    Trace.contract_in(Controller.CONTRACT.label_hydrate.in_)

    assert(type(label) == "string", "Board.controller.label_hydrate(): label string required")
    Contract.assert({ label = label }, Controller.CONTRACT.label_hydrate.in_)

    local spec = Registry.label.hydrate(label)

    Contract.assert({ spec = spec }, Controller.CONTRACT.label_hydrate.out)
    Trace.contract_out(Controller.CONTRACT.label_hydrate.out)

    return spec
end

return Controller
