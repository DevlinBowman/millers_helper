-- core/domain/pricing/contracts.lua
--
-- Pricing service contract authority.
-- This module defines:
--   • how pricing context is built
--   • which capabilities exist
--   • which strategies require which capabilities

local Input       = require("core.domain.pricing.internal.input")
local TargetValue = require("core.domain.pricing.internal.target_value")

local Contracts = {}

------------------------------------------------------------
-- Context Builder
------------------------------------------------------------

---@param source any
---@param basis string
---@param opts table|nil
---@return table
function Contracts.build_env(source, basis, opts)
    opts = opts or {}

    local boards = Input.extract_boards(source)

    return {
        source = source,
        basis  = basis,

        boards = {
            kind  = "boards",
            items = boards,
        },

        allocations = opts.allocations,
        vendor      = opts.vendor,
        compare     = opts.compare,

        opts = opts,
    }
end

------------------------------------------------------------
-- Capability Checks
------------------------------------------------------------

Contracts.capabilities = {}

---@param env table
---@return boolean
function Contracts.capabilities.boards(env)
    return type(env) == "table"
        and type(env.boards) == "table"
        and env.boards.kind == "boards"
        and type(env.boards.items) == "table"
end

---@param env table
---@return boolean
function Contracts.capabilities.vendor(env)
    return type(env) == "table"
        and type(env.vendor) == "table"
        and env.vendor.kind == "vendor"
        and type(env.vendor.items) == "table"
end

---@param env table
---@return boolean
function Contracts.capabilities.allocations(env)
    return env ~= nil and env.allocations ~= nil
end

---@param env table
---@return boolean
function Contracts.capabilities.compare(env)
    return env ~= nil and env.compare ~= nil
end

---@param env table
---@return boolean
function Contracts.capabilities.order_total(env)
    local value = TargetValue.resolve(env and env.source, env and env.opts)
    return type(value) == "number"
end

------------------------------------------------------------
-- Contract Shape
------------------------------------------------------------

Contracts.base = {
    required = {
        "boards",
    },

    optional = {
        "vendor",
        "allocations",
        "compare",
    }
}

Contracts.strategies = {
    vendor_anchor = {
        required = {
            "vendor",
        },

        optional = {
            "allocations",
            "compare",
        },

        opts = {
            "percentage",
            "profile",
        }
    },

    reverse_order_value = {
        required = {
            "order_total",
        },

        optional = {
            "allocations",
        },

        opts = {
            "target_total_value",
            "profile",
        }
    }
}

return Contracts
