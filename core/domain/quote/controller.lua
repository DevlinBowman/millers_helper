local Registry = require("core.domain.quote.registry")
local Format   = require("core.domain._priced_doc.internal.format_text")
local Signals  = require("core.signal")

local Controller = {}

function Controller.run(boards)
    local sig = Signals.list()

    Registry.schema.validate_input(boards, sig)

    if Signals.has_errors(sig) then
        return { signals = sig }
    end

    local model = Registry.pipeline.run(boards, sig)

    model.signals = sig
    return model
end

function Controller.render_text(model)
    return Format.render(model)
end

return Controller
