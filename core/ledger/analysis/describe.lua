-- ledger/analysis/describe.lua
--
-- Responsibility:
--   Exhaustive, human-readable description of the BOARD / LEDGER field surface.
--
-- Guarantees:
--   • Covers EVERY canonical field in core.board.schema
--   • No IO
--   • No mutation
--   • No dependency on runtime ledger contents
--   • Deterministic
--
-- Purpose:
--   • CLI inspection (--describe)
--   • Query validation & hints
--   • User-facing documentation
--   • Stable contract of "what exists"

local Describe = {}

----------------------------------------------------------------
-- Field descriptions (EXHAUSTIVE)
----------------------------------------------------------------

Describe.fields = {

    ----------------------------------------------------------------
    -- Identity / labeling
    ----------------------------------------------------------------
    id = {
        role        = "identity",
        source      = "system",
        description = "Stable board identity string (equal to generated label)",
        derived     = true,
        queryable   = true,
    },

    label = {
        role        = "identity",
        source      = "system",
        description = "Human-readable label generated from board attributes",
        derived     = true,
        queryable   = true,
    },

    ----------------------------------------------------------------
    -- Declared dimensions (input)
    ----------------------------------------------------------------
    base_h = {
        role        = "authoritative",
        source      = "input",
        units       = "inches",
        description = "Declared board thickness (nominal or actual, interpreted via tag)",
        queryable   = true,
    },

    base_w = {
        role        = "authoritative",
        source      = "input",
        units       = "inches",
        description = "Declared board width (nominal or actual, interpreted via tag)",
        queryable   = true,
    },

    l = {
        role        = "authoritative",
        source      = "input",
        units       = "feet",
        description = "Board length",
        queryable   = true,
    },

    ct = {
        role        = "authoritative",
        source      = "input",
        units       = "count",
        description = "Quantity of identical boards in this record",
        queryable   = true,
    },

    tag = {
        role        = "authoritative",
        source      = "input",
        description = "Dimension interpretation flag: 'n' = nominal, 'f'/nil = actual",
        queryable   = true,
    },

    ----------------------------------------------------------------
    -- Resolved working dimensions (derived)
    ----------------------------------------------------------------
    h = {
        role        = "derived",
        source      = "system",
        units       = "inches",
        description = "Resolved working thickness after nominal mapping",
        queryable   = true,
    },

    w = {
        role        = "derived",
        source      = "system",
        units       = "inches",
        description = "Resolved working width after nominal mapping",
        queryable   = true,
    },

    ----------------------------------------------------------------
    -- Volume & pricing (derived)
    ----------------------------------------------------------------
    bf_ea = {
        role        = "derived",
        source      = "system",
        units       = "board-feet",
        description = "Board feet per individual board (h × w × l ÷ 12)",
        queryable   = true,
    },

    bf_batch = {
        role        = "derived",
        source      = "system",
        units       = "board-feet",
        description = "Board feet for this record (bf_ea × ct)",
        queryable   = true,
    },

    bf_per_lf = {
        role        = "derived",
        source      = "system",
        units       = "bf / linear-foot",
        description = "Board feet per linear foot (unrounded intermediate)",
        queryable   = true,
    },

    bf_price = {
        role        = "authoritative",
        source      = "input",
        units       = "currency / board-foot",
        description = "Price per board foot",
        queryable   = true,
    },

    ea_price = {
        role        = "derived",
        source      = "system",
        units       = "currency",
        description = "Price per board, derived from bf_price",
        queryable   = true,
    },

    value = {
        role        = "derived",
        source      = "system",
        units       = "currency",
        description = "Total value (ea_price × ct)",
        queryable   = true,
    },

    ----------------------------------------------------------------
    -- Nominal diagnostics
    ----------------------------------------------------------------
    n_delta_vol = {
        role        = "derived",
        source      = "system",
        description = "Ratio of actual BF to nominal BF (nominal boards only)",
        queryable   = true,
    },

    ----------------------------------------------------------------
    -- Material classification
    ----------------------------------------------------------------
    species = {
        role        = "authoritative",
        source      = "input",
        description = "Wood species code",
        queryable   = true,
    },

    grade = {
        role        = "authoritative",
        source      = "input",
        description = "Lumber grade",
        queryable   = true,
    },

    moisture = {
        role        = "authoritative",
        source      = "input",
        description = "Moisture condition (e.g. KD, AD)",
        queryable   = true,
    },

    surface = {
        role        = "authoritative",
        source      = "input",
        description = "Surface finish or treatment",
        queryable   = true,
    },

    ----------------------------------------------------------------
    -- Ledger / business context
    ----------------------------------------------------------------
    date = {
        role        = "contextual",
        source      = "input",
        description = "Transaction or order date",
        queryable   = true,
    },

    job_number = {
        role        = "contextual",
        source      = "input",
        description = "Job or project identifier",
        queryable   = true,
    },

    order_number = {
        role        = "contextual",
        source      = "input",
        description = "Order number",
        queryable   = true,
    },

    order_id = {
        role        = "contextual",
        source      = "input",
        description = "Internal order identifier",
        queryable   = true,
    },

    order_status = {
        role        = "contextual",
        source      = "input",
        description = "Order status (e.g. open, closed)",
        queryable   = true,
    },

    customer_name = {
        role        = "contextual",
        source      = "input",
        description = "Customer or recipient name",
        queryable   = true,
    },

    customer_id = {
        role        = "contextual",
        source      = "input",
        description = "Customer identifier",
        queryable   = true,
    },

    beneficiary = {
        role        = "contextual",
        source      = "input",
        description = "Payee or beneficiary",
        queryable   = true,
    },

    distribution_type = {
        role        = "contextual",
        source      = "input",
        description = "Delivery or distribution type",
        queryable   = true,
    },

    invoice_number = {
        role        = "contextual",
        source      = "input",
        description = "Invoice identifier",
        queryable   = true,
    },

    purpose = {
        role        = "contextual",
        source      = "input",
        description = "Declared purpose or usage",
        queryable   = true,
    },

    order_notes = {
        role        = "contextual",
        source      = "input",
        description = "Order-specific notes",
        queryable   = false,
    },

    stumpage_cost = {
        role        = "contextual",
        source      = "input",
        description = "Stumpage or acquisition cost",
        queryable   = true,
    },

    stumpage_origin = {
        role        = "contextual",
        source      = "input",
        description = "Source or owner of logs",
        queryable   = true,
    },

    notes = {
        role        = "contextual",
        source      = "input",
        description = "Freeform notes",
        queryable   = false,
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Describe a single field
---@param key string
---@return table|nil
function Describe.field(key)
    return Describe.fields[key]
end

--- Describe all known fields
---@return table
function Describe.all()
    return Describe.fields
end

return Describe
