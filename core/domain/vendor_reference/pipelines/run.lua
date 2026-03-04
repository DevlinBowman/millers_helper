-- core/domain/vendor_reference/pipelines/run.lua
--
-- Orchestrated "main run":
--   - resolve target path
--   - if target file missing: write new snapshot
--   - if collision: load existing and reconcile (comparison), optionally write
--
-- Inputs:
--   vendor_name : string
--   data        : RuntimeBatch OR array[canonical_row] OR { boards = array[canonical_row] }
--   target      : string (dir or file path)
--   opts        : table
--
-- opts:
--   codec                 : string ("delimited" default)
--   overwrite_mode        : "if_changed"|"always"|"never" (passed to reconcile)
--   allow_new             : boolean (passed to reconcile)
--   price_fields          : array[string] (passed to reconcile)
--   write_on_collision    : boolean (default false)
--   created_at/updated_at/source : forwarded into Package.next_meta via update opts
--
-- Returns:
--   {
--     action = "created"|"compared"|"updated",
--     path   = string,
--     collision = boolean,
--     result = VendorReferenceResult,
--   }

local Registry   = require("core.domain.vendor_reference.registry")
local Update     = require("core.domain.vendor_reference.pipelines.update")
local Result     = require("core.domain.vendor_reference.result")

local Persist    = require("platform.persist").controller
local FS         = require("platform.io.registry").fs

local Run = {}

local function is_nonempty_string(x)
    return type(x) == "string" and x ~= ""
end

local function as_vendor_batch(data)
    -- Accept:
    --   RuntimeBatch { boards = [...] }
    --   { boards = [...] }
    --   array[canonical_row]
    if type(data) ~= "table" then
        return nil, "data_not_table"
    end

    if type(data.boards) == "table" then
        return data
    end

    -- Treat as raw boards array
    return { boards = data }
end

local function has_path_extension(path)
    -- simple heuristic: ".../.csv" or ".json" etc
    return path:match("%.[a-zA-Z0-9]+$") ~= nil
end

local function join_path(a, b)
    if a:sub(-1) == "/" then return a .. b end
    return a .. "/" .. b
end

local function resolve_target_path(target, vendor_name, opts)
    assert(is_nonempty_string(target), "target required")
    assert(is_nonempty_string(vendor_name), "vendor_name required")

    local codec = (opts and opts.codec) or "delimited"

    -- If user passed a file path, use it as-is.
    if has_path_extension(target) then
        return target, codec
    end

    -- Otherwise treat target as a directory; pick extension based on codec.
    local ext = "csv"
    if codec ~= "delimited" then
        -- If you later support "json"/"lua_object"/etc, map them here.
        ext = "json"
    end

    return join_path(target, vendor_name .. "." .. ext), codec
end

local function file_exists(path)
    -- Rely on registry FS if present; fall back to false if unavailable.
    if FS and FS.exists then
        return FS.exists(path) and true or false
    end
    -- Minimal fallback: try a read probe (non-strict).
    local ok = pcall(function()
        Persist.read(path, "raw")
    end)
    return ok
end

local function read_existing(path, codec, opts)
    -- For delimited snapshots, we expect existing rows array.
    -- Persist.read is assumed to return decoded payload.
    local payload = Persist.read(path, codec, opts)
    if type(payload) == "table" then
        -- Accept either {rows=...} or raw array
        if type(payload.rows) == "table" then return payload end
        return payload
    end
    return nil
end

local function write_rows(path, rows, codec, opts)
    -- delimited expects array of rows
    if codec == "delimited" then
        return Persist.write_strict(path, rows, codec, opts)
    end
    -- structured codecs: write full package if needed (not used in this run path)
    return Persist.write_strict(path, rows, codec, opts)
end

function Run.run(vendor_name, data, target, opts)
    opts = opts or {}

    local normalized = Registry.vendor.normalize_name(vendor_name)
    assert(normalized, "[vendor_reference.run] invalid vendor_name")

    local vendor_batch, err = as_vendor_batch(data)
    assert(vendor_batch and type(vendor_batch.boards) == "table",
        "[vendor_reference.run] invalid data: " .. tostring(err or "missing_boards"))

    local path, codec = resolve_target_path(target, normalized, opts)

    local collision = file_exists(path)

    if not collision then
        -- Create new snapshot from incoming canonical rows (no existing)
        local dto = Update.run({
            vendor_name     = normalized,
            incoming_rows   = vendor_batch.boards,
            existing_vendor = nil,
            opts            = opts,
        })

        local result = Result.new(dto)

        -- Write initial file
        write_rows(path, result:rows(), codec, opts)

        return {
            action    = "created",
            path      = path,
            collision = false,
            result    = result,
        }
    end

    -- Collision: load existing snapshot and reconcile
    local existing = read_existing(path, codec, opts)

    local dto = Update.run({
        vendor_name     = normalized,
        incoming_rows   = vendor_batch.boards,
        existing_vendor = existing,
        opts            = opts,
    })

    local result = Result.new(dto)

    if opts.write_on_collision then
        write_rows(path, result:rows(), codec, opts)
        return {
            action    = "updated",
            path      = path,
            collision = true,
            result    = result,
        }
    end

    return {
        action    = "compared",
        path      = path,
        collision = true,
        result    = result,
    }
end

return Run
