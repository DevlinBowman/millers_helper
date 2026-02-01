-- ledger/review.lua
--
-- Optional manual review hooks.

local Review = {}

function Review.needs_review(fact)
    return fact.board.purpose == nil
end

return Review
