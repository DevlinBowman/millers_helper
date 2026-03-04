local Allocation = {}

Allocation.FIELD = {

    ------------------------------------------------------------
    -- Allocation Profile
    ------------------------------------------------------------

    PROFILE_ID = {
        kind   = "field",
        domain = "allocation_profile",
        name   = "profile_id",
        type   = "string",
        required = true,
        authority = "authoritative",
        mutable = false,
        description = "Unique allocation profile identifier.",
    },

    DESCRIPTION = {
        kind   = "field",
        domain = "allocation_profile",
        name   = "description",
        type   = "string",
        required = false,
        authority = "authoritative",
        mutable = true,
        description = "Human-readable description.",
    },

    EXTENDS = {
        kind   = "field",
        domain = "allocation_profile",
        name   = "extends",
        type   = "string",
        required = false,
        authority = "authoritative",
        mutable = false,
        description = "Parent profile identifier.",
    },

    ALLOCATIONS = {
        kind   = "field",
        domain = "allocation_profile",
        name   = "allocations",
        type   = "table",
        required = true,
        authority = "authoritative",
        mutable = true,
        description = "List of allocation entries.",
    },

    ------------------------------------------------------------
    -- Allocation Entry
    ------------------------------------------------------------

    ENTRY_SCOPE = {
        kind   = "field",
        domain = "allocation_entry",
        name   = "scope",
        type   = "symbol",
        required = true,
        reference = "allocation.scope",
        authority = "authoritative",
        mutable = false,
        description = "Application scope of allocation.",
    },

    ENTRY_PARTY = {
        kind   = "field",
        domain = "allocation_entry",
        name   = "party",
        type   = "string",
        required = true,
        authority = "authoritative",
        mutable = false,
        description = "Receiving party.",
    },

    ENTRY_CATEGORY = {
        kind   = "field",
        domain = "allocation_entry",
        name   = "category",
        type   = "string",
        required = true,
        authority = "authoritative",
        mutable = false,
        description = "Cost classification.",
    },

    ENTRY_AMOUNT = {
        kind   = "field",
        domain = "allocation_entry",
        name   = "amount",
        type   = "number",
        required = true,
        authority = "authoritative",
        mutable = false,
        description = "Rate or percentage amount.",
    },

    ENTRY_BASIS = {
        kind   = "field",
        domain = "allocation_entry",
        name   = "basis",
        type   = "symbol",
        required = true,
        reference = "allocation.basis",
        authority = "authoritative",
        mutable = false,
        description = "Rate interpretation method.",
    },

    ENTRY_PRIORITY = {
        kind   = "field",
        domain = "allocation_entry",
        name   = "priority",
        type   = "number",
        required = false,
        default = 0,
        authority = "authoritative",
        mutable = false,
        description = "Evaluation order.",
    },
}

return Allocation
