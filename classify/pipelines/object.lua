-- classify/pipelines/object.lua
--
-- Classification behavior pipeline.
--
-- PURPOSE
-- -------
-- Convert one decoded attribute map (flat object) into
-- domain-partitioned canonical fragments.
--
-- This module:
--   • Resolves raw keys → canonical keys (alias resolution)
--   • Determines domain ownership (board vs order)
--   • Partitions fields accordingly
--   • Tracks structural diagnostics (overwrites, alias collisions)
--
-- This module does NOT:
--   • Perform reconciliation across rows
--   • Enforce policy decisions
--   • Validate domain semantics
--   • Build final domain models
--
-- It is purely structural normalization of a single object.

local Registry = require("classify.registry")

local Object = {}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Classify one decoded object into domain partitions.
---
--- INPUT
---   object : table (flat attribute map from parser/format layer)
---
--- OUTPUT
---   {
---     board       = table,   -- canonical board fields
---     order       = table,   -- canonical order fields
---     unknown     = table,   -- keys not recognized by alias system
---     diagnostics = {
---         overwrites = table[]|nil,   -- duplicate canonical assignments
---         collisions = table|nil,     -- alias index conflicts
---     }
---   }
---
function Object.run(object)
    assert(type(object) == "table", "classify.pipelines.object: table required")

    local alias = Registry.alias
    local part  = Registry.partition
    local spec  = Registry.spec

    ----------------------------------------------------------------
    -- Output shape
    --
    -- board/order contain canonicalized fields only.
    -- unknown preserves raw key/value pairs not recognized.
    -- diagnostics captures structural irregularities.
    ----------------------------------------------------------------

    local out = {
        board       = {},
        order       = {},
        unknown     = {},
        diagnostics = {
            overwrites = nil,
            collisions = nil,
        },
    }

    ----------------------------------------------------------------
    -- Phase 1: Field-by-field classification
    --
    -- For each raw key:
    --   1. Resolve canonical key via alias system
    --   2. Determine domain ownership
    --   3. Assign into board/order partition
    --   4. Track overwrite diagnostics if canonical repeats
    --
    -- No semantic validation occurs here.
    ----------------------------------------------------------------

    for raw_key, value in pairs(object) do
        local canonical = alias.resolve(raw_key)

        ------------------------------------------------------------
        -- Case A: Key not recognized by alias system
        --
        -- The field is not declared in classify.internal.schema.
        -- It is preserved verbatim in unknown for visibility.
        ------------------------------------------------------------
        if not canonical then
            out.unknown[raw_key] = value

        else
            --------------------------------------------------------
            -- Determine domain ownership for canonical field
            --------------------------------------------------------
            local owner = part.owner_of(canonical)

            --------------------------------------------------------
            -- BOARD DOMAIN
            --------------------------------------------------------
            if owner == spec.DOMAIN.BOARD then
                part.set_field(
                    out.board,
                    canonical,
                    value,
                    out.diagnostics,
                    tostring(raw_key)
                )

            --------------------------------------------------------
            -- ORDER DOMAIN
            --------------------------------------------------------
            elseif owner == spec.DOMAIN.ORDER then
                part.set_field(
                    out.order,
                    canonical,
                    value,
                    out.diagnostics,
                    tostring(raw_key)
                )

            --------------------------------------------------------
            -- Canonical resolved but no declared owner
            --
            -- This should not normally occur if schema is aligned.
            -- Treated as unknown to avoid silent loss.
            --------------------------------------------------------
            else
                out.unknown[raw_key] = value
            end
        end
    end

    ----------------------------------------------------------------
    -- Phase 2: Alias index collision diagnostics
    --
    -- If multiple canonical fields share the same alias
    -- (exact or normalized), the alias system records this.
    --
    -- This is a structural configuration issue, not row-specific.
    ----------------------------------------------------------------

    local collisions = alias.collisions()
    if next(collisions) ~= nil then
        out.diagnostics.collisions = collisions
    end

    ----------------------------------------------------------------
    -- Output
    --
    -- At this stage:
    --   • All recognized keys are canonical
    --   • Domain ownership is enforced
    --   • No reconciliation has occurred
    --   • No validation has occurred
    --
    -- The next stage (order_context or board builder)
    -- will apply semantic rules.
    ----------------------------------------------------------------

    return out
end

return Object
