-- system/app/persistence.lua
--
-- Persistence Layer for Session State
--
-- Responsibility:
--   • Load and save the persistable portion of State
--
-- It persists ONLY:
--   • state.context
--   • state.resources
--
-- It explicitly does NOT persist:
--   • state.results (ephemeral service outputs)
--   • runtime objects
--
-- This module is intentionally thin:
--   • No domain logic
--   • No runtime construction
--   • No schema validation
--   • No migration logic (version field reserved for future use)
--
-- Lifecycle:
--   Surface → Persistence.load()  → State.new(...)
--   Surface → Persistence.save()  → write JSON snapshot

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")
local State       = require("system.app.state")

---@class Persistence
local Persistence = {}

------------------------------------------------------------
-- load()
------------------------------------------------------------
-- Restores a persisted session snapshot from disk.
--
-- Behavior:
--   • If file missing or invalid → returns empty State
--   • Always initializes results = {} (ephemeral)
--
-- Failure model:
--   • Never throws
--   • Always returns a valid State instance
--
---@param opts? { file?: string }
---@return State
function Persistence.load(opts)
    opts = opts or {}

    -- Resolve session file path
    local path = opts.file or Storage.session_file("last_session")

    -- Attempt to read JSON snapshot
    local data = FileGateway.read_json(path)

    -- If missing, corrupted, or invalid shape → start fresh
    if not data or type(data) ~= "table" then
        return State.new()
    end

    -- Construct new State from persisted fields only.
    -- results intentionally reset.
    return State.new({
        context   = data.context,
        resources = data.resources,
        results   = {}, -- always ephemeral
    })
end

------------------------------------------------------------
-- save()
------------------------------------------------------------
-- Persists the session snapshot to disk.
--
-- Only writes:
--   • context
--   • resources
--
-- Ignores:
--   • results
--
-- Failure model:
--   • Returns false, err on failure
--   • Does NOT throw
--
---@param state State
---@param opts? { file?: string }
---@return boolean|string
function Persistence.save(state, opts)
    opts = opts or {}

    -- Resolve session file path
    local path = opts.file or Storage.session_file("last_session")

    -- Construct persistable payload.
    -- Version reserved for future migration.
    local payload = {
        version   = 1,
        context   = state.context,
        resources = state.resources,
    }

    local ok, err = FileGateway.write_json(path, payload)

    if not ok then
        return false, err
    end

    return true
end

return Persistence
