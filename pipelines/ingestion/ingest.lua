-- pipelines/ingestion/ingest.lua

local IO         = require("io.controller")
local Format     = require("format").controller
local Parsers    = require("parsers.controller")
local Classify   = require("classify.controller")
local Compress   = require("pipelines.ingestion.compress")

local OrderModel = require("core.model.order").controller
local BoardModel = require("core.model.board").controller

local Trace      = require("tools.trace")
local Contract   = require("core.contract")

local Ingest = {}

----------------------------------------------------------------
-- DEBUG
----------------------------------------------------------------

local DEBUG = true

local function header(title)
    if not DEBUG then return end
    print("\n------------------------------------------------------------")
    print("INGEST STAGE:", title)
    print("------------------------------------------------------------")
end

local function summarize(label, value)
    if not DEBUG then return end

    local t = type(value)
    local count = 0

    if t == "table" then
        count = #value
    end

    print(string.format(
        "%-15s | type=%-8s | count=%s",
        label,
        t,
        tostring(count)
    ))

    if t == "table" and count > 0 then
        local first = value[1]
        if type(first) == "table" then
            local keys = {}
            for k in pairs(first) do
                keys[#keys+1] = tostring(k)
            end
            table.sort(keys)
            print("  sample keys:", table.concat(keys, ", "))
        end
    end
end

local function summarize_groups(groups)
    if not DEBUG then return end
    if type(groups) ~= "table" then return end

    for i, g in ipairs(groups) do
        local board_count = g.boards and #g.boards or 0
        print(string.format(
            "  group[%d] | boards=%d | order_keys=%s",
            i,
            board_count,
            g.order and (next(g.order) and "yes" or "empty") or "nil"
        ))
    end
end

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

local function classify_inbound_objects(objects)
    assert(type(objects) == "table", "classification requires array of objects")

    local out = {}
    for i, attr in ipairs(objects) do
        out[i] = Classify.object(attr)
    end
    return out
end

local function build_items(groups)
    local items = {}

    for _, group in ipairs(groups or {}) do

        local order_result = OrderModel.build(group.order or {})
        local built_order  = order_result.order

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

    Trace.contract_enter("pipelines.ingestion.ingest.read")
    Trace.contract_in(Ingest.CONTRACT.read.in_)

    local function run()

        header("START")

        Contract.assert({ path = path, opts = opts }, Ingest.CONTRACT.read.in_)
        opts = opts or {}
        local stop_at = opts.stop_at

        --------------------------------------------------------
        -- IO
        --------------------------------------------------------

        header("IO")

        local raw = IO.read(path)
        local io_meta = raw.meta and raw.meta.io or {}

        summarize("raw.data", raw.data)

        if stop_at == "io" then
            return raw
        end

        --------------------------------------------------------
        -- Decode
        --------------------------------------------------------

        header("DECODE")

        local decoded = Format.decode(raw.codec, raw.data)

        summarize("decoded", decoded.data)

        if stop_at == "decode" then
            return build_envelope(decoded.data, io_meta, "decode")
        end

        --------------------------------------------------------
        -- Parse
        --------------------------------------------------------

        header("PARSE")

        local objects

        if decoded.codec == "lines" then
            local parsed = Parsers.parse_text(decoded.data)
            assert(parsed and parsed.data, "parser returned invalid shape")
            objects = parsed.data
        else
            objects = decoded.data
        end

        summarize("objects", objects)

        if stop_at == "parse" then
            return build_envelope(objects, io_meta, "parse")
        end

        --------------------------------------------------------
        -- Classify
        --------------------------------------------------------

        header("CLASSIFY")

        local classified = classify_inbound_objects(objects)
        summarize("classified", classified)

        if stop_at == "classify" then
            return build_envelope(classified, io_meta, "classify")
        end

        --------------------------------------------------------
        -- Compress
        --------------------------------------------------------

        header("COMPRESS")

        local identity_key = "order_number"
        local compressed   = Compress.run(classified, identity_key)

        summarize("compressed", compressed)
        summarize_groups(compressed)

        if stop_at == "compress" then
            return build_envelope(compressed, io_meta, "compress")
        end

        --------------------------------------------------------
        -- Build
        --------------------------------------------------------

        header("BUILD")

        local built = build_items(compressed)
        summarize("built items", built)

        if stop_at == "build" then
            return build_envelope(built, io_meta, "build")
        end

        --------------------------------------------------------
        -- Final
        --------------------------------------------------------

        header("DONE")
        summarize("final data", built)

        return build_envelope(built, io_meta, "done")
    end

    local ok, result = pcall(run)
    Trace.contract_leave()

    if not ok then
        error(result, 0)
    end

    return result
end

return Ingest
