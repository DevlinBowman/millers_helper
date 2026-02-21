-- scripts/struct.lua
--
-- Zero-setup CLI for tools.struct with deterministic fuzzy matching

----------------------------------------------------------------
-- Bootstrap: ensure project root is in package.path
----------------------------------------------------------------

local function get_script_dir()
    local info = debug.getinfo(1, "S")
    local source = info.source

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    return source:match("(.*/)")
end

local function inject_project_root()
    local script_dir = get_script_dir()
    if not script_dir then return end

    local project_root = script_dir:gsub("scripts/$", "")

    package.path =
        project_root .. "?.lua;" ..
        project_root .. "?/init.lua;" ..
        package.path
end

inject_project_root()

----------------------------------------------------------------
-- Load StructTool
----------------------------------------------------------------

local StructTool = require("tools.struct")

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

local function print_usage()
    print([[
struct usage:

  categories
  all
  <category>
  <category> list
  <category> <key>
]])
end

local function resolve_single(input, candidates)
    -- exact match
    for _, name in ipairs(candidates) do
        if name == input then
            return name
        end
    end

    -- prefix match
    local prefix_matches = {}
    for _, name in ipairs(candidates) do
        if name:find("^" .. input) then
            prefix_matches[#prefix_matches + 1] = name
        end
    end

    if #prefix_matches == 1 then
        return prefix_matches[1]
    elseif #prefix_matches > 1 then
        return nil, prefix_matches
    end

    -- substring match (plain search)
    local substring_matches = {}
    for _, name in ipairs(candidates) do
        if name:find(input, 1, true) then
            substring_matches[#substring_matches + 1] = name
        end
    end

    if #substring_matches == 1 then
        return substring_matches[1]
    elseif #substring_matches > 1 then
        return nil, substring_matches
    end

    return nil
end

local function resolve_category(input)
    return resolve_single(input, StructTool.categories())
end

local function resolve_key(section, input)
    return resolve_single(input, section.list())
end

local function print_ambiguity(label, matches)
    print("ambiguous " .. label .. ":")
    for _, name in ipairs(matches) do
        print("  " .. name)
    end
end

----------------------------------------------------------------
-- Main
----------------------------------------------------------------

local args = { ... }

if #args == 0 then
    print_usage()
    os.exit(1)
end

local command = args[1]

-- categories
if command == "categories" then
    for _, name in ipairs(StructTool.categories()) do
        print(name)
    end
    return
end

-- all
if command == "all" then
    StructTool.print_all()
    return
end

----------------------------------------------------------------
-- Resolve Category
----------------------------------------------------------------

local category, cat_matches = resolve_category(command)

if not category then
    if cat_matches then
        print_ambiguity("category", cat_matches)
    else
        print("unknown category:", command)
    end
    os.exit(1)
end

local section = StructTool[category]

-- only category → print entire category
if #args == 1 then
    StructTool.print_category(category)
    return
end

-- list keys
if args[2] == "list" then
    for _, key in ipairs(section.list()) do
        print(key)
    end
    return
end

----------------------------------------------------------------
-- Resolve Key
----------------------------------------------------------------

local key_input = args[2]
local resolved_key, key_matches = resolve_key(section, key_input)

if not resolved_key then
    if key_matches then
        print_ambiguity("key", key_matches)
    else
        print("unknown key:", key_input)
    end
    os.exit(1)
end

section.print(resolved_key, args[3])
