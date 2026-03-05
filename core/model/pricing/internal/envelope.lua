-- core/model/pricing/internal/envelope.lua
--
-- Minimal helpers for canonical object envelopes.
--
-- Convention:
--   env.kind   : string
--   env.items  : table[] | nil
--   env.meta   : table | nil

local Envelope = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function assert_table(x, msg)
    assert(type(x) == "table", msg)
end

local function assert_string(x, msg)
    assert(type(x) == "string" and x ~= "", msg)
end

----------------------------------------------------------------
-- Items Envelope
----------------------------------------------------------------

---@param env table
---@param expected_kind string|nil
---@param label string
---@return table[] items, table meta
function Envelope.items(env, expected_kind, label)

    label = label or "envelope"

    assert_table(env, "[" .. label .. "] envelope required")

    if expected_kind ~= nil then
        assert_string(env.kind, "[" .. label .. "] kind required")
        assert(env.kind == expected_kind,
            "[" .. label .. "] kind must be '" .. expected_kind .. "'")
    end

    local items = env.items
    assert_table(items, "[" .. label .. "] items required")

    local meta = env.meta
    if meta ~= nil then
        assert_table(meta, "[" .. label .. "] meta must be table|nil")
    else
        meta = {}
    end

    return items, meta
end

----------------------------------------------------------------
-- Metadata Envelope
----------------------------------------------------------------

---@param env table
---@param expected_kind string|nil
---@param label string
---@return table meta
function Envelope.meta(env, expected_kind, label)

    label = label or "envelope"

    assert_table(env, "[" .. label .. "] envelope required")

    if expected_kind ~= nil then
        assert_string(env.kind, "[" .. label .. "] kind required")
        assert(env.kind == expected_kind,
            "[" .. label .. "] kind must be '" .. expected_kind .. "'")
    end

    local meta = env.meta
    if meta ~= nil then
        assert_table(meta, "[" .. label .. "] meta must be table|nil")
        return meta
    end

    return {}

end

----------------------------------------------------------------

return Envelope
