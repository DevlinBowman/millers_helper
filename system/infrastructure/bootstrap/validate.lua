-- system/infrastructure/bootstrap/validate.lua
--
-- Validates required system files exist.

local Storage  = require("system.infrastructure.storage.controller")
local FS       = require("platform.io.registry").fs

local Validate = {}

function Validate.check(ledger_id)
    ledger_id = ledger_id or "default"

    local required = {
        Storage.ledger_root(ledger_id),
        Storage.ledger_file(ledger_id),
        Storage.runtime_ids(),
        Storage.session_file("last_session"),
    }

    if Storage.vendor_cache_root then
        table.insert(required, Storage.vendor_cache_root())
    end

    for _, path in ipairs(required) do
        if not FS.file_exists(path)
            and not FS.dir_exists
            or (FS.dir_exists and not FS.dir_exists(path))
        then
            return false, "missing required system path: " .. path
        end
    end

    return true
end

return Validate
