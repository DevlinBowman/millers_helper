-- scripts/test_allocations.lua

local Alloc = require("core.model.allocations")
local Board = require("core.model.board")
local Order = require("core.model.order")

------------------------------------------------------------
-- 1. Build Allocation Profile
------------------------------------------------------------

local profile = Alloc.controller
    .build("standard_split")
    .profile

------------------------------------------------------------
-- 2. Build Example Boards
------------------------------------------------------------

local boards = {}

do
    local result = Board.controller.build({
        base_h = 2,
        base_w = 6,
        l      = 10,
        ct     = 100,
        bf_price = 4.50,  -- irrelevant for cost surface
    })

    assert(result.board, "board failed")
    boards[1] = result.board
end

--------------------------------------------------------
-- 3. Build Example Order (no revenue required)
------------------------------------------------------------

local order_result = Order.controller.build({
    order_number = "TEST-001",
}, boards)

local order = order_result.order

------------------------------------------------------------
-- 4. Compute Cost Surface (Cost-Only)
------------------------------------------------------------

local surface = Alloc.controller
    .cost_surface(order, boards, profile)
    .surface

------------------------------------------------------------
-- 5. Format Output
------------------------------------------------------------

local output = Alloc.controller
    .format_cost_surface(surface)

print(output)
