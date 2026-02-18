-- core/model/allocations/internal/resolve.lua
--
-- Pure inheritance resolution.

local Resolve = {}

local function deep_copy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = deep_copy(v)
    end
    return out
end

local function identity_key(entry)
    return table.concat({
        entry.scope or "",
        entry.party or "",
        entry.category or "",
        entry.basis or "",
    }, "::")
end

function Resolve.run(profile, presets)

    if not profile.extends then
        return deep_copy(profile)
    end

    local parent = presets[profile.extends]
    assert(parent,
        "Allocations.resolve(): unknown parent '" .. profile.extends .. "'")

    local resolved_parent = Resolve.run(parent, presets)

    local merged_index = {}

    for _, entry in ipairs(resolved_parent.allocations or {}) do
        merged_index[identity_key(entry)] = entry
    end

    for _, entry in ipairs(profile.allocations or {}) do
        merged_index[identity_key(entry)] = entry
    end

    local merged = {}
    for _, entry in pairs(merged_index) do
        table.insert(merged, entry)
    end

    local result = deep_copy(resolved_parent)
    result.profile_id = profile.profile_id
    result.description = profile.description or result.description
    result.allocations = merged

    return result
end

return Resolve
