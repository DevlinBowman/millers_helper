-- core/domain/invoice/controller.lua

local Trace    = require("tools.trace.trace")
local Pipeline = require("core.domain.invoice.pipelines.build")
local Registry = require("core.domain.invoice.registry")
local Schema   = require("core.domain.invoice.internal.schema")

local Controller = {}

Controller.contract = Schema.contract

----------------------------------------------------------------
-- BUILD ENTRY
----------------------------------------------------------------

function Controller.build(input, opts)
    Trace.contract_enter("core.domain.invoice.controller.build")

    opts = opts or {}

    local sig = Schema.new_signals()

    -- INPUT CONTRACT
    Schema.validate_input(input, sig)

    if Schema.has_errors(sig) then
        Trace.contract_leave()
        return Schema.empty_model(sig)
    end

    -- PIPELINE EXECUTION
    local model = Pipeline.run(input, sig)

    model.kind    = "invoice_model"
    model.signals = sig

    -- OUTPUT CONTRACT
    if opts.enforce_output ~= false then
        Schema.validate_model(model, sig)
    end

    Trace.contract_leave()

    return model
end

----------------------------------------------------------------
-- FROM CAPTURE ENTRY
----------------------------------------------------------------

function Controller.from_capture(capture, source_id, opts)
    Trace.contract_enter("core.domain.invoice.controller.from_capture")

    local input = Registry.capabilities.input.build(capture, source_id)
    local result = Controller.build(input, opts)

    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- FORMAT TEXT ENTRY
----------------------------------------------------------------

function Controller.render_text(model)
    Trace.contract_enter("core.domain.invoice.controller.render_text")

    local sig = model and model.signals or Schema.new_signals()

    if not model or model.kind ~= "invoice_model" then
        Trace.contract_leave()
        return {
            kind  = "text",
            lines = { "Invalid invoice model." },
        }
    end

    -- Enforce output contract before formatting
    Schema.validate_model(model, sig)

    local renderer = Registry.capabilities.format.text
    local rendered = renderer.render(model)

    Trace.contract_leave()

    return rendered
end

return Controller
