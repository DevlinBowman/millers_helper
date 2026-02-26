-- system/infrastructure/app_fs/registry.lua
--
-- Canonical application filesystem layout (relative to Storage.app_root()).
--
-- Rule:
--   This is the ONLY place that defines where internal files/dirs live.

local Registry = {}

Registry.locations = {
    ------------------------------------------------------------
    -- ROOT GROUPS
    ------------------------------------------------------------
    ledgers        = "ledgers",
    sessions       = "sessions",
    exports        = "exports",
    clients        = "clients",
    user           = "user",
    system         = "system",

    ------------------------------------------------------------
    -- SYSTEM (owned by system)
    ------------------------------------------------------------
    system_caches       = "system/caches",
    vendor_store        = "system/caches/vendor",
    ledger_store        = "system/caches/ledger",
    runtime_ids         = "system/runtime_ids",

    ------------------------------------------------------------
    -- SESSIONS (owned by system/app boundary)
    ------------------------------------------------------------
    last_session        = "sessions/last_session.json",

    ------------------------------------------------------------
    -- USER (owned by user workflows)
    ------------------------------------------------------------
    user_inputs         = "user/inputs",
    user_exports        = "user/exports",
}

-- Canonical directories that must exist for a valid instance.
Registry.ensure_dirs = {
    "ledgers",
    "sessions",
    "exports",
    "clients",
    "user",
    "user/inputs",
    "user/exports",
    "system",
    "system/caches",
    "system/caches/vendor",
    "system/caches/ledger",
    "system/runtime_ids",
}

return Registry
