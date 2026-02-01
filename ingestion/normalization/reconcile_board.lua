local Schema = require("core.board.schema")

---@class BoardReconcile
local BoardIngest = {}

----------------------------------------------------------------
-- Record → board spec (schema-driven, lossless)
----------------------------------------------------------------

---@param record table
---@return table
function BoardIngest.record_to_spec(record)
    assert(type(record) == "table", "record must be table")

    local spec = {}
    local seen = {}

    ----------------------------------------------------------------
    -- Pass 1: Schema-mapped fields (authoritative)
    ----------------------------------------------------------------
    for key, value in pairs(record) do
        local canonical = Schema.alias_index[key]
        if canonical then
            local def = Schema.fields[canonical]
            local coerced = def.coerce and def.coerce(value) or value

            if coerced ~= nil and coerced ~= "" then
                spec[canonical] = coerced
                seen[canonical] = true
            end
        end
    end

    ----------------------------------------------------------------
    -- Pass 2: Apply schema defaults
    ----------------------------------------------------------------
    for canonical, def in pairs(Schema.fields) do
        if not seen[canonical] and def.default ~= nil then
            spec[canonical] = def.default
        end
    end

    ----------------------------------------------------------------
    -- Pass 3: Preserve arbitrary non-schema fields (CSV/TEXT parity)
    ----------------------------------------------------------------
    for key, value in pairs(record) do
        if type(key) == "string"
            and spec[key] == nil
            and not key:match("^_")
            and not key:match("^__")
        then
            spec[key] = value
        end
    end

    ----------------------------------------------------------------
    -- Structural invariants (non-negotiable)
    ----------------------------------------------------------------
    assert(
        spec.base_h and spec.base_w and spec.l,
        "ingest.board: missing required dimensions (base_h, base_w, l)"
    )

    return spec
end

----------------------------------------------------------------
-- Records → board_specs
----------------------------------------------------------------

---@param records { kind: "records", data: table[], meta: table }
---@return { kind: "board_specs", data: table[], meta: table }
function BoardIngest.run(records)
    assert(records.kind == "records", "expected records")

    local out = {}
    local meta = records.meta or {}


    for i, record in ipairs(records.data) do
        local ok, spec = pcall(BoardIngest.record_to_spec, record)
        if not ok then
            error(("reconcile(board) failed at record %d: %s"):format(i, spec))
        end
        out[#out + 1] = spec
    end

    return {
        kind = "board_specs",
        data = out,
        meta = meta,
    }
end

return BoardIngest
