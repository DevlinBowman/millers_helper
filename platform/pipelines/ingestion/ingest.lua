-- pipelines/ingestion/ingest.lua
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
-- Build (Flattened)
----------------------------------------------------------------

local function build_items(groups)
    local items = {}

    for _, group in ipairs(groups or {}) do
        --------------------------------------------------------
        -- Build Order (once per group)
        --------------------------------------------------------
        local order_result = OrderModel.build(group.order or {})
        local built_order  = order_result.order

        --------------------------------------------------------
        -- Build Boards (one item per board)
        --------------------------------------------------------
        for _, board_spec in ipairs(group.boards or {}) do
            local board_result = BoardModel.build(board_spec)

            if board_result.board then
                items[#items + 1] = {
                    order = built_order,
                    board = board_result.board,
                }
            end
        end
    end

    return items
end

----------------------------------------------------------------
-- Build Order Batches
----------------------------------------------------------------

-- pipelines/ingestion/ingest.lua
--
-- replace function build_batches(groups)

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

    local ok, result_or_err = pcall(function()
        opts = opts or {}
        local stop_at = opts.stop_at


        --------------------------------------------------------
        -- IO
        --------------------------------------------------------
        local raw, io_err = IO.read(path)

        if not raw then
            error(("IO.read failed for path '%s': %s")
                :format(tostring(path), tostring(io_err)), 0)
        end

        local io_meta = raw.meta and raw.meta.io or {}

        if stop_at == "io" then
            Trace.contract_out(raw, "io.controller.read", "caller")
            return raw
        end

        --------------------------------------------------------
        -- Decode
        --------------------------------------------------------
        local decoded = Format.decode(raw.codec, raw.data)

        if stop_at == "decode" then
            local env = build_envelope(decoded.data, io_meta, "decode", {
                transport_codec = raw.codec
            })
            Trace.contract_out(env, "format.controller.decode", "caller")
            return env
        end

        --------------------------------------------------------
        -- Parse
        --------------------------------------------------------
        local objects

        if decoded.codec == "lines" then
            local parsed = Parsers.parse_text(decoded.data)
            assert(parsed and parsed.data, "parser returned invalid shape")
            objects = parsed.data
        else
            objects = decoded.data
        end

        if stop_at == "parse" then
            local env = build_envelope(objects, io_meta, "parse", {
                transport_codec = raw.codec
            })
            Trace.contract_out(env, "parsers.controller.parse_text", "caller")
            return env
        end

        --------------------------------------------------------
        -- Classify
        --------------------------------------------------------
        local classified = classify_inbound_objects(objects)

        if stop_at == "classify" then
            local env = build_envelope(classified, io_meta, "classify")
            Trace.contract_out(env, "classify.controller.object", "caller")
            return env
        end

        --------------------------------------------------------
        -- OrderContext Compress (group + reconcile)
        --------------------------------------------------------
        local identity_key = "order_number"

        local compress_result =
            OrderContext.compress(classified, identity_key, opts.order_context)

        local groups = compress_result.groups

        if stop_at == "compress" then
            local env = build_envelope(groups, io_meta, "compress", {
                identity_key = identity_key,
                shape        = "order_groups",
            })
            Trace.contract_out(env, "order_context.controller.compress", "caller")
            return env
        end

        --------------------------------------------------------
        -- Build Models (Flattened)
        --------------------------------------------------------
        -- local built = build_items(groups)
        local built = build_batches(groups)

        if stop_at == "build" then
            local env = build_envelope(built, io_meta, "build", {
                identity_key = identity_key,
            })
            Trace.contract_out(env, "core.model.*.controller.build", "caller")
            return env
        end

        --------------------------------------------------------
        -- Final
        --------------------------------------------------------
        local final_env = build_envelope(built, io_meta, "done", {
            identity_key = identity_key,
        })

        Contract.assert(final_env, Ingest.CONTRACT.read.out)

        Trace.contract_out(final_env, "platform.pipelines.ingestion.ingest.read", "caller")
        return final_env
    end)

    Trace.contract_leave()

    if not ok then
        error(result_or_err, 0)
    end

    return result_or_err
end

return Ingest
