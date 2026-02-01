-- core/board/schema.lua
-- Authoritative BOARD (ledger row) schema

---@class BoardSchema
local Schema = {}

----------------------------------------------------------------
-- Field definitions
----------------------------------------------------------------

Schema.fields = {

    -- ========================
    -- DIMENSIONS / PHYSICAL
    -- ========================
    base_h = {
        aliases = { "base_h", "BaseH", "BH", "H", "h", "height", "Height", "T", "thickness" },
        coerce  = tonumber,
    },

    base_w = {
        aliases = { "base_w", "BaseW", "BW", "W", "w", "width", "Width" },
        coerce  = tonumber,
    },

    l = {
        aliases = { "l", "L", "len", "length", "Length" },
        coerce  = tonumber,
    },

    ct = {
        aliases = { "ct", "Ct", "CT", "count", "Count" },
        coerce  = function(v) return tonumber(v) or 1 end,
        default = 1,
    },

    tag = {
        aliases = { "tag", "Tag", "Flag", "flag", "N/F", "Nominal" },
        coerce  = function(v)
            if v == nil or v == "" then return nil end
            local s = tostring(v):lower()
            if s == "n" or s == "f" then return s end
            return nil
        end,
    },

    -- ========================
    -- PRICING
    -- ========================
    bf_price = {
        aliases = { "bf_price", "BFPrice", "Price/BF", "price_per_bf" },
        coerce  = tonumber,
    },

    -- ========================
    -- MATERIAL
    -- ========================
    species = {
        aliases = { "species", "Species", "SP" },
        coerce  = tostring,
    },

    grade = {
        aliases = { "grade", "Grade", "GR", 'grd' },
        coerce  = tostring,
    },

    moisture = {
        aliases = { "moisture", "Moisture", "MC" },
        coerce  = tostring,
    },

    surface = {
        aliases = { "surface", "Surface", "Finish" },
        coerce  = tostring,
    },

    -- ========================
    -- LEDGER / CONTEXT
    -- ========================
    date = {
        aliases = { "date", "Date", "Order Date" },
        coerce  = tostring,
    },

    job_number = {
        aliases = { "job_number", "Job Number", "job", "Job" },
        coerce  = tostring,
    },

    order_number = {
        aliases = { "order_number", "Order Number", "OrderNo" },
        coerce  = tostring,
    },

    order_id = {
        aliases = { "order_id", "OrderID" },
        coerce  = tostring,
    },

    order_status = {
        aliases = { "order_status", "Order Status", "Status" },
        coerce  = tostring,
    },

    customer_name = {
        aliases = { "customer_name", "Customer", "customer" },
        coerce  = tostring,
    },

    customer_id = {
        aliases = { "customer_id", "CustomerID" },
        coerce  = tostring,
    },

    beneficiary = {
        aliases = { "beneficiary", "Payee", "payee" },
        coerce  = tostring,
    },

    distribution_type = {
        aliases = { "distribution_type", "Distribution", "Delivery" },
        coerce  = tostring,
    },

    invoice_number = {
        aliases = { "invoice_number", "Invoice", "Invoice Number" },
        coerce  = tostring,
    },

    purpose = {
        aliases = { "purpose", "Purposei", "useage" },
        coerce  = tostring,
    },

    order_notes = {
        aliases = { "order_notes", "Order Notes" },
        coerce  = tostring,
    },

    stumpage_cost = {
        aliases = { "cost", "stumpage" },
        coerce = tostring,
    },

    stumpage_origin = {
        aliases = { "owner", "log owner", "purchased from" },
        coerce = tostring,
    },

    notes = {
        aliases = { "notes", "Notes", "note", "head" },
        coerce  = tostring,
    },
}

----------------------------------------------------------------
-- Alias index (derived once)
----------------------------------------------------------------

Schema.alias_index = {}

for canonical, def in pairs(Schema.fields) do
    for _, alias in ipairs(def.aliases or {}) do
        Schema.alias_index[alias] = canonical
    end
end

return Schema
