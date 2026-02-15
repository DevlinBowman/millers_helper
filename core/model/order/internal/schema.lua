local Schema = {}

Schema.ROLES = {
    AUTHORITATIVE = "authoritative",
    DERIVED       = "derived",
}

-- Defines authoritative identity resolution order.
-- Ingest will use the first non-nil field found here.
Schema.identity_priority = {
    "order_id",
    "order_number",
    "job_number",
    "invoice_number",
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

    date              = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    job_number        = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    order_number      = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    order_id          = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    order_status      = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    customer_name     = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    customer_id       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    beneficiary       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    distribution_type = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    invoice_number    = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    -- purpose           = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    order_notes       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    -- notes             = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    stumpage_cost     = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_currency_number },
    stumpage_origin   = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    value             = { role = Schema.ROLES.DERIVED,coerce = coerce_currency_number }
}

return Schema
