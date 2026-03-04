local Scope = {}

Scope.VALUE = {

    BOARD = {
        kind   = "value",
        domain = "allocation.scope",
        name   = "board",
        type   = "symbol",
        description = "Per board (volume-based).",
    },

    ORDER = {
        kind   = "value",
        domain = "allocation.scope",
        name   = "order",
        type   = "symbol",
        description = "Whole order level.",
    },

    PROFIT = {
        kind   = "value",
        domain = "allocation.scope",
        name   = "profit",
        type   = "symbol",
        description = "Profit distribution stage.",
    },
}

return Scope
