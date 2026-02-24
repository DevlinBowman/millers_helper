-- platform/pipelines/ingestion/ingest.lua
--
-- Cross-domain ingestion pipeline.
--
-- Flow:
--   IO → Decode → Parse → Classify → OrderContext.compress → Build
--
-- Compression now handled by order_context module.


local IO           = require("platform.io.controller")
local Format       = require("platform.format").controller
local Parsers      = require("platform.parsers.controller")
local Classify     = require("platform.classify.controller")
local OrderContext = require("platform.order_context").controller

local OrderModel   = require("core.model.order").controller
local BoardModel   = require("core.model.board").controller

local Trace        = require("tools.trace.trace")
local Contract     = require("core.contract")

local Ingest       = {}

----------------------------------------------------------------
-- Contract
----------------------------------------------------------------

Ingest.CONTRACT    = {
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

local function classify_inbound_objects(objects)
    assert(type(objects) == "table", "classification requires array of objects")

    local out = {}
    for i, attr in ipairs(objects) do
        out[i] = Classify.object(attr)
    end
    return out
end

----------------------------------------------------------------
-- Build Order Batches
----------------------------------------------------------------


local function build_batches(groups)
    local batches = {}

    for _, group in ipairs(groups or {}) do
        --------------------------------------------------------
        -- 1) Build Boards FIRST (collect built boards)
        --------------------------------------------------------
        local built_boards = {}

        for _, board_spec in ipairs(group.boards or {}) do
            local board_result = BoardModel.build(board_spec)

            if board_result.board then
                built_boards[#built_boards + 1] = board_result.board
            end
        end

        --------------------------------------------------------
        -- 2) Build Order WITH built boards (may be empty)
        --------------------------------------------------------
        local order_result = OrderModel.build(
            group.order or {},
            built_boards
        )

        local built_order = order_result.order

        --------------------------------------------------------
        -- 3) Batch (domain only)
        --------------------------------------------------------
        batches[#batches + 1] = {
            order  = built_order,
            boards = built_boards,
        }
    end

    return batches
end

----------------------------------------------------------------
-- Envelope Builder
----------------------------------------------------------------

local function build_envelope(data, io_meta, stage, extra)
    local parse_meta = {
        stage = stage,
        count = type(data) == "table" and #data or 0,
    }

    if type(extra) == "table" then
        for k, v in pairs(extra) do
            parse_meta[k] = v
        end
    end

    local out = {
        codec = "lua_object",
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
-- Public API
----------------------------------------------------------------

function Ingest.read(path, opts)
    Trace.contract_enter("platform.pipelines.ingestion.ingest.read")
    Trace.contract_in({ path = path, opts = opts })
    Contract.assert({ path = path, opts = opts }, Ingest.CONTRACT.read.in_)

    opts = opts or {}
    local stop_at = opts.stop_at

    --------------------------------------------------------
    -- IO
    --------------------------------------------------------
    local raw, io_err = IO.read(path)

    if not raw then
        Trace.contract_leave()
        return nil, {
            kind  = "io_failure",
            stage = "io",
            path  = path,
            error = io_err,
        }
    end

    local io_meta = raw.meta and raw.meta.io or {}

    if stop_at == "io" then
        Trace.contract_out(raw, "io.controller.read", "caller")
        Trace.contract_leave()
        return raw
    end

    --------------------------------------------------------
    -- Decode (includes ParserGate)
    --------------------------------------------------------
    local decoded, decode_err = Format.decode(raw.codec, raw.data)

    if not decoded then
        Trace.contract_leave()
        return nil, {
            kind  = "input_validation_failure",
            stage = "decode",
            path  = path,
            error = decode_err,
            meta  = { io = io_meta },
        }
    end

    if stop_at == "decode" then
        local env = build_envelope(decoded.data, io_meta, "decode", {
            transport_codec = raw.codec
        })
        Trace.contract_out(env, "format.controller.decode", "caller")
        Trace.contract_leave()
        return env
    end

    --------------------------------------------------------
    -- Extract Objects
    --------------------------------------------------------
    local objects = decoded.data

    if type(objects) ~= "table" then
        Trace.contract_leave()
        return nil, {
            kind  = "decode_shape_error",
            stage = "decode",
            path  = path,
            error = "decoded objects missing or invalid",
            meta  = { io = io_meta },
        }
    end

    if stop_at == "parse" then
        local env = build_envelope(objects, io_meta, "parse", {
            transport_codec = raw.codec
        })
        Trace.contract_out(env, "parsers.controller.parse_text", "caller")
        Trace.contract_leave()
        return env
    end

    --------------------------------------------------------
    -- Classify
    --------------------------------------------------------
    local classified = classify_inbound_objects(objects)

    if stop_at == "classify" then
        local env = build_envelope(classified, io_meta, "classify")
        Trace.contract_out(env, "classify.controller.object", "caller")
        Trace.contract_leave()
        return env
    end

    --------------------------------------------------------
    -- OrderContext Compress
    --------------------------------------------------------
    local identity_key = "order_number"

    local compress_result, compress_err =
        OrderContext.compress(classified, identity_key, opts.order_context)

    if not compress_result then
        Trace.contract_leave()
        return nil, {
            kind  = "order_context_failure",
            stage = "compress",
            path  = path,
            error = compress_err,
            meta  = { io = io_meta },
        }
    end

    local groups = compress_result.groups

    if type(groups) ~= "table" then
        Trace.contract_leave()
        return nil, {
            kind  = "order_context_shape_error",
            stage = "compress",
            path  = path,
            error = "compress returned invalid groups",
            meta  = { io = io_meta },
        }
    end

    if stop_at == "compress" then
        local env = build_envelope(groups, io_meta, "compress", {
            identity_key = identity_key,
            shape        = "order_groups",
        })
        Trace.contract_out(env, "order_context.controller.compress", "caller")
        Trace.contract_leave()
        return env
    end

    --------------------------------------------------------
    -- Build Canonical Batches
    --------------------------------------------------------
    local built = build_batches(groups)

    if stop_at == "build" then
        local env = build_envelope(built, io_meta, "build", {
            identity_key = identity_key,
        })
        Trace.contract_out(env, "core.model.*.controller.build", "caller")
        Trace.contract_leave()
        return env
    end

    --------------------------------------------------------
    -- Final Envelope
    --------------------------------------------------------
    local final_env = build_envelope(built, io_meta, "done", {
        identity_key = identity_key,
    })

    Contract.assert(final_env, Ingest.CONTRACT.read.out)
    Trace.contract_out(final_env, "platform.pipelines.ingestion.ingest.read", "caller")
    Trace.contract_leave()

    return final_env
end

return Ingest
