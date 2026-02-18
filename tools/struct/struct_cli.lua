#!/usr/bin/env lua
--
-- scripts/struct_cli.lua
--
-- Simple CLI for tools.struct
--
-- Usage:
--   lua scripts/struct_cli.lua categories
--   lua scripts/struct_cli.lua all
--   lua scripts/struct_cli.lua <category>
--   lua scripts/struct_cli.lua <category> <key>
--   lua scripts/struct_cli.lua <category> list

local StructTool = require("tools.struct")

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function print_usage()
    print([[
struct_cli usage:

  categories                 List available categories
  all                        Print everything
  <category>                 Print entire category
  <category> list            List keys in category
  <category> <key>           Print specific entry

Examples:
  lua scripts/struct_cli.lua schema
  lua scripts/struct_cli.lua schema model.board
  lua scripts/struct_cli.lua contract list
]])
end

local function get_section(category)
    local categories = StructTool.categories()
    for _, name in ipairs(categories) do
        if name == category then
            return StructTool[category]
        end
    end
    return nil
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

-- list categories
if command == "categories" then
    for _, name in ipairs(StructTool.categories()) do
        print(name)
    end
    os.exit(0)
end

-- print everything
if command == "all" then
    StructTool.print_all()
    os.exit(0)
end

-- category-specific
local category = command
local section = get_section(category)

if not section then
    print("unknown category: " .. tostring(category))
    print_usage()
    os.exit(1)
end

-- only category provided → print whole category
if #args == 1 then
    StructTool.print_category(category)
    os.exit(0)
end

-- category list
if args[2] == "list" then
    for _, key in ipairs(section.list()) do
        print(key)
    end
    os.exit(0)
end

-- category + specific key
local key = args[2]
section.print(key)
