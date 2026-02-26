-- core/domain/vendor_reference/pipelines/update.lua
--
-- Orchestrates:
-- - create signals
-- - project incoming canonical rows into vendor envelope
-- - reconcile against existing vendor snapshot
-- - return new vendor PACKAGE + report + signals

local Registry = require("core.domain.vendor_reference.registry")

local Pipeline = {}

local function resolve_existing(existing_vendor)
    -- Accept:
    --   nil
    --   array[vendor_row]
    --   { vendor=string, meta=table, rows=array[vendor_row] }
    if existing_vendor == nil then
        return {}, nil
    end

    if type(existing_vendor) ~= "table" then
        return {}, nil
    end

    if type(existing_vendor.rows) == "table" then
        return existing_vendor.rows, existing_vendor.meta
    end

    -- Treat as raw rows array
    return existing_vendor, nil
end

function Pipeline.run(req)
    local Signals   = Registry.signals
    local Envelope  = Registry.envelope
    local Key       = Registry.key
    local Reconcile = Registry.reconcile
    local Package   = Registry.package

    local vendor_name    = req.vendor_name
    local incoming_rows  = req.incoming_rows or {}
    local existing_vendor = req.existing_vendor
    local opts           = req.opts or {}

    local existing_rows, existing_meta = resolve_existing(existing_vendor)

    local sig = Signals.new()

    sig.stats.incoming_count = #incoming_rows
    sig.stats.existing_count = #existing_rows

    -- Project canonical input -> vendor envelope (strict gating)
    local projected = Envelope.project_rows(incoming_rows, vendor_name, sig, Signals)

    -- Reconcile with policy
    local merged, report = Reconcile.run(existing_rows, projected, {
        Key     = Key,
        Signals = Signals,
        sig     = sig,
        opts    = opts,
    })

    local next_meta = Package.next_meta(existing_meta, opts)
    local vendor_package = Package.new(vendor_name, merged, next_meta)

    return {
        vendor        = vendor_name,
        vendor_package = vendor_package, -- NEW: persistable artifact
        rows          = merged,          -- preserved for legacy callers
        report        = report,
        signals       = sig,
    }
end

return Pipeline
