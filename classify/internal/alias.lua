-- classify/alias.lua
--
-- Canonical + alias resolution.
-- SPEC-ONLY.
-- No pattern matching.
--
-- Resolution order:
--   1. Exact raw key match
--   2. Normalized match
--   3. nil
--
-- Collisions tracked across both exact + normalized indexes.

local Spec      = require("classify.internal.spec")
local Normalize = require("classify.internal.normalize")

local Alias = {}

local INDEX_EXACT  = {}
local INDEX_NORMAL = {}
local COLLISIONS   = {}

----------------------------------------------------------------
-- Collision tracking
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
-- Indexing
----------------------------------------------------------------

local function index_one(raw_key, canonical)
    -- exact index
    local previous = INDEX_EXACT[raw_key]
    if previous and previous ~= canonical then
        remember_collision(raw_key, previous)
        remember_collision(raw_key, canonical)
    else
        INDEX_EXACT[raw_key] = canonical
    end

    -- normalized index
    local normalized = Normalize.key(raw_key)
    local previous_norm = INDEX_NORMAL[normalized]
    if previous_norm and previous_norm ~= canonical then
        remember_collision(normalized, previous_norm)
        remember_collision(normalized, canonical)
    else
        INDEX_NORMAL[normalized] = canonical
    end
end

local function index_fields(field_table)
    for canonical, def in pairs(field_table) do
        -- canonical self-index
        index_one(canonical, canonical)

        -- declared aliases
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

--- Resolve a raw key to canonical field.
---@param raw_key string|any
---@return string|nil
function Alias.resolve(raw_key)
    if raw_key == nil then
        return nil
    end

    local key = tostring(raw_key)

    -- 1. Exact
    local exact = INDEX_EXACT[key]
    if exact then
        return exact
    end

    -- 2. Normalized
    local normalized = Normalize.key(key)
    return INDEX_NORMAL[normalized]
end

--- Return collision report.
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
