-- core/domain/runtime/pipelines/load.lua
--
-- Single entrypoint loader.
-- Always returns canonical RuntimeBatch[] OR raises a useful error.

local Ingest = require("platform.pipelines.ingestion.ingest")
local Ledger = require("core.domain.ledger.controller")
local IO     = require("platform.io.controller")

----------------------------------------------------------------
-- Utility: identify canonical batch shape
----------------------------------------------------------------

local function is_batch(v)
    return type(v) == "table"
        and type(v.order) == "table"
        and type(v.boards) == "table"
end

----------------------------------------------------------------
-- Error formatting (structured, deterministic)
----------------------------------------------------------------

local function format_err(err, depth)
    depth = depth or 0

    if err == nil then
        return "unknown error"
    end

    if type(err) == "string" then
        return err
    end

    if type(err) ~= "table" then
        return tostring(err)
    end

    local lines = {}

    local indent = string.rep("  ", depth)

    if err.kind then
        lines[#lines+1] = indent .. "kind: " .. tostring(err.kind)
    end

    if err.stage then
        lines[#lines+1] = indent .. "stage: " .. tostring(err.stage)
    end

    if err.field then
        lines[#lines+1] = indent .. "field: " .. tostring(err.field)
    end

    if err.message then
        lines[#lines+1] = indent .. "message: " .. tostring(err.message)
    end

    if err.values then
        lines[#lines+1] = indent .. "values:"
        for _, v in ipairs(err.values) do
            lines[#lines+1] = indent .. "  - " .. tostring(v)
        end
    end

    if err.errors and type(err.errors) == "table" then
        lines[#lines+1] = indent .. "errors:"
        for _, e in ipairs(err.errors) do
            lines[#lines+1] = format_err(e, depth + 1)
        end
    end

    if err.error and type(err.error) == "table" then
        lines[#lines+1] = indent .. "caused_by:"
        lines[#lines+1] = format_err(err.error, depth + 1)
    end

    return table.concat(lines, "\n")
end

----------------------------------------------------------------
-- Normalize any supported env into canonical batches
----------------------------------------------------------------

-- core/domain/runtime/pipelines/load.lua
-- function normalize(env)

local function normalize(env)
    if type(env) ~= "table" then
        return nil, {
            kind    = "runtime_normalize_failure",
            stage   = "normalize",
            message = "invalid env type",
        }
    end

    -- IMPORTANT: propagate structured upstream error (do not stringify/throw)
    if env.ok == false then
        return nil, env
    end

    -- Envelope unwrap
    if env.codec == "lua_object" and type(env.data) == "table" then
        print("[load] unwrapping lua_object envelope")
        env = env.data
    end

    -- Single batch
    if is_batch(env) then
        print("[load] detected single batch -> wrapping into array")
        return { env }, nil
    end

    -- Batch array
    if type(env) == "table" and #env > 0 and is_batch(env[1]) then
        print(string.format("[load] detected %d batch(es)", #env))
        return env, nil
    end

    return nil, {
        kind    = "runtime_normalize_failure",
        stage   = "normalize",
        message = "unable to normalize to canonical batches",
    }
end

----------------------------------------------------------------
-- Routing Decision
----------------------------------------------------------------

-- core/domain/runtime/pipelines/load.lua
-- function route(input)

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
    -- Ledger index file
    ------------------------------------------------------------
    if not env and type(input) == "table" and input.ledger_path then
        print("[load] route: ledger index file")
        print("[load]   ledger_path -> " .. tostring(input.ledger_path))

        local result, io_err = IO.read_strict(input.ledger_path)

        if not result or type(result.data) ~= "table" then
            return nil, {
                kind  = "ledger_load_failure",
                stage = "route",
                path  = input.ledger_path,
                error = io_err or "invalid ledger index file"
            }
        end

        local index = result.data
        local batches = {}

        for _, entry in ipairs(index) do
            local bundle = Ledger.read_bundle(entry.transaction_id)
            batches[#batches + 1] = {
                order  = bundle.order,
                boards = bundle.boards,
            }
        end

        env = { codec = "lua_object", data = batches }
    end

    ------------------------------------------------------------
    -- Already envelope
    ------------------------------------------------------------
    if not env and type(input) == "table" and input.codec == "lua_object" then
        print("[load] route: already lua_object envelope")
        env = input
    end

    ------------------------------------------------------------
    -- IMPORTANT: Treat structured failure env as failure
    ------------------------------------------------------------
    if type(env) == "table" and env.ok == false then
        -- This is an upstream failure envelope (ex: ingest/decode/parser gate)
        -- Return it as route_err so caller preserves structure.
        return nil, env
    end

    ------------------------------------------------------------
    -- Failure
    ------------------------------------------------------------
    if not env then
        return nil, err or {
            kind    = "unsupported_input_type",
            stage   = "route",
            message = "Unsupported runtime input"
        }
    end

    return env
end

----------------------------------------------------------------
-- Public Loader (callable module)
----------------------------------------------------------------

local LoadPipeline = {}

-- core/domain/runtime/pipelines/load.lua
-- function LoadPipeline.run(input)

function LoadPipeline.run(input)
    print("\n[load] BEGIN")

    ------------------------------------------------------------
    -- Route
    ------------------------------------------------------------
    local env, route_err = route(input)

    if not env then
        print("[load] FAILED during route")
        print("[load] END\n")

        return nil, {
            kind  = "runtime_input_failure",
            stage = "route",
            path  = route_err and route_err.path,
            error = route_err,
        }
    end

    ------------------------------------------------------------
    -- Capture provenance BEFORE normalize unwraps env.data
    ------------------------------------------------------------
    local io_meta = nil
    if type(env) == "table"
        and type(env.meta) == "table"
        and type(env.meta.io) == "table"
    then
        io_meta = env.meta.io
    end

    ------------------------------------------------------------
    -- Normalize (must be protected)
    ------------------------------------------------------------
    local ok, batches_or_err = pcall(function()
        return normalize(env)
    end)

    if not ok then
        print("[load] FAILED during normalize")
        print("[load] END\n")

        return nil, {
            kind  = "runtime_input_failure",
            stage = "normalize",
            path  = io_meta and io_meta.source_path,
            error = batches_or_err,
        }
    end

    local batches = batches_or_err

    ------------------------------------------------------------
    -- Attach provenance
    ------------------------------------------------------------
    if io_meta then
        for i = 1, #batches do
            local batch = batches[i]
            batch.meta = batch.meta or {}
            if batch.meta.io == nil then
                batch.meta.io = io_meta
            end
        end
    end

    print(string.format("[load] COMPLETE -> %d batch(es) ready", #batches))
    print("[load] END\n")

    return batches
end

return LoadPipeline
