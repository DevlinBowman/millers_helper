-- core/board/schema.lua
-- Authoritative BOARD (ledger row) schema
--
-- NOTE:
--   This file is PURELY declarative.
--   It does NOT perform:
--     • validation
--     • normalization
--     • lowercasing
--     • ingestion behavior
--
-- Existing alias behavior is preserved EXACTLY.

---@class BoardSchema
local Schema = {}

----------------------------------------------------------------
-- Field role constants (declarative only)
----------------------------------------------------------------

Schema.ROLES = {
    AUTHORITATIVE = "authoritative", -- trusted input
    DERIVED       = "derived",       -- computed internally, input ignored
    IGNORED       = "ignored",       -- known, process-irrelevant
}

----------------------------------------------------------------
-- Field definitions
----------------------------------------------------------------

Schema.fields = {

    -- ========================
    -- DIMENSIONS / PHYSICAL
    -- ========================
    base_h = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "base_h", "BaseH", "BH", "H", "h", "height", "Height", "T", "thickness" },
        coerce  = tonumber,
    },

    base_w = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "base_w", "BaseW", "BW", "W", "w", "width", "Width" },
        coerce  = tonumber,
    },

    l = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "l", "L", "len", "length", "Length" },
        coerce  = tonumber,
    },

    ct = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "ct", "Ct", "CT", "count", "Count" },
        coerce  = function(v) return tonumber(v) or 1 end,
        default = 1,
    },

    tag = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "tag", "Tag", "Flag", "flag", "N/F", "Nominal" },
        coerce  = function(v)
            if v == nil or v == "" then return nil end
            local s = tostring(v):lower()
            if s == "n" or s == "f" then return s end
            return nil
        end,
    },

    -- ========================
    -- DERIVED / COMPUTED
    -- ========================
    bf_vol = {
        role    = Schema.ROLES.DERIVED,
        aliases = { "bf vol", "BF Vol", "bf_vol", "BF_Vol" },
    },

    batch_bf = {
        role    = Schema.ROLES.DERIVED,
        aliases = { "total_bf", "Total BF", "BF Total" },
    },

    value = {
        role    = Schema.ROLES.DERIVED,
        aliases = { "value", "Value", "Total Value" },
    },

    ea_price = {
        role    = Schema.ROLES.DERIVED,
        aliases = { "ea_price", "EA Price", "Each Price" },
    },

    -- ========================
    -- PRICING (INPUT)
    -- ========================
    bf_price = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "bf_price", "BFPrice", "Price/BF", "price/bf", "price_per_bf" },
        coerce  = tonumber,
    },

    -- ========================
    -- MATERIAL
    -- ========================
    species = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "species", "Species", "SP" },
        coerce  = tostring,
    },

    grade = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "grade", "Grade", "GR", "grd" },
        coerce  = tostring,
    },

    moisture = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "moisture", "Moisture", "MC" },
        coerce  = tostring,
    },

    surface = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "surface", "Surface", "Finish" },
        coerce  = tostring,
    },

    -- ========================
    -- LEDGER / CONTEXT
    -- ========================
    date = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "date", "Date", "Order Date" },
        coerce  = tostring,
    },

    job_number = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "job_number", "Job Number", "job", "Job", "job number" },
        coerce  = tostring,
    },

    order_number = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "order_number", "Order Number", "OrderNo" },
        coerce  = tostring,
    },

    order_id = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "order_id", "OrderID" },
        coerce  = tostring,
    },

    order_status = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "order_status", "Order Status", "Status" },
        coerce  = tostring,
    },

    customer_name = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "customer_name", "Customer", "customer" },
        coerce  = tostring,
    },

    customer_id = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "customer_id", "CustomerID" },
        coerce  = tostring,
    },

    beneficiary = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "beneficiary", "Payee", "payee" },
        coerce  = tostring,
    },

    distribution_type = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "distribution_type", "Distribution", "Delivery" },
        coerce  = tostring,
    },

    invoice_number = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "invoice_number", "Invoice", "Invoice Number" },
        coerce  = tostring,
    },

    purpose = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "purpose", "Purpose", "useage" },
        coerce  = tostring,
    },

    order_notes = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "order_notes", "Order Notes" },
        coerce  = tostring,
    },

    stumpage_cost = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "cost", "stumpage" },
        coerce  = tostring,
    },

    stumpage_origin = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "owner", "log owner", "purchased from" },
        coerce  = tostring,
    },

    notes = {
        role    = Schema.ROLES.AUTHORITATIVE,
        aliases = { "notes", "Notes", "note" },
        coerce  = tostring,
    },
}

----------------------------------------------------------------
-- Alias index (derived once, unchanged behavior)
----------------------------------------------------------------

Schema.alias_index = {}

for canonical, def in pairs(Schema.fields) do
    for _, alias in ipairs(def.aliases or {}) do
        Schema.alias_index[alias] = canonical
    end
end

----------------------------------------------------------------
-- Role helpers (pure queries, no behavior)
----------------------------------------------------------------

function Schema.role_of(field)
    local def = Schema.fields[field]
    return def and def.role or Schema.ROLES.AUTHORITATIVE
end

function Schema.is_derived(field)
    return Schema.role_of(field) == Schema.ROLES.DERIVED
end

function Schema.is_ignored(field)
    return Schema.role_of(field) == Schema.ROLES.IGNORED
end

return Schema
