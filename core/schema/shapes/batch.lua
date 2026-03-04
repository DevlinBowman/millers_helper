-- core/shapes/batch.lua
--
-- Canonical structural definition for batch envelopes.

local BatchShape = {}

BatchShape.SHAPE = {

    kind = "shape",
    domain = "batch",
    fields = {
        "order",
        "boards",
        "allocations",
        "meta",
    },
}

return BatchShape
