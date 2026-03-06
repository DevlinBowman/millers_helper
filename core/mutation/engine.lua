-- core/mutation/engine.lua
--
-- Generic mutation engine for domain models.
-- Applies patch, clears derived fields, triggers recalc.

local Engine = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function clear_derived_fields(object, schema)
    local roles = schema.ROLES
    local fields = schema.fields

    for field, def in pairs(fields) do
        if def.role == roles.DERIVED then
            object[field] = nil
        end
    end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Apply a mutation patch to an object.
---
--- @param object table  -- domain object (board, order, etc)
--- @param patch table   -- fields to update
--- @param schema table  -- model schema
--- @param opts table|nil { immutable?:table }
--- @return table object
function Engine.apply(object, patch, schema, opts)
    assert(type(object) == "table", "MutationEngine.apply(): object required")
    assert(type(patch) == "table", "MutationEngine.apply(): patch table required")
    assert(type(schema) == "table", "MutationEngine.apply(): schema required")

    opts = opts or {}
    local immutable = opts.immutable or {}

    ------------------------------------------------------------
    -- Apply patch
    ------------------------------------------------------------

    for k, v in pairs(patch) do
        if immutable[k] then
            error("MutationEngine.apply(): field '" .. k .. "' is immutable")
        end
        object[k] = v
    end

    ------------------------------------------------------------
    -- Clear derived fields
    ------------------------------------------------------------

    clear_derived_fields(object, schema)

    ------------------------------------------------------------
    -- Recalculate
    ------------------------------------------------------------

    if object.recalc then
        object:recalc()
    end

    return object
end

return Engine
