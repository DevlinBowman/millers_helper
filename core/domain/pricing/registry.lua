-- core/domain/pricing/registry.lua
--
-- Domain registry for pricing.
--
-- Responsibilities:
--   • Input normalization helpers
--   • Strategy lookup table
--
-- Note:
--   Pricing model math is NOT registered here.
--   Strategies import the pricing model directly.

local Registry = {}

----------------------------------------------------------------
-- Input Extraction
----------------------------------------------------------------

Registry.input =
    require("core.domain.pricing.internal.input")

----------------------------------------------------------------
-- Pricing Strategies
----------------------------------------------------------------

Registry.strategies = {
    cost_model =
        require("core.domain.pricing.strategies.cost_model"),

    vendor_anchor =
        require("core.domain.pricing.strategies.vendor_anchor"),

    hybrid_market =
        require("core.domain.pricing.strategies.hybrid_market"),
}

----------------------------------------------------------------

return Registry
