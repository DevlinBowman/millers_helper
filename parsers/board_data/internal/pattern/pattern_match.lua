-- parsers/board_data/internal/pattern/pattern_match.lua

local function match_at(tokens, start, pattern)
    local matched = {}

    for offset = 1, #pattern do
        local i = start + offset - 1
        local t = tokens[i]
        if not t then
            return nil
        end

        local pred = pattern[offset]

        -- IMPORTANT:
        -- predicates receive (token, index, tokens)
        local ok = pred(t, i, tokens)
        if not ok then
            return nil
        end

        matched[#matched + 1] = t
    end

    return matched
end

return {
    match_at = match_at
}
