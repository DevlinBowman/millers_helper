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

-- IMPORTANT:: THESE FIELDS MUST MATCH THE OUTPUTS FROM THE CLASSIFIER TO MAKE IT INTO THE FINAL DATA
-- EXAMPLE; IF YOU EXPECT TO SEE 'CLIENT' IN THE OUTPUT, THE CLASSIFIER MUST RETURN A MAPPED 'CLIENT' ALIAS TO ASSOCIATE WITH
Schema.fields = {

    -- DEV NOTE - THESE HAVE BEEN 'CLASSIFIED'

    order_number      = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },         -- Primary Unique Identifier
    order_status      = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },         -- Open | Closed | Pending ...
    date              = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },         -- Transaction Date
    claimant          = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },         -- Initiating Party
    client            = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },         -- Recieving Party
    value             = { role = Schema.ROLES.DERIVED, coerce = coerce_currency_number }, -- Final Associated Total $ Amount
    use               = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },         -- Sale | Personal | Gift

    -- DEV NOTE - THESE HAVE **NOT** BEEN 'CLASSIFIED'
    order_id          = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring }, -- Unique ID for system storage
    customer_id       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring }, -- Unique ID for system Storage
    invoice_id        = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring }, -- Unique ID for system storage

    order_notes       = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },


    -- DEV NOTE - THESE HAVE NOT BEEN CONSIDERED AT ALL BUT ARE VERY IMPORTANT
    stumpage_cost   = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_currency_number },
    stumpage_origin = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

}

return Schema
