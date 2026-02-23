-- system/services/vendor_reference_service.lua
--
-- Vendor Reference Orchestration (v3)
--
-- Responsibilities:
--   • Normalize vendor name
--   • Load existing vendor snapshot rows
--   • Reconcile via VendorDomain.update()
--   • Control export column ordering
--   • Persist ordered rows (FileGateway)
--
-- Domain owns reconciliation.
-- Service owns export shape + column order.

local VendorDomain = require("core.domain.vendor_reference").controller
local FileGateway  = require("system.infrastructure.file_gateway")
local Storage      = require("system.infrastructure.storage.controller")
local FS           = require("platform.io.registry").fs
local Runtime      = require("core.domain.runtime.controller")

local Service = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function ok(payload)
    payload.ok = true
    return payload
end

local function fail(msg, ctx)
    return { ok = false, error = msg, ctx = ctx }
end

local function normalize_vendor(name)
    return VendorDomain.normalize_vendor(name)
end

local function vendor_root()
    return Storage.vendor_cache_root()
end

local function vendor_path(vendor)
    return vendor_root() .. "/" .. vendor .. ".csv"
end

local function flatten_runtime_rows(runtime)
    local rows = {}
    for _, batch in ipairs(runtime:batches() or {}) do
        for _, board in ipairs(batch.boards or {}) do
            rows[#rows + 1] = board
        end
    end
    return rows
end

----------------------------------------------------------------
-- Export Column Order (Authoritative)
----------------------------------------------------------------

local EXPORT_COLUMNS = {
    "vendor",
    "label",

    "base_w",
    "base_h",
    "w",
    "h",
    "l",
    "ct",
    "tag",

    "species",
    "grade",
    "moisture",
    "surface",

    "bf_each",

    "ea_price",
    "bf_price",
    "lf_price",
}

local function shape_for_export(rows)
    local shaped = {}

    for i = 1, #rows do
        local src = rows[i]
        local dst = {}

        for c = 1, #EXPORT_COLUMNS do
            local key = EXPORT_COLUMNS[c]
            dst[key] = src[key]
        end

        shaped[#shaped + 1] = dst
    end

    return shaped
end

----------------------------------------------------------------
-- handle(req)
----------------------------------------------------------------

function Service.handle(req)

    if type(req) ~= "table" then
        return fail("invalid request")
    end

    local action = req.action
    if type(action) ~= "string" then
        return fail("missing action")
    end

    ------------------------------------------------------------
    -- LIST
    ------------------------------------------------------------

    if action == "list" then
        local root = vendor_root()

        if not FS.dir_exists(root) then
            return ok({ vendors = {} })
        end

        local entries, err = FS.list_dir(root)
        if not entries then return fail("list failed", { err = err }) end

        local names = {}

        for _, entry in ipairs(entries) do
            local filename = FS.get_filename(entry) or entry
            local name = filename:match("^(.*)%.csv$")
            if name then
                names[#names + 1] = name
            end
        end

        table.sort(names)
        return ok({ vendors = names })
    end

    ------------------------------------------------------------
    -- Vendor Required
    ------------------------------------------------------------

    local vendor = req.vendor
    if type(vendor) ~= "string" then
        return fail("missing vendor")
    end

    local normalized = normalize_vendor(vendor)
    if not normalized then
        return fail("invalid vendor")
    end

    local path = vendor_path(normalized)

    ------------------------------------------------------------
    -- LOAD
    ------------------------------------------------------------

    if action == "load" then

        if not FS.file_exists(path) then
            return ok({ vendor = normalized, rows = {} })
        end

        local runtime = Runtime.load(path, {
            category = "board",
            name     = normalized
        })

        return ok({
            vendor = normalized,
            rows   = flatten_runtime_rows(runtime),
        })
    end

    ------------------------------------------------------------
    -- DELETE
    ------------------------------------------------------------

    if action == "delete" then

        if not FS.file_exists(path) then
            return ok({ deleted = true })
        end

        local ok_remove, err = FS.remove_file(path)
        if not ok_remove then
            return fail("delete failed", { err = err })
        end

        return ok({ deleted = true })
    end

    ------------------------------------------------------------
    -- UPDATE (no persist)
    ------------------------------------------------------------

    if action == "update" then

        local incoming = req.rows or req.boards
        if type(incoming) ~= "table" then
            return fail("update requires rows or boards")
        end

        local existing = {}
        if FS.file_exists(path) then
            local runtime = Runtime.load(path, {
                category = "board",
                name     = normalized
            })
            existing = flatten_runtime_rows(runtime)
        end

        local result = VendorDomain.update(normalized, incoming, existing, req.opts)

        return ok({
            vendor  = normalized,
            rows    = result.rows,
            report  = result.report,
            signals = result.signals,
        })
    end

    ------------------------------------------------------------
    -- COMMIT (reconcile + persist with strict column order)
    ------------------------------------------------------------

    if action == "commit" then

        local incoming = req.rows or req.boards
        if type(incoming) ~= "table" then
            return fail("commit requires rows or boards")
        end

        local existing = {}
        if FS.file_exists(path) then
            local runtime = Runtime.load(path, {
                category = "board",
                name     = normalized
            })
            existing = flatten_runtime_rows(runtime)
        end

        local result = VendorDomain.update(normalized, incoming, existing, req.opts)

        local shaped = shape_for_export(result.rows)

        local meta, err = FileGateway.write_delimited(path, shaped)
        if not meta then
            return fail("commit failed", { err = err })
        end

        return ok({
            vendor    = normalized,
            committed = true,
            rows      = shaped,
            report    = result.report,
            signals   = result.signals,
        })
    end

    return fail("unknown action")
end

return Service
