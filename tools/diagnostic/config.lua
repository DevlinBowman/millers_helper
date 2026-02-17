-- tools/diagnostic/config.lua
--
-- Central configuration for Diagnostic runtime.
--
-- This file defines DEFAULT behavior only.
-- Runtime overrides may be applied via Diagnostic.set().

local Config = {}

----------------------------------------------------------------
-- Default Runtime Behavior
----------------------------------------------------------------

Config.defaults = {

    -- Master enable switch
    enabled = true,

    -- Automatically create scope in with_scope helpers
    auto_scope = true,

    -- Event Recording
    record = {
        signals       = true,
        decisions     = true,
        debug         = true,
        user_messages = true,
        raw_events    = true,
    },

    -- Sink behavior
    sinks = {
        auto_console = false,   -- automatically attach console sink
    },

    -- Console sink defaults
    console = {
        print_debug           = false,
        print_signals         = true,
        print_user_messages   = true,
        min_signal_severity   = "warn",
    },
}

return Config
