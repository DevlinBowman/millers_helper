-- pipelines/export/project.lua
--
-- Domain projection layer.
--
-- Accepts EITHER:
--
-- 1) Grouped shape:
--    {
--      { order={}, boards={} }
--    }
--
-- 2) Flat shape:
--    {
--      { order={}, board={} }
--    }
--
-- Outputs:
--   { { key=value, ... }, ... }

local Project = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function merge(dst, src)
    if type(src) ~= "table" then return end
    for k, v in pairs(src) do
        dst[k] = v
    end
end

local function is_grouped_shape(t)
    return type(t) == "table"
        and type(t[1]) == "table"
        and t[1].boards ~= nil
end

local function is_flat_shape(t)
    return type(t) == "table"
        and type(t[1]) == "table"
        and t[1].board ~= nil
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Project.groups_to_objects(input)
    assert(type(input) == "table", "export input must be array")

    local objects = {}

    ------------------------------------------------------------
    -- GROUPED SHAPE
    ------------------------------------------------------------

    if is_grouped_shape(input) then
        for i, group in ipairs(input) do
            assert(type(group.order) == "table",
                "group[" .. i .. "].order missing")
            assert(type(group.boards) == "table",
                "group[" .. i .. "].boards missing")

            for _, board in ipairs(group.boards) do
                local obj = {}
                merge(obj, group.order)
                merge(obj, board)
                objects[#objects + 1] = obj
            end
        end

        return objects
    end

    ------------------------------------------------------------
    -- FLAT SHAPE
    ------------------------------------------------------------

    if is_flat_shape(input) then
        for i, item in ipairs(input) do
            assert(type(item.board) == "table",
                "item[" .. i .. "].board missing")

            local obj = {}

            if type(item.order) == "table" then
                merge(obj, item.order)
            end

            merge(obj, item.board)

            objects[#objects + 1] = obj
        end

        return objects
    end

    ------------------------------------------------------------
    -- UNKNOWN SHAPE
    ------------------------------------------------------------

    error("export projection: unsupported input shape")
end

return Project
