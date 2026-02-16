local Schema = {}

Schema.ROLES = {
    AUTHORITATIVE = "authoritative",
    DERIVED       = "derived",
}

local function coerce_currency_number(v)
    if v == nil then return nil end
    if type(v) == "number" then return v end
    if type(v) ~= "string" then return nil end
    local s = v:match("^%s*(.-)%s*$")
    if not s or s == "" then return nil end
    s = s:gsub("[%$,]", "")
    return tonumber(s)
end

Schema.fields = {

    -- identity
    transaction_id = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    -- classification
    type           = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    -- sale | personal | gift | waste | transfer | adjustment

    date           = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    -- references
    order_id       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    customer_id    = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    invoice_id     = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    item_ids       = {
        role = Schema.ROLES.AUTHORITATIVE,
        coerce = function(v)
            return type(v) == "table" and v or nil
        end
    },

    -- financial
    value          = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_currency_number },
    currency       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    -- lumber impact
    total_bf       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tonumber },

    -- optional descriptive metadata
    notes          = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    -- snapshot
    snapshot       = {
        role = Schema.ROLES.AUTHORITATIVE,
        coerce = function(v)
            return type(v) == "table" and v or nil
        end
    },
}

return Schema
