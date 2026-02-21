-- core/domain/runtime/internal/batch.lua
--
-- Pure batch utilities.
-- Operates on canonical batch arrays:
--   { { order=table, boards=table[] }[] }

local Batch = {}

----------------------------------------------------------------
-- Validation
----------------------------------------------------------------

local function assert_batches(batches)
    assert(type(batches) == "table", "batches must be table")
end

local function assert_single(batches)
    assert_batches(batches)

    if #batches == 0 then
        return nil
    end

    if #batches > 1 then
        error("[runtime.batch] multiple batches present", 2)
    end

    return batches[1]
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Batch.get_batch(batches, index)
    assert_batches(batches)

    if index then
        return batches[index]
    end

    return assert_single(batches)
end

function Batch.get_boards(batches, index)
    local batch = Batch.get_batch(batches, index)
    if not batch then
        return {}
    end
    return batch.boards or {}
end

function Batch.get_order(batches, index)
    local batch = Batch.get_batch(batches, index)
    if not batch then
        return nil
    end
    return batch.order
end

function Batch.get_field(batches, key, index)
    local batch = Batch.get_batch(batches, index)
    if not batch then
        return nil
    end
    return batch[key]
end

return Batch
