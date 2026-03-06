-- scripts/test_schema_requires.lua
--
-- Verifies that every Lua module inside core/schema
-- can be required successfully.

local lfs = require("lfs")

------------------------------------------------------------
-- configuration
------------------------------------------------------------

local ROOT_DIR = "core/schema"
local MODULE_PREFIX = "core.schema"

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function path_to_module(path)

    -- remove .lua
    path = path:gsub("%.lua$", "")

    -- normalize slashes
    path = path:gsub("^core/schema", MODULE_PREFIX)

    -- convert / to .
    path = path:gsub("/", ".")

    return path
end

------------------------------------------------------------
-- module tester
------------------------------------------------------------

local failures = {}
local tested = 0

local function test_module(module)

    tested = tested + 1

    local ok, err = pcall(require, module)

    if not ok then
        failures[#failures + 1] = {
            module = module,
            error = err
        }

        print("FAIL:", module)
        print(err)
        print("")
    else
        print("OK:", module)
    end

end

------------------------------------------------------------
-- recursive directory walk
------------------------------------------------------------

local function walk(dir)

    for entry in lfs.dir(dir) do

        if entry ~= "." and entry ~= ".." then

            local path = dir .. "/" .. entry
            local attr = lfs.attributes(path)

            if attr.mode == "directory" then

                walk(path)

            elseif attr.mode == "file" and entry:match("%.lua$") then

                local module = path_to_module(path)
                test_module(module)

            end

        end
    end

end

------------------------------------------------------------
-- run
------------------------------------------------------------

print("")
print("===================================")
print(" Checking Schema Module Requires")
print("===================================")
print("")

walk(ROOT_DIR)

print("")
print("===================================")
print(" Summary")
print("===================================")
print("Modules tested:", tested)
print("Failures:", #failures)

if #failures > 0 then

    print("")
    print("Broken modules:")

    for _, f in ipairs(failures) do
        print(" -", f.module)
    end

end
