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
    match     = function(c)
        return c.size == 2
            and c.tokens[1].labels
            and c.tokens[1].labels.prefix_separator
            and c.tokens[2].traits
            and c.tokens[2].traits.numeric
    end,
    evaluate  = function(c)
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
    match     = function(c)
        return c.size == 2
            and c.tokens[1].traits
            and c.tokens[1].traits.numeric
            and c.tokens[2].labels
            and c.tokens[2].labels.postfix_separator
    end,
    evaluate  = function(c)
        return { value = tonumber(c.tokens[1].raw) }
    end,
}

Rules[#Rules + 1] = {
    name      = "chunk_count_postfix_infix",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.95,
    explicit  = true,

    match     = function(chunk)
        if chunk.size ~= 2 then return false end
        local a, b = chunk.tokens[1], chunk.tokens[2]
        return a.traits and a.traits.numeric
            and b.labels and b.labels.infix_separator
    end,

    evaluate  = function(chunk)
        return { value = tonumber(chunk.tokens[1].raw) }
    end,
}

-- Glued number + unit: "10pcs" / "8ft"
Rules[#Rules + 1] = {
    name      = "chunk_explicit_num_unit",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.95,
    explicit  = true,
    match     = function(c)
        return c.size == 2
            and c.tokens[1].traits
            and c.tokens[1].traits.numeric
            and c.tokens[2].traits
            and c.tokens[2].traits.unit_candidate
    end,
    evaluate  = function(c)
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
    match     = function(c)
        return c.has_num and c.has_infix and c.size >= 5
    end,
    evaluate  = function(c)
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

-- 4-number infix chain: treat first 3 nums as dimensions (h,w,l)
-- Example: "2 x 4 x 8 x 10" => dims = 2x4x8 (ct handled by separate rule)
Rules[#Rules + 1] = {
    name      = "chunk_dimension_chain_3_of_4",
    scope     = "chunk",
    slot      = "dimensions",
    certainty = 0.90,
    explicit  = true,

    match     = function(c)
        if not (c and c.has_num and c.has_infix and c.tokens) then return false end

        local nums = {}
        for _, t in ipairs(c.tokens) do
            if t.traits and t.traits.numeric then
                nums[#nums + 1] = t
            end
        end

        return #nums == 4
    end,

    evaluate  = function(c)
        local nums = {}
        local first, last

        for _, t in ipairs(c.tokens) do
            if t.traits and t.traits.numeric then
                nums[#nums + 1] = t
                first           = first or t
                last            = t
            end
        end

        if #nums ~= 4 then return nil end

        return {
            value = {
                height = tonumber(nums[1].raw),
                width  = tonumber(nums[2].raw),
                length = tonumber(nums[3].raw),
            },

            -- semantic truth: dims only
            span_override = {
                from = nums[1].index,
                to   = nums[3].index,
            },

            -- syntactic truth: whole chain consumed
            touched = {
                from = first.index,
                to   = last.index,
            },
        }
    end,
}

-- 4-number infix chain: trailing count
-- Example: "2 x 4 x 8 x 10" => ct = 10
Rules[#Rules + 1] = {
    name      = "chunk_count_trailing_infix_chain_4",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.88,
    explicit  = true,

    match     = function(c)
        if not (c and c.has_num and c.has_infix and c.tokens) then return false end

        local nums = {}
        for _, t in ipairs(c.tokens) do
            if t.traits and t.traits.numeric then
                nums[#nums + 1] = t
            end
        end

        return #nums == 4
    end,

    evaluate  = function(c)
        local nums = {}
        local first, last

        for _, t in ipairs(c.tokens) do
            if t.traits and t.traits.numeric then
                nums[#nums + 1] = t
                first           = first or t
                last            = t
            end
        end

        if #nums ~= 4 then return nil end

        return {
            value = tonumber(nums[4].raw),

            span_override = {
                from = nums[4].index,
                to   = nums[4].index,
            },

            -- consume the preceding infix separator
            touched = {
                from = nums[3].index,
                to   = nums[4].index,
            },
        }
    end,

}

-- Infix separator followed by numeric + length unit: "x8ft"
Rules[#Rules + 1] = {
    name      = "chunk_length_postfix_infix",
    scope     = "chunk",
    slot      = "length",
    certainty = 0.95,
    explicit  = true,

    match     = function(chunk)
        if chunk.size ~= 3 then return false end
        local a, b, c = chunk.tokens[1], chunk.tokens[2], chunk.tokens[3]
        return a.labels and a.labels.infix_separator
            and b.traits and b.traits.numeric
            and c.traits and c.traits.unit_kind == "length"
    end,

    evaluate  = function(chunk)
        return {
            value = tonumber(chunk.tokens[2].raw),

            span_override = {
                from = chunk.tokens[2].index,
                to   = chunk.tokens[2].index,
            },

            -- consume the infix + number + unit
            touched = {
                from = chunk.tokens[1].index,
                to   = chunk.tokens[3].index,
            },
        }
    end,
}

return Rules
