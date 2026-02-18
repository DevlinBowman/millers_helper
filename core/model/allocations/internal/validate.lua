-- core/model/allocations/internal/validate.lua
--
-- Pure shape validation.

local Validate = {}

function Validate.run(profile, schema)

    assert(type(profile) == "table",
        "Allocations.validate(): profile must be table")

    assert(profile.profile_id,
        "Allocations.validate(): profile_id required")

    assert(type(profile.allocations) == "table",
        "Allocations.validate(): allocations must be table")

    for _, entry in ipairs(profile.allocations) do

        assert(entry.scope,
            "allocation entry missing scope")

        assert(entry.party,
            "allocation entry missing party")

        assert(entry.category,
            "allocation entry missing category")

        assert(type(entry.amount) == "number",
            "allocation entry amount must be number")

        assert(entry.basis,
            "allocation entry missing basis")
    end

    return profile
end

return Validate
