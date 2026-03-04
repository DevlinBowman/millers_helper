-- core/schema/engine/bootstrap.lua
--
-- Declarative bootstrap list for the closed-world semantic system.
-- Core consumes this and builds indexes.
--
-- Order of registration:
--   1. values
--   2. fields
--   3. shapes
--
-- Shapes reference fields.
-- Fields reference values.
-- Values are leaf nodes.

local Bootstrap = {}

------------------------------------------------------------
-- Value Domains (Closed Universes)
------------------------------------------------------------

Bootstrap.values = {

    --------------------------------------------------------
    -- Board Value Domains
    --------------------------------------------------------

    "core.schema.values.board.grade",
    "core.schema.values.board.moisture",
    "core.schema.values.board.species",
    "core.schema.values.board.surface",

    --------------------------------------------------------
    -- Order Value Domains
    --------------------------------------------------------

    "core.schema.values.order.status",
    "core.schema.values.order.use",

    ------------------------------------------------------------
    -- Transaction Value Domains
    ------------------------------------------------------------

    "core.schema.values.transaction.type",

    ------------------------------------------------------------
    -- Allocation Value Domains
    ------------------------------------------------------------

    "core.schema.values.allocation.scope",
    "core.schema.values.allocation.basis",

    ------------------------------------------------------------
    -- Shared
    ------------------------------------------------------------

    "core.schema.values.tag",
}

------------------------------------------------------------
-- Field Meta Definitions
------------------------------------------------------------

Bootstrap.fields = {

    "core.schema.fields.board",
    "core.schema.fields.order",
    "core.schema.fields.transaction",
    "core.schema.fields.allocation",
    "core.schema.fields.batch",
}

------------------------------------------------------------
-- Shape Membership Definitions
------------------------------------------------------------

Bootstrap.shapes = {

    "core.schema.shapes.board",
    "core.schema.shapes.order",
    "core.schema.shapes.transaction",
    "core.schema.shapes.allocation_profile",
    "core.schema.shapes.allocation_entry",
    "core.schema.shapes.batch",
}

return Bootstrap
