-- system/services/ingest_service.lua
--
-- General ingestion / formalization service.
-- Loads raw inputs via runtime domain and exports structured output.
--
-- No business rules.
-- No ledger logic.

local RuntimeController = require("core.domain.runtime.controller")
local Format            = require("platform.format.controller")
local IO                = require("platform.io.controller")

local IngestService = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function merge(dst, src)
    for k, v in pairs(src) do
        dst[k] = v
    end
end

local function exclude_fields(obj, exclude)
    if not exclude then
        return obj
    end

    for _, key in ipairs(exclude) do
        obj[key] = nil
    end

    return obj
end

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
-- Public API
----------------------------------------------------------------

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
    -- Transform
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
        ok = true,
        count = #objects,
        path  = output_path
    }
end

return IngestService
