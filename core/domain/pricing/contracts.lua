-- core/domain/pricing/contracts.lua
--
-- Authoritative contract description for the pricing domain service.
--
-- This module defines:
--   • the canonical execution context (env)
--   • strategy capability requirements
--   • minimal structural expectations for referenced objects
--
-- It contains NO logic. It only describes shapes.

local Contracts = {}

------------------------------------------------------------
-- SERVICE EXECUTION CONTEXT
------------------------------------------------------------

Contracts.context = {

    description = "Pricing execution context passed to strategies",

    fields = {

        basis = {
            required = true,
            description = "strategy identifier"
        },

        source = {
            required = true,
            description = "original input object"
        },

        boards = {
            required = true,
            description = "board envelope",

            envelope = {
                kind = "boards",
                required = {
                    "items"
                }
            }
        },

        vendor = {
            required = false,

            envelope = {
                kind = "vendor",
                required = {
                    "items"
                }
            }
        },

        allocations = {
            required = false
        },

        compare = {
            required = false
        },

        opts = {
            required = false
        }

    }

}

------------------------------------------------------------
-- STRATEGY REQUIREMENTS
------------------------------------------------------------

Contracts.strategies = {

    vendor_anchor = {

        description = "Vendor price anchored pricing",

        requires = {
            "boards",
            "vendor"
        },

        opts = {
            "percentage"
        }

    },

    reverse_order_value = {

        description = "Distribute order value across boards",

        requires = {
            "boards",
            "order_total"
        }

    }

}

------------------------------------------------------------
-- CAPABILITIES
------------------------------------------------------------

Contracts.capabilities = {

    boards = {
        description = "boards to be priced"
    },

    vendor = {
        description = "vendor reference boards"
    },

    allocations = {
        description = "allocation model"
    },

    compare = {
        description = "compare analysis results"
    },

    order_total = {
        description = "resolved total order value"
    }

}

------------------------------------------------------------
-- STRUCTURAL TYPES
------------------------------------------------------------

Contracts.types = {}

Contracts.types.board = {
    label = "string",
    ct    = "number?",
    bf    = "number?",
    bf_ea = "number?",
    h     = "number?",
    w     = "number?",
    l     = "number?"
}

Contracts.types.vendor_board = {
    label = "string",
    bf_price = "number?",
    ea_price = "number?",
    bf_ea = "number?"
}

------------------------------------------------------------

return Contracts
