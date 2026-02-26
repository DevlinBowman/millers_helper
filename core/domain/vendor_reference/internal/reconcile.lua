-- core/domain/vendor_reference/internal/reconcile.lua
--
-- Pure reconciliation engine.
-- - identity is label
-- - structural fields must not drift for same label
-- - price fields update per-field (only when incoming is non-nil)
-- - overwrite policy controls whether differing prices may overwrite

local Reconcile = {}

local function index_by_label(rows, Key, sig, Signals)
    local idx = {}
    for i = 1, #rows do
        local row = rows[i]
        local k = Key.build(row)
        if not k then
            Signals.warn(sig, "existing_row_invalid", "missing_label", { index = i })
        elseif idx[k] then
            -- Duplicate labels in existing snapshot is a data integrity issue
            Signals.warn(sig, "existing_duplicate_label", "duplicate_label", { label = k, first = idx[k], second = i })
        else
            idx[k] = i
        end
    end
    return idx
end

local function structural_conflicts(existing_row, incoming_row)
    -- For same label, these fields should not drift.
    -- If they drift, it is not a price update; it is a conflict.
    local fields = {
        "base_w", "base_h", "w", "h", "l", "ct", "tag",
        "species", "grade", "moisture", "surface", "bf_each",
    }

    local diffs = {}

    for i = 1, #fields do
        local f = fields[i]
        local a = existing_row[f]
        local b = incoming_row[f]

        -- Only consider conflicts when both sides have a value and they differ.
        if a ~= nil and b ~= nil and a ~= b then
            diffs[#diffs + 1] = { field = f, existing = a, incoming = b }
        end
    end

    return diffs
end

local function get_price_fields(opts)
    if opts and type(opts.price_fields) == "table" and #opts.price_fields > 0 then
        return opts.price_fields
    end
    return { "ea_price", "bf_price", "lf_price" }
end

local function get_overwrite_mode(opts)
    local mode = opts and opts.overwrite_mode or "if_changed"
    if mode ~= "if_changed" and mode ~= "always" and mode ~= "never" then
        return "if_changed"
    end
    return mode
end

local function allow_new(opts)
    if opts and opts.allow_new == false then return false end
    return true
end

local function apply_price_updates(existing_row, incoming_row, price_fields, overwrite_mode)
    -- Returns: changed(boolean), field_updates_count(int), deltas(array)
    local changed = false
    local updates = 0
    local deltas  = {}

    for i = 1, #price_fields do
        local f = price_fields[i]
        local incoming_val = incoming_row[f]

        -- Never overwrite with nil (partial feeds should not erase stored values)
        if incoming_val ~= nil then
            local existing_val = existing_row[f]
            if existing_val ~= incoming_val then
                if overwrite_mode == "never" then
                    deltas[#deltas + 1] = { field = f, from = existing_val, to = incoming_val, action = "conflict" }
                else
                    -- "if_changed" and "always" both allow updates when different.
                    existing_row[f] = incoming_val
                    changed = true
                    updates = updates + 1
                    deltas[#deltas + 1] = { field = f, from = existing_val, to = incoming_val, action = "updated" }
                end
            end
        end
    end

    return changed, updates, deltas
end

function Reconcile.run(existing_rows, incoming_rows, deps)
    local Key     = deps.Key
    local Signals = deps.Signals
    local sig     = deps.sig
    local opts    = deps.opts or {}

    local price_fields   = get_price_fields(opts)
    local overwrite_mode = get_overwrite_mode(opts)
    local allow_new_rows = allow_new(opts)

    -- Copy existing rows into merged output (shallow copy of array; rows are mutated in-place for updates)
    local merged = {}
    for i = 1, #existing_rows do
        merged[i] = existing_rows[i]
    end

    local existing_index = index_by_label(merged, Key, sig, Signals)

    local report = {
        inserted  = {},
        updated   = {},
        unchanged = {},
        skipped   = {},
        conflicts = {},
    }

    for i = 1, #incoming_rows do
        local in_row = incoming_rows[i]
        local label = Key.build(in_row)

        if not label then
            Signals.warn(sig, "incoming_row_invalid", "missing_label", { index = i })
            sig.stats.dropped_count = sig.stats.dropped_count + 1
            goto continue
        end

        local at = existing_index[label]

        if not at then
            if allow_new_rows then
                merged[#merged + 1] = in_row
                existing_index[label] = #merged

                sig.stats.inserted_count = sig.stats.inserted_count + 1
                report.inserted[#report.inserted + 1] = { label = label }
            else
                sig.stats.skipped_count = sig.stats.skipped_count + 1
                report.skipped[#report.skipped + 1] = { label = label, reason = "allow_new=false" }
            end
            goto continue
        end

        local cur = merged[at]

        -- Gate vendor mismatch: existing snapshot should belong to same vendor
        if cur.vendor ~= in_row.vendor then
            sig.stats.conflict_count = sig.stats.conflict_count + 1
            report.conflicts[#report.conflicts + 1] = {
                label  = label,
                reason = "vendor_mismatch",
                existing_vendor = cur.vendor,
                incoming_vendor = in_row.vendor,
            }
            Signals.warn(sig, "vendor_mismatch", "existing vendor differs from incoming vendor for label", {
                label = label,
                existing_vendor = cur.vendor,
                incoming_vendor = in_row.vendor,
            })
            goto continue
        end

        -- Structural conflict detection
        local diffs = structural_conflicts(cur, in_row)
        if #diffs > 0 then
            sig.stats.conflict_count = sig.stats.conflict_count + 1
            report.conflicts[#report.conflicts + 1] = { label = label, reason = "structural_drift", diffs = diffs }

            Signals.warn(sig, "structural_drift", "structural fields differ for same label; prices not applied", {
                label = label,
                diffs = diffs,
            })
            goto continue
        end

        -- Apply price updates per-field
        local changed, field_updates, deltas = apply_price_updates(cur, in_row, price_fields, overwrite_mode)

        if changed then
            sig.stats.updated_count = sig.stats.updated_count + 1
            sig.stats.price_field_updates = sig.stats.price_field_updates + field_updates

            report.updated[#report.updated + 1] = {
                label  = label,
                deltas = deltas,
            }

            for d = 1, #deltas do
                local delta = deltas[d]
                if delta.action == "updated" then
                    Signals.info(sig, "price_changed", "price field updated for " .. label, delta)
                end
            end
        else
            -- If overwrite_mode == "never" and deltas contain conflicts, record conflict
            local has_conflict = false
            for d = 1, #deltas do
                if deltas[d].action == "conflict" then
                    has_conflict = true
                    break
                end
            end

            if has_conflict then
                sig.stats.conflict_count = sig.stats.conflict_count + 1
                report.conflicts[#report.conflicts + 1] = { label = label, reason = "price_conflict", deltas = deltas }

                Signals.warn(sig, "price_conflict", "incoming prices differ but overwrite_mode=never", {
                    label = label,
                    deltas = deltas,
                })
            else
                sig.stats.unchanged_count = sig.stats.unchanged_count + 1
                report.unchanged[#report.unchanged + 1] = { label = label }
            end
        end

        ::continue::
    end

    -- Stable order (deterministic output)
    table.sort(merged, function(a, b)
        local ka = a and a.label or ""
        local kb = b and b.label or ""
        return ka < kb
    end)

    return merged, report
end

return Reconcile
