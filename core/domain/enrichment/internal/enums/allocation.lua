-- core/domain/enrichment/internal/enums/allocation.lua
--
-- Canonical allocation enums.
-- Each entry is self-describing.
-- Fields:
--   kind        = "key" | "value"
--   domain      = "allocation"
--   value       = canonical string
--   description = semantic meaning

local AllocationEnums = {}

----------------------------------------------------------------
-- Canonical Keys
----------------------------------------------------------------

AllocationEnums.KEYS = {

    PROFILE_ID = {
        kind = "key",
        domain = "allocation",
        value = "profile_id",
        description = "Unique allocation profile identifier (used for presets).",
    },

    SCOPE = {
        kind = "key",
        domain = "allocation",
        value = "scope",
        description = "Level at which allocation applies (board, order, profit).",
    },

    PARTY = {
        kind = "key",
        domain = "allocation",
        value = "party",
        description = "Beneficiary or responsible entity for the allocation.",
    },

    CATEGORY = {
        kind = "key",
        domain = "allocation",
        value = "category",
        description = "Economic classification used for reporting and grouping.",
    },

    AMOUNT = {
        kind = "key",
        domain = "allocation",
        value = "amount",
        description = "Numeric value applied under the specified basis.",
    },

    BASIS = {
        kind = "key",
        domain = "allocation",
        value = "basis",
        description = "Calculation method for amount (per_bf, fixed, percent).",
    },

    PRIORITY = {
        kind = "key",
        domain = "allocation",
        value = "priority",
        description = "Execution order when applying allocations.",
    },

    SOURCE = {
        kind = "key",
        domain = "allocation",
        value = "source",
        description = "Origin of allocation rule (preset, derived, manual).",
    },
}

----------------------------------------------------------------
-- Scope Values
----------------------------------------------------------------

AllocationEnums.SCOPE = {

    BOARD = {
        kind = "value",
        domain = "allocation.scope",
        value = "board",
        description = "Allocation calculated per board or per board-foot unit.",
    },

    ORDER = {
        kind = "value",
        domain = "allocation.scope",
        value = "order",
        description = "Allocation applied once at the order level.",
    },

    PROFIT = {
        kind = "value",
        domain = "allocation.scope",
        value = "profit",
        description = "Allocation applied after revenue to distribute net profit.",
    },
}

----------------------------------------------------------------
-- Basis Values
----------------------------------------------------------------

AllocationEnums.BASIS = {

    PER_BF = {
        kind = "value",
        domain = "allocation.basis",
        value = "per_bf",
        description = "Amount multiplied by total board feet.",
    },

    FIXED = {
        kind = "value",
        domain = "allocation.basis",
        value = "fixed",
        description = "Flat absolute amount applied once.",
    },

    PERCENT = {
        kind = "value",
        domain = "allocation.basis",
        value = "percent",
        description = "Percentage applied to revenue or profit.",
    },
}

----------------------------------------------------------------
-- Category Values
----------------------------------------------------------------

----------------------------------------------------------------
-- Category Values
----------------------------------------------------------------

AllocationEnums.CATEGORY = {

    STUMPAGE = {
        kind = "value",
        domain = "allocation.category",
        value = "stumpage",
        description = "Cost of raw timber acquisition.",
    },

    LAND_USE = {
        kind = "value",
        domain = "allocation.category",
        value = "land_use",
        description = "Cost associated with land access, lease, or usage rights.",
    },

    LABOR = {
        kind = "value",
        domain = "allocation.category",
        value = "labor",
        description = "Direct production labor cost.",
    },

    MILL = {
        kind = "value",
        domain = "allocation.category",
        value = "mill",
        description = "Operational mill cost (equipment, utilities).",
    },

    DELIVERY = {
        kind = "value",
        domain = "allocation.category",
        value = "delivery",
        description = "Transportation or logistics cost.",
    },

    ADMIN = {
        kind = "value",
        domain = "allocation.category",
        value = "admin",
        description = "Administrative or overhead expenses.",
    },

    BONUS = {
        kind = "value",
        domain = "allocation.category",
        value = "bonus",
        description = "Discretionary or performance-based payout.",
    },

    PROFIT = {
        kind = "value",
        domain = "allocation.category",
        value = "profit",
        description = "Net profit allocation to stakeholders.",
    },

    OTHER = {
        kind = "value",
        domain = "allocation.category",
        value = "other",
        description = "Explicit fallback category for uncategorized allocations.",
    },
}

----------------------------------------------------------------
-- Rebuild Category Set
----------------------------------------------------------------

AllocationEnums.CATEGORY_SET = {}
for _, def in pairs(AllocationEnums.CATEGORY) do
    AllocationEnums.CATEGORY_SET[def.value] = true
end
----------------------------------------------------------------
-- Derived Lookup Sets (built once, not stored per entry)
----------------------------------------------------------------

AllocationEnums.SCOPE_SET = {}
for _, def in pairs(AllocationEnums.SCOPE) do
    AllocationEnums.SCOPE_SET[def.value] = true
end

AllocationEnums.BASIS_SET = {}
for _, def in pairs(AllocationEnums.BASIS) do
    AllocationEnums.BASIS_SET[def.value] = true
end

AllocationEnums.CATEGORY_SET = {}
for _, def in pairs(AllocationEnums.CATEGORY) do
    AllocationEnums.CATEGORY_SET[def.value] = true
end

return AllocationEnums
