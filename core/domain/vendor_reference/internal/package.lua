-- core/domain/vendor_reference/internal/package.lua
--
-- Vendor package (persistable) helpers.
-- Pure constructors / meta evolution.

local Package = {}

local function shallow_copy(t)
    if type(t) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(t) do
        out[k] = v
    end
    return out
end

local function normalize_meta(meta)
    meta = shallow_copy(meta)
    if type(meta.revision) ~= "number" then meta.revision = 0 end
    return meta
end

function Package.new(vendor_name, rows, meta)
    return {
        vendor = vendor_name,
        meta   = normalize_meta(meta),
        rows   = rows or {},
    }
end

function Package.next_meta(existing_meta, opts)
    existing_meta = normalize_meta(existing_meta)
    opts = opts or {}

    local next = shallow_copy(existing_meta)
    next.revision = (existing_meta.revision or 0) + 1

    -- Optional caller-provided timestamps/ids. Keep pure: no os.date().
    if opts.updated_at ~= nil then next.updated_at = opts.updated_at end
    if next.created_at == nil and opts.created_at ~= nil then next.created_at = opts.created_at end
    if opts.source ~= nil then next.source = opts.source end

    return next
end

return Package
