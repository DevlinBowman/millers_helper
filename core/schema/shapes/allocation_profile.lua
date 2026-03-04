-- core/shapes/allocation_profile.lua
--
-- Allocation Profile Shape
-- Membership only.

local AllocationProfile = {}

AllocationProfile.SHAPE = {
    domain = "allocation_profile",
    fields = {
        "profile_id",
        "description",
        "extends",
        "allocations",
    },
}

return AllocationProfile
