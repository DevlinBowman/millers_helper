-- core/formula/pricing_convert.lua
--
-- Pure pricing conversion math.

local Volume = require("core.formula.board.volume")

local PricingConvert = {}

function PricingConvert.ea_to_bf(height_in, width_in, length_ft, ea_price)
    local bf = Volume.bf(height_in, width_in, length_ft)
    return ea_price / bf
end

function PricingConvert.lf_to_bf(height_in, width_in, lf_price)
    local bf_per_lf = Volume.bf_per_lf(height_in, width_in)
    return lf_price / bf_per_lf
end

function PricingConvert.bf_to_ea(height_in, width_in, length_ft, bf_price)
    local bf = Volume.bf(height_in, width_in, length_ft)
    return bf_price * bf
end

function PricingConvert.bf_to_lf(height_in, width_in, bf_price)
    local bf_per_lf = Volume.bf_per_lf(height_in, width_in)
    return bf_price * bf_per_lf
end

return PricingConvert
