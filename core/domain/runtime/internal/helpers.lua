-- core/domain/runtime/internal/helpers.lua
--
-- Runtime structural helpers.
--
-- PURE LOGIC ONLY.
-- No tracing.
-- No contract enforcement.
-- No controller concerns.
--
-- Responsibilities:
-- • Canonical RuntimeBatch shape checks
-- • Canonical RuntimeBatch[] validation
-- • Envelope unwrapping
-- • Batch resolution with injectable loader
--
-- Canonical RuntimeBatch shape:
--   {
--     order  = table,
--     boards = table[],
--   }

---@class RuntimeBatch
---@field order table
---@field boards table[]

local Helpers = {}

----------------------------------------------------------------
-- SHAPE CHECKS
----------------------------------------------------------------

--- Determine if value matches canonical RuntimeBatch shape.
--- @param value any
--- @return boolean
function Helpers.is_batch(value)
    return type(value) == "table"
        and type(value.order) == "table"
        and type(value.boards) == "table"
end

--- Determine if value is RuntimeBatch[].
--- Empty arrays are NOT considered canonical.
--- @param value any
--- @return boolean
function Helpers.is_batch_array(value)
    if type(value) ~= "table" then
        return false
    end

    -- Prevent single batch misclassification
    if Helpers.is_batch(value) then
        return false
    end

    for _, v in ipairs(value) do
        if not Helpers.is_batch(v) then
            return false
        end
    end

    return #value > 0
end

--- Hard structural validation of RuntimeBatch[].
--- Errors if malformed.
--- @param batches RuntimeBatch[]
function Helpers.assert_batch_array(batches)
    if type(batches) ~= "table" then
        error("[runtime] batches must be table", 2)
    end

    for i, batch in ipairs(batches) do
        if not Helpers.is_batch(batch) then
            error(
                string.format(
                    "[runtime] invalid batch at index %d (expected {order, boards})",
                    i
                ),
                2
            )
        end
    end
end

----------------------------------------------------------------
-- ENVELOPE UNWRAP
----------------------------------------------------------------

--- Recursively unwrap envelope structures.
---
--- Recognizes:
---   { data = table }
---
--- Stops when no further unwrap is possible.
---
--- @param input any
--- @return any
function Helpers.unwrap_envelope(input)
    if type(input) ~= "table" then
        return input
    end

    if input.data and type(input.data) == "table" then
        return Helpers.unwrap_envelope(input.data)
    end

    return input
end

----------------------------------------------------------------
-- RESOLUTION ENGINE
----------------------------------------------------------------

--- Normalize arbitrary runtime input into RuntimeBatch[].
---
--- Resolution order:
---   1. Envelope unwrap
---   2. Canonical RuntimeBatch[] passthrough
---   3. Canonical RuntimeBatch auto-wrap
---   4. Loader fallback (if provided)
---
--- Loader must be a function:
---   loader(input) → RuntimeBatch[]
---
--- @param input any
--- @param loader function|nil
--- @return RuntimeBatch[]
function Helpers.resolve_batches(input, loader)
    if input == nil then
        error("[runtime] input required", 2)
    end

    input = Helpers.unwrap_envelope(input)

    -- Canonical batch[]
    if Helpers.is_batch_array(input) then
        Helpers.assert_batch_array(input)
        return input
    end

    -- Single canonical batch
    if Helpers.is_batch(input) then
        return { input }
    end

    -- Loader fallback
    if type(loader) ~= "function" then
        error("[runtime] loader required for non-canonical input", 2)
    end

    local batches, err = loader(input)

    -- NEW: structured loader failure support
    if not batches then
        return nil, err
    end

    Helpers.assert_batch_array(batches)

    return batches
end----------------------------------------------------------------

return Helpers
