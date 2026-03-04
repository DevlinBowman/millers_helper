# field_record_contract.md

-- Canonical FieldRecord Contract
-- Defines the semantic shape of all fields in the system.
-- This is the meta-schema governing board, order, transaction, etc.

```lua
local FieldRecordContract = {

    ----------------------------------------------------------------
    -- Identity
    ----------------------------------------------------------------

    kind = "field", 
    -- Invariant discriminator.
    -- Allows registry to distinguish field records from value records.

    domain = "<string>", 
    -- Owning domain of the field.
    -- Example: "board", "order", "transaction".
    -- Defines structural namespace only (not grouping).

    name = "<string>",
    -- Canonical object key.
    -- Example: "base_h", "grade", "order_id".


    ----------------------------------------------------------------
    -- Type System
    ----------------------------------------------------------------

    type = "symbol" or "number" or "string" or "boolean" or "table",
    -- Primitive semantic type.
    -- Drives validation and coercion expectations.

    ----------------------------------------------------------------
    -- Structural Requirements
    ----------------------------------------------------------------

    required = true or false,
    -- Whether the field must exist structurally
    -- for the object to pass Core:exists().

    default = nil or "<any>",
    -- Template default used by Core:template(domain).
    -- Does NOT imply authority.


    ----------------------------------------------------------------
    -- Symbolic Constraint (Closed-World Link)
    ----------------------------------------------------------------

    reference = "<value_domain>" or nil,
    -- Optional.
    -- If type == "symbol", reference links this field
    -- to a closed value universe.
    --
    -- Example:
    --   reference = "grade"
    --
    -- Validation rule:
    --   object[field.name] must resolve to a registered
    --   value in that domain.
    --
    -- If nil → no symbolic constraint enforced.


    ----------------------------------------------------------------
    -- Authority & Mutability Policy
    ----------------------------------------------------------------

    authority = "authoritative"
             or "derived"
             or "system"
             or "archival",
    -- Semantic ownership model.
    --
    -- authoritative → user-supplied canonical input
    -- derived       → computed by engine
    -- system        → runtime-managed internal data
    -- archival      → write-once immutable historical record

    mutable = true or false,
    -- Runtime write permission.
    --
    -- Example:
    --   derived fields → mutable = false
    --   archival IDs   → mutable = false
    --   user inputs    → mutable = true


    ----------------------------------------------------------------
    -- Numeric Semantics (Optional)
    ----------------------------------------------------------------

    unit = "<string>" or nil,
    -- Semantic measurement unit.
    -- Example: "inches", "feet", "usd", "board_feet".

    precision = <number> or nil,
    -- Numeric rounding policy hint.
    -- Example: 2 for currency, 3 for volume.


    ----------------------------------------------------------------
    -- Logical Grouping (Projection Only)
    ----------------------------------------------------------------

    groups = { "<string>", ... } or nil,
    -- Logical classification tags.
    -- Used for introspection and projection.
    --
    -- Example:
    --   { "dimensions", "physical" }
    --   { "pricing" }
    --   { "metrics", "volume" }
    --
    -- Does NOT affect validation or structure.


    ----------------------------------------------------------------
    -- Documentation / Compatibility
    ----------------------------------------------------------------

    description = "<string>" or nil,
    -- Human-readable semantic explanation.

    aliases = { "<string>", ... } or nil,
    -- Optional alternate input keys.
    -- Used by ingestion/classifier layer only.
}

return FieldRecordContract
```
