-- system/infrastructure/attachment_store.lua
--
-- Ledger attachment persistence.
-- Infrastructure only:
--   - resolves canonical destinations via Storage schema
--   - ensures directories exist via platform FS
--   - copies bytes (binary-safe)
--
-- No domain rules.

local Storage = require("system.infrastructure.storage.controller")
local FS      = require("platform.io.registry").fs

local AttachmentStore = {}

local function copy_file_bytes(src, dest)
    local fh_in, in_err = io.open(src, "rb")
    if not fh_in then
        return nil, in_err
    end

    local bytes = fh_in:read("*a")
    fh_in:close()

    if bytes == nil then
        return nil, "failed to read attachment bytes"
    end

    local fh_out, out_err = io.open(dest, "wb")
    if not fh_out then
        return nil, out_err
    end

    fh_out:write(bytes)
    fh_out:close()

    return true
end

--- Copy a file into the transaction attachment directory.
--- @param ledger_id string
--- @param txn_id string
--- @param source_path string
--- @return string|nil dest_path
--- @return string|nil err
function AttachmentStore.add(ledger_id, txn_id, source_path)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    assert(type(txn_id) == "string" and txn_id ~= "", "txn_id required")
    assert(type(source_path) == "string" and source_path ~= "", "source_path required")

    local filename = FS.get_filename(source_path)
    if not filename or filename == "" then
        return nil, "invalid attachment path: missing filename"
    end

    local dest_dir  = Storage.ledger_txn_attachments(ledger_id, txn_id)
    local dest_path = dest_dir .. "/" .. filename

    FS.ensure_parent_dir(dest_path)

    local ok, err = copy_file_bytes(source_path, dest_path)
    if not ok then
        return nil, err
    end

    return dest_path
end

return AttachmentStore
