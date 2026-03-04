-- core/engine/bootstrap.lua
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

    "core.values.board.grade",
    "core.values.board.moisture",
    "core.values.board.species",
    "core.values.board.surface",

    --------------------------------------------------------
    -- Order Value Domains
    --------------------------------------------------------

    "core.values.order.status",
    "core.values.order.use",

    --------------------------------------------------------
    -- Transaction Value Domains
    --------------------------------------------------------

    "core.values.transaction.type",

    --------------------------------------------------------
    -- Allocation Value Domains
    --------------------------------------------------------
    "core.values.allocation.scope",
    "core.values.allocation.basis",

    --------------------------------------------------------
    -- Shared
    --------------------------------------------------------

    "core.values.tag",
}

------------------------------------------------------------
-- Field Meta Definitions
------------------------------------------------------------

Bootstrap.fields = {

    "core.fields.board",
    "core.fields.order",
    "core.fields.transaction",
    "core.fields.allocation",
    "core.fields.batch",
}

------------------------------------------------------------
-- Shape Membership Definitions
------------------------------------------------------------

Bootstrap.shapes = {

    "core.shapes.board",
    "core.shapes.order",
    "core.shapes.transaction",
    "core.shapes.allocation_profile",
    "core.shapes.allocation_entry",
    "core.shapes.batch",
}

return Bootstrap
