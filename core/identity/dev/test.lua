-- core/identity/dev/test.lua
--
-- Simple identity module test harness.

local I = require("inspector")   -- optional if you already use it
local ID = require("core.identity")

print("\n==============================")
print("IDENTITY TEST")
print("==============================")

------------------------------------------------
-- sample board
------------------------------------------------

local board = {
    base_h   = 1,
    base_w   = 6,
    l        = 12,
    ct       = 19,
    tag      = "n",
    species  = "RW",
    grade    = "CC",
    -- moisture = "KD",
    surface  = "S4S"
}

print("\nBoard input:")
I.print(board)

local label = ID.board.label(board)
local full = label:full()
print(full)
I.print(ID.board.parse(full))
