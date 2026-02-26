local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local Registry = require("core.domain.compare.registry")
local Result   = require("core.domain.compare.result")

local BuildModelPipe = require("core.domain.compare.pipelines.build_model")

local Controller = {}

----------------------------------------------------------------
-- CONTRACTS
----------------------------------------------------------------

Controller.CONTRACT = {

    run_raw = {
        in_ = {
            user_batch     = true,
            vendor_batches = true,
            opts           = false,
        },
        out = { model = true },
    },

    run = {
        in_ = {
            user_batch     = true,
            vendor_batches = true,
            opts           = false,
        },
        out = { result = true },
    },
}

----------------------------------------------------------------
-- RAW
----------------------------------------------------------------

function Controller.run_raw(user_batch, vendor_batches, opts)
    Trace.contract_enter("core.domain.compare.controller.run_raw")
    Trace.contract_in(Controller.CONTRACT.run_raw.in_)

    Contract.assert(
        {
            user_batch     = user_batch,
            vendor_batches = vendor_batches,
            opts           = opts,
        },
        Controller.CONTRACT.run_raw.in_
    )

    local input = Registry.input.from_batches(
        user_batch,
        vendor_batches,
        opts
    )

    local ok, err = Registry.shape.validate_input(input)
    if not ok then
        Trace.contract_leave()
        return nil, err
    end

    local model = BuildModelPipe.run(input)

    Contract.assert({ model = model }, Controller.CONTRACT.run_raw.out)

    Trace.contract_out(Controller.CONTRACT.run_raw.out)
    Trace.contract_leave()

    return model
end

----------------------------------------------------------------
-- FACADE
----------------------------------------------------------------

function Controller.run(user_batch, vendor_batches, opts)
    Trace.contract_enter("core.domain.compare.controller.run")
    Trace.contract_in(Controller.CONTRACT.run.in_)

    Contract.assert(
        {
            user_batch     = user_batch,
            vendor_batches = vendor_batches,
            opts           = opts,
        },
        Controller.CONTRACT.run.in_
    )

    local model, err = Controller.run_raw(
        user_batch,
        vendor_batches,
        opts
    )

    if not model then
        Trace.contract_leave()
        return nil, err
    end

    local result = Result.new(model)

    Contract.assert({ result = result }, Controller.CONTRACT.run.out)

    Trace.contract_out(Controller.CONTRACT.run.out)
    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- STRICT
----------------------------------------------------------------

function Controller.run_strict(user_batch, vendor_batches, opts)
    local result, err = Controller.run(
        user_batch,
        vendor_batches,
        opts
    )
    if not result then
        error(err, 2)
    end
    return result:require_valid()
end

return Controller
