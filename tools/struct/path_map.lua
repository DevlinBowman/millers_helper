-- tools/struct/path_map.lua

local M = {}

local function is_array(tbl)
    return type(tbl) == "table" and #tbl > 0
end

local function walk(value, prefix, paths, visited)
    prefix = prefix or ""
    paths = paths or {}
    visited = visited or {}

    if type(value) ~= "table" then
        paths[prefix] = type(value)
        return paths
    end

    if visited[value] then
        return paths
    end
    visited[value] = true

    if is_array(value) then
        local array_path = prefix .. "[]"
        paths[array_path] = "array"

        if value[1] then
            walk(value[1], array_path, paths, visited)
        end

        return paths
    end

    for key, v in pairs(value) do
        local new_prefix
        if prefix == "" then
            new_prefix = key
        else
            new_prefix = prefix .. "." .. key
        end

        walk(v, new_prefix, paths, visited)
    end

    return paths
end

function M.print(result)
    local paths = walk(result)

    local sorted = {}
    for k in pairs(paths) do
        sorted[#sorted + 1] = k
    end
    table.sort(sorted)

    print("\n============= PATH MAP =============\n")

    for _, path in ipairs(sorted) do
        print(path)
    end

    print("\n====================================\n")
end

return M
