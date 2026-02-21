-- order_context/pipelines/compress.lua
--
-- Order compression + context resolution.
--
-- PURPOSE
-- -------
-- Convert a flat array of classified rows into coherent order groups.
--
-- This pipeline:
--   • Groups rows by a declared identity field (e.g. order_number)
--   • Defines how identity-less rows are treated
--   • Ensures structural consistency before reconciliation
--   • Delegates actual field reconciliation to resolve_group
--
-- This module does NOT:
--   • Perform alias resolution (classify already did that)
--   • Decide field conflicts (policy does that)
--   • Build domain models
--   • Perform tracing or validation
--
-- It is purely structural grouping + orchestration.
--
-- Invariants:
--   • Each returned group represents one logical order
--   • Each group contains:
--         - resolved order context
--         - associated board partitions
--         - reconciliation signals
--         - policy decisions
--
-- No contracts. No tracing.

local Registry     = require("platform.order_context.registry")
local ResolveGroup = require("platform.order_context.pipelines.resolve_group")

local Compress = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

-- Extract board partitions from classified rows.
-- Classification already separated board vs order domains.
-- We simply collect non-empty board fragments.
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

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Compress classified rows into order groups and resolve order context per group.
---
--- INPUT
---   classified_rows : array of classify results
---   identity_key    : canonical order field used as grouping identity
---   opts            : optional behavior flags
---
--- OUTPUT
---   groups[] where each group is:
---   {
---       order     = table,     -- resolved order context
---       boards    = table[],   -- board fragments belonging to this order
---       signals   = table[],   -- reconciliation signals
---       decisions = table,     -- per-field policy decisions
---   }
---
function Compress.run(classified_rows, identity_key, opts)
    opts = opts or {}

    local Util = Registry.util

    ----------------------------------------------------------------
    -- Phase 1: Partition rows by identity
    --
    -- We split rows into:
    --   • rows_by_identity[id]
    --   • rows_without_identity
    --
    -- Identity normalization is applied here to ensure consistent grouping.
    ----------------------------------------------------------------

    local rows_by_identity      = {}
    local rows_without_identity = {}
    local identity_set          = {}

    for _, row in ipairs(classified_rows) do
        local order_part  = row.order or {}
        local raw_identity = order_part[identity_key]
        local identity     = Util.normalize_identity(raw_identity)

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

    ----------------------------------------------------------------
    -- Phase 2: Collect distinct identities (stable order)
    --
    -- Sorting ensures deterministic output order regardless
    -- of input ordering.
    ----------------------------------------------------------------

    local distinct = {}
    for id in pairs(identity_set) do
        distinct[#distinct + 1] = id
    end
    table.sort(distinct)

    ----------------------------------------------------------------
    -- Case 1:
    -- No identity found anywhere.
    --
    -- Interpretation:
    --   The entire input represents a single implicit order.
    --
    -- Behavior:
    --   Treat all rows as one group and let resolve_group
    --   reconcile distributed order fragments.
    ----------------------------------------------------------------

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

    ----------------------------------------------------------------
    -- Case 2:
    -- Exactly one identity present.
    --
    -- Interpretation:
    --   Some rows explicitly declare identity,
    --   others omit it.
    --
    -- Assumption:
    --   Identity-less rows implicitly belong to that single order.
    --
    -- Behavior:
    --   Merge identity-less rows into the single identity bucket.
    ----------------------------------------------------------------

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

    ----------------------------------------------------------------
    -- Case 3:
    -- Multiple identities present AND some rows lack identity.
    --
    -- This is structurally ambiguous:
    --
    --   Example:
    --     Order A rows
    --     Order B rows
    --     Rows with no identity
    --
    -- We cannot deterministically assign identity-less rows.
    --
    -- Therefore this is a hard structural error.
    ----------------------------------------------------------------

    if #rows_without_identity > 0 then
        error(
            "ambiguous order compression: multiple identities present " ..
            "and some rows lack identity. Cannot determine grouping."
        )
    end

    ----------------------------------------------------------------
    -- Case 4:
    -- Multiple identities present.
    --
    -- Interpretation:
    --   Input contains multiple distinct orders.
    --
    -- Behavior:
    --   Create one resolved group per identity.
    ----------------------------------------------------------------

    local results = {}

    for _, id in ipairs(distinct) do
        local group_rows = rows_by_identity[id] or {}
        local resolved   = ResolveGroup.run(group_rows, opts)

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
