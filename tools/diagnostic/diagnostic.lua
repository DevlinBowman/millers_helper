-- tools/diagnostic/diagnostic.lua
--
-- Scoped Diagnostic Runtime Bus (Config-driven)

local ConfigModule = require("tools.diagnostic.config")

local Diagnostic = {}

----------------------------------------------------------------
-- Runtime State
----------------------------------------------------------------

local CONFIG = {}
local STACK  = {}
local SINKS  = {}
local AUTO_CONSOLE_ATTACHED = false

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

local function is_table(x)    return type(x) == "table" end
local function is_string(x)   return type(x) == "string" end
local function is_function(x) return type(x) == "function" end

local function wall_time()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function cpu_time()
    return os.clock()
end

local function safe_call(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        -- swallow sink errors by design
        return false, err
    end
    return true
end

local function deep_copy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = deep_copy(v)
    end
    return out
end

local function deep_merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            deep_merge(dst[k], v)
        else
            dst[k] = v
        end
    end
end

local function current_scope()
    return STACK[#STACK]
end

local function bump_count(scope, kind)
    local c = scope.counts[kind] or 0
    scope.counts[kind] = c + 1
end

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

local function reset_to_defaults()
    CONFIG = deep_copy(ConfigModule.defaults)
end

local function ensure_auto_console()
    if not CONFIG.enabled then return end
    if not CONFIG.sinks or not CONFIG.sinks.auto_console then return end
    if AUTO_CONSOLE_ATTACHED then return end

    local ConsoleSink = require("tools.diagnostic.sinks.console")
    local sink = ConsoleSink.new(CONFIG.console or {})
    SINKS[#SINKS + 1] = sink
    AUTO_CONSOLE_ATTACHED = true
end

reset_to_defaults()
ensure_auto_console()

----------------------------------------------------------------
-- Public Control
----------------------------------------------------------------

function Diagnostic.set(enabled, opts)
    assert(type(enabled) == "boolean", "Diagnostic.set(): boolean required")

    CONFIG.enabled = enabled

    if opts ~= nil then
        assert(is_table(opts), "Diagnostic.set(): opts must be table|nil")
        deep_merge(CONFIG, opts)
    end

    ensure_auto_console()
    return true
end

function Diagnostic.get_config()
    return deep_copy(CONFIG)
end

function Diagnostic.configure(opts)
    assert(is_table(opts), "Diagnostic.configure(): table required")
    deep_merge(CONFIG, opts)
    ensure_auto_console()
    return true
end

----------------------------------------------------------------
-- Sink Management
----------------------------------------------------------------

function Diagnostic.add_sink(sink_fn)
    assert(is_function(sink_fn), "Diagnostic.add_sink(): function required")
    SINKS[#SINKS + 1] = sink_fn
    return true
end

function Diagnostic.remove_sink(sink_fn)
    for i = #SINKS, 1, -1 do
        if SINKS[i] == sink_fn then
            table.remove(SINKS, i)
            return true
        end
    end
    return false
end

function Diagnostic.clear_sinks()
    for i = #SINKS, 1, -1 do
        SINKS[i] = nil
    end
    AUTO_CONSOLE_ATTACHED = false
    ensure_auto_console()
    return true
end

function Diagnostic.list_sinks()
    local out = {}
    for i, s in ipairs(SINKS) do
        out[i] = s
    end
    return out
end

----------------------------------------------------------------
-- Scope Management
----------------------------------------------------------------

function Diagnostic.scope_enter(label, opts)
    if not CONFIG.enabled then return nil end
    assert(is_string(label), "Diagnostic.scope_enter(): label string required")

    if opts ~= nil then
        assert(is_table(opts), "Diagnostic.scope_enter(): opts must be table|nil")
    end

    local scope = {
        label        = label,
        tags         = (opts and opts.tags) or nil,

        started_at   = wall_time(),
        started_cpu  = cpu_time(),
        finished_at  = nil,
        finished_cpu = nil,
        duration_cpu = nil,

        events    = {},
        signals   = {},
        decisions = {},
        debug     = {},
        messages  = {},
        counts    = {},
        depth     = #STACK + 1,
    }

    STACK[#STACK + 1] = scope
    return scope
end

function Diagnostic.scope_leave()
    if not CONFIG.enabled then return nil end

    local scope = STACK[#STACK]
    STACK[#STACK] = nil

    if scope then
        scope.finished_at  = wall_time()
        scope.finished_cpu = cpu_time()
        scope.duration_cpu = scope.finished_cpu - (scope.started_cpu or scope.finished_cpu)
    end

    return scope
end

function Diagnostic.current()
    return current_scope()
end

function Diagnostic.peek_events()
    local scope = current_scope()
    if not scope then return {} end
    return scope.events
end

----------------------------------------------------------------
-- Core Emit
----------------------------------------------------------------

function Diagnostic.emit_event(kind, payload)
    if not CONFIG.enabled then return nil end
    if not (CONFIG.record and CONFIG.record.raw_events) then
        return nil
    end

    assert(is_string(kind), "Diagnostic.emit_event(): kind string required")
    if payload ~= nil then
        assert(is_table(payload), "Diagnostic.emit_event(): payload table|nil")
    end

    local scope = current_scope()
    if not scope then
        return nil -- evaporate
    end

    local event = {
        kind    = kind,
        time    = wall_time(),
        cpu     = cpu_time(),
        scope   = scope.label,
        depth   = scope.depth,
        payload = payload or {},
    }

    scope.events[#scope.events + 1] = event
    bump_count(scope, kind)

    for _, sink in ipairs(SINKS) do
        safe_call(sink, event, scope)
    end

    return event
end

----------------------------------------------------------------
-- Typed Helpers (Config Gated)
----------------------------------------------------------------

function Diagnostic.signal(signal)
    assert(is_table(signal), "Diagnostic.signal(): table required")
    if not (CONFIG.record and CONFIG.record.signals) then return nil end

    local scope = current_scope()
    if scope then
        scope.signals[#scope.signals + 1] = signal
    end

    return Diagnostic.emit_event("signal", { signal = signal })
end

function Diagnostic.decision(key, decision)
    assert(is_string(key), "Diagnostic.decision(): key string required")
    assert(is_table(decision), "Diagnostic.decision(): decision table required")
    if not (CONFIG.record and CONFIG.record.decisions) then return nil end

    local scope = current_scope()
    if scope then
        scope.decisions[key] = decision
    end

    return Diagnostic.emit_event("decision", { key = key, decision = decision })
end

function Diagnostic.debug(label, value)
    assert(is_string(label), "Diagnostic.debug(): label string required")
    if not (CONFIG.record and CONFIG.record.debug) then return nil end

    local scope = current_scope()
    if scope then
        scope.debug[#scope.debug + 1] = { label = label, value = value }
    end

    return Diagnostic.emit_event("debug", { label = label, value = value })
end

function Diagnostic.user_message(message, severity, meta)
    assert(is_string(message), "Diagnostic.user_message(): message string required")
    if not (CONFIG.record and CONFIG.record.user_messages) then return nil end

    local payload = {
        message  = message,
        severity = severity or "info",
        meta     = meta or {},
    }

    local scope = current_scope()
    if scope then
        scope.messages[#scope.messages + 1] = payload
    end

    return Diagnostic.emit_event("user_message", payload)
end

return Diagnostic
