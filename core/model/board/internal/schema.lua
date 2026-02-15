-- core/model/board/schema.lua
--
-- Canonical BOARD domain schema.
-- Physical + material + pricing only.
-- No order / ledger context.

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

    -- declared
    base_h = { role = Schema.ROLES.AUTHORITATIVE, coerce = tonumber },
    base_w = { role = Schema.ROLES.AUTHORITATIVE, coerce = tonumber },
    l      = { role = Schema.ROLES.AUTHORITATIVE, coerce = tonumber },
    ct     = { role = Schema.ROLES.AUTHORITATIVE, coerce = function(v) return tonumber(v) or 1 end },
    tag    = {
        role = Schema.ROLES.AUTHORITATIVE,
        coerce = function(v)
            if v == nil or v == "" then return nil end
            local s = tostring(v):lower()
            if s == "n" or s == "f" or "c" then return s end
            return nil
        end
    },

    -- material
    species  = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    grade    = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    moisture = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },
    surface  = { role = Schema.ROLES.AUTHORITATIVE, coerce = tostring },

    -- pricing inputs
    bf_price = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_currency_number },
    ea_price = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_currency_number },
    lf_price = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_currency_number },

    -- derived
    h            = { role = Schema.ROLES.DERIVED },
    w            = { role = Schema.ROLES.DERIVED },
    bf_ea        = { role = Schema.ROLES.DERIVED },
    bf_per_lf    = { role = Schema.ROLES.DERIVED },
    bf_batch     = { role = Schema.ROLES.DERIVED },
    batch_price  = { role = Schema.ROLES.DERIVED },
    n_delta_vol  = { role = Schema.ROLES.DERIVED },
}

return Schema
