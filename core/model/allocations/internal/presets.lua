-- core/model/allocations/internal/presets.lua
--
-- Static cost structure presets.

local Presets = {}

----------------------------------------------------------------
-- Standard Mill Split
----------------------------------------------------------------

Presets.standard_split = {
    profile_id = "standard_split",
    description = "Standard stumpage + labor + 65/35 profit",

    allocations = {

        -- Stumpage E
        {
            category = "stumpage",
            party    = "Landowner1",
            scope    = "board",
            amount   = 0.40,
            basis    = "per_bf",
            priority = 10,
        },
        -- Stumpage J
        {
            category = "stumpage",
            party    = "Landowner2",
            scope    = "board",
            amount   = 0.40,
            basis    = "per_bf",
            priority = 10,
        },
        -- Milling Labor
        {
            category = "labor",
            party    = "Miller",
            scope    = "board",
            amount   = 1.30,
            basis    = "per_bf",
            priority = 20,
        },
        -- Admin Comission
        {
            category = "admin",
            party    = "Miller",
            scope    = "board",
            amount   = .30,
            basis    = "per_bf",
            priority = 20,
        },
        -- land use E
        {
            category = "land_use",
            party    = "Landowner1",
            scope    = "board",
            amount   = 0.05,
            basis    = "per_bf",
            priority = 20,
        },
        -- land use J
        {
            category = "land_use",
            scope    = "board",
            party    = "Landowner2",
            amount   = 0.05,
            basis    = "per_bf",
            priority = 20,
        },

        -- Profit party 1
        {
            scope    = "profit",
            party    = "Landowner1",
            category = "profit",
            amount   = 65,
            basis    = "percent",
            priority = 100,
        },

        {
            scope    = "profit",
            party    = "Miller",
            category = "profit",
            amount   = 35,
            basis    = "percent",
            priority = 100,
        },
    }
}

----------------------------------------------------------------
-- Delivery Add-on
----------------------------------------------------------------

Presets.delivery_addon = {
    profile_id = "delivery_addon",
    description = "Adds fixed delivery cost",
    extends = "standard_split",

    allocations = {
        {
            scope    = "order",
            party    = "driver",
            category = "delivery",
            amount   = 250,
            basis    = "fixed",
            priority = 5,
        }
    }
}

return Presets
