-- system/infrastructure/storage/controller.lua

local Storage = {}
local ROOT = "data"

local function join(...)
    return table.concat({...}, "/")
end

------------------------------------------------------------
-- Ledgers
------------------------------------------------------------

function Storage.ledgers_root()
    return join(ROOT, "ledgers")
end

function Storage.ledger_root(ledger_id)
    return join(Storage.ledgers_root(), ledger_id)
end

function Storage.ledger_file(ledger_id)
    return join(Storage.ledger_root(ledger_id), "ledger.json")
end

function Storage.ledger_txn_dir(ledger_id, txn_id)
    return join(Storage.ledger_root(ledger_id), "txn", txn_id)
end

function Storage.ledger_txn_file(ledger_id, txn_id, name)
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

function Storage.client_file(client_id)
    return join(ROOT, "clients", client_id .. ".json")
end

------------------------------------------------------------
-- Exports
------------------------------------------------------------

function Storage.export_root(kind)
    return join(ROOT, "exports", kind)
end

function Storage.export_doc(kind, doc_id)
    return join(Storage.export_root(kind), doc_id .. ".txt")
end

function Storage.export_meta(kind, doc_id)
    return join(Storage.export_root(kind), doc_id .. ".meta.json")
end

------------------------------------------------------------
-- System
------------------------------------------------------------

function Storage.runtime_ids()
    return join(ROOT, "system", "runtime_ids")
end

function Storage.presets(domain)
    return join(ROOT, "system", "presets", domain)
end

function Storage.vendor_cache_root()
    return join(ROOT, "system", "caches", "vendor")
end

------------------------------------------------------------
-- Sessions
------------------------------------------------------------

function Storage.sessions_root()
    return join(ROOT, "sessions")
end

function Storage.session_file(name)
    name = name or "last_session"
    return join(Storage.sessions_root(), name .. ".json")
end

return Storage
