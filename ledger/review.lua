-- ledger/review.lua
--
-- Manual review / staging (future).

local Review = {}

function Review.needs_review(fact)
    return fact.data.use == nil
end

return Review
