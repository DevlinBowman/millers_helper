-- system/infrastructure/app_fs/registry.lua
--
-- Canonical application filesystem layout (relative to Storage.app_root()).
--
-- Rule:
--   This is the ONLY place that defines where internal files/dirs live.

local Registry = {}

Registry.locations = {
    ------------------------------------------------------------
    -- DOMAIN ROOTS
    ------------------------------------------------------------
    ledger = "ledger",
    client = "client",
    vendor = "vendor",

    ------------------------------------------------------------
    -- USER (persisted, user-facing)
    ------------------------------------------------------------
    user         = "user",
    user_imports = "user/imports",
    user_exports = "user/exports",
    user_vault   = "user/vault",

    ------------------------------------------------------------
    -- SYSTEM (owned by system/app boundary)
    ------------------------------------------------------------
    system            = "system",
    system_staged     = "system/staged",
    system_sessions   = "system/sessions",
    system_runtime_ids= "system/runtime_ids",
    system_presets    = "system/presets",

    ------------------------------------------------------------
    -- SYSTEM FILES
    ------------------------------------------------------------
    last_session = "system/sessions/last_session.json",
}

-- Canonical directories that must exist for a valid instance.
Registry.ensure_dirs = {
    "ledger",
    "client",
    "vendor",

    "user",
    "user/imports",
    "user/exports",
    "user/vault",

    "system",
    "system/staged",
    "system/sessions",
    "system/runtime_ids",
    "system/presets",
}

return Registry
