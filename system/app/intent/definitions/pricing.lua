-- system/app/intent/definitions/pricing.lua

local PricingIntent = {}

PricingIntent.fields = {

    basis = {
        values = {
            "vendor_anchor",
            "reverse_order_value"
        },
        default = "vendor_anchor"
    },

    vendor = {
        type = "string",
        optional = true
    },

    percentage = {
        type = "number",
        default = 10
    },

    profile = {
        type = "string",
        default = "default"
    }
}

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
