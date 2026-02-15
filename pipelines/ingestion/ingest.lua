local IO        = require("io.controller")
local Format    = require("format").controller
local Classify  = require("classify.controller")
local Compress  = require("pipelines.ingestion.compress")

local Trace     = require("tools.trace")
local Contract  = require("core.contract")

local ParserGate = require("format.validate.parser_gate")

local Ingest    = {}

----------------------------------------------------------------
-- Contract
----------------------------------------------------------------

Ingest.CONTRACT = {
    read = {
        in_ = {
            path = true,
            opts = false,
        },
        out = {
            codec = true,
            data  = true,
            meta  = true,
        },
    },
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function classify_rows(rows)
    local out = {}
    for i, row in ipairs(rows) do
        out[i] = Classify.row(row)
    end
    return out
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Ingest.read(path, opts)
    Trace.contract_enter("pipelines.ingestion.ingest.read")
    Trace.contract_in(Ingest.CONTRACT.read.in_)

    Contract.assert({ path = path, opts = opts }, Ingest.CONTRACT.read.in_)

    opts = opts or {}
    local stop_at = opts.stop_at

    ----------------------------------------------------------------
    -- Helper: canonical envelope builder
    ----------------------------------------------------------------

    local function build_out(data, io_meta, stage, extra_parse)
        local parse_meta = {
            stage  = stage,
            count  = type(data) == "table" and #data or 0,
        }

        if type(extra_parse) == "table" then
            for k, v in pairs(extra_parse) do
                parse_meta[k] = v
            end
        end

        local out = {
            codec = "objects",
            data  = data,
            meta  = {
                io    = io_meta or {},
                parse = parse_meta,
            },
        }

        Contract.assert(out, Ingest.CONTRACT.read.out)
        return out
    end

    ----------------------------------------------------------------
    -- IO
    ----------------------------------------------------------------

    local raw, read_err = IO.read(path)
    if not raw then
        Trace.contract_leave()
        return nil, read_err
    end

    local io_meta         = raw.meta and raw.meta.io or {}
    local transport_codec = raw.codec
    local input_data      = raw.data

    if stop_at == "io" then
        Contract.assert(raw, Ingest.CONTRACT.read.out)
        Trace.contract_leave()
        return raw
    end

    ----------------------------------------------------------------
    -- Decode (parser + validation now handled inside format)
    ----------------------------------------------------------------

    local decoded, decode_err =
        Format.decode(transport_codec, input_data)

    if not decoded then
        Trace.contract_leave()
        return nil, decode_err
    end

    local objects = decoded.data

    if stop_at == "decode" then
        local out = build_out(
            objects,
            io_meta,
            "decode",
            { transport_codec = transport_codec }
        )
        Trace.contract_leave()
        return out
    end

    ----------------------------------------------------------------
    -- Classification
    ----------------------------------------------------------------

    local classified = classify_rows(objects)

    if stop_at == "classify" then
        local out = build_out(
            classified,
            io_meta,
            "classify",
            { transport_codec = transport_codec }
        )
        Trace.contract_leave()
        return out
    end

    ----------------------------------------------------------------
    -- Compression
    ----------------------------------------------------------------

    local identity_key = "order_number"
    local compressed   =
        Compress.run(classified, identity_key)

    if stop_at == "compress" then
        local out = build_out(
            compressed,
            io_meta,
            "compress",
            {
                transport_codec = transport_codec,
                identity_key    = identity_key,
            }
        )
        Trace.contract_leave()
        return out
    end

    ----------------------------------------------------------------
    -- Final Output
    ----------------------------------------------------------------

    local out = build_out(
        compressed,
        io_meta,
        "done",
        {
            transport_codec = transport_codec,
            identity_key    = identity_key,
        }
    )

    Trace.contract_out(
        Ingest.CONTRACT.read.out,
        "pipelines.ingestion.ingest",
        "caller"
    )

    Trace.contract_leave()
    return out
end

return Ingest
