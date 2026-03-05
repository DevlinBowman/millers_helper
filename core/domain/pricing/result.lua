-- core/domain/pricing/result.lua

local PricingResult = {}
PricingResult.__index = PricingResult

function PricingResult.new(model_result)

    assert(type(model_result) == "table",
        "[pricing.domain] model result required")

    return setmetatable({
        __data = model_result
    }, PricingResult)
end

function PricingResult:model()
    return self.__data
end

function PricingResult:per_board()
    return self.__data:per_board()
end

function PricingResult:suggested(index)
    return self.__data:suggested_price_per_bf(index)
end

function PricingResult:recommended(index)
    return self.__data:recommended_price_per_bf(index)
end

return PricingResult
