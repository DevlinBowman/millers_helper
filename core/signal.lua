-- core/signals.lua
--
-- Global diagnostic signal utilities.
--
-- PURPOSE
--   • Provide a canonical diagnostic shape
--   • Provide aggregation helpers
--   • Provide severity utilities
--
-- This module is PURE.
-- No tracing.
-- No throwing.
-- No IO.
-- No policy decisions.
--
-- Signals are data only.
--
-- Canonical shape:
--
-- {
--     code    = string,      -- machine-readable identifier
--     level   = string,      -- "error" | "warn" | "info"
--     message = string,      -- human-readable description
--     module  = string?,     -- optional module name
--     stage   = string?,     -- optional pipeline stage
--     context = table?,      -- optional structured metadata
-- }
--

local Signals = {}

----------------------------------------------------------------
-- Severity constants
----------------------------------------------------------------

Signals.LEVEL = {
    ERROR = "error",
    WARN  = "warn",
    INFO  = "info",
}

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

local function assert_string(name, value)
    if type(value) ~= "string" or value == "" then
        error(name .. " must be non-empty string", 3)
    end
end

local function normalize_level(level)
    if level == Signals.LEVEL.ERROR then
        return level
    end

    if level == Signals.LEVEL.WARN then
        return level
    end

    if level == Signals.LEVEL.INFO then
        return level
    end

    error("invalid signal level: " .. tostring(level), 3)
end

----------------------------------------------------------------
-- Signal factory
----------------------------------------------------------------

---@param code string
---@param level "error"|"warn"|"info"
---@param message string
---@param opts? { module?:string, stage?:string, context?:table }
---@return table
function Signals.new(code, level, message, opts)
    assert_string("code", code)
    assert_string("message", message)

    level = normalize_level(level)
    opts  = opts or {}

    local signal = {
        code    = code,
        level   = level,
        message = message,
    }

    if opts.module then
        assert_string("module", opts.module)
        signal.module = opts.module
    end

    if opts.stage then
        assert_string("stage", opts.stage)
        signal.stage = opts.stage
    end

    if opts.context then
        if type(opts.context) ~= "table" then
            error("context must be table", 3)
        end
        signal.context = opts.context
    end

    return signal
end

----------------------------------------------------------------
-- Collection helpers
----------------------------------------------------------------

---@param list table|nil
---@return table
function Signals.list(list)
    if list == nil then
        return {}
    end

    if type(list) ~= "table" then
        error("signal list must be table or nil", 2)
    end

    return list
end

---@param list table
---@param signal table
function Signals.push(list, signal)
    if type(list) ~= "table" then
        error("push: list must be table", 2)
    end

    if type(signal) ~= "table" then
        error("push: signal must be table", 2)
    end

    list[#list + 1] = signal
end

---@param dst table
---@param src table|nil
function Signals.merge(dst, src)
    if not src then
        return
    end

    if type(dst) ~= "table" or type(src) ~= "table" then
        error("merge requires tables", 2)
    end

    for _, sig in ipairs(src) do
        dst[#dst + 1] = sig
    end
end

----------------------------------------------------------------
-- Severity checks
----------------------------------------------------------------

---@param list table|nil
---@return boolean
function Signals.has_errors(list)
    if not list then
        return false
    end

    for _, sig in ipairs(list) do
        if sig.level == Signals.LEVEL.ERROR then
            return true
        end
    end

    return false
end

---@param list table|nil
---@return boolean
function Signals.has_warnings(list)
    if not list then
        return false
    end

    for _, sig in ipairs(list) do
        if sig.level == Signals.LEVEL.WARN then
            return true
        end
    end

    return false
end

----------------------------------------------------------------
-- Filtering
----------------------------------------------------------------

---@param list table
---@param level string
---@return table
function Signals.filter(list, level)
    normalize_level(level)

    local out = {}

    for _, sig in ipairs(list or {}) do
        if sig.level == level then
            out[#out + 1] = sig
        end
    end

    return out
end

return Signals
