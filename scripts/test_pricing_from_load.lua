-- scripts/test_pricing_from_runtime.lua

local Runtime = require("core.domain.runtime.controller")
local Alloc   = require("core.model.allocations")
local Pricing = require("core.model.pricing")
local I       = require("inspector")

------------------------------------------------------------
-- 1. Load Order via Runtime
------------------------------------------------------------

local path =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt"

local state = Runtime.load(
    path,
    { name = "pricing_test", category = "order" }
)

I.print(state, { shape_only = true })

------------------------------------------------------------
-- Validate Runtime State
------------------------------------------------------------

local batch = state:batch(1)

assert(batch, "[test] no batch returned from runtime")

local order  = state:order(1)
local boards = state:boards(1)

assert(order,  "[test] missing order")
assert(boards, "[test] missing boards")

assert(#boards > 0, "[test] no boards found")

print("\n========================================")
print("ORDER:", order.order_number or order.order_id or "unknown")
print("========================================\n")

------------------------------------------------------------
-- 2. Build Allocation Profile
------------------------------------------------------------

local alloc_profile = Alloc.controller
    .build("standard_split")
    .profile

------------------------------------------------------------
-- 3. Compute Cost Surface
------------------------------------------------------------

local cost_surface = Alloc.controller
    .cost_surface(order, boards, alloc_profile)
    .surface

------------------------------------------------------------
-- 4. Build Pricing Profile
------------------------------------------------------------

local pricing_profile = Pricing.controller
    .build_profile("default")
    .profile

------------------------------------------------------------
-- 5. Suggest Pricing
------------------------------------------------------------

local suggestion = Pricing.controller
    .suggest(
        boards,
        cost_surface,
        pricing_profile,
        nil, -- market matches (optional)
        {
            waste_ratio            = 0.12,
            rush_level             = 0,
            market_target_discount = 15,
        }
    )
    .suggestion

------------------------------------------------------------
-- 6. Print Result
------------------------------------------------------------

local text = Pricing.controller
    .format_suggestion(suggestion)
    .text

print(text)

------------------------------------------------------------
-- 7. Optional Provenance Check
------------------------------------------------------------

local meta = batch.meta or {}

if meta.io then
    print("\n[PROVENANCE]")
    print("source_path:", meta.io.source_path)
end
