-- presentation/exports/compare/layout.lua
--
-- Column schemas for comparison printing.

local CompareLayout = {}

CompareLayout.header = {
    { "Source", 15, "L" },
    { "Matched", 28, "L" },
    { "ea", 10, "R" },
    { "lf", 10, "R" },
    { "bf", 10, "R" },
    { "total", 12, "R" },
    { "match", 10, "L" },
}

return CompareLayout
