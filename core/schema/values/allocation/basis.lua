local Basis = {}

Basis.VALUE = {

    PER_BF = {
        kind   = "value",
        domain = "allocation.basis",
        name   = "per_bf",
        type   = "symbol",
        description = "Rate per board foot.",
    },

    FIXED = {
        kind   = "value",
        domain = "allocation.basis",
        name   = "fixed",
        type   = "symbol",
        description = "Fixed amount.",
    },

    PERCENT = {
        kind   = "value",
        domain = "allocation.basis",
        name   = "percent",
        type   = "symbol",
        description = "Percentage of base.",
    },
}

return Basis
