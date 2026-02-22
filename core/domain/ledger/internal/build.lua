-- core/domain/ledger/internal/build.lua

local Schema = require("core.domain.ledger.internal.schema")

local Build = {}

local function coerce_fields(input)
    local out = {}

    for field, spec in pairs(Schema.fields) do
        local raw = input[field]
        if raw ~= nil and spec.coerce then
            out[field] = spec.coerce(raw)
        else
            out[field] = raw
        end
    end

    return out
end

function Build.run(input)
    assert(type(input) == "table", "transaction input must be table")

    local entry = coerce_fields(input)

    assert(entry.transaction_id, "transaction_id required")
    assert(entry.type, "type required")
    assert(entry.date, "date required")

    return entry
end

return Build
