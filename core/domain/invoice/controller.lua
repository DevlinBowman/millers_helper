local Registry = require("core.domain.invoice.registry")
local Format   = require("core.domain._priced_doc.internal.format_text")

local Controller = {}

function Controller.run(batch)
    Registry.schema.validate(batch)

    local model = Registry.pipeline.run(batch)

    return model
end

function Controller.render_text(model)
    return Format.render(model)
end

return Controller
