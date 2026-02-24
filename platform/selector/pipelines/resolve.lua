-- platform/selector/pipelines/resolve.lua
--
-- Composes selector internals.
-- No tracing. No contracts.

local Registry = require("platform.selector.registry")

local Resolve = {}

----------------------------------------------------------------
-- Normalize token input
--
-- Supports:
--   get(root, { "a", 1 })
--   get(root, "a", 1)
----------------------------------------------------------------

local function normalize_tokens(tokens, ...)
    if type(tokens) == "table" and select("#", ...) == 0 then
        return tokens
    end

    local out = {}

    if tokens ~= nil then
        out[#out + 1] = tokens
    end

    local count = select("#", ...)
    for i = 1, count do
        out[#out + 1] = select(i, ...)
    end

    return out
end

----------------------------------------------------------------
-- GET
----------------------------------------------------------------

function Resolve.get(root, tokens, ...)
    local normalized = normalize_tokens(tokens, ...)

    local ok, err = Registry.validate_tokens.run(normalized)
    if not ok then
        return nil, {
            step = 0,
            reason = "invalid_tokens",
            message = err,
            path = normalized,
        }
    end

    return Registry.walk.run(root, normalized)
end

----------------------------------------------------------------
-- EXISTS
----------------------------------------------------------------

function Resolve.exists(root, tokens, ...)
    local normalized = normalize_tokens(tokens, ...)

    local ok, err = Registry.validate_tokens.run(normalized)
    if not ok then
        return false, err
    end

    local value, walk_err = Registry.walk.run(root, normalized)

    if value == nil then
        return false, walk_err
    end

    return true
end

return Resolve
