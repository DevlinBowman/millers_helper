-- core/diagnostics/signals.lua
--
-- Debug / validation signal collector.
-- Core, domain-agnostic diagnostics primitive.
-- Additive-only design: all existing behavior preserved.

local Signals = {}

---@alias SignalLevel "error"|"warn"|"info"

---@class Signal
---@field level SignalLevel
---@field code string
---@field path string
---@field message string
---@field meta table|nil
---@field id string|nil

---@class SignalBag
---@field items Signal[]
---@field counts table<string, integer>
---@field has_error boolean

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

---@return SignalBag
function Signals.new()
    return {
        items = {},
        counts = { error = 0, warn = 0, info = 0 },
        has_error = false,
    }
end

--- Ensure a signal bag exists (convenience helper)
---@param bag SignalBag|nil
---@return SignalBag
function Signals.ensure(bag)
    if bag == nil then
        return Signals.new()
    end
    return bag
end

----------------------------------------------------------------
-- Core mutation
----------------------------------------------------------------

local VALID_LEVELS = {
    error = true,
    warn  = true,
    info  = true,
}

---@param bag SignalBag
---@param level SignalLevel
---@param code string
---@param path string
---@param message string
---@param meta table|nil
function Signals.add(bag, level, code, path, message, meta)
    -- Defensive: never silently accept invalid levels
    if not VALID_LEVELS[level] then
        level   = "error"
        code    = "INVALID_SIGNAL_LEVEL"
        path    = path or "<signal>"
        message = "invalid signal level; coerced to error"
        meta    = { original_level = level }
    end

    local item = {
        level   = level,
        code    = code,
        path    = path,
        message = message,
        meta    = meta,
        id      = code .. "@" .. tostring(path),
    }

    bag.items[#bag.items + 1] = item
    bag.counts[level] = (bag.counts[level] or 0) + 1

    if level == "error" then
        bag.has_error = true
    end
end

----------------------------------------------------------------
-- Severity helpers (semantic sugar)
----------------------------------------------------------------

---@param bag SignalBag
---@param code string
---@param path string
---@param message string
---@param meta table|nil
function Signals.error(bag, code, path, message, meta)
    Signals.add(bag, "error", code, path, message, meta)
end

---@param bag SignalBag
---@param code string
---@param path string
---@param message string
---@param meta table|nil
function Signals.warn(bag, code, path, message, meta)
    Signals.add(bag, "warn", code, path, message, meta)
end

---@param bag SignalBag
---@param code string
---@param path string
---@param message string
---@param meta table|nil
function Signals.info(bag, code, path, message, meta)
    Signals.add(bag, "info", code, path, message, meta)
end

----------------------------------------------------------------
-- Bag composition
----------------------------------------------------------------

--- Merge signals from src into dst
---@param dst SignalBag
---@param src SignalBag
function Signals.merge(dst, src)
    if not src or not src.items then
        return
    end

    for _, item in ipairs(src.items) do
        Signals.add(
            dst,
            item.level,
            item.code,
            item.path,
            item.message,
            item.meta
        )
    end
end

----------------------------------------------------------------
-- Queries
----------------------------------------------------------------

---@param bag SignalBag
---@return boolean
function Signals.ok(bag)
    return not bag.has_error
end

---@param bag SignalBag
---@param level SignalLevel
---@return integer
function Signals.count(bag, level)
    return (bag.counts and bag.counts[level]) or 0
end

---@param bag SignalBag
---@param level SignalLevel
---@return boolean
function Signals.any(bag, level)
    return Signals.count(bag, level) > 0
end

---@param bag SignalBag
---@param level SignalLevel
---@return Signal[]
function Signals.by_level(bag, level)
    local out = {}
    for _, s in ipairs(bag.items or {}) do
        if s.level == level then
            out[#out + 1] = s
        end
    end
    return out
end

return Signals
