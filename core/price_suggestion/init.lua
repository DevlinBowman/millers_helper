-- core/price_suggestion/init.lua

local Model = require("core.price_suggestion.model")

local PriceSuggestion = {}

function PriceSuggestion.run(compare_model, cost_model, strategy)
    return Model.build(compare_model, cost_model, strategy)
end

return PriceSuggestion
