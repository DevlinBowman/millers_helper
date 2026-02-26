-- core/domain/runtime/result.lua
--
-- RuntimeResult façade.
--
-- Wraps canonical RuntimeBatch[] and provides:
--   • Semantic accessors
--   • Query helpers
--   • Ergonomic indexed access (defaults to first batch)
--   • Debug helpers

local BatchUtil = require("core.domain.runtime.internal.batch")

----------------------------------------------------------------
-- Types
----------------------------------------------------------------

---@class RuntimeBatchMeta
---@field name string|nil
---@field category string|nil
---@field io table|nil

---@class RuntimeBatch
---@field order table
---@field boards table[]
---@field meta RuntimeBatchMeta|nil

---@class RuntimeResult
---@field private __batches RuntimeBatch[]
local RuntimeResult = {}
RuntimeResult.__index = RuntimeResult

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param batches RuntimeBatch[]
---@return RuntimeResult
function RuntimeResult.new(batches)
    assert(type(batches) == "table", "[runtime] batches must be table")

    return setmetatable({
        __batches = batches
    }, RuntimeResult)
end

----------------------------------------------------------------
-- Debug Surface
----------------------------------------------------------------

--- Returns raw underlying batches (debug escape hatch).
---@return RuntimeBatch[]
function RuntimeResult:raw()
    return self.__batches
end

function RuntimeResult:__tostring()
    return string.format(
        "[RuntimeResult batches=%d]",
        #self.__batches
    )
end

----------------------------------------------------------------
-- Internal Helpers
----------------------------------------------------------------

local function normalize_index(index)
    if index == nil then
        return 1
    end

    if type(index) ~= "number" or index < 1 then
        error("[runtime] index must be positive integer", 2)
    end

    return index
end

----------------------------------------------------------------
-- Core Access
----------------------------------------------------------------

--- Returns all runtime batches.
---@return RuntimeBatch[]
function RuntimeResult:batches()
    return self.__batches
end

--- Returns batch by index (defaults to first).
---@param index integer|nil
---@return RuntimeBatch
function RuntimeResult:batch(index)
    index = normalize_index(index)

    local batch = BatchUtil.get_batch(self.__batches, index)
    if not batch then
        error("[runtime] batch not found at index " .. tostring(index), 2)
    end

    return batch
end

--- Returns first batch.
---@return RuntimeBatch
function RuntimeResult:first()
    return self:batch(1)
end

----------------------------------------------------------------
-- Order Access
----------------------------------------------------------------

--- Returns all orders across batches.
---@return table[]
function RuntimeResult:orders()
    local out = {}

    for i = 1, #self.__batches do
        out[i] = self.__batches[i].order
    end

    return out
end

--- Returns order by batch index (defaults to first).
---@param index integer|nil
---@return table
function RuntimeResult:order(index)
    return self:batch(index).order
end

----------------------------------------------------------------
-- Board Access
----------------------------------------------------------------

--- Returns boards from specific batch,
--- or all boards across all batches if index omitted.
---@param index integer|nil
---@return table[]
function RuntimeResult:boards(index)
    if index ~= nil then
        return self:batch(index).boards or {}
    end

    local out = {}

    for i = 1, #self.__batches do
        local boards = self.__batches[i].boards or {}
        for j = 1, #boards do
            out[#out + 1] = boards[j]
        end
    end

    return out
end

----------------------------------------------------------------
-- Filtering
----------------------------------------------------------------

--- Returns runtime batches whose metadata category matches the given value.
---@param category string
---@return RuntimeBatch[]
function RuntimeResult:batches_by_category(category)
    if type(category) ~= "string" then
        error("[runtime] category must be string", 2)
    end

    local out = {}

    for i = 1, #self.__batches do
        local meta = self.__batches[i].meta
        if meta and meta.category == category then
            out[#out + 1] = self.__batches[i]
        end
    end

    return out
end

----------------------------------------------------------------

return RuntimeResult
