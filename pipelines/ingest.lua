-- pipelines/ingest.lua
--
-- Cross-domain ingestion pipeline.
--
-- Responsibility:
--   • Compose IO + format + parsers
--   • Normalize everything to canonical object rows
--   • Apply alias resolution + ownership partition (classify)
--   • Aggregate into 1 Order ctx + N Board ctxs
--   • Apply domain builders ONCE (here) to produce canonical objects
--
-- This layer is orchestration only.

local IO       = require("io.controller")
local Format   = require("format").controller
local Parsers  = require("parsers").controller
local Classify = require("classify.controller")

local BoardBuild = require("core.model.board.pipelines.build")
local OrderBuild = require("core.model.order.pipelines.build")

local BoardRegistry = require("core.model.board.registry")
local OrderRegistry = require("core.model.order.registry")

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
            order  = true, -- built Order
            boards = true, -- built Board[]
            meta   = true, -- provenance only
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

local function aggregate_order_context(classified_rows)
    local ctx = {}
    for _, row in ipairs(classified_rows) do
        for k, v in pairs(row.order or {}) do
            ctx[k] = v
        end
    end
    return ctx
end

local function extract_board_contexts(classified_rows)
    local boards = {}
    for _, row in ipairs(classified_rows) do
        local ctx = row.board
        if ctx
            and type(ctx) == "table"
            and ctx.base_h
            and ctx.base_w
            and ctx.l
        then
            boards[#boards + 1] = ctx
        end
    end
    return boards
end

-- Key fix:
-- If input already contains derived keys (bf_ea, bf_batch, h/w, label/id, etc),
-- do NOT feed them into the model as "unknown".
-- Only pass AUTHORITATIVE keys + truly unknown passthrough keys.
local function sanitize_ctx_by_schema(ctx, schema)
    assert(type(ctx) == "table", "sanitize_ctx_by_schema(): ctx table required")
    assert(schema and schema.fields and schema.ROLES, "sanitize_ctx_by_schema(): schema required")

    local out = {}

    for k, v in pairs(ctx) do
        local def = schema.fields[k]

        if def then
            -- Keep only AUTHORITATIVE inputs; drop derived keys here.
            if def.role == schema.ROLES.AUTHORITATIVE then
                out[k] = v
            end
        else
            -- Preserve truly unknown passthrough keys (lossless ingest).
            out[k] = v
        end
    end

    -- Never treat identity fields as input (even if upstream provided them).
    out.id = nil
    out.label = nil

    return out
end

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

    Contract.assert({ path = path, opts = opts }, Ingest.CONTRACT.read.in_)

    assert(type(path) == "string", "Ingest.read(): path string required")
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
    -- Decode / Parse to canonical object rows
    ----------------------------------------------------------------
    local canonical_rows

    if codec ~= "lines" then
        local decoded, decode_err = Format.decode(codec, input)
        if not decoded then
            Trace.contract_leave()
            return nil, decode_err
        end
        canonical_rows = decoded.data
    else
        local parsed, parse_err = Parsers.parse_text(input, opts)
        if not parsed then
            Trace.contract_leave()
            return nil, parse_err or "text parser failed"
        end
        if type(parsed) ~= "table" or type(parsed.data) ~= "table" then
            Trace.contract_leave()
            return nil, "text parser returned invalid shape (expected { data=object[] })"
        end
        canonical_rows = parsed.data
    end

    ----------------------------------------------------------------
    -- Canonical alias normalization + ownership partition
    ----------------------------------------------------------------
    local classified_rows = classify_rows(canonical_rows)

    ----------------------------------------------------------------
    -- Aggregate into 1 Order ctx + N Board ctxs
    ----------------------------------------------------------------
    local order_ctx  = aggregate_order_context(classified_rows)
    local board_ctxs = extract_board_contexts(classified_rows)

    ----------------------------------------------------------------
    -- Apply Domain Builders (ONLY HERE)
    ----------------------------------------------------------------

    -- Sanitize contexts so derived keys do not become "unknown" in models
    order_ctx = sanitize_ctx_by_schema(order_ctx, OrderRegistry.schema)

    local order = OrderBuild.run(order_ctx)

    local boards = {}
    for i, ctx in ipairs(board_ctxs) do
        ctx = sanitize_ctx_by_schema(ctx, BoardRegistry.schema)
        boards[i] = BoardBuild.run(ctx)
    end

    ----------------------------------------------------------------
    -- Final Output
    ----------------------------------------------------------------
    local out = {
        order  = order,
        boards = boards,
        meta   = {
            io = io_meta, -- provenance only
        },
    }

    Trace.contract_out(Ingest.CONTRACT.read.out, "pipelines.ingest", "caller")
    Contract.assert(out, Ingest.CONTRACT.read.out)
    Trace.contract_leave()

    return out
end

return Ingest
