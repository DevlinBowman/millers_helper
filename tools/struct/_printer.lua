-- tools/struct/_printer.lua

local Printer = {}

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

local function sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl or {}) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function indent(depth)
    return string.rep("  ", depth)
end

local function header(title)
    print("\n============================================================")
    print(title)
    print("============================================================")
end

local function footer()
    print("============================================================\n")
end

----------------------------------------------------------------
-- Generic Recursive Table Printer
----------------------------------------------------------------

local function print_table(tbl, depth)
    depth = depth or 0

    if type(tbl) ~= "table" then
        print(indent(depth) .. tostring(tbl))
        return
    end

    for _, key in ipairs(sorted_keys(tbl)) do
        local value = tbl[key]

        if type(value) == "table" then
            print(indent(depth) .. tostring(key) .. " = {")
            print_table(value, depth + 1)
            print(indent(depth) .. "}")
        else
            print(indent(depth) .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

----------------------------------------------------------------
-- Public Printers
----------------------------------------------------------------

function Printer.print(title, tbl)
    header(title)
    print_table(tbl, 1)
    footer()
end

function Printer.print_schema(name, fields)
    header("SCHEMA: " .. name)

    for _, key in ipairs(sorted_keys(fields)) do
        local field = fields[key]
        local role  = field.role or "?"
        print(string.format("  %-20s | role=%s", key, role))
    end

    footer()
end

function Printer.print_contract(name, contract)
    header("CONTRACT: " .. name)

    for _, method in ipairs(sorted_keys(contract)) do
        local def = contract[method]
        print("  " .. method)

        if type(def.in_) == "table" then
            print("    in:")
            for _, k in ipairs(sorted_keys(def.in_)) do
                print("      " .. k)
            end
        end

        if type(def.out) == "table" then
            print("    out:")
            for _, k in ipairs(sorted_keys(def.out)) do
                print("      " .. k)
            end
        end
    end

    footer()
end

function Printer.print_spec(name, mod)
    header("SPEC: " .. name)

    if type(mod.fields) == "table" then
        print("  fields:")
        for _, key in ipairs(sorted_keys(mod.fields)) do
            print("    " .. key)
        end
    end

    if mod.default ~= nil then
        print("  default:")
        if type(mod.default) == "table" then
            for _, key in ipairs(sorted_keys(mod.default)) do
                print("    " .. key)
            end
        else
            print("    " .. tostring(mod.default))
        end
    end

    footer()
end

return Printer
