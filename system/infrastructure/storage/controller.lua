-- system/infrastructure/storage/controller.lua
--
-- Canonical storage schema resolver.
-- ALL filesystem paths in the system must resolve through here.
--
-- Supports multi-instance isolation:
--   data/app/{instance}/...

local Storage = {}

------------------------------------------------------------
-- Configuration
------------------------------------------------------------
-- Detect project root relative to this file
-- Detect project root relative to this file
local function detect_project_root()
    local source = debug.getinfo(1, "S").source
    local filepath = source:sub(2) -- strip leading "@"

    -- Normalize slashes
    filepath = filepath:gsub("\\", "/")

    -- Remove "/system/infrastructure/storage/controller.lua"
    local root = filepath:gsub("/system/infrastructure/storage/controller.lua$", "")

    return root
end

local PROJECT_ROOT = detect_project_root()
local BASE_DIR = PROJECT_ROOT .. "/data"

local APP_DIR  = "app"
local INSTANCE = "default"

local function join(...)
    return table.concat({...}, "/")
end

------------------------------------------------------------
-- Instance Control
------------------------------------------------------------

function Storage.set_instance(name)
    assert(type(name) == "string" and name ~= "", "instance name required")
    INSTANCE = name
end

function Storage.get_instance()
    return INSTANCE
end

function Storage.base_root()
    return BASE_DIR
end

function Storage.root()
    return join(BASE_DIR, APP_DIR, INSTANCE)
end

------------------------------------------------------------
-- Ledgers
------------------------------------------------------------

function Storage.ledgers_root()
    return join(Storage.root(), "ledgers")
end

function Storage.ledger_root(ledger_id)
    assert(type(ledger_id) == "string", "ledger_id required")
    return join(Storage.ledgers_root(), ledger_id)
end

function Storage.ledger_file(ledger_id)
    return join(Storage.ledger_root(ledger_id), "ledger.json")
end

function Storage.ledger_txn_dir(ledger_id, txn_id)
    assert(type(txn_id) == "string", "txn_id required")
    return join(Storage.ledger_root(ledger_id), "txn", txn_id)
end

function Storage.ledger_txn_file(ledger_id, txn_id, name)
    assert(type(name) == "string", "txn file name required")
    return join(Storage.ledger_txn_dir(ledger_id, txn_id), name .. ".json")
end

function Storage.ledger_txn_attachments(ledger_id, txn_id)
    return join(Storage.ledger_txn_dir(ledger_id, txn_id), "attachments")
end

function Storage.ledger_exports_log(ledger_id)
    return join(Storage.ledger_root(ledger_id), "exports_log.json")
end

------------------------------------------------------------
-- Clients
------------------------------------------------------------

function Storage.clients_root()
    return join(Storage.root(), "clients")
end

function Storage.client_file(client_id)
    assert(type(client_id) == "string", "client_id required")
    return join(Storage.clients_root(), client_id .. ".json")
end

------------------------------------------------------------
-- Exports
------------------------------------------------------------

function Storage.exports_root()
    return join(Storage.root(), "exports")
end

function Storage.export_root(kind)
    assert(type(kind) == "string", "export kind required")
    return join(Storage.exports_root(), kind)
end

function Storage.export_doc(kind, doc_id)
    assert(type(doc_id) == "string", "doc_id required")
    return join(Storage.export_root(kind), doc_id .. ".txt")
end

function Storage.export_meta(kind, doc_id)
    return join(Storage.export_root(kind), doc_id .. ".meta.json")
end

------------------------------------------------------------
-- System Internals
------------------------------------------------------------

function Storage.system_root()
    return join(Storage.root(), "system")
end

function Storage.runtime_ids()
    return join(Storage.system_root(), "runtime_ids")
end

function Storage.presets(domain)
    assert(type(domain) == "string", "domain required")
    return join(Storage.system_root(), "presets", domain)
end

function Storage.vendor_cache_root()
    return join(Storage.system_root(), "caches", "vendor")
end

------------------------------------------------------------
-- Sessions
------------------------------------------------------------

function Storage.sessions_root()
    return join(Storage.root(), "sessions")
end

function Storage.session_file(name)
    name = name or "last_session"
    return join(Storage.sessions_root(), name .. ".json")
end

return Storage
