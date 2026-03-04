-- core/fields/batch.lua
--
-- Canonical runtime envelope field definitions.
-- Represents the full batch object moving through the engine.

local RuntimeBatchFields = {}

RuntimeBatchFields.FIELD = {

    ------------------------------------------------
    -- order
    ------------------------------------------------

    order = {
        kind = "field",
        domain = "batch",
        name = "order",
        type = "table",
        required = true,
        default = nil,
        reference = "order",
        authority = "authoritative",
        mutable = true,
        groups = { "batch", "input" },
        description =
            "Canonical order object associated with the batch."
    },
    ------------------------------------------------
    -- boards
    ------------------------------------------------

    boards = {
        kind = "field",
        domain = "batch",
        name = "boards",
        type = "table",
        required = true,
        default = {},
        reference = 'board',
        authority = "authoritative",
        mutable = true,
        groups = { "batch", "input" },
        description =
            "List of board domain objects associated with the batch."
    },

    ------------------------------------------------
    -- allocations
    ------------------------------------------------

    allocations = {
        kind = "field",
        domain = "batch",
        name = "allocations",
        type = "table",
        required = false,
        default = {},
        reference = "allocation_entry",
        authority = "system",
        mutable = true,
        groups = { "allocation" },
        description =
            "Collection of allocation_entry objects associated with the batch."
    },
    ------------------------------------------------
    -- meta
    ------------------------------------------------

    meta = {
        kind = "field",
        domain = "batch",
        name = "meta",
        type = "table",
        required = false,
        default = {},
        reference = nil,
        authority = "system",
        mutable = true,
        groups = { "metadata" },
        description =
            "Runtime metadata attached to the batch (io, ingest, provenance)."
    }

}

return RuntimeBatchFields
