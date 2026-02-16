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

    value = {
        conflict          = "recalculable",
        allow_sentinel    = true,
        sentinel_strategy = "drop",
        recalc_requires   = "boards_have_bf_price",
    },

    -- examples of future fields

    date = {
        conflict = "strict",
        normalize = "normalize_date"
    },

    order_number = {
        conflict = "strict",
    },

    customer = {
        conflict = "strict",
    },
}

----------------------------------------------------------------
-- Default Policy
----------------------------------------------------------------

Spec.default = {
    conflict = "strict",
}

return Spec
