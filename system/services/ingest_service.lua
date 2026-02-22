-- system/services/ingest_service.lua
--
-- IngestService
-- =============
--
-- General-purpose ingestion / formalization service.
--
-- Responsibilities:
--   • Load arbitrary inputs via RuntimeController
--   • Extract canonical batches
--   • Flatten structured order/board bundles
--   • Encode via platform.format
--   • Write via platform.io
--
-- It explicitly does NOT:
--   • Interact with State
--   • Interact with RuntimeHub
--   • Contain business rules
--   • Contain ledger logic
--
-- This service is intentionally stateless and standalone.
-- It is suitable for CLI utilities, batch conversion, and tooling.

local RuntimeController = require("core.domain.runtime.controller")
local Format            = require("platform.format.controller")
local IO                = require("platform.io.controller")

---@class IngestOptions
---@field flatten? boolean        -- If false, order remains nested
---@field exclude? string[]       -- Keys to remove from output objects

---@class IngestRequest
---@field inputs any              -- Runtime load input(s)
---@field output_path string      -- Destination file path
---@field codec? string           -- Encoding codec (default: "json")
---@field opts? IngestOptions

---@class IngestResponse
---@field ok boolean
---@field count? number
---@field path? string
---@field error? string

---@class IngestService
local IngestService = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

---@param dst table
---@param src table
local function merge(dst, src)
    for k, v in pairs(src) do
        dst[k] = v
    end
end

---@param obj table
---@param exclude? string[]
---@return table
local function exclude_fields(obj, exclude)
    if not exclude then
        return obj
    end

    for _, key in ipairs(exclude) do
        obj[key] = nil
    end

    return obj
end

----------------------------------------------------------------
-- flatten_batch()
--
-- Converts a canonical batch:
--
--   {
--     order = {...},
--     boards = { {...}, {...} }
--   }
--
-- Into flat object rows:
--
--   {
--     { <order fields merged>, <board fields> },
--     ...
--   }
--
-- Behavior:
--   • If opts.flatten ~= false → merge order into each row
--   • If opts.flatten == false → keep order nested under obj.order
--   • Applies optional field exclusion
----------------------------------------------------------------

---@param batch table
---@param opts IngestOptions
---@return table[]
local function flatten_batch(batch, opts)

    local objects = {}

    local order = batch.order or {}

    for _, board in ipairs(batch.boards or {}) do
        local obj = {}

        if opts.flatten ~= false then
            merge(obj, order)
        else
            obj.order = order
        end

        merge(obj, board)

        exclude_fields(obj, opts.exclude)

        objects[#objects + 1] = obj
    end

    return objects
end

----------------------------------------------------------------
-- handle()
----------------------------------------------------------------
-- Ingest pipeline:
--
--   inputs
--     ↓
--   RuntimeController.load()
--     ↓
--   batches()
--     ↓
--   flatten_batch()
--     ↓
--   Format.encode()
--     ↓
--   IO.write()
--
-- Failure model:
--   • Never throws
--   • Returns { ok=false, error=... }

---@param req IngestRequest
---@return IngestResponse
function IngestService.handle(req)

    if not req or type(req) ~= "table" then
        return { ok = false, error = "invalid request" }
    end

    local inputs      = req.inputs
    local output_path = req.output_path
    local codec       = req.codec or "json"
    local opts        = req.opts or {}

    if not inputs then
        return { ok = false, error = "missing inputs" }
    end

    if not output_path then
        return { ok = false, error = "missing output_path" }
    end

    ------------------------------------------------------------
    -- Load runtime
    ------------------------------------------------------------

    local runtime = RuntimeController.load(inputs, {})

    local batches = runtime:batches()
    if not batches or #batches == 0 then
        return { ok = false, error = "no batches loaded" }
    end

    ------------------------------------------------------------
    -- Transform batches → flat object rows
    ------------------------------------------------------------

    local objects = {}

    for _, batch in ipairs(batches) do
        local flattened = flatten_batch(batch, opts)

        for _, obj in ipairs(flattened) do
            objects[#objects + 1] = obj
        end
    end

    ------------------------------------------------------------
    -- Encode
    ------------------------------------------------------------

    local encoded, encode_err =
        Format.encode(codec, objects)

    if not encoded then
        return { ok = false, error = encode_err }
    end

    ------------------------------------------------------------
    -- Write
    ------------------------------------------------------------

    local meta, write_err =
        IO.write(output_path, encoded)

    if not meta then
        return { ok = false, error = write_err }
    end

    return {
        ok    = true,
        count = #objects,
        path  = output_path
    }
end

return IngestService
