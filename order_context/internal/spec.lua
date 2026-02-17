-- order_context/internal/spec.lua
--
-- Declarative reconciliation spec.
-- Defines how each order field behaves under conflict.
--
-- Pure data only.

local Spec = {}

----------------------------------------------------------------
-- Field Policies
----------------------------------------------------------------

-- conflict:
--   "strict"         → always error on conflict
--   "keep_first"     → deterministic first wins
--   "recalculable"   → may drop and defer to builder
--
-- allow_sentinel:
--   if true, non-numeric or token values allowed
--
-- sentinel_strategy:
--   "drop" → remove field so builder recalculates
--
-- recalc_requires:
--   name of util predicate required to allow recalculation

Spec.fields = {

    ----------------------------------------------------------------
    -- CORE ORDER IDENTITY / STRUCTURAL FIELDS
    ----------------------------------------------------------------

    date            = { conflict = "strict", normalize = "normalize_date", },
    client          = { conflict = "strict", },
    claimant        = { conflict = "strict", },
    order_number    = { conflict = "strict", },
    order_id        = { conflict = "strict", },
    customer_id     = { conflict = "strict", },
    invoice_id      = { conflict = "strict", },
    job_number      = { conflict = "strict", },

    ----------------------------------------------------------------
    -- STATUS / CONTEXT
    ----------------------------------------------------------------

    use             = { conflict = "keep_first", },
    order_status    = { conflict = "keep_first", },
    order_notes     = { conflict = "keep_first", },
    stumpage_origin = { conflict = "keep_first", },

    ----------------------------------------------------------------
    -- NUMERIC / RECONCILABLE FIELDS
    ----------------------------------------------------------------

    value           = {
        conflict          = "recalculable",
        allow_sentinel    = true,
        sentinel_strategy = "drop",
        recalc_requires   = "boards_have_bf_price",
    },

    stumpage_cost   = {
        conflict          = "recalculable",
        allow_sentinel    = true,
        sentinel_strategy = "drop",
    },
}

----------------------------------------------------------------
-- Default Policy
----------------------------------------------------------------

Spec.default = {
    conflict = "strict",
}

return Spec
