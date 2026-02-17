-- tools/diagnostic/sinks/console.lua
--
-- Console sink (opt-in).
-- Prints selected diagnostic events in real-time.

local M = {}

local function is_table(x) return type(x) == "table" end

local severity_rank = { info = 1, warn = 2, error = 3 }

local function rank(sev)
    return severity_rank[sev or "info"] or 1
end

local function prefix(event, scope)
    local label = (scope and scope.label) or (event and event.scope) or "diagnostic"
    local kind  = (event and event.kind) or "event"
    return ("[%s] %s"):format(label, kind)
end

--- Create a console sink.
--- opts:
---   {
---     print_debug = boolean|nil,
---     print_signals = boolean|nil,
---     min_signal_severity = "info"|"warn"|"error"|nil,
---     print_user_messages = boolean|nil,
---   }
function M.new(opts)
    opts = opts or {}

    local print_debug = opts.print_debug == true
    local print_signals = (opts.print_signals ~= false)
    local print_user_messages = (opts.print_user_messages ~= false)

    local min_signal_severity = opts.min_signal_severity or "warn"
    local min_rank = rank(min_signal_severity)

    return function(event, scope)
        if not event then return end

        if event.kind == "debug" and print_debug then
            local p = event.payload or {}
            print(("%s %s"):format(prefix(event, scope), tostring(p.label)))
            return
        end

        if event.kind == "user_message" and print_user_messages then
            local p = event.payload or {}
            print(("%s (%s) %s"):format(prefix(event, scope), tostring(p.severity), tostring(p.message)))
            return
        end

        if event.kind == "signal" and print_signals then
            local p = event.payload or {}
            local s = p.signal or {}
            if rank(s.severity) >= min_rank then
                print(("%s (%s) %s"):format(prefix(event, scope), tostring(s.severity), tostring(s.message)))
            end
            return
        end
    end
end

return M
