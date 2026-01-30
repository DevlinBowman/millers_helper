-- parsers/board_data/chunk/chunk_ignore.lua
--
-- Structural merge prohibitions
-- PURPOSE:
--   • Define situations where chunk merging is illegal
--   • Preserve user-intended token boundaries
--   • Prevent condensation from inventing semantics

local Ignore = {}

local function is_numeric(t)
    return t and t.traits and t.traits.numeric
end

local function is_separator(t)
    return t and t.labels and t.labels.separator_candidate
end

-- ------------------------------------------------------------
-- Rule 1: Leading count marker is atomic
--   ^[num][sep]
-- ------------------------------------------------------------
local function forbid_leading_count_merge(left, right)
    if not (left and right) then return false end
    if left.id ~= 1 then return false end
    if left.size ~= 2 then return false end

    local a = left.tokens[1]
    local b = left.tokens[2]

    return is_numeric(a) and is_separator(b)
end

-- ------------------------------------------------------------
-- Rule 2: Reject merges that create numeric adjacency
--   [num][num]
--   [num][label][num]
-- ------------------------------------------------------------
local function forbid_numeric_adjacency(left, right)
    if not (left and right) then return false end

    local a = left.tokens[#left.tokens]
    local b = right.tokens[1]

    -- num | num
    if is_numeric(a) and is_numeric(b) then
        return true
    end

    -- num | label | num
    if is_numeric(a) and is_separator(b) then
        local c = right.tokens[2]
        if is_numeric(c) then
            return true
        end
    end

    return false
end

-- ------------------------------------------------------------
-- Rule: Do not collapse spaced infix operators
--
-- [num][ws][sep][ws][num] must not become [num][sep][num]
-- User-intent spacing is significant and must be preserved.
-- ------------------------------------------------------------
local function forbid_spaced_infix_collapse(left, right)
    if not (left and right) then return false end

    local a = left.tokens[#left.tokens]
    local b = right.tokens[1]

    -- We are only concerned with merging around an infix separator
    if not (a and b) then return false end

    -- Case: left ends with infix separator
    if a.labels and a.labels.infix_separator then
        -- If that infix was originally preceded by whitespace, forbid
        local prev = left.tokens[#left.tokens - 1]
        if prev and prev.lex == "ws" then
            return true
        end
    end

    -- Case: right begins with infix separator
    if b.labels and b.labels.infix_separator then
        local next = right.tokens[2]
        if next and next.lex == "ws" then
            return true
        end
    end

    return false
end

-- ------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------
function Ignore.should_forbid_merge(left, right)
    if forbid_leading_count_merge(left, right) then
        return true
    end

    if forbid_numeric_adjacency(left, right) then
        return true
    end

    if forbid_spaced_infix_collapse(left, right) then
        return true
    end

    return false
end

return Ignore
