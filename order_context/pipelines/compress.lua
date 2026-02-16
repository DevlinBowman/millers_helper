-- order_context/pipelines/compress.lua
--
-- Order compression + context resolution.
--
-- Responsibility:
--   • Group classified rows by identity field
--   • Enforce one structural order context per identity
--   • Resolve distributed order fragments via resolve_group (spec-driven)
--   • Collect board partitions per order
--
-- No contracts. No tracing.

local Registry     = require("order_context.registry")
local ResolveGroup = require("order_context.pipelines.resolve_group")

local Compress = {}

local function collect_boards(rows)
    local boards = {}

    for _, row in ipairs(rows) do
        local board_part = row.board
        if board_part and next(board_part) ~= nil then
            boards[#boards + 1] = board_part
        end
    end

    return boards
end

--- Compress classified rows into order groups and resolve order context per group.
--- @param classified_rows table[]
--- @param identity_key string
--- @param opts table|nil
--- @return table[] groups { order=table, boards=table[], signals=table[], decisions=table }
function Compress.run(classified_rows, identity_key, opts)
    opts = opts or {}

    local Util = Registry.util

    local rows_by_identity = {}
    local rows_without_identity = {}
    local identity_set = {}

    ------------------------------------------------------------
    -- Partition rows by identity
    ------------------------------------------------------------

    for _, row in ipairs(classified_rows) do
        local order_part = row.order or {}
        local raw_identity = order_part[identity_key]
        local identity = Util.normalize_identity(raw_identity)

        if identity then
            identity_set[identity] = true

            local bucket = rows_by_identity[identity]
            if not bucket then
                bucket = {}
                rows_by_identity[identity] = bucket
            end

            bucket[#bucket + 1] = row
        else
            rows_without_identity[#rows_without_identity + 1] = row
        end
    end

    ------------------------------------------------------------
    -- Collect distinct identities (stable order)
    ------------------------------------------------------------

    local distinct = {}
    for id in pairs(identity_set) do
        distinct[#distinct + 1] = id
    end
    table.sort(distinct)

    ------------------------------------------------------------
    -- Case 1: No identity anywhere → single synthetic order group
    ------------------------------------------------------------

    if #distinct == 0 then
        local resolved = ResolveGroup.run(classified_rows, opts)
        return {
            {
                order     = resolved.order,
                boards    = collect_boards(classified_rows),
                signals   = resolved.signals or {},
                decisions = resolved.decisions or {},
            }
        }
    end

    ------------------------------------------------------------
    -- Case 2: Exactly one identity → absorb identity-less rows
    ------------------------------------------------------------

    if #distinct == 1 then
        local id = distinct[1]

        local combined_rows = {}
        for _, row in ipairs(rows_by_identity[id] or {}) do
            combined_rows[#combined_rows + 1] = row
        end
        for _, row in ipairs(rows_without_identity) do
            combined_rows[#combined_rows + 1] = row
        end

        local resolved = ResolveGroup.run(combined_rows, opts)
        return {
            {
                order     = resolved.order,
                boards    = collect_boards(combined_rows),
                signals   = resolved.signals or {},
                decisions = resolved.decisions or {},
            }
        }
    end

    ------------------------------------------------------------
    -- Case 3: Multiple identities present + any identity-less rows → error
    ------------------------------------------------------------

    if #rows_without_identity > 0 then
        error("ambiguous order compression: multiple identities present and some rows lack identity")
    end

    ------------------------------------------------------------
    -- Case 4: Multiple identities present → one group per identity
    ------------------------------------------------------------

    local results = {}

    for _, id in ipairs(distinct) do
        local group_rows = rows_by_identity[id] or {}
        local resolved = ResolveGroup.run(group_rows, opts)

        results[#results + 1] = {
            order     = resolved.order,
            boards    = collect_boards(group_rows),
            signals   = resolved.signals or {},
            decisions = resolved.decisions or {},
        }
    end

    return results
end

return Compress
