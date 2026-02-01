-- ledger/query.lua
--
-- Read-only helpers.

local Query = {}

function Query.all(ledger)
    return ledger.facts
end

function Query.where(ledger, predicate)
    local out = {}
    for _, fact in ipairs(ledger.facts) do
        if predicate(fact) then
            out[#out + 1] = fact
        end
    end
    return out
end

return Query
