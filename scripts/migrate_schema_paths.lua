-- scripts/migrate_schema_paths.lua
--
-- Updates require paths and header comments after moving the
-- schema engine from core/* to core/schema/*.

local lfs = require("lfs")

------------------------------------------------------------
-- configuration
------------------------------------------------------------

local ROOT = "core/schema"

local REQUIRE_REWRITES = {
    ["core.engine.runtime"] = "core.schema.engine.runtime",
    ["core.engine"]         = "core.schema.engine",
    ["core.fields"]         = "core.schema.fields",
    ["core.shapes"]         = "core.schema.shapes",
    ["core.values"]         = "core.schema.values",
    ["core.reference"]      = "core.schema.reference",
}

------------------------------------------------------------
-- file reader
------------------------------------------------------------

local function read_file(path)

    local f = assert(io.open(path, "r"))
    local data = f:read("*a")
    f:close()

    return data
end

------------------------------------------------------------
-- file writer
------------------------------------------------------------

local function write_file(path, data)

    local f = assert(io.open(path, "w"))
    f:write(data)
    f:close()

end

------------------------------------------------------------
-- rewrite require paths
------------------------------------------------------------

local function rewrite_requires(content)

    for old, new in pairs(REQUIRE_REWRITES) do
        content = content:gsub(old, new)
    end

    return content
end

------------------------------------------------------------
-- rewrite header comments
------------------------------------------------------------

local function rewrite_headers(content)

    content = content:gsub(
        "%-%-%s*core/engine/",
        "-- core/schema/engine/"
    )

    content = content:gsub(
        "%-%-%s*core/fields/",
        "-- core/schema/fields/"
    )

    content = content:gsub(
        "%-%-%s*core/shapes/",
        "-- core/schema/shapes/"
    )

    content = content:gsub(
        "%-%-%s*core/values/",
        "-- core/schema/values/"
    )

    content = content:gsub(
        "%-%-%s*core/reference/",
        "-- core/schema/reference/"
    )

    return content
end

------------------------------------------------------------
-- process single file
------------------------------------------------------------

local function process_file(path)

    local content = read_file(path)

    local updated = content

    updated = rewrite_requires(updated)
    updated = rewrite_headers(updated)

    if updated ~= content then
        print("updated:", path)
        write_file(path, updated)
    end

end

------------------------------------------------------------
-- recursive directory walk
------------------------------------------------------------

local function walk_directory(dir)

    for entry in lfs.dir(dir) do

        if entry ~= "." and entry ~= ".." then

            local path = dir .. "/" .. entry
            local attr = lfs.attributes(path)

            if attr.mode == "directory" then
                walk_directory(path)

            elseif entry:match("%.lua$") then
                process_file(path)
            end

        end
    end

end

------------------------------------------------------------
-- entrypoint
------------------------------------------------------------

local function main()

    print("Migrating schema require paths...")

    walk_directory(ROOT)

    print("Migration complete.")

end

main()
