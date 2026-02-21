-- system/infrastructure/bootstrap/controller.lua
--
-- Idempotent filesystem initializer.

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")
local FS          = require("platform.io.registry").fs

local Bootstrap = {}

local function ensure_dir(path)
    FS.ensure_parent_dir(path .. "/.keep")
end

local function ensure_json_file(path, default_value)
    if not FS.file_exists(path) then
        local ok, err = FileGateway.write(path, "json", default_value)
        if not ok then
            error("bootstrap failed writing " .. path .. ": " .. tostring(err))
        end
    end
end

function Bootstrap.build(opts)
    opts = opts or {}
    local ledger_id = opts.ledger_id or "default"

    ------------------------------------------------------------
    -- Core directories
    ------------------------------------------------------------

    ensure_dir(Storage.ledger_root(ledger_id))
    ensure_dir(Storage.ledger_txn_dir(ledger_id, "placeholder"))

    if Storage.vendor_cache then
        ensure_dir(Storage.vendor_cache())
    end

    if Storage.runtime_ids then
        ensure_dir(Storage.runtime_ids())
    end

    if Storage.presets then
        ensure_dir(Storage.presets("default"))
    end

    ensure_dir(Storage.session_file("tmp"):gsub("/[^/]+$", ""))

    ------------------------------------------------------------
    -- Core files
    ------------------------------------------------------------

    ensure_json_file(Storage.ledger_file(ledger_id), {})
    ensure_json_file(Storage.ledger_exports_log(ledger_id), {})

    ensure_json_file(
        Storage.session_file("last_session"),
        {
            version = 1,
            active_ledger = ledger_id,
            resources = {},
            context = {}
        }
    )

    return true
end

return Bootstrap
