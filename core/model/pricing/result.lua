-- core/model/pricing/result.lua
--
-- PricingResult DTO
--
-- Responsibilities:
--   • Wrap raw pricing engine payload
--   • Provide safe read accessors
--   • Provide debug helpers
--
-- NOTE:
--   This module MUST NOT depend on the controller.
--   It is a pure DTO wrapper.

----------------------------------------------------------------
-- Types
----------------------------------------------------------------

---@class PricingEngineResult
---@field basis string
---@field profile_id string
---@field cost_floor_per_bf number|nil
---@field per_board table[]
---@field meta table|nil
---@field opts table|nil

---@class PricingResult
---@field private __data PricingEngineResult
local PricingResult = {}
PricingResult.__index = PricingResult

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param data PricingEngineResult
---@return PricingResult
function PricingResult.new(data)

    assert(type(data) == "table", "[pricing.result] data table required")

    return setmetatable({
        __data = data
    }, PricingResult)

end

----------------------------------------------------------------
-- Debug
----------------------------------------------------------------

--- Returns raw engine result payload.
---@return PricingEngineResult
function PricingResult:raw()
    return self.__data
end

function PricingResult:__tostring()
    local basis = self.__data.basis or "unknown"
    local count = #(self.__data.per_board or {})

    return string.format(
        "[PricingResult basis=%s boards=%d]",
        tostring(basis),
        count
    )
end

----------------------------------------------------------------
-- Core Fields
----------------------------------------------------------------

---@return string
function PricingResult:basis()
    return self.__data.basis
end

---@return string
function PricingResult:profile_id()
    return self.__data.profile_id
end

---@return number|nil
function PricingResult:cost_floor_per_bf()
    return self.__data.cost_floor_per_bf
end

----------------------------------------------------------------
-- Per-Board Data
----------------------------------------------------------------

---@return table[]
function PricingResult:per_board()
    return self.__data.per_board or {}
end

---@param index number
---@return table
function PricingResult:board(index)

    assert(type(index) == "number" and index >= 1,
        "[pricing.result] board index must be positive integer")

    local boards = self.__data.per_board or {}

    local item = boards[index]

    if not item then
        error("[pricing.result] board not found at index " .. tostring(index), 2)
    end

    return item

end

----------------------------------------------------------------
-- Board Convenience Accessors
----------------------------------------------------------------

---@param index number
---@return number|nil
function PricingResult:suggested_price_per_bf(index)
    local b = self:board(index)
    return b.suggested_price_per_bf
end

---@param index number
---@return number|nil
function PricingResult:recommended_price_per_bf(index)
    local b = self:board(index)
    return b.recommended_price_per_bf
end

---@param index number
---@return string|nil
function PricingResult:recommendation_mode(index)
    local b = self:board(index)
    return b.recommendation_mode
end

----------------------------------------------------------------
-- Metadata
----------------------------------------------------------------

---@return table
function PricingResult:meta()
    return self.__data.meta or {}
end

---@return table
function PricingResult:opts()
    return self.__data.opts or {}
end

----------------------------------------------------------------

return PricingResult
