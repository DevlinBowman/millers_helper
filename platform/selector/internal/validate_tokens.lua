-- platform/selector/internal/validate_tokens.lua
--
-- Strict validation of selector token arrays.

local Validate = {}

function Validate.run(tokens)
    if type(tokens) ~= "table" then
        return nil, "tokens must be table"
    end

    local count = 0

    for i, v in ipairs(tokens) do
        count = count + 1

        local t = type(v)
        if t ~= "string" and t ~= "number" then
            return nil,
                string.format(
                    "invalid token type at index %d: %s",
                    i,
                    t
                )
        end
    end

    -- detect empty token list
    if count == 0 then
        return nil, "tokens cannot be empty"
    end

    -- detect holes
    for k in pairs(tokens) do
        if type(k) ~= "number" or k < 1 or k > count then
            return nil, "tokens must be a contiguous numeric array"
        end
    end

    return true
end

return Validate
