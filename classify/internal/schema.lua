-- classify/spec.lua
--
-- Canonical classification specification.
-- 1:1 lift of original core/board/schema.lua
-- Ownership split: board vs order.
--
-- No coercion.
-- No derivation.
-- No validation.
-- Pure canonical + alias mapping.

local Spec = {}

Spec.DOMAIN = {
    BOARD = "board",
    ORDER = "order",
}

----------------------------------------------------------------
-- BOARD DOMAIN
----------------------------------------------------------------

Spec.board_fields = {

    -- ========================
    -- DIMENSIONS / PHYSICAL
    -- ========================

    base_h      = { aliases = { "base_h", "BaseH", "BH", "H", "h", "height", "Height", "T", "thickness" }, },
    base_w      = { aliases = { "base_w", "BaseW", "BW", "W", "w", "width", "Width" }, },
    l           = { aliases = { "l", "L", "len", "length", "Length" }, },
    ct          = { aliases = { "ct", "Ct", "CT", "count", "Count" }, },
    tag         = { aliases = { "tag", "Tag", "Flag", "flag", "N/F", "Nominal" }, },

    -- ========================
    -- DERIVED / COMPUTED
    -- (classified but builder decides behavior)
    -- ========================

    bf_batch    = { aliases = { "bf_batch", "bf vol", "BF Vol", "bf_vol", "BF_Vol", "total_bf", "Total BF", "BF Total", }, },
    bf_ea       = { aliases = { "bf_ea", "BF EA" }, },
    bf_per_lf   = { aliases = { "bf_per_lf", "BF/LF" }, },

    -- ========================
    -- PRICING
    -- ========================

    bf_price    = { aliases = { "bf_price", "BFPrice", "Price/BF", "price/bf", "price_per_bf" }, },
    ea_price    = { aliases = { "ea_price", "EA Price", "Each Price" }, },
    lf_price    = { aliases = { "lf_price", "LF Price", "Price/LF", "price_per_lf" }, },

    -- ========================
    -- MATERIAL
    -- ========================

    species     = { aliases = { "species", "Species", "SP" }, },
    grade       = { aliases = { "grade", "Grade", "GR", "grd" }, },
    moisture    = { aliases = { "moisture", "Moisture", "MC" }, },
    surface     = { aliases = { "surface", "Surface", "Finish" }, },

    purpose     = { aliases = { "purpose", "Purpose", "useage" }, },
    description = { aliases = { "notes", "Notes", "note", 'Description' }, },
}

----------------------------------------------------------------
-- ORDER DOMAIN
----------------------------------------------------------------

Spec.order_fields = {

    -- ========================
    --  CONTEXT
    -- ========================

    -- Assigned Canonical Fields in the Order Builder (Expect to see in post build data)
    date            = { aliases = { "date", "Date", "Order Date" }, },
    client          = { aliases = { "Client", "client", "customer_name", "customer name", "Customer", "customer" }, },
    claimant        = { aliases = { 'claimant', 'Claimant' } },
    order_number    = { aliases = { "order_number", "Order Number", "OrderNo", "Order No" }, },
    use             = { aliases = { 'use', 'Use' } },
    order_status    = { aliases = { "order_status", "Order Status", "Status" }, },
    value           = { aliases = { "value", "Value", "Total Value" }, },

    -- These Are Assigned but are not yest tested for or fully implemented
    order_id        = { aliases = { "order_id", "OrderID" }, },
    customer_id     = { aliases = { "customer_id", "CustomerID" }, },
    invoice_id      = { aliases = { "invoice_number", "Invoice", "Invoice Number" }, },
    order_notes     = { aliases = { "order_notes", "Order Notes" }, },
    stumpage_cost   = { aliases = { "stumpage_cost", "cost", "stumpage" }, },
    stumpage_origin = { aliases = { "stumpage_origin", "owner", "log owner", "purchased from" }, },

    -- These will be filtered out by the Order Builder until assigned
    job_number      = { aliases = { "job_number", "Job Number", "job", "Job", "job number" }, }, -- Should be different than order number

    -- Deprecated
    -- beneficiary = { aliases = { "beneficiary", "Payee", "payee" }, },
    -- distribution_type = { aliases = { "distribution_type", "Distribution", "Delivery" }, },
}

return Spec
