-- ledger/mutate.lua
--
-- Batch mutation of sparse facts.

local Mutate = {}

---@param ledger table
---@param predicate fun(fact):boolean
---@param updater fun(data:table)
---@return number updated
function Mutate.update_where(ledger, predicate, updater)
    local n = 0
    for _, fact in ipairs(ledger.facts) do
        if predicate(fact) then
            updater(fact.data)
            n = n + 1
        end
    end
    return n
end

return Mutate
