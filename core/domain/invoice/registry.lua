-- core/domain/invoice/registry.lua

local InternalInput = require("core.domain.invoice.internal.input")
local FormatText    = require("core.domain.invoice.internal.format_text")

local Registry = {}

Registry.capabilities = {

    input  = InternalInput,
    format = {
        text = FormatText,
    },
}

return Registry
