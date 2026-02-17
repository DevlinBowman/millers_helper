-- tools/system_index/internal/persist.lua

local Persist = {}

local COVERAGE_PATH = "data/system_index_coverage.lua"

----------------------------------------------------------------
-- Serialize
----------------------------------------------------------------

local function serialize_table(tbl, indent)
    indent = indent or 0
    local padding = string.rep("  ", indent)

    local lines = {"{"}

    for _, value in ipairs(tbl) do
        table.insert(lines,
            padding .. "  " .. string.format("%q,", value))
    end

    table.insert(lines, padding .. "}")
    return table.concat(lines, "\n")
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function Persist.save(list)
    local file = assert(io.open(COVERAGE_PATH, "w"))

    file:write("return ")
    file:write(serialize_table(list))
    file:write("\n")

    file:close()
end

function Persist.load()
    local ok, result = pcall(dofile, COVERAGE_PATH)
    if not ok then
        return {}
    end
    return result
end

return Persist
