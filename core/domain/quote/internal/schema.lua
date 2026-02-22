local Signals = require("core.signal")

local Schema = {}

function Schema.validate_input(boards, sig)
    if type(boards) ~= "table" then
        Signals.push(sig, Signals.new(
            "QUOTE_INPUT_INVALID",
            Signals.LEVEL.ERROR,
            "Quote requires boards table"
        ))
    end
end

return Schema
