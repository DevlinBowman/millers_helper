-- core/shapes/allocation_entry.lua
--
-- Allocation Entry Shape
-- Membership only.

local AllocationEntry = {}

AllocationEntry.SHAPE = {
    domain = "allocation_entry",
    fields = {
        "scope",
        "party",
        "category",
        "amount",
        "basis",
        "priority",
    },
}

return AllocationEntry
