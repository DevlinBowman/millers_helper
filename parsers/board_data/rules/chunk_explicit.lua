-- parsers/board_data/rules/chunk_explicit.lua
--
-- Chunk-scoped explicit rules
-- PURPOSE:
--   • Assert meaning from tightly bound chunk structure
--   • No cross-chunk context

local Rules = {}

-- Prefix separator glued to number: "x10"
Rules[#Rules + 1] = {
    name      = "chunk_count_prefix_symbol",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.92,
    explicit  = true,
    match = function(c)
        return c.size == 2
           and c.tokens[1].labels
           and c.tokens[1].labels.prefix_separator
           and c.tokens[2].traits
           and c.tokens[2].traits.numeric
    end,
    evaluate = function(c)
        return { value = tonumber(c.tokens[2].raw) }
    end,
}

-- Number glued to postfix separator: "10x"
Rules[#Rules + 1] = {
    name      = "chunk_count_postfix_symbol",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.90,
    explicit  = true,
    match = function(c)
        return c.size == 2
           and c.tokens[1].traits
           and c.tokens[1].traits.numeric
           and c.tokens[2].labels
           and c.tokens[2].labels.postfix_separator
    end,
    evaluate = function(c)
        return { value = tonumber(c.tokens[1].raw) }
    end,
}

-- Glued number + unit: "10pcs" / "8ft"
Rules[#Rules + 1] = {
    name      = "chunk_explicit_num_unit",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.95,
    explicit  = true,
    match = function(c)
        return c.size == 2
           and c.tokens[1].traits
           and c.tokens[1].traits.numeric
           and c.tokens[2].traits
           and c.tokens[2].traits.unit_candidate
    end,
    evaluate = function(c)
        local n = tonumber(c.tokens[1].raw)
        local k = c.tokens[2].traits.unit_kind
        if k == "count" then return { value = n, slot_override = "count" } end
        if k == "length" then return { value = n, slot_override = "length" } end
        return nil
    end,
}

-- Chunk containing exactly 3 numbers separated by infix separators
Rules[#Rules + 1] = {
    name      = "chunk_dimension_chain",
    scope     = "chunk",
    slot      = "dimensions",
    certainty = 0.95,
    explicit  = true,
    match = function(c)
        return c.has_num and c.has_infix and c.size >= 5
    end,
    evaluate = function(c)
        local nums = {}
        for _, t in ipairs(c.tokens) do
            if t.traits and t.traits.numeric then
                nums[#nums + 1] = tonumber(t.raw)
            end
        end
        if #nums ~= 3 then return nil end
        return {
            value = {
                height = nums[1],
                width  = nums[2],
                length = nums[3],
            }
        }
    end,
}

return Rules
