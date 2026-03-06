local cases = {
    missing_board_prices = {
        target  = "batch",
        scope   = "boards",
        message = "Board bf_price is missing. Building pricing context.",
        fields  = { names = { "bf_price" } },
        checks  = { "is_incomplete" },
        service = "pricing",
        package = "build_pricing_context"
    },
    missing_allocations = {
        target  = "batch",
        scope   = "allocations",
        message = "Allocations missing. Generating allocations.",
        checks  = { "is_incomplete" },
        service = "allocations",
        package = "generate"
    }
}
return cases
