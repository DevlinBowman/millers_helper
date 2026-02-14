-- pipelines/ingest.lua
--
-- Cross-domain ingestion pipeline.
--
-- Responsibility:
--   • Compose IO + format + parsers
--   • Decide when structure must be synthesized
--   • Normalize everything to canonical objects
--
-- This layer is orchestration only.

local IO       = require("io.controller")
local Format   = require("format").controller
local Parsers  = require("parsers").controller

local Trace    = require("tools.trace")
local Contract = require("core.contract")

local Ingest = {}

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
            codec = true,  -- "objects"
            data  = true,  -- object[]
            meta  = true,  -- table (must include io provenance)
        },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param path string
---@param opts table|nil
---@return table|nil result
---@return string|nil err
function Ingest.read(path, opts)
    Trace.contract_enter("pipelines.ingest.read")
    Trace.contract_in(Ingest.CONTRACT.read.in_)

    Contract.assert(
        { path = path, opts = opts },
        Ingest.CONTRACT.read.in_
    )

    opts = opts or {}

    ----------------------------------------------------------------
    -- IO boundary
    ----------------------------------------------------------------
    local raw, read_err = IO.read(path)
    if not raw then
        Trace.contract_leave()
        return nil, read_err
    end

    local codec   = raw.codec
    local input   = raw.data
    local io_meta = raw.meta and raw.meta.io or {}

    ----------------------------------------------------------------
    -- Structured codecs → objects
    ----------------------------------------------------------------
    if codec ~= "lines" then
        local decoded, decode_err = Format.decode(codec, input)
        if not decoded then
            Trace.contract_leave()
            return nil, decode_err
        end

        local out = {
            codec = "objects",
            data  = decoded.data,
            meta  = {
                io = io_meta,
                parse = {
                    source = codec,
                    count  = type(decoded.data) == "table" and #decoded.data or 0,
                },
            },
        }

        Trace.contract_out(Ingest.CONTRACT.read.out, "pipelines.ingest", "caller")
        Contract.assert(out, Ingest.CONTRACT.read.out)
        Trace.contract_leave()

        return out
    end

    ----------------------------------------------------------------
    -- Freeform text → synthesize objects
    ----------------------------------------------------------------
    local parsed, parse_err = Parsers.parse_text(input, opts)
    if not parsed then
        Trace.contract_leave()
        return nil, parse_err or "text parser failed"
    end

    if type(parsed) ~= "table" or type(parsed.data) ~= "table" then
        Trace.contract_leave()
        return nil, "text parser returned invalid shape (expected { data=object[], meta=table })"
    end

    local out = {
        codec = "objects",
        data  = parsed.data,
        meta  = {
            io    = io_meta,
            parse = parsed.meta or {
                parser = "text_pipeline",
                count  = #parsed.data,
            },
        },
    }

    Trace.contract_out(Ingest.CONTRACT.read.out, "pipelines.ingest", "caller")
    Contract.assert(out, Ingest.CONTRACT.read.out)
    Trace.contract_leave()

    return out
end

return Ingest
