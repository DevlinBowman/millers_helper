-- core/engine/registry.lua
--
-- Raw record sink for values + fields + shapes.
-- Core indexes Registry into fast lookup structures.
-- Registry retains all raw records for auditing/trace and tooling.

---@class StandardRecord
---@field kind "value"
---@field domain string
---@field name string
---@field type "symbol"|"number"
---@field description string|nil
---@field aliases string[]|nil
---@field value number|nil
---@field unit string|nil
---@field __source table|nil

---@class FieldRecord
---@field kind "field"
---@field domain string
---@field name string
---@field type "symbol"|"number"|"string"|"boolean"|"table"
---@field required boolean
---@field default any
---@field reference string|nil
---@field authority "authoritative"|"derived"|"system"|"archival"
---@field mutable boolean
---@field unit string|nil
---@field precision number|nil
---@field groups string[]|nil
---@field description string|nil
---@field aliases string[]|nil
---@field __source table|nil

---@class ShapeRecord
---@field kind "shape"
---@field domain string
---@field fields string[]
---@field description string|nil
---@field __source table|nil

local Registry = {}

Registry._values = {} ---@type table<string, StandardRecord[]>
Registry._fields = {} ---@type table<string, FieldRecord[]>
Registry._shapes = {} ---@type table<string, ShapeRecord>

local function attach_source(record, source)
    record.__source = source
    return record
end

local function assert_field_record(r, source)

    assert(type(r) == "table",
        ("[registry] field record must be table (%s)")
        :format(source or "unknown")
    )

    assert(r.kind == "field",
        ("[registry] field.kind must be 'field' (%s)")
        :format(source or "unknown")
    )

    assert(type(r.domain) == "string" and r.domain ~= "",
        ("[registry] field.domain required (%s)")
        :format(source or "unknown")
    )

    assert(type(r.name) == "string" and r.name ~= "",
        ("[registry] field.name required (%s)")
        :format(source or "unknown")
    )

    assert(type(r.type) == "string" and r.type ~= "",
        ("[registry] field.type required (%s)")
        :format(source or "unknown")
    )

    assert(type(r.required) == "boolean",
        ("[registry] field.required boolean required (%s:%s)")
        :format(source or "unknown", r.name)
    )

    -- default may be nil (per schema contract)
    assert(r.default ~= nil or true, "")

    assert(type(r.authority) == "string" and r.authority ~= "",
        ("[registry] field.authority required (%s:%s)")
        :format(source or "unknown", r.name)
    )

    assert(type(r.mutable) == "boolean",
        ("[registry] field.mutable boolean required (%s:%s)")
        :format(source or "unknown", r.name)
    )

    ------------------------------------------------
    -- reference validation (syntax only)
    ------------------------------------------------

    if r.reference ~= nil then

        local msg = ([[
[field reference rule violation]

rule: IF field.reference THEN reference must be a schema domain identifier

field: %s.%s
module: %s
received reference: %s

expected reference formats:

value domain:
    board.surface
    order.status
    allocation.basis

field domain:
    board
    order
    allocation_entry

note:
    semantic validation occurs later during indexer build.
]]):format(
            r.domain or "unknown",
            r.name or "unknown",
            source or "unknown",
            tostring(r.reference)
        )

        assert(type(r.reference) == "string", msg)

        -- prevent obvious malformed values
        assert(
            not r.reference:find("%s"),
            msg
        )

    end

    ------------------------------------------------
    -- optional collections
    ------------------------------------------------

    if r.aliases ~= nil then
        assert(type(r.aliases) == "table",
            ("[registry] field.aliases must be table|nil (%s:%s)")
            :format(source or "unknown", r.name)
        )
    end

    if r.groups ~= nil then
        assert(type(r.groups) == "table",
            ("[registry] field.groups must be table|nil (%s:%s)")
            :format(source or "unknown", r.name)
        )
    end

end

local function assert_standard_record(r, source)
    assert(type(r) == "table", ("[registry] value record must be table (%s)"):format(source or "unknown"))
    assert(r.kind == "value", ("[registry] value.kind must be 'value' (%s)"):format(source or "unknown"))
    assert(type(r.domain) == "string" and r.domain ~= "", ("[registry] value.domain required (%s)"):format(source or "unknown"))
    assert(type(r.name) == "string" and r.name ~= "", ("[registry] value.name required (%s)"):format(source or "unknown"))
    assert(r.type == "symbol" or r.type == "number", ("[registry] value.type must be symbol|number (%s:%s)"):format(source or "unknown", r.name))

    if r.aliases ~= nil then
        assert(type(r.aliases) == "table", ("[registry] value.aliases must be table|nil (%s:%s)"):format(source or "unknown", r.name))
    end
end

local function assert_shape_record(s, source)
    assert(type(s) == "table", ("[registry] shape must be table (%s)"):format(source or "unknown"))
    assert(s.kind == "shape" or s.SHAPE ~= nil or s.SHAPE == nil, "") -- allow normalized or module form
    local shape = s.SHAPE or s
    assert(type(shape.domain) == "string" and shape.domain ~= "", ("[registry] shape.domain required (%s)"):format(source or "unknown"))
    assert(type(shape.fields) == "table", ("[registry] shape.fields must be table (%s:%s)"):format(source or "unknown", shape.domain))
end

------------------------------------------------------------
-- Registration
------------------------------------------------------------

---@param module { VALUE: table<string, StandardRecord> }|{ VALUE: StandardRecord[] }
---@param source string|nil
function Registry.register_standard(module, source)
    local src = { module = source or "unknown", kind = "standard" }
    local values = module.VALUE or {}

    for _, record in pairs(values) do
        assert_standard_record(record, source)
        attach_source(record, src)
        local domain = record.domain
        Registry._values[domain] = Registry._values[domain] or {}
        table.insert(Registry._values[domain], record)
    end
end

---@param module { FIELD: table<string, FieldRecord> }|{ FIELD: FieldRecord[] }
---@param source string|nil
function Registry.register_fields(module, source)
    local src = { module = source or "unknown", kind = "fields" }
    local fields = module.FIELD or {}

    for _, record in pairs(fields) do
        assert_field_record(record, source)
        attach_source(record, src)
        local domain = record.domain
        Registry._fields[domain] = Registry._fields[domain] or {}
        table.insert(Registry._fields[domain], record)
    end
end

---@param module { SHAPE: { domain: string, fields: string[], description?: string } }|{ domain: string, fields: string[], description?: string }
---@param source string|nil
function Registry.register_shapes(module, source)
    local src = { module = source or "unknown", kind = "shape" }
    assert_shape_record(module, source)

    local shape = module.SHAPE or module
    local record = {
        kind = "shape",
        domain = shape.domain,
        fields = shape.fields,
        description = shape.description,
    }

    attach_source(record, src)
    Registry._shapes[record.domain] = record
end

return Registry
