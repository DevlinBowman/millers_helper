-- system/app/intent/definitions/pricing.lua

local PricingIntent = {}

------------------------------------------------------------
-- validation
------------------------------------------------------------

function PricingIntent.validate(runtime, intent)

    if intent.basis == "vendor_anchor" then
        if not intent.vendor then
            return nil, {
                message = "vendor must be specified for vendor_anchor pricing",
                required = { "vendor" }
            }
        end
    end

    return true
end

return PricingIntent
