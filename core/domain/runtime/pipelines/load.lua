-- core/domain/runtime/pipelines/load.lua
--
-- Single entrypoint loader.
--
-- Usage:
--     local load = require("pipelines.runtime.load")
--     local batches = load(inputs)
--
-- Always returns:
--     { { order=table, boards=table[] }[] }
--
-- Routing Rules:
--     string                      -> Ingest.read(path)
--     { path=... }                -> Ingest.read
--     { order_path=..., boards_path=... }
--                                   -> Bundle.load
--     envelope (codec=lua_object) -> normalized directly
--
-- Output is ALWAYS canonical batches.
-- No envelope leakage.

local Ingest  = require("pipelines.ingestion.ingest")
local Bundle  = require("pipelines.ingestion.context_bundle")
local Ledger  = require("core.domain.ledger.controller")
local Storage = require("core.domain.ledger.internal.storage")
local IO      = require('io.controller')

----------------------------------------------------------------
-- Utility: identify canonical batch shape
----------------------------------------------------------------

local function is_batch(v)
    return type(v) == "table"
        and type(v.order) == "table"
        and type(v.boards) == "table"
end

----------------------------------------------------------------
-- Normalize any supported env into canonical batches
----------------------------------------------------------------

local function normalize(env)
    if type(env) ~= "table" then
        error("load(): invalid env type", 0)
    end

    -- Envelope unwrap
    if env.codec == "lua_object" and type(env.data) == "table" then
        print("[load] unwrapping lua_object envelope")
        env = env.data
    end

    -- Single batch
    if is_batch(env) then
        print("[load] detected single batch -> wrapping into array")
        return { env }
    end

    -- Batch array
    if type(env) == "table"
        and #env > 0
        and is_batch(env[1])
    then
        print(string.format("[load] detected %d batch(es)", #env))
        return env
    end

    error("load(): unable to normalize to canonical batches", 0)
end

----------------------------------------------------------------
-- Routing Decision
----------------------------------------------------------------

local function route(input)
    local env, err

    ------------------------------------------------------------
    -- Raw string path
    ------------------------------------------------------------
    if type(input) == "string" then
        print("[load] route: single file (string)")
        print("[load]   path -> " .. tostring(input))

        env, err = Ingest.read(input)
    end

    ------------------------------------------------------------
    -- Single file spec
    ------------------------------------------------------------
    if not env and type(input) == "table" and input.path then
        print("[load] route: single file (spec)")
        print("[load]   path -> " .. tostring(input.path))

        env, err = Ingest.read(input.path, input.opts)
    end

    ------------------------------------------------------------
    -- Two file bundle
    ------------------------------------------------------------
    if not env and type(input) == "table"
        and input.order_path
        and input.boards_path
    then
        print("[load] route: two-file bundle")
        print("[load]   order_path  -> " .. tostring(input.order_path))
        print("[load]   boards_path -> " .. tostring(input.boards_path))

        env, err = Bundle.load(
            input.order_path,
            input.boards_path,
            input.opts
        )
    end

    ------------------------------------------------------------
    -- Ledger index file (.lua source)
    ------------------------------------------------------------
    if not env and type(input) == "table" and input.ledger_path then
        print("[load] route: ledger index file")
        print("[load]   ledger_path -> " .. tostring(input.ledger_path))

        --------------------------------------------------------
        -- Read ledger index file directly
        --------------------------------------------------------
        local result = IO.read_strict(input.ledger_path)

        if not result or type(result.data) ~= "table" then
            error("[load] invalid ledger index file", 0)
        end

        local index = result.data
        local batches = {}

        print("[load]   rehydrating bundles via controller...")

        for _, entry in ipairs(index) do
            local bundle =
                Ledger.read_bundle(entry.transaction_id)

            batches[#batches + 1] = {
                order  = bundle.order,
                boards = bundle.boards,
            }
        end

        print(string.format(
            "[load]   rehydrated %d transaction(s)",
            #batches
        ))

        env = {
            codec = "lua_object",
            data  = batches,
        }
    end


    ------------------------------------------------------------
    -- Already envelope
    ------------------------------------------------------------
    if not env and type(input) == "table"
        and input.codec == "lua_object"
    then
        print("[load] route: already lua_object envelope")
        env = input
    end

    ------------------------------------------------------------
    -- Failure Handling
    ------------------------------------------------------------
    if not env then
        if err then
            error("[load] FAILED -> " .. tostring(err), 0)
        end
        error("[load] unsupported input type", 0)
    end

    return env
end

----------------------------------------------------------------
-- Public Loader (callable module)
----------------------------------------------------------------

-- core/domain/runtime/pipelines/load.lua

local LoadPipeline = {}

function LoadPipeline.run(input)
    print("\n[load] BEGIN")

    local env = route(input)
    local batches = normalize(env)

    print(string.format(
        "[load] COMPLETE -> %d batch(es) ready",
        #batches
    ))

    print("[load] END\n")

    return batches
end

return LoadPipeline
