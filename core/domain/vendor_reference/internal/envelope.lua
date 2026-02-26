-- core/domain/vendor_reference/internal/envelope.lua
--
-- Vendor data envelope gate.
-- Projects canonical board rows into vendor snapshot rows.
-- Drops all non-vendor fields.

local Envelope = {}

local function copy_if_present(dst, src, field)
    local v = src[field]
    if v ~= nil then dst[field] = v end
end

local function is_nonempty_string(x)
    return type(x) == "string" and x ~= ""
end

local function is_number(x)
    return type(x) == "number"
end

-- Required for identity:
--   label (string)
-- Recommended for structure (not enforced here; conflicts handled during reconcile):
--   base_w, base_h, w, h, l, ct, tag, species, grade, moisture, surface, bf_each
function Envelope.project_row(canonical_row, vendor_name)
    if type(canonical_row) ~= "table" then
        return nil, "row_not_table"
    end

    local label = canonical_row.label
    if not is_nonempty_string(label) then
        return nil, "missing_label"
    end

    local out = {
        vendor = vendor_name,
        label  = label,
    }

    -- Identity geometry / physical
    copy_if_present(out, canonical_row, "base_w")
    copy_if_present(out, canonical_row, "base_h")
    copy_if_present(out, canonical_row, "w")
    copy_if_present(out, canonical_row, "h")
    copy_if_present(out, canonical_row, "l")
    copy_if_present(out, canonical_row, "ct")
    copy_if_present(out, canonical_row, "tag")

    -- Material identity
    copy_if_present(out, canonical_row, "species")
    copy_if_present(out, canonical_row, "grade")
    copy_if_present(out, canonical_row, "moisture")
    copy_if_present(out, canonical_row, "surface")

    -- Metrics
    copy_if_present(out, canonical_row, "bf_each")

    -- Pricing
    copy_if_present(out, canonical_row, "ea_price")
    copy_if_present(out, canonical_row, "bf_price")
    copy_if_present(out, canonical_row, "lf_price")

    return out, nil
end

function Envelope.project_rows(canonical_rows, vendor_name, sig, Signals)
    local projected = {}

    for i = 1, #canonical_rows do
        local row = canonical_rows[i]
        local out, code = Envelope.project_row(row, vendor_name)
        if out then
            projected[#projected + 1] = out
        else
            Signals.warn(sig, "row_dropped", code, { index = i })
            sig.stats.dropped_count = sig.stats.dropped_count + 1
        end
    end

    sig.stats.projected_count = #projected
    return projected
end

return Envelope
