-- pipelines/compress.lua
--
-- Order compression layer.
--
-- Responsibility:
--   • Group classified rows by identity field
--   • Merge distributed order fragments
--   • Collect board partitions per order
--
-- Pure structural aggregation.
-- No domain builders.

local Compress = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function resolve_identity(row, identity_key)
    local order_part = row.order or {}
    return order_part[identity_key]
end

local function merge_order_fragments(rows)
    local merged = {}

    for _, row in ipairs(rows) do
        local order_part = row.order or {}

        for k, v in pairs(order_part) do
            if merged[k] == nil then
                merged[k] = v
            elseif merged[k] ~= v then
                -- deterministic rule: first wins
                -- upgrade later if needed
            end
        end
    end

    return merged
end

local function collect_boards(rows)
    local boards = {}

    for _, row in ipairs(rows) do
        if row.board and next(row.board) ~= nil then
            boards[#boards + 1] = row.board
        end
    end

    return boards
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Compress.run(classified_rows, identity_key)

    assert(type(classified_rows) == "table", "Compress.run(): rows required")
    assert(type(identity_key) == "string", "Compress.run(): identity_key required")

    local identities = {}
    local rows_by_identity = {}
    local rows_without_identity = {}

    ------------------------------------------------------------
    -- Scan rows
    ------------------------------------------------------------

    for _, row in ipairs(classified_rows) do
        local order_part = row.order or {}
        local identity = order_part[identity_key]

        if identity ~= nil and identity ~= "" then
            identity = tostring(identity)

            identities[identity] = true

            local bucket = rows_by_identity[identity]
            if not bucket then
                bucket = {}
                rows_by_identity[identity] = bucket
            end

            table.insert(bucket, row)
        else
            table.insert(rows_without_identity, row)
        end
    end

    ------------------------------------------------------------
    -- Count distinct identities
    ------------------------------------------------------------

    local distinct = {}
    for id in pairs(identities) do
        distinct[#distinct + 1] = id
    end

    ------------------------------------------------------------
    -- Case 1: No identity anywhere
    ------------------------------------------------------------

    if #distinct == 0 then
        return {
            {
                order  = {},
                boards = collect_boards(classified_rows),
            }
        }
    end

    ------------------------------------------------------------
    -- Case 2: Exactly one identity
    ------------------------------------------------------------

    if #distinct == 1 then
        local id = distinct[1]

        local all_rows = {}

        -- include rows with identity
        for _, row in ipairs(rows_by_identity[id]) do
            all_rows[#all_rows + 1] = row
        end

        -- include rows without identity
        for _, row in ipairs(rows_without_identity) do
            all_rows[#all_rows + 1] = row
        end

        return {
            {
                order  = merge_order_fragments(all_rows),
                boards = collect_boards(all_rows),
            }
        }
    end

    ------------------------------------------------------------
    -- Case 3: Multiple identities
    ------------------------------------------------------------

    if #rows_without_identity > 0 then
        error("ambiguous order compression: multiple order identities present and some rows lack identity")
    end

    local results = {}

    for _, id in ipairs(distinct) do
        local group_rows = rows_by_identity[id]

        results[#results + 1] = {
            order  = merge_order_fragments(group_rows),
            boards = collect_boards(group_rows),
        }
    end

    return results
end

return Compress
