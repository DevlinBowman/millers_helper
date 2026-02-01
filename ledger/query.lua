-- ledger/query.lua

local Query = {}

function Query.all(ledger)
    return ledger.facts
end

function Query.where(ledger, predicate)
    local out = {}
    for _, f in ipairs(ledger.facts) do
        if predicate(f) then
            out[#out + 1] = f
        end
    end
    return out
end

return Query
