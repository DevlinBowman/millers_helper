-- classify/internal/alias.lua
--
-- Canonical + alias resolution engine.
--
-- PURPOSE
-- -------
-- Convert raw attribute keys into canonical field names
-- declared in classify.internal.schema.
--
-- This module:
--   • Builds static lookup indexes at load time
--   • Supports exact and normalized resolution
--   • Tracks schema-level alias collisions
--
-- This module does NOT:
--   • Perform pattern matching
--   • Perform fuzzy inference
--   • Perform domain ownership checks
--   • Perform reconciliation or validation
--
-- It is a pure, deterministic key-mapping system.

local Spec      = require("platform.classify.internal.schema")
local Normalize = require("platform.classify.internal.normalize")

local Alias = {}

----------------------------------------------------------------
-- Internal Index Structures
--
-- INDEX_EXACT:
--   raw_key → canonical
--
-- INDEX_NORMAL:
--   normalized(raw_key) → canonical
--
-- COLLISIONS:
--   key → { canonical1 = true, canonical2 = true }
--
-- COLLISIONS represent configuration errors in schema.
----------------------------------------------------------------

local INDEX_EXACT  = {}
local INDEX_NORMAL = {}
local COLLISIONS   = {}

----------------------------------------------------------------
-- Collision tracking
--
-- If two different canonical fields declare the same alias
-- (either exact or normalized), that is a schema-level error.
--
-- We do not throw immediately; we record collisions for diagnostics.
----------------------------------------------------------------

local function remember_collision(key, canonical)
    local bucket = COLLISIONS[key]
    if not bucket then
        bucket = {}
        COLLISIONS[key] = bucket
    end
    bucket[canonical] = true
end

----------------------------------------------------------------
-- Indexing logic
--
-- index_one registers:
--   • exact raw_key → canonical
--   • normalized(raw_key) → canonical
--
-- If a previous canonical is already mapped for that key
-- and differs, a collision is recorded.
----------------------------------------------------------------

local function index_one(raw_key, canonical)
    ------------------------------------------------------------
    -- Exact index
    ------------------------------------------------------------
    local previous = INDEX_EXACT[raw_key]
    if previous and previous ~= canonical then
        remember_collision(raw_key, previous)
        remember_collision(raw_key, canonical)
    else
        INDEX_EXACT[raw_key] = canonical
    end

    ------------------------------------------------------------
    -- Normalized index
    --
    -- Normalize.key enforces:
    --   • lowercase
    --   • trimmed
    --   • unified separators
    --
    -- This allows:
    --   "Order Number"
    --   "order_number"
    --   "Order-Number"
    --
    -- to resolve identically.
    ------------------------------------------------------------
    local normalized = Normalize.key(raw_key)
    local previous_norm = INDEX_NORMAL[normalized]

    if previous_norm and previous_norm ~= canonical then
        remember_collision(normalized, previous_norm)
        remember_collision(normalized, canonical)
    else
        INDEX_NORMAL[normalized] = canonical
    end
end

----------------------------------------------------------------
-- Index all canonical fields declared in schema.
--
-- We index:
--   • canonical name itself
--   • each declared alias
--
-- This happens once at module load time.
----------------------------------------------------------------

local function index_fields(field_table)
    for canonical, def in pairs(field_table) do
        -- Canonical self-index
        index_one(canonical, canonical)

        -- Declared aliases
        for _, alias_key in ipairs(def.aliases or {}) do
            index_one(alias_key, canonical)
        end
    end
end

-- Build indexes once at load time
index_fields(Spec.board_fields)
index_fields(Spec.order_fields)

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Resolve a raw key to its canonical field.
---
--- Resolution order:
---   1. Exact match (raw_key as-is)
---   2. Normalized match (Normalize.key(raw_key))
---   3. nil (unrecognized)
---
--- This function performs no ownership checks.
--- That is handled later by classify.partition.
---
---@param raw_key string|any
---@return string|nil
function Alias.resolve(raw_key)
    if raw_key == nil then
        return nil
    end

    local key = tostring(raw_key)

    ------------------------------------------------------------
    -- 1. Exact resolution
    ------------------------------------------------------------
    local exact = INDEX_EXACT[key]
    if exact then
        return exact
    end

    ------------------------------------------------------------
    -- 2. Normalized resolution
    ------------------------------------------------------------
    local normalized = Normalize.key(key)
    return INDEX_NORMAL[normalized]
end

----------------------------------------------------------------
-- Collision Report
--
-- Returns all detected alias collisions.
--
-- Collisions indicate schema misconfiguration where:
--   • Two canonical fields share the same alias
--   • Or normalize to the same key
--
-- This is a structural schema problem, not a row-level issue.
----------------------------------------------------------------

---@return table<string, string[]>
function Alias.collisions()
    local out = {}

    for key, set in pairs(COLLISIONS) do
        local list = {}
        for canonical in pairs(set) do
            list[#list + 1] = canonical
        end
        table.sort(list)
        out[key] = list
    end

    return out
end

return Alias
