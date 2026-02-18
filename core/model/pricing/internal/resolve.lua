-- core/model/pricing/internal/resolve.lua
--
-- Pure inheritance resolution for pricing profiles.

local Resolve = {}

local function deep_copy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do out[k] = deep_copy(v) end
    return out
end

local function deep_merge(parent, child)
    local out = deep_copy(parent)
    for k, v in pairs(child) do
        if type(v) == "table" and type(out[k]) == "table" then
            out[k] = deep_merge(out[k], v)
        else
            out[k] = v
        end
    end
    return out
end

function Resolve.run(profile, presets)
    assert(type(profile) == "table", "Resolve.run(): profile required")
    assert(type(presets) == "table", "Resolve.run(): presets required")

    if not profile.extends then
        return deep_copy(profile)
    end

    local parent = presets[profile.extends]
    assert(parent, "unknown parent pricing profile: " .. profile.extends)

    local resolved_parent = Resolve.run(parent, presets)
    local merged = deep_merge(resolved_parent, profile)

    merged.profile_id = profile.profile_id
    merged.description = profile.description or merged.description

    return merged
end

return Resolve
